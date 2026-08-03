function verification = module2_pinn_verify(...
    fem, pinn, history, params, opts, scales, outputDir)
% MODULE2_PINN_VERIFY Compare Module 2 PINN results with FEM and analytics.
%
%   verification = MODULE2_PINN_VERIFY(...) computes potential, electric-field,
%   and Poisson-residual metrics.  It also writes comparison plots and a text
%   summary when the corresponding options are enabled.
%
%   Analytical checks are added automatically for:
%       zero_charge
%       linear_potential
%       uniform_space_charge

% Create the output directory before any plot or summary is written.
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Compute the PINN-minus-FEM potential error at every FEM node.
potentialError = pinn.phi - fem.phi;

% Compute the PINN-minus-FEM electric-field vector error at every node.
fieldError = pinn.field.Enodal - fem.field.Enodal;

% Build a stable potential denominator for zero-reference verification cases.
potentialReferenceNorm = norm(fem.phi, 2);
potentialScaleNorm = scales.V * sqrt(numel(fem.phi));
potentialDenominator = max(potentialReferenceNorm, ...
    eps(max(potentialScaleNorm, 1.0)));

% Build an analogous stable denominator for zero-electric-field cases.
fieldReferenceNorm = norm(fem.field.Enodal(:), 2);
fieldScaleNorm = scales.gradPhi * sqrt(numel(fem.field.Enodal));
fieldDenominator = max(fieldReferenceNorm, ...
    eps(max(fieldScaleNorm, 1.0)));

% Report relative L2 potential error against the FEM nodal reference.
metrics.relativePhiL2 = norm(potentialError, 2) / potentialDenominator;

% Report absolute potential errors in volts.
metrics.maxAbsPhiError = max(abs(potentialError));
metrics.meanAbsPhiError = mean(abs(potentialError));

% Report relative L2 electric-field error using both Cartesian components.
metrics.relativeElectricFieldL2 = ...
    norm(fieldError(:), 2) / fieldDenominator;

% Report a component-wise maximum electric-field error in V/m.
metrics.maxAbsElectricFieldError = max(abs(fieldError(:)));

% Report dimensional and normalized strong-form residual diagnostics.
metrics.maxAbsResidual = max(abs(pinn.residual));
metrics.rmsResidual = sqrt(mean(pinn.residual.^2));
metrics.rmsNormalizedResidual = ...
    sqrt(mean(pinn.residualNormalized.^2));

% Preserve peak predicted field because it is useful to later coupling modules.
metrics.maxAbsE = pinn.maxAbsE;

% Compare against a closed-form solution when the selected case permits it.
analytic = local_analytic_verification(pinn.nodes, pinn, params, scales);

% Initialize an empty plot manifest for no-plot or headless workflows.
plotFiles = struct();

% Produce the requested FEM/PINN/residual/training plots.
if opts.makePlots
    plotFiles = local_write_plots(...
        fem, pinn, history, params, outputDir);
end

% Initialize an empty filename when text-summary output is disabled.
summaryFile = '';

% Write a human-readable record of model settings and verification metrics.
if opts.writeSummary
    summaryFile = local_write_summary(...
        params, opts, scales, metrics, analytic, outputDir);
end

% Package numerical metrics for programmatic regression tests.
verification.metrics = metrics;

% Package any available exact-solution comparison.
verification.analytic = analytic;

% Package paths to plots actually written by this function.
verification.plotFiles = plotFiles;

% Package the text-summary path, or an empty character vector when disabled.
verification.summaryFile = summaryFile;
end

function analytic = local_analytic_verification(nodes, pinn, params, scales)
% LOCAL_ANALYTIC_VERIFICATION Build exact solutions for supported simple cases.

% Default to unavailable because the Gaussian source has no simple rectangle solution.
analytic.available = false;
analytic.description = 'No closed-form solution configured for this case.';
analytic.phi = zeros(0, 1);
analytic.Enodal = zeros(0, 2);
analytic.relativePhiL2 = NaN;
analytic.relativeElectricFieldL2 = NaN;
analytic.maxAbsPhiError = NaN;
analytic.maxAbsElectricFieldError = NaN;

% Extract x once because every current exact case is one-dimensional in x.
x = nodes(:, 1);

% Read the left and right contact voltages used by the FEM/PINN case.
leftVoltage = params.bc.left.value;
rightVoltage = params.bc.right.value;

% Select the analytical expression associated with the requested case.
switch lower(params.caseName)
    case {'zero_charge', 'linear_potential'}
        % Laplace's equation with left/right Dirichlet data has a linear solution.
        phiExact = leftVoltage + ...
            (rightVoltage - leftVoltage) .* x ./ params.Lx;

        % The exact electric field is spatially uniform and points along x.
        ExExact = -(rightVoltage - leftVoltage) ./ params.Lx .* ...
            ones(size(x));
        EyExact = zeros(size(x));

        % Describe this branch explicitly in saved results and summaries.
        analytic.description = ...
            'Exact zero-charge linear-potential solution.';

    case 'uniform_space_charge'
        % The verification source is a constant physical charge density.
        rhoUniform = params.rho_uniform;

        % Integrating eps*d2phi/dx2=-rho twice gives this linear coefficient.
        linearCoefficient = ...
            (rightVoltage - leftVoltage) ./ params.Lx + ...
            rhoUniform .* params.Lx ./ (2.0 .* params.eps_si);

        % Evaluate the exact parabolic potential satisfying both contact voltages.
        phiExact = leftVoltage + linearCoefficient .* x - ...
            rhoUniform .* x.^2 ./ (2.0 .* params.eps_si);

        % Differentiate analytically and apply E_x=-dphi/dx.
        ExExact = -linearCoefficient + ...
            rhoUniform .* x ./ params.eps_si;
        EyExact = zeros(size(x));

        % Describe this branch explicitly in saved results and summaries.
        analytic.description = ...
            'Exact one-dimensional uniform-space-charge solution.';

    otherwise
        % Return the initialized unavailable result for Gaussian/source-map cases.
        return;
end

% Mark that exact arrays and exact-error metrics are now available.
analytic.available = true;

% Package exact potential and electric field at the query nodes.
analytic.phi = phiExact;
analytic.Enodal = [ExExact, EyExact];

% Form differences between the trained PINN and exact analytical fields.
phiError = pinn.phi - phiExact;
fieldError = pinn.field.Enodal - analytic.Enodal;

% Use scale-aware denominators so the all-zero exact case remains finite.
phiDenominator = max(norm(phiExact, 2), ...
    eps(max(scales.V * sqrt(numel(phiExact)), 1.0)));
fieldDenominator = max(norm(analytic.Enodal(:), 2), ...
    eps(max(scales.gradPhi * sqrt(numel(analytic.Enodal)), 1.0)));

% Store exact-solution relative and maximum absolute errors.
analytic.relativePhiL2 = norm(phiError, 2) / phiDenominator;
analytic.relativeElectricFieldL2 = ...
    norm(fieldError(:), 2) / fieldDenominator;
analytic.maxAbsPhiError = max(abs(phiError));
analytic.maxAbsElectricFieldError = max(abs(fieldError(:)));
end

function plotFiles = local_write_plots(fem, pinn, history, params, outputDir)
% LOCAL_WRITE_PLOTS Save field comparisons and separate training-loss curves.

% Reuse the FEM triangular mesh for all spatial comparison panels.
elements = fem.mesh.elems;
nodes = fem.mesh.nodes;

% Make the case name readable in MATLAB titles without underscore subscripts.
titleCaseName = strrep(params.caseName, '_', '\_');

% Save the FEM reference potential.
plotFiles.femPotential = local_save_field_plot(...
    elements, nodes, fem.phi, ...
    ['Module 2 FEM potential: ', titleCaseName], ...
    '\phi_{FEM} [V]', ...
    fullfile(outputDir, [params.caseName, '_fem_potential_reference.png']));

% Save the PINN potential on the identical nodes and color geometry.
plotFiles.pinnPotential = local_save_field_plot(...
    elements, nodes, pinn.phi, ...
    ['Module 2 PINN potential: ', titleCaseName], ...
    '\phi_{PINN} [V]', ...
    fullfile(outputDir, [params.caseName, '_pinn_potential.png']));

% Save the signed potential-error field to expose systematic bias.
plotFiles.potentialError = local_save_field_plot(...
    elements, nodes, pinn.phi - fem.phi, ...
    ['Module 2 PINN minus FEM potential: ', titleCaseName], ...
    '\phi_{PINN}-\phi_{FEM} [V]', ...
    fullfile(outputDir, [params.caseName, '_pinn_potential_error.png']));

% Save the reference FEM electric-field magnitude.
plotFiles.femField = local_save_field_plot(...
    elements, nodes, fem.field.Emag_nodal, ...
    ['Module 2 FEM electric-field magnitude: ', titleCaseName], ...
    '|E_{FEM}| [V/m]', ...
    fullfile(outputDir, [params.caseName, '_fem_electric_field_magnitude.png']));

% Save the PINN electric-field magnitude obtained by automatic differentiation.
plotFiles.pinnField = local_save_field_plot(...
    elements, nodes, pinn.field.Emag_nodal, ...
    ['Module 2 PINN electric-field magnitude: ', titleCaseName], ...
    '|E_{PINN}| [V/m]', ...
    fullfile(outputDir, [params.caseName, '_pinn_electric_field_magnitude.png']));

% Save the dimensional Poisson residual map.
plotFiles.residual = local_save_field_plot(...
    elements, nodes, pinn.residual, ...
    ['Module 2 PINN Poisson residual: ', titleCaseName], ...
    '\epsilon\nabla^2\phi+\rho [C/m^3]', ...
    fullfile(outputDir, [params.caseName, '_pinn_pde_residual.png']));

% Create a separate figure for the total and component loss histories.
lossFigure = figure('Visible', 'off');

% Apply a positive numerical floor so exact zero losses remain plottable on log axes.
lossFloor = realmin('double');

% Plot the weighted total objective and every unweighted component.
semilogy(history.iteration, max(history.total, lossFloor), ...
    'LineWidth', 1.5);
hold on;
semilogy(history.iteration, max(history.pde, lossFloor), ...
    'LineWidth', 1.0);
semilogy(history.iteration, max(history.dirichlet, lossFloor), ...
    'LineWidth', 1.0);
semilogy(history.iteration, max(history.neumann, lossFloor), ...
    'LineWidth', 1.0);
semilogy(history.iteration, max(history.data, lossFloor), ...
    'LineWidth', 1.0);

% Label and annotate the loss plot for direct use in reports or slides.
grid on;
xlabel('training iteration');
ylabel('loss');
title(['Module 2 PINN training losses: ', titleCaseName]);
legend({'total', 'PDE', 'Dirichlet', 'Neumann', 'data'}, ...
    'Location', 'northeast');

% Save and close the hidden figure to avoid accumulating graphics handles.
plotFiles.lossHistory = fullfile(outputDir, ...
    [params.caseName, '_pinn_training_loss.png']);
saveas(lossFigure, plotFiles.lossHistory);
close(lossFigure);
end

function fileName = local_save_field_plot(...
    elements, nodes, values, plotTitle, colorbarLabel, fileName)
% LOCAL_SAVE_FIELD_PLOT Render one nodal triangular field as a 2D color plot.

% Create the plot invisibly so batch and test runs do not open GUI windows.
fieldFigure = figure('Visible', 'off');

% Draw one colored triangular surface and suppress mesh-edge clutter.
trisurf(elements, nodes(:, 1), nodes(:, 2), values, ...
    'EdgeColor', 'none');

% Look down on the surface so it becomes a two-dimensional field map.
view(2);
axis equal tight;

% Add a labeled colorbar carrying the physical field units.
colorbarHandle = colorbar;
ylabel(colorbarHandle, colorbarLabel);

% Add the case-specific title and physical coordinate labels.
title(plotTitle);
xlabel('x [m]');
ylabel('y [m]');

% Save the PNG and immediately release the hidden figure.
saveas(fieldFigure, fileName);
close(fieldFigure);
end

function summaryFile = local_write_summary(...
    params, opts, scales, metrics, analytic, outputDir)
% LOCAL_WRITE_SUMMARY Write a compact, inspectable record of the PINN run.

% Construct a deterministic summary filename for the current case.
summaryFile = fullfile(outputDir, ...
    [params.caseName, '_module2_pinn_summary.txt']);

% Open the text file for replacement by this completed run.
fileIdentifier = fopen(summaryFile, 'w');

% Stop with an explicit error if the output destination cannot be opened.
if fileIdentifier < 0
    error('module2_pinn_verify:SummaryOpenFailed', ...
        'Could not open summary file: %s', summaryFile);
end

% Guarantee file closure even if a later fprintf operation throws an error.
cleanupObject = onCleanup(@() fclose(fileIdentifier)); %#ok<NASGU>

% Write the physical problem statement and domain configuration.
fprintf(fileIdentifier, 'Module 2 physics-informed neural-network summary\n');
fprintf(fileIdentifier, '===================================================\n');
fprintf(fileIdentifier, 'Case: %s\n', params.caseName);
fprintf(fileIdentifier, ...
    'PDE residual: eps_si*(d2phi/dx2 + d2phi/dy2) + rho\n');
fprintf(fileIdentifier, 'Lx = %.6e m\n', params.Lx);
fprintf(fileIdentifier, 'Ly = %.6e m\n', params.Ly);
fprintf(fileIdentifier, 'eps_si = %.6e F/m\n', params.eps_si);

% Write the architecture and optimizer configuration.
fprintf(fileIdentifier, '\nNetwork and training\n');
fprintf(fileIdentifier, '--------------------\n');
fprintf(fileIdentifier, 'Inputs: x/Lx and y/Ly\n');
fprintf(fileIdentifier, 'Output: phi/Vscale\n');
fprintf(fileIdentifier, 'Hidden layers: %d\n', opts.numHiddenLayers);
fprintf(fileIdentifier, 'Neurons per hidden layer: %d\n', opts.numNeurons);
fprintf(fileIdentifier, 'Activation: tanh\n');
fprintf(fileIdentifier, 'Iterations: %d\n', opts.maxIterations);
fprintf(fileIdentifier, 'Learning rate: %.6e\n', opts.learnRate);
fprintf(fileIdentifier, ...
    'Interior collocation points per iteration: %d\n', opts.numInterior);
fprintf(fileIdentifier, ...
    'Boundary points per side per iteration: %d\n', ...
    opts.numBoundaryPerSide);
fprintf(fileIdentifier, 'FEM anchors enabled: %d\n', opts.useDataAnchors);
fprintf(fileIdentifier, 'Requested FEM anchors: %d\n', opts.numDataAnchors);
fprintf(fileIdentifier, ...
    'Loss weights [PDE, Dirichlet, Neumann, data]: %.3e %.3e %.3e %.3e\n', ...
    opts.wPDE, opts.wDirichlet, opts.wNeumann, opts.wData);

% Write every scale used to nondimensionalize the network calculation.
fprintf(fileIdentifier, '\nNondimensionalization scales\n');
fprintf(fileIdentifier, '----------------------------\n');
fprintf(fileIdentifier, 'Potential scale: %.6e V\n', scales.V);
fprintf(fileIdentifier, 'Charge scale: %.6e C/m^3\n', scales.rho);
fprintf(fileIdentifier, 'Gradient scale: %.6e V/m\n', scales.gradPhi);

% Write FEM-reference comparison metrics.
fprintf(fileIdentifier, '\nFEM comparison\n');
fprintf(fileIdentifier, '--------------\n');
fprintf(fileIdentifier, 'Relative potential L2 error: %.6e\n', ...
    metrics.relativePhiL2);
fprintf(fileIdentifier, 'Maximum absolute potential error: %.6e V\n', ...
    metrics.maxAbsPhiError);
fprintf(fileIdentifier, 'Mean absolute potential error: %.6e V\n', ...
    metrics.meanAbsPhiError);
fprintf(fileIdentifier, 'Relative electric-field L2 error: %.6e\n', ...
    metrics.relativeElectricFieldL2);
fprintf(fileIdentifier, 'Maximum electric-field component error: %.6e V/m\n', ...
    metrics.maxAbsElectricFieldError);
fprintf(fileIdentifier, 'Maximum absolute PDE residual: %.6e C/m^3\n', ...
    metrics.maxAbsResidual);
fprintf(fileIdentifier, 'RMS PDE residual: %.6e C/m^3\n', ...
    metrics.rmsResidual);
fprintf(fileIdentifier, 'RMS normalized PDE residual: %.6e\n', ...
    metrics.rmsNormalizedResidual);
fprintf(fileIdentifier, 'Maximum predicted |E|: %.6e V/m\n', ...
    metrics.maxAbsE);

% Write exact-solution metrics only for supported analytical cases.
if analytic.available
    fprintf(fileIdentifier, '\nAnalytical comparison\n');
    fprintf(fileIdentifier, '---------------------\n');
    fprintf(fileIdentifier, '%s\n', analytic.description);
    fprintf(fileIdentifier, 'Relative potential L2 error: %.6e\n', ...
        analytic.relativePhiL2);
    fprintf(fileIdentifier, 'Maximum absolute potential error: %.6e V\n', ...
        analytic.maxAbsPhiError);
    fprintf(fileIdentifier, 'Relative electric-field L2 error: %.6e\n', ...
        analytic.relativeElectricFieldL2);
    fprintf(fileIdentifier, 'Maximum electric-field component error: %.6e V/m\n', ...
        analytic.maxAbsElectricFieldError);
end
end
