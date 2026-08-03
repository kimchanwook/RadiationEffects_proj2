function [loss, gradients, terms] = module2_pinn_loss(net, batch, params, scales, opts)
% MODULE2_PINN_LOSS Evaluate Module 2 PINN losses and parameter gradients.
%
%   [loss, gradients, terms] = MODULE2_PINN_LOSS(...) builds the weighted
%   objective
%
%       L = wPDE*LPDE + wDirichlet*LDirichlet
%           + wNeumann*LNeumann + wData*LData,
%
%   where the strong-form electrostatic residual is
%
%       eps_si*(d2phi/dx2 + d2phi/dy2) + rho = 0.
%
%   Call this function through dlfeval.  Automatic differentiation is used
%   first with respect to coordinates and then with respect to network
%   parameters.  The network input is [x/Lx; y/Ly], and its output is
%   phi/Vscale.

% Assemble normalized coordinates for interior collocation points.
interiorXY = dlarray([batch.xHatInterior(:).'; ...
                      batch.yHatInterior(:).'], 'CB');

% Obtain normalized potential, first derivatives, and pure second derivatives.
[~, ~, interiorCurvature] = ...
    local_phi_gradient_curvature(net, interiorXY);

% Convert sampled physical charge density to a labeled deep-learning array.
rhoInterior = dlarray(batch.rhoInterior(:).', 'CB');

% Convert normalized coordinate curvature back to the physical Laplacian.
laplacianPhysical = scales.V .* (...
    interiorCurvature.xx ./ params.Lx^2 + ...
    interiorCurvature.yy ./ params.Ly^2);

% Evaluate the dimensional Poisson residual in C/m^3.
residualPhysical = params.eps_si .* laplacianPhysical + rhoInterior;

% Divide by the reference charge scale before taking the mean-square loss.
residualNormalized = residualPhysical ./ scales.rho;

% The PDE loss penalizes violations throughout the interior collocation set.
lossPDE = mean(residualNormalized.^2, 'all');

% Evaluate the soft Dirichlet boundary penalty when such points are present.
if isempty(batch.xHatDirichlet)
    % Use an exact zero when the current boundary configuration has no Dirichlet side.
    lossDirichlet = dlarray(0.0);
else
    % Package normalized boundary coordinates as channel-by-batch observations.
    dirichletXY = dlarray([batch.xHatDirichlet(:).'; ...
                           batch.yHatDirichlet(:).'], 'CB');

    % Predict normalized potential at every Dirichlet boundary sample.
    phiHatDirichlet = forward(net, dirichletXY);

    % Normalize the prescribed physical voltage by the same output scale.
    phiHatTarget = dlarray(batch.phiDirichlet(:).' ./ scales.V, 'CB');

    % Penalize the mean-square normalized voltage mismatch.
    lossDirichlet = mean((phiHatDirichlet - phiHatTarget).^2, 'all');
end

% Evaluate the normal-derivative penalty on all Neumann boundary samples.
if isempty(batch.xHatNeumann)
    % Use an exact zero when the case has no Neumann boundary side.
    lossNeumann = dlarray(0.0);
else
    % Package normalized Neumann coordinates for automatic differentiation.
    neumannXY = dlarray([batch.xHatNeumann(:).'; ...
                         batch.yHatNeumann(:).'], 'CB');

    % Only first coordinate derivatives are needed for the normal gradient.
    [~, neumannGradient, ~] = local_phi_gradient_curvature(net, neumannXY);

    % Convert outward-normal components to labeled deep-learning arrays.
    normalX = dlarray(batch.normalX(:).', 'CB');
    normalY = dlarray(batch.normalY(:).', 'CB');

    % Convert the requested physical normal derivative to the same array form.
    normalDerivativeTarget = dlarray(batch.dphidn(:).', 'CB');

    % Apply the chain rule from normalized x-y coordinates to physical units.
    normalDerivativePrediction = scales.V .* (...
        normalX .* neumannGradient.x ./ params.Lx + ...
        normalY .* neumannGradient.y ./ params.Ly);

    % Normalize the derivative mismatch before forming its mean-square loss.
    derivativeMismatch = ...
        (normalDerivativePrediction - normalDerivativeTarget) ./ scales.gradPhi;

    % Penalize departures from the specified normal electric-potential gradient.
    lossNeumann = mean(derivativeMismatch.^2, 'all');
end

% Evaluate the optional sparse FEM supervision term.
if isempty(batch.xHatData)
    % A pure PINN sets the supervised data term exactly to zero.
    lossData = dlarray(0.0);
else
    % Package FEM-anchor coordinates using the same normalized input convention.
    dataXY = dlarray([batch.xHatData(:).'; ...
                      batch.yHatData(:).'], 'CB');

    % Predict normalized potential at the selected FEM nodes.
    phiHatDataPrediction = forward(net, dataXY);

    % Package already-normalized FEM target values.
    phiHatDataTarget = dlarray(batch.phiHatData(:).', 'CB');

    % Penalize the mean-square mismatch to sparse FEM reference values.
    lossData = mean((phiHatDataPrediction - phiHatDataTarget).^2, 'all');
end

% Form the scalar weighted objective optimized by Adam.
loss = opts.wPDE .* lossPDE + ...
       opts.wDirichlet .* lossDirichlet + ...
       opts.wNeumann .* lossNeumann + ...
       opts.wData .* lossData;

% Differentiate the total loss with respect to every trainable network value.
gradients = dlgradient(loss, net.Learnables);

% Return each unweighted term separately so loss competition remains visible.
terms.pde = lossPDE;
terms.dirichlet = lossDirichlet;
terms.neumann = lossNeumann;
terms.data = lossData;
end

function [phiHat, firstDerivative, secondDerivative] = ...
    local_phi_gradient_curvature(net, normalizedXY)
% LOCAL_PHI_GRADIENT_CURVATURE Differentiate network output with respect to x-y.

% Evaluate normalized potential at all coordinate observations.
phiHat = forward(net, normalizedXY);

% Differentiate the sum because observations are independent batch members.
% Higher derivatives remain enabled so the Poisson curvature can be computed.
gradientXY = dlgradient(sum(phiHat, 'all'), normalizedXY, ...
    'EnableHigherDerivatives', true);

% The first input channel is d(phiHat)/d(xHat).
firstDerivative.x = gradientXY(1, :);

% The second input channel is d(phiHat)/d(yHat).
firstDerivative.y = gradientXY(2, :);

% Differentiate the x derivative again with respect to both input channels.
gradientOfXDerivative = dlgradient(sum(firstDerivative.x, 'all'), ...
    normalizedXY, 'EnableHigherDerivatives', true);

% Differentiate the y derivative again with respect to both input channels.
gradientOfYDerivative = dlgradient(sum(firstDerivative.y, 'all'), ...
    normalizedXY, 'EnableHigherDerivatives', true);

% Retain d2(phiHat)/d(xHat)^2 for the Laplacian.
secondDerivative.xx = gradientOfXDerivative(1, :);

% Retain d2(phiHat)/d(yHat)^2 for the Laplacian.
secondDerivative.yy = gradientOfYDerivative(2, :);
end
