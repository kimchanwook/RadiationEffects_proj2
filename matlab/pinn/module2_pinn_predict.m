function prediction = module2_pinn_predict(net, query, params, scales)
% MODULE2_PINN_PREDICT Evaluate potential, field, and residual from a trained PINN.
%
%   prediction = MODULE2_PINN_PREDICT(net, query, params, scales)
%   accepts either:
%       query = FEM mesh structure containing query.nodes, or
%       query = N-by-2 numeric array of [x,y] coordinates in meters.
%
%   The function returns physical potential, electric field E=-grad(phi),
%   dimensional Poisson residual, and normalized residual at every point.

% Accept the existing FEM mesh directly so callers do not have to copy nodes.
if isstruct(query)
    % A mesh-like structure must expose its N-by-2 coordinate array as nodes.
    if ~isfield(query, 'nodes')
        error('module2_pinn_predict:MissingNodes', ...
            'A query structure must contain a nodes field.');
    end

    % Extract the physical query coordinates from the mesh.
    nodes = query.nodes;
else
    % Treat a numeric query directly as physical x-y coordinates.
    nodes = query;
end

% Verify that each query point has exactly two spatial coordinates.
validateattributes(nodes, {'numeric'}, ...
    {'2d', 'ncols', 2, 'real', 'finite', 'nonempty'}, ...
    mfilename, 'query coordinates');

% Normalize x by the physical x-length used during training.
xHat = nodes(:, 1) ./ params.Lx;

% Normalize y independently by the physical y-length.
yHat = nodes(:, 2) ./ params.Ly;

% Evaluate physical charge density at exactly the requested coordinates.
rho = build_space_charge_module2_2d(nodes, params);

% Enter an automatic-differentiation context for first and second derivatives.
[phi, Ex, Ey, residual, residualNormalized] = dlfeval(...
    @local_predict_with_derivatives, net, xHat, yHat, rho, params, scales);

% Preserve the physical coordinates alongside every predicted field.
prediction.nodes = nodes;

% Store physical potential in volts as an N-by-1 vector.
prediction.phi = phi;

% Store the reference physical charge density in C/m^3.
prediction.rho = rho;

% Store electric-field components using the same conventions as the FEM code.
prediction.field.Ex_nodal = Ex;
prediction.field.Ey_nodal = Ey;
prediction.field.Enodal = [Ex, Ey];

% Compute field magnitude from the two predicted Cartesian components.
prediction.field.Emag_nodal = sqrt(Ex.^2 + Ey.^2);

% Store the dimensional strong-form residual in C/m^3.
prediction.residual = residual;

% Store the dimensionless residual used by the training objective.
prediction.residualNormalized = residualNormalized;

% Cache useful extrema for reporting and coupling diagnostics.
prediction.maxAbsPhi = max(abs(phi));
prediction.maxAbsE = max(prediction.field.Emag_nodal);
prediction.maxAbsResidual = max(abs(residual));
prediction.rmsNormalizedResidual = sqrt(mean(residualNormalized.^2));
end

function [phi, Ex, Ey, residual, residualNormalized] = ...
    local_predict_with_derivatives(net, xHat, yHat, rho, params, scales)
% LOCAL_PREDICT_WITH_DERIVATIVES Evaluate network derivatives before extraction.

% Arrange normalized coordinates as two channels and N batch observations.
normalizedXY = dlarray([xHat(:).'; yHat(:).'], 'CB');

% Evaluate normalized potential at all requested points.
phiHat = forward(net, normalizedXY);

% Differentiate potential with respect to normalized x and y coordinates.
gradientXY = dlgradient(sum(phiHat, 'all'), normalizedXY, ...
    'EnableHigherDerivatives', true);

% Extract the two first derivatives required for electric field.
dPhiHatDxHat = gradientXY(1, :);
dPhiHatDyHat = gradientXY(2, :);

% Differentiate the x derivative again to obtain x curvature.
gradientOfXDerivative = dlgradient(sum(dPhiHatDxHat, 'all'), ...
    normalizedXY, 'EnableHigherDerivatives', true);

% Differentiate the y derivative again to obtain y curvature.
gradientOfYDerivative = dlgradient(sum(dPhiHatDyHat, 'all'), ...
    normalizedXY, 'EnableHigherDerivatives', true);

% Extract the two pure second derivatives entering the Laplacian.
d2PhiHatDxHat2 = gradientOfXDerivative(1, :);
d2PhiHatDyHat2 = gradientOfYDerivative(2, :);

% Recover dimensional potential from the normalized network output.
phiDeep = scales.V .* phiHat;

% Apply E_x=-dphi/dx and the normalized-to-physical chain rule.
ExDeep = -scales.V .* dPhiHatDxHat ./ params.Lx;

% Apply E_y=-dphi/dy and the normalized-to-physical chain rule.
EyDeep = -scales.V .* dPhiHatDyHat ./ params.Ly;

% Convert normalized curvature to the physical Laplacian of potential.
laplacianPhysical = scales.V .* (...
    d2PhiHatDxHat2 ./ params.Lx^2 + ...
    d2PhiHatDyHat2 ./ params.Ly^2);

% Package physical charge values so they can enter the differentiable expression.
rhoDeep = dlarray(rho(:).', 'CB');

% Evaluate eps*Laplacian(phi)+rho; the exact Poisson solution gives zero.
residualDeep = params.eps_si .* laplacianPhysical + rhoDeep;

% Divide by the same charge scale used by the PDE training loss.
residualNormalizedDeep = residualDeep ./ scales.rho;

% Extract ordinary CPU column vectors for downstream MATLAB calculations.
phi = double(gather(extractdata(phiDeep))).';
Ex = double(gather(extractdata(ExDeep))).';
Ey = double(gather(extractdata(EyDeep))).';
residual = double(gather(extractdata(residualDeep))).';
residualNormalized = ...
    double(gather(extractdata(residualNormalizedDeep))).';
end
