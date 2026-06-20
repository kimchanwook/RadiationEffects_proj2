function out = main_module2_pinn_electrostatics(caseName, opts)
% MAIN_MODULE2_PINN_ELECTROSTATICS Standalone Module 2 physics-inspired NN demo.
%
%   out = MAIN_MODULE2_PINN_ELECTROSTATICS(caseName) trains a small
%   physics-inspired neural network surrogate for the Module 2 electrostatic
%   Poisson problem,
%
%       div(eps_si grad(phi)) = -rho,
%
%   on the same 2D silicon domain used by the finite-element Module 2 solver.
%   The loss combines:
%
%       1. PDE residual inside the domain,
%       2. Dirichlet boundary-condition mismatch,
%       3. natural zero-Neumann boundary mismatch where applicable,
%       4. optional sparse FEM anchor data for stabilization.
%
%   The script is intentionally self-contained as a runnable MATLAB entry
%   point, but it reuses the existing Module 2 mesh, charge-density, FEM, and
%   postprocessing conventions already present in this project.
%
%   Example:
%       setup_project_paths
%       out = main_module2_pinn_electrostatics('localized_defect_charge');
%
%   Faster smoke run:
%       opts.maxIterations = 100;
%       opts.numInterior = 256;
%       opts.numBoundaryPerSide = 32;
%       out = main_module2_pinn_electrostatics('linear_potential', opts);
%
%   Requirements:
%       MATLAB Deep Learning Toolbox, because this file uses dlarray,
%       dlnetwork, dlgradient, and adamupdate.

if nargin < 1 || isempty(caseName)
    caseName = 'localized_defect_charge';
end
if nargin < 2 || isempty(opts)
    opts = struct();
end

projectMatlabDir = fileparts(mfilename('fullpath'));
addpath(genpath(fullfile(projectMatlabDir, 'src')));
addpath(fullfile(projectMatlabDir, 'cases'));

require_deep_learning_toolbox_for_module2_pinn();
opts = default_module2_pinn_options(opts);
rng(opts.randomSeed, 'twister');

params = default_module2_params(caseName);
params.makePlots = false;
params.saveMat = false;

outputDir = fullfile(projectMatlabDir, 'outputs', 'module2_pinn_2d');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('Module 2 PINN case "%s" starting.\n', params.caseName);
fprintf('  Output dir: %s\n', outputDir);
fprintf('  Training iterations: %d\n', opts.maxIterations);

% FEM solution is used in two ways: (i) as a reference for plots and error
% metrics, and (ii) optionally as sparse anchor data. The governing equation
% is still imposed through the PDE residual, not learned as a black-box fit.
fem = solve_poisson_defect_space_charge_2d(params);
scales = compute_module2_pinn_scales(fem, params);

anchors = make_module2_pinn_anchor_data(fem, params, scales, opts);
net = initialize_module2_pinn_network(opts);

trailingAvg = [];
trailingAvgSq = [];
history = initialize_module2_pinn_history(opts.maxIterations);

for iter = 1:opts.maxIterations
    batch = sample_module2_pinn_batch(params, opts, anchors);
    [loss, gradients, terms] = dlfeval(@module2_pinn_model_loss, net, batch, params, scales, opts);
    [net, trailingAvg, trailingAvgSq] = adamupdate(net, gradients, trailingAvg, trailingAvgSq, iter, ...
        opts.learnRate, opts.gradientDecayFactor, opts.squaredGradientDecayFactor);

    history.total(iter)     = scalar_extract(loss);
    history.pde(iter)       = scalar_extract(terms.pde);
    history.dirichlet(iter) = scalar_extract(terms.dirichlet);
    history.neumann(iter)   = scalar_extract(terms.neumann);
    history.data(iter)      = scalar_extract(terms.data);

    if opts.verbose && (iter == 1 || mod(iter, opts.printEvery) == 0 || iter == opts.maxIterations)
        fprintf('  iter %5d | total %.3e | PDE %.3e | Dir %.3e | Neu %.3e | Data %.3e\n', ...
            iter, history.total(iter), history.pde(iter), history.dirichlet(iter), ...
            history.neumann(iter), history.data(iter));
    end
end

pinn = evaluate_module2_pinn_on_mesh(net, fem.mesh, params, scales);
metrics = compute_module2_pinn_metrics(fem, pinn);
plotFiles = plot_module2_pinn_results(fem, pinn, history, params, outputDir);
summaryFile = write_module2_pinn_summary(params, opts, scales, metrics, outputDir);

out.params = params;
out.options = opts;
out.scales = scales;
out.net = net;
out.fem = fem;
out.pinn = pinn;
out.trainingHistory = history;
out.metrics = metrics;
out.outputDir = outputDir;
out.plotFiles = plotFiles;
out.summaryFile = summaryFile;

save(fullfile(outputDir, [params.caseName, '_module2_pinn_results.mat']), 'out', '-v7.3');

fprintf('Module 2 PINN case "%s" complete.\n', params.caseName);
fprintf('  relative phi L2 error : %.4e\n', metrics.relativePhiL2);
fprintf('  max |phi error|       : %.4e V\n', metrics.maxAbsPhiError);
fprintf('  max |PDE residual|    : %.4e C/m^3\n', metrics.maxAbsResidual);
fprintf('  output dir            : %s\n', outputDir);
end

function require_deep_learning_toolbox_for_module2_pinn()
if exist('dlarray', 'file') ~= 2 || exist('dlnetwork', 'file') ~= 2 || exist('dlgradient', 'file') ~= 2
    error(['Module 2 PINN requires MATLAB Deep Learning Toolbox. ', ...
           'Required functions include dlarray, dlnetwork, dlgradient, and adamupdate.']);
end
end

function opts = default_module2_pinn_options(opts)
% Defaults chosen for a useful first plot-generating run on a laptop.
opts = set_default(opts, 'randomSeed', 7);
opts = set_default(opts, 'numHiddenLayers', 4);
opts = set_default(opts, 'numNeurons', 48);
opts = set_default(opts, 'maxIterations', 1200);
opts = set_default(opts, 'learnRate', 2.0e-3);
opts = set_default(opts, 'gradientDecayFactor', 0.9);
opts = set_default(opts, 'squaredGradientDecayFactor', 0.999);
opts = set_default(opts, 'numInterior', 1024);
opts = set_default(opts, 'numBoundaryPerSide', 96);
opts = set_default(opts, 'numDataAnchors', 160);
opts = set_default(opts, 'useDataAnchors', true);
opts = set_default(opts, 'wPDE', 1.0);
opts = set_default(opts, 'wDirichlet', 20.0);
opts = set_default(opts, 'wNeumann', 2.0);
opts = set_default(opts, 'wData', 2.0);
opts = set_default(opts, 'verbose', true);
opts = set_default(opts, 'printEvery', 100);
end

function s = set_default(s, fieldName, value)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = value;
end
end

function scales = compute_module2_pinn_scales(fem, params)
rhoAbsMax = max(abs(fem.rho));
rhoScaleEstimate = rhoAbsMax;
if rhoScaleEstimate <= 0
    rhoScaleEstimate = 1.0;
end

phiAbsMax = max(abs(fem.phi));
sourcePotentialEstimate = rhoScaleEstimate * max([params.Lx, params.Ly])^2 / params.eps_si;
Vscale = max([phiAbsMax, sourcePotentialEstimate, 1.0e-12]);
if Vscale <= 1.0e-12
    Vscale = 1.0;
end

gradScale = Vscale / max([params.Lx, params.Ly]);

scales.rho = rhoScaleEstimate;
scales.V = Vscale;
scales.gradPhi = gradScale;
scales.x = params.Lx;
scales.y = params.Ly;
end

function anchors = make_module2_pinn_anchor_data(fem, params, scales, opts)
anchors.xHat = [];
anchors.yHat = [];
anchors.phiHat = [];

if ~opts.useDataAnchors || opts.numDataAnchors <= 0
    return;
end

numNodes = size(fem.mesh.nodes, 1);
numAnchors = min(opts.numDataAnchors, numNodes);
idx = randperm(numNodes, numAnchors);
xy = fem.mesh.nodes(idx, :);

anchors.xHat = xy(:,1) ./ params.Lx;
anchors.yHat = xy(:,2) ./ params.Ly;
anchors.phiHat = fem.phi(idx) ./ scales.V;
end

function net = initialize_module2_pinn_network(opts)
layers = featureInputLayer(2, 'Normalization', 'none', 'Name', 'input');
for k = 1:opts.numHiddenLayers
    layers = [layers
        fullyConnectedLayer(opts.numNeurons, 'Name', sprintf('fc_%d', k))
        tanhLayer('Name', sprintf('tanh_%d', k))]; %#ok<AGROW>
end
layers = [layers
    fullyConnectedLayer(1, 'Name', 'phi_hat')];

net = dlnetwork(layerGraph(layers));
end

function history = initialize_module2_pinn_history(numIter)
history.total = nan(numIter, 1);
history.pde = nan(numIter, 1);
history.dirichlet = nan(numIter, 1);
history.neumann = nan(numIter, 1);
history.data = nan(numIter, 1);
history.iteration = (1:numIter).';
end

function batch = sample_module2_pinn_batch(params, opts, anchors)
% Interior collocation points.
xHat = rand(opts.numInterior, 1);
yHat = rand(opts.numInterior, 1);
x = params.Lx .* xHat;
y = params.Ly .* yHat;
rho = build_space_charge_module2_2d([x, y], params);

batch.xHatInterior = xHat;
batch.yHatInterior = yHat;
batch.rhoInterior = rho;

% Dirichlet and Neumann boundary samples.
[batch.xHatDirichlet, batch.yHatDirichlet, batch.phiDirichlet] = sample_module2_dirichlet_points(params, opts.numBoundaryPerSide);
[batch.xHatNeumann, batch.yHatNeumann, batch.normalX, batch.normalY, batch.dphidn] = sample_module2_neumann_points(params, opts.numBoundaryPerSide);

% Sparse supervised anchors from the FEM reference. These stabilize training
% without replacing the physics residual.
batch.xHatData = anchors.xHat;
batch.yHatData = anchors.yHat;
batch.phiHatData = anchors.phiHat;
end

function [xHat, yHat, phiValue] = sample_module2_dirichlet_points(params, nPerSide)
xHat = [];
yHat = [];
phiValue = [];

if isfield(params.bc, 'left') && strcmpi(params.bc.left.type, 'dirichlet')
    yy = rand(nPerSide, 1);
    xHat = [xHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; yy]; %#ok<AGROW>
    phiValue = [phiValue; params.bc.left.value * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'right') && strcmpi(params.bc.right.type, 'dirichlet')
    yy = rand(nPerSide, 1);
    xHat = [xHat; ones(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; yy]; %#ok<AGROW>
    phiValue = [phiValue; params.bc.right.value * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'bottom') && strcmpi(params.bc.bottom.type, 'dirichlet')
    xx = rand(nPerSide, 1);
    xHat = [xHat; xx]; %#ok<AGROW>
    yHat = [yHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    phiValue = [phiValue; params.bc.bottom.value * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'top') && strcmpi(params.bc.top.type, 'dirichlet')
    xx = rand(nPerSide, 1);
    xHat = [xHat; xx]; %#ok<AGROW>
    yHat = [yHat; ones(nPerSide, 1)]; %#ok<AGROW>
    phiValue = [phiValue; params.bc.top.value * ones(nPerSide, 1)]; %#ok<AGROW>
end
end

function [xHat, yHat, normalX, normalY, dphidn] = sample_module2_neumann_points(params, nPerSide)
xHat = [];
yHat = [];
normalX = [];
normalY = [];
dphidn = [];

if isfield(params.bc, 'bottom') && strcmpi(params.bc.bottom.type, 'neumann')
    xx = rand(nPerSide, 1);
    xHat = [xHat; xx]; %#ok<AGROW>
    yHat = [yHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalX = [normalX; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; -ones(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; params.bc.bottom.dphidn * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'top') && strcmpi(params.bc.top.type, 'neumann')
    xx = rand(nPerSide, 1);
    xHat = [xHat; xx]; %#ok<AGROW>
    yHat = [yHat; ones(nPerSide, 1)]; %#ok<AGROW>
    normalX = [normalX; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; ones(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; params.bc.top.dphidn * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'left') && strcmpi(params.bc.left.type, 'neumann')
    yy = rand(nPerSide, 1);
    xHat = [xHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; yy]; %#ok<AGROW>
    normalX = [normalX; -ones(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; zeros(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; params.bc.left.dphidn * ones(nPerSide, 1)]; %#ok<AGROW>
end

if isfield(params.bc, 'right') && strcmpi(params.bc.right.type, 'neumann')
    yy = rand(nPerSide, 1);
    xHat = [xHat; ones(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; yy]; %#ok<AGROW>
    normalX = [normalX; ones(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; zeros(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; params.bc.right.dphidn * ones(nPerSide, 1)]; %#ok<AGROW>
end
end

function [loss, gradients, terms] = module2_pinn_model_loss(net, batch, params, scales, opts)
% PDE residual loss: eps_si * Laplacian(phi) + rho = 0.
XY = dlarray([batch.xHatInterior(:).'; batch.yHatInterior(:).'], 'CB');
[~, gradHat, lapHat] = module2_pinn_phi_grad_lap(net, XY);
rho = dlarray(batch.rhoInterior(:).', 'CB');
residual = params.eps_si * scales.V .* (lapHat.x ./ params.Lx^2 + lapHat.y ./ params.Ly^2) + rho;
lossPDE = mean((residual ./ scales.rho).^2, 'all');

% Dirichlet boundary loss.
if isempty(batch.xHatDirichlet)
    lossDirichlet = dlarray(0.0);
else
    XYbc = dlarray([batch.xHatDirichlet(:).'; batch.yHatDirichlet(:).'], 'CB');
    phiHatBc = forward(net, XYbc);
    targetHat = dlarray(batch.phiDirichlet(:).' ./ scales.V, 'CB');
    lossDirichlet = mean((phiHatBc - targetHat).^2, 'all');
end

% Neumann boundary loss, expressed in physical V/m and then normalized.
if isempty(batch.xHatNeumann)
    lossNeumann = dlarray(0.0);
else
    XYneu = dlarray([batch.xHatNeumann(:).'; batch.yHatNeumann(:).'], 'CB');
    [~, gradHatNeu, ~] = module2_pinn_phi_grad_lap(net, XYneu);
    nx = dlarray(batch.normalX(:).', 'CB');
    ny = dlarray(batch.normalY(:).', 'CB');
    target = dlarray(batch.dphidn(:).', 'CB');
    dphidnPred = scales.V .* (nx .* gradHatNeu.x ./ params.Lx + ny .* gradHatNeu.y ./ params.Ly);
    lossNeumann = mean(((dphidnPred - target) ./ scales.gradPhi).^2, 'all');
end

% Optional sparse anchor-data loss.
if isempty(batch.xHatData)
    lossData = dlarray(0.0);
else
    XYdata = dlarray([batch.xHatData(:).'; batch.yHatData(:).'], 'CB');
    phiHatDataPred = forward(net, XYdata);
    phiHatDataTarget = dlarray(batch.phiHatData(:).', 'CB');
    lossData = mean((phiHatDataPred - phiHatDataTarget).^2, 'all');
end

loss = opts.wPDE .* lossPDE + opts.wDirichlet .* lossDirichlet + ...
       opts.wNeumann .* lossNeumann + opts.wData .* lossData;

gradients = dlgradient(loss, net.Learnables);

terms.pde = lossPDE;
terms.dirichlet = lossDirichlet;
terms.neumann = lossNeumann;
terms.data = lossData;
end

function [phiHat, gradHat, lapHat] = module2_pinn_phi_grad_lap(net, XY)
phiHat = forward(net, XY);
gradPhi = dlgradient(sum(phiHat, 'all'), XY, 'EnableHigherDerivatives', true);

dphidxHat = gradPhi(1, :);
dphidyHat = gradPhi(2, :);

gradX = dlgradient(sum(dphidxHat, 'all'), XY, 'EnableHigherDerivatives', true);
gradY = dlgradient(sum(dphidyHat, 'all'), XY, 'EnableHigherDerivatives', true);

gradHat.x = dphidxHat;
gradHat.y = dphidyHat;
lapHat.x = gradX(1, :);
lapHat.y = gradY(2, :);
end

function val = scalar_extract(x)
val = double(gather(extractdata(x)));
end

function pinn = evaluate_module2_pinn_on_mesh(net, mesh, params, scales)
nodes = mesh.nodes;
xHat = nodes(:,1) ./ params.Lx;
yHat = nodes(:,2) ./ params.Ly;
rho = build_space_charge_module2_2d(nodes, params);
[phi, Ex, Ey, residual] = dlfeval(@evaluate_module2_pinn_dl, net, xHat, yHat, rho, params, scales);

pinn.phi = phi;
pinn.rho = rho;
pinn.field.Ex_nodal = Ex;
pinn.field.Ey_nodal = Ey;
pinn.field.Enodal = [Ex, Ey];
pinn.field.Emag_nodal = sqrt(Ex.^2 + Ey.^2);
pinn.residual = residual;
pinn.maxAbsPhi = max(abs(phi));
pinn.maxAbsE = max(pinn.field.Emag_nodal);
pinn.maxAbsResidual = max(abs(residual));
end

function [phi, Ex, Ey, residual] = evaluate_module2_pinn_dl(net, xHat, yHat, rho, params, scales)
XY = dlarray([xHat(:).'; yHat(:).'], 'CB');
[phiHat, gradHat, lapHat] = module2_pinn_phi_grad_lap(net, XY);

phiDl = scales.V .* phiHat;
ExDl = -scales.V .* gradHat.x ./ params.Lx;
EyDl = -scales.V .* gradHat.y ./ params.Ly;
rhoDl = dlarray(rho(:).', 'CB');
residualDl = params.eps_si * scales.V .* (lapHat.x ./ params.Lx^2 + lapHat.y ./ params.Ly^2) + rhoDl;

phi = double(gather(extractdata(phiDl))).';
Ex = double(gather(extractdata(ExDl))).';
Ey = double(gather(extractdata(EyDl))).';
residual = double(gather(extractdata(residualDl))).';
end

function metrics = compute_module2_pinn_metrics(fem, pinn)
err = pinn.phi - fem.phi;
refNorm = norm(fem.phi, 2);
if refNorm <= 0
    refNorm = 1.0;
end
metrics.relativePhiL2 = norm(err, 2) / refNorm;
metrics.maxAbsPhiError = max(abs(err));
metrics.meanAbsPhiError = mean(abs(err));
metrics.maxAbsResidual = max(abs(pinn.residual));
metrics.rmsResidual = sqrt(mean(pinn.residual.^2));
metrics.maxAbsE = pinn.maxAbsE;
end

function plotFiles = plot_module2_pinn_results(fem, pinn, history, params, outputDir)
mesh = fem.mesh;
nodes = mesh.nodes;
elems = mesh.elems;
caseName = params.caseName;
plotFiles = struct();

plotFiles.femPotential = save_trisurf_plot(elems, nodes, fem.phi, ...
    ['Module 2 FEM potential: ', strrep(caseName, '_', '\_')], ...
    'phi_{FEM} [V]', fullfile(outputDir, [caseName, '_fem_potential_reference.png']));

plotFiles.pinnPotential = save_trisurf_plot(elems, nodes, pinn.phi, ...
    ['Module 2 PINN potential: ', strrep(caseName, '_', '\_')], ...
    'phi_{PINN} [V]', fullfile(outputDir, [caseName, '_pinn_potential.png']));

plotFiles.absError = save_trisurf_plot(elems, nodes, abs(pinn.phi - fem.phi), ...
    ['Module 2 PINN absolute potential error: ', strrep(caseName, '_', '\_')], ...
    '|phi_{PINN}-phi_{FEM}| [V]', fullfile(outputDir, [caseName, '_pinn_abs_potential_error.png']));

plotFiles.pinnField = save_trisurf_plot(elems, nodes, pinn.field.Emag_nodal, ...
    ['Module 2 PINN electric-field magnitude: ', strrep(caseName, '_', '\_')], ...
    '|E_{PINN}| [V/m]', fullfile(outputDir, [caseName, '_pinn_electric_field_magnitude.png']));

plotFiles.residual = save_trisurf_plot(elems, nodes, pinn.residual, ...
    ['Module 2 PINN PDE residual: ', strrep(caseName, '_', '\_')], ...
    'eps laplacian(phi)+rho [C/m^3]', fullfile(outputDir, [caseName, '_pinn_pde_residual.png']));

fig = figure('Visible', 'off');
semilogy(history.iteration, history.total, 'LineWidth', 1.5); hold on;
semilogy(history.iteration, history.pde, 'LineWidth', 1.0);
semilogy(history.iteration, history.dirichlet, 'LineWidth', 1.0);
semilogy(history.iteration, history.neumann, 'LineWidth', 1.0);
semilogy(history.iteration, history.data, 'LineWidth', 1.0);
grid on;
xlabel('training iteration');
ylabel('loss');
title(['Module 2 PINN training losses: ', strrep(caseName, '_', '\_')]);
legend({'total','PDE','Dirichlet','Neumann','data'}, 'Location', 'northeast');
plotFiles.lossHistory = fullfile(outputDir, [caseName, '_pinn_training_loss.png']);
saveas(fig, plotFiles.lossHistory);
close(fig);
end

function fname = save_trisurf_plot(elems, nodes, values, ttl, cbarLabel, fname)
fig = figure('Visible', 'off');
trisurf(elems, nodes(:,1), nodes(:,2), values, 'EdgeColor', 'none');
view(2); axis equal tight;
cb = colorbar;
ylabel(cb, cbarLabel);
title(ttl);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fname);
close(fig);
end

function summaryFile = write_module2_pinn_summary(params, opts, scales, metrics, outputDir)
summaryFile = fullfile(outputDir, [params.caseName, '_module2_pinn_summary.txt']);
fid = fopen(summaryFile, 'w');
if fid < 0
    error('Could not open summary file: %s', summaryFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Module 2 physics-inspired neural-network summary\n');
fprintf(fid, '================================================\n');
fprintf(fid, 'Case: %s\n', params.caseName);
fprintf(fid, 'PDE: div(eps_si grad(phi)) = -rho\n');
fprintf(fid, 'Residual minimized: eps_si*(d2phi/dx2 + d2phi/dy2) + rho\n');
fprintf(fid, 'Domain: Lx = %.6e m, Ly = %.6e m\n', params.Lx, params.Ly);
fprintf(fid, 'Mesh used for reference plots: nx = %d, ny = %d\n', params.nx, params.ny);
fprintf(fid, 'eps_si = %.6e F/m\n', params.eps_si);
fprintf(fid, '\nNetwork and training\n');
fprintf(fid, '--------------------\n');
fprintf(fid, 'Hidden layers: %d\n', opts.numHiddenLayers);
fprintf(fid, 'Neurons/layer: %d\n', opts.numNeurons);
fprintf(fid, 'Activation: tanh\n');
fprintf(fid, 'Iterations: %d\n', opts.maxIterations);
fprintf(fid, 'Learning rate: %.6e\n', opts.learnRate);
fprintf(fid, 'Interior collocation points/iteration: %d\n', opts.numInterior);
fprintf(fid, 'Boundary points/side/iteration: %d\n', opts.numBoundaryPerSide);
fprintf(fid, 'FEM anchor data enabled: %d\n', opts.useDataAnchors);
fprintf(fid, 'FEM anchor points: %d\n', opts.numDataAnchors);
fprintf(fid, 'Loss weights: PDE %.3e, Dirichlet %.3e, Neumann %.3e, Data %.3e\n', ...
    opts.wPDE, opts.wDirichlet, opts.wNeumann, opts.wData);
fprintf(fid, '\nScales\n');
fprintf(fid, '------\n');
fprintf(fid, 'Potential scale V = %.6e V\n', scales.V);
fprintf(fid, 'Charge-density scale rho = %.6e C/m^3\n', scales.rho);
fprintf(fid, 'Gradient scale = %.6e V/m\n', scales.gradPhi);
fprintf(fid, '\nReference-comparison metrics\n');
fprintf(fid, '----------------------------\n');
fprintf(fid, 'Relative phi L2 error = %.6e\n', metrics.relativePhiL2);
fprintf(fid, 'Max absolute phi error = %.6e V\n', metrics.maxAbsPhiError);
fprintf(fid, 'Mean absolute phi error = %.6e V\n', metrics.meanAbsPhiError);
fprintf(fid, 'Max absolute PDE residual = %.6e C/m^3\n', metrics.maxAbsResidual);
fprintf(fid, 'RMS PDE residual = %.6e C/m^3\n', metrics.rmsResidual);
fprintf(fid, 'Max PINN |E| = %.6e V/m\n', metrics.maxAbsE);
end
