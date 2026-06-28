function out = main_module2_cpinn_electrostatics(caseName, opts)
% MAIN_MODULE2_CPINN_ELECTROSTATICS Standalone Module 2 causal-PINN demo.
%
%   out = MAIN_MODULE2_CPINN_ELECTROSTATICS(caseName) trains a small causal
%   physics-informed neural-network surrogate for the Module 2 electrostatic
%   Poisson problem,
%
%       div(eps_si grad(phi)) = -rho,
%
%   on the same 2D silicon domain used by the finite-element Module 2 solver.
%
%   Important modeling note:
%       Module 2 electrostatics is elliptic and quasi-static. It does not have
%       a physical time direction by itself. The causal-PINN construction below
%       therefore introduces an ordered continuation coordinate alpha in [0,1].
%       alpha can be interpreted as a dose/load step, defect-snapshot index,
%       coupling-iteration continuation variable, or source-amplitude ramp. The
%       network learns phi(x,y,alpha), and the final Module 2 electrostatic
%       prediction is evaluated at alpha = 1.
%
%   Compared with MAIN_MODULE2_PINN_ELECTROSTATICS, the residual and constraint
%   losses are not treated as one unordered global cloud. They are grouped by
%   ordered alpha stages. Later stages are exponentially down-weighted until
%   earlier stages have smaller residuals:
%
%       w_1 = 1,
%       w_k = exp(-epsilon * sum_{j<k} L_j),  k = 2,...,Nstage.
%
%   This is the causal training mechanism. For Module 2, it is best understood
%   as causal continuation over radiation damage/dose/coupling state rather
%   than causality in the Poisson equation itself.
%
%   Example:
%       setup_project_paths
%       out = main_module2_cpinn_electrostatics('localized_defect_charge');
%
%   Faster smoke run:
%       opts.maxIterations = 100;
%       opts.numStages = 4;
%       opts.numInteriorPerStage = 128;
%       opts.numBoundaryPerSide = 24;
%       out = main_module2_cpinn_electrostatics('linear_potential', opts);
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

require_deep_learning_toolbox_for_module2_cpinn();
opts = default_module2_cpinn_options(opts);
rng(opts.randomSeed, 'twister');

params = default_module2_params(caseName);
params.makePlots = false;
params.saveMat = false;

outputDir = fullfile(projectMatlabDir, 'outputs', 'module2_cpinn_2d');
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

fprintf('Module 2 Causal PINN case "%s" starting.\n', params.caseName);
fprintf('  Output dir: %s\n', outputDir);
fprintf('  Training iterations: %d\n', opts.maxIterations);
fprintf('  Causal continuation stages: %d\n', opts.numStages);

% The FEM solution is the final alpha = 1 reference.  Because Module 2 is a
% linear Poisson problem for fixed eps_si and fixed boundary-condition type,
% the continuation target for intermediate alpha stages is alpha times the
% final source and, if enabled, alpha times the nonzero Dirichlet/Neumann data.
fem = solve_poisson_defect_space_charge_2d(params);
scales = compute_module2_cpinn_scales(fem, params);
stages = make_module2_cpinn_stages(opts);
anchors = make_module2_cpinn_anchor_data(fem, params, scales, opts);
net = initialize_module2_cpinn_network(opts);

trailingAvg = [];
trailingAvgSq = [];
history = initialize_module2_cpinn_history(opts.maxIterations, opts.numStages);

for iter = 1:opts.maxIterations
    batch = sample_module2_cpinn_batch(params, opts, anchors, stages);
    [loss, gradients, terms] = dlfeval(@module2_cpinn_model_loss, net, batch, params, scales, opts, stages);
    [net, trailingAvg, trailingAvgSq] = adamupdate(net, gradients, trailingAvg, trailingAvgSq, iter, ...
        opts.learnRate, opts.gradientDecayFactor, opts.squaredGradientDecayFactor);

    history.total(iter) = scalar_extract(loss);
    history.pde(iter) = terms.pde;
    history.dirichlet(iter) = terms.dirichlet;
    history.neumann(iter) = terms.neumann;
    history.data(iter) = terms.data;
    history.causalWeightedStageLoss(iter) = terms.causalWeightedStageLoss;
    history.stagePDE(iter, :) = terms.stagePDE;
    history.stageDirichlet(iter, :) = terms.stageDirichlet;
    history.stageNeumann(iter, :) = terms.stageNeumann;
    history.stageData(iter, :) = terms.stageData;
    history.stageRawLoss(iter, :) = terms.stageRawLoss;
    history.stageWeights(iter, :) = terms.stageWeights;

    if opts.verbose && (iter == 1 || mod(iter, opts.printEvery) == 0 || iter == opts.maxIterations)
        fprintf(['  iter %5d | total %.3e | PDE %.3e | Dir %.3e | Neu %.3e | Data %.3e ', ...
                 '| min causal w %.3e | final-stage w %.3e\n'], ...
            iter, history.total(iter), history.pde(iter), history.dirichlet(iter), ...
            history.neumann(iter), history.data(iter), min(history.stageWeights(iter, :)), ...
            history.stageWeights(iter, end));
    end
end

cpinn = evaluate_module2_cpinn_on_mesh(net, fem.mesh, params, scales, opts.finalAlpha, opts);
metrics = compute_module2_cpinn_metrics(fem, cpinn);
plotFiles = plot_module2_cpinn_results(fem, cpinn, history, params, outputDir, stages);
summaryFile = write_module2_cpinn_summary(params, opts, scales, metrics, outputDir, stages);

out.params = params;
out.options = opts;
out.causalStages = stages;
out.scales = scales;
out.net = net;
out.fem = fem;
out.cpinn = cpinn;
% Alias retained for convenience when comparing against the older PINN output.
out.pinn = cpinn;
out.trainingHistory = history;
out.metrics = metrics;
out.outputDir = outputDir;
out.plotFiles = plotFiles;
out.summaryFile = summaryFile;

save(fullfile(outputDir, [params.caseName, '_module2_cpinn_results.mat']), 'out', '-v7.3');

fprintf('Module 2 Causal PINN case "%s" complete.\n', params.caseName);
fprintf('  relative phi L2 error : %.4e\n', metrics.relativePhiL2);
fprintf('  max |phi error|       : %.4e V\n', metrics.maxAbsPhiError);
fprintf('  max |PDE residual|    : %.4e C/m^3\n', metrics.maxAbsResidual);
fprintf('  output dir            : %s\n', outputDir);
end

function require_deep_learning_toolbox_for_module2_cpinn()
if exist('dlarray', 'file') ~= 2 || exist('dlnetwork', 'file') ~= 2 || exist('dlgradient', 'file') ~= 2
    error(['Module 2 Causal PINN requires MATLAB Deep Learning Toolbox. ', ...
           'Required functions include dlarray, dlnetwork, dlgradient, and adamupdate.']);
end
end

function opts = default_module2_cpinn_options(opts)
% Defaults chosen for a useful first plot-generating run on a laptop.
opts = set_default(opts, 'randomSeed', 11);
opts = set_default(opts, 'numHiddenLayers', 4);
opts = set_default(opts, 'numNeurons', 48);
opts = set_default(opts, 'maxIterations', 1500);
opts = set_default(opts, 'learnRate', 2.0e-3);
opts = set_default(opts, 'gradientDecayFactor', 0.9);
opts = set_default(opts, 'squaredGradientDecayFactor', 0.999);
opts = set_default(opts, 'numStages', 6);
opts = set_default(opts, 'stagePower', 1.0);
opts = set_default(opts, 'numInteriorPerStage', 384);
opts = set_default(opts, 'numBoundaryPerSide', 64);
opts = set_default(opts, 'numDataAnchors', 160);
opts = set_default(opts, 'useDataAnchors', true);
opts = set_default(opts, 'useChargeContinuation', true);
opts = set_default(opts, 'useBoundaryContinuation', true);
opts = set_default(opts, 'wPDE', 1.0);
opts = set_default(opts, 'wDirichlet', 20.0);
opts = set_default(opts, 'wNeumann', 2.0);
opts = set_default(opts, 'wData', 2.0);
opts = set_default(opts, 'causalEpsilon', 5.0);
opts = set_default(opts, 'causalWeightFloor', 1.0e-4);
opts = set_default(opts, 'finalAlpha', 1.0);
opts = set_default(opts, 'verbose', true);
opts = set_default(opts, 'printEvery', 100);

if opts.numStages < 2
    error('opts.numStages must be at least 2 for causal continuation.');
end
if opts.causalWeightFloor < 0 || opts.causalWeightFloor > 1
    error('opts.causalWeightFloor must lie between 0 and 1.');
end
end

function s = set_default(s, fieldName, value)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = value;
end
end

function stages = make_module2_cpinn_stages(opts)
% Ordered continuation coordinate.  stagePower > 1 clusters stages near the
% weak-source end; stagePower < 1 clusters them near the final alpha = 1 end.
base = linspace(0, 1, opts.numStages);
stages = base .^ opts.stagePower;
stages(1) = 0.0;
stages(end) = 1.0;
stages = reshape(stages, 1, []);
end

function scales = compute_module2_cpinn_scales(fem, params)
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

function anchors = make_module2_cpinn_anchor_data(fem, params, scales, opts)
anchors.xHat = [];
anchors.yHat = [];
anchors.phiHatFinal = [];

if ~opts.useDataAnchors || opts.numDataAnchors <= 0
    return;
end

numNodes = size(fem.mesh.nodes, 1);
numAnchors = min(opts.numDataAnchors, numNodes);
idx = randperm(numNodes, numAnchors);
xy = fem.mesh.nodes(idx, :);

anchors.xHat = xy(:,1) ./ params.Lx;
anchors.yHat = xy(:,2) ./ params.Ly;
anchors.phiHatFinal = fem.phi(idx) ./ scales.V;
end

function net = initialize_module2_cpinn_network(opts)
% Inputs are normalized x, normalized y, and the continuation coordinate alpha.
layers = featureInputLayer(3, 'Normalization', 'none', 'Name', 'input');
for k = 1:opts.numHiddenLayers
    layers = [layers
        fullyConnectedLayer(opts.numNeurons, 'Name', sprintf('fc_%d', k))
        tanhLayer('Name', sprintf('tanh_%d', k))]; %#ok<AGROW>
end
layers = [layers
    fullyConnectedLayer(1, 'Name', 'phi_hat')];

net = dlnetwork(layerGraph(layers));
end

function history = initialize_module2_cpinn_history(numIter, numStages)
history.total = nan(numIter, 1);
history.pde = nan(numIter, 1);
history.dirichlet = nan(numIter, 1);
history.neumann = nan(numIter, 1);
history.data = nan(numIter, 1);
history.causalWeightedStageLoss = nan(numIter, 1);
history.stagePDE = nan(numIter, numStages);
history.stageDirichlet = nan(numIter, numStages);
history.stageNeumann = nan(numIter, numStages);
history.stageData = nan(numIter, numStages);
history.stageRawLoss = nan(numIter, numStages);
history.stageWeights = nan(numIter, numStages);
history.iteration = (1:numIter).';
end

function batch = sample_module2_cpinn_batch(params, opts, anchors, stages)
numStages = numel(stages);
Nint = opts.numInteriorPerStage;

batch.xHatInterior = rand(Nint, numStages);
batch.yHatInterior = rand(Nint, numStages);
batch.rhoFullInterior = zeros(Nint, numStages);
for k = 1:numStages
    x = params.Lx .* batch.xHatInterior(:, k);
    y = params.Ly .* batch.yHatInterior(:, k);
    batch.rhoFullInterior(:, k) = build_space_charge_module2_2d([x, y], params);
end

% Boundary samples are shared across stages in each iteration.  The target
% values are stage-scaled inside the loss function.
[batch.xHatDirichlet, batch.yHatDirichlet, batch.phiDirichletFinal] = ...
    sample_module2_dirichlet_points(params, opts.numBoundaryPerSide);
[batch.xHatNeumann, batch.yHatNeumann, batch.normalX, batch.normalY, batch.dphidnFinal] = ...
    sample_module2_neumann_points(params, opts.numBoundaryPerSide);

% Sparse supervised anchors from the final FEM reference.  Intermediate-stage
% anchor targets are alpha times the final anchor potential.
batch.xHatData = anchors.xHat;
batch.yHatData = anchors.yHat;
batch.phiHatDataFinal = anchors.phiHatFinal;
batch.stageAlpha = stages;
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

function [loss, gradients, terms] = module2_cpinn_model_loss(net, batch, params, scales, opts, stages)
numStages = numel(stages);
stageLossCell = cell(1, numStages);
stagePDE = zeros(1, numStages);
stageDirichlet = zeros(1, numStages);
stageNeumann = zeros(1, numStages);
stageData = zeros(1, numStages);
stageRawLoss = zeros(1, numStages);

for k = 1:numStages
    alpha = stages(k);
    [lossStage, parts] = module2_cpinn_single_stage_loss(net, batch, params, scales, opts, alpha, k);
    stageLossCell{k} = lossStage;
    stagePDE(k) = scalar_extract(parts.pde);
    stageDirichlet(k) = scalar_extract(parts.dirichlet);
    stageNeumann(k) = scalar_extract(parts.neumann);
    stageData(k) = scalar_extract(parts.data);
    stageRawLoss(k) = scalar_extract(lossStage);
end

stageWeights = compute_module2_cpinn_causal_weights(stageRawLoss, opts);
loss = dlarray(0.0);
for k = 1:numStages
    loss = loss + stageWeights(k) .* stageLossCell{k};
end
loss = loss ./ sum(stageWeights);

gradients = dlgradient(loss, net.Learnables);

terms.pde = mean(stagePDE);
terms.dirichlet = mean(stageDirichlet);
terms.neumann = mean(stageNeumann);
terms.data = mean(stageData);
terms.causalWeightedStageLoss = sum(stageWeights .* stageRawLoss) ./ sum(stageWeights);
terms.stagePDE = stagePDE;
terms.stageDirichlet = stageDirichlet;
terms.stageNeumann = stageNeumann;
terms.stageData = stageData;
terms.stageRawLoss = stageRawLoss;
terms.stageWeights = stageWeights;
end

function [lossStage, parts] = module2_cpinn_single_stage_loss(net, batch, params, scales, opts, alpha, stageIndex)
% PDE residual loss at this continuation stage.
xHat = batch.xHatInterior(:, stageIndex);
yHat = batch.yHatInterior(:, stageIndex);
alphaVec = alpha * ones(size(xHat));
XYA = dlarray([xHat(:).'; yHat(:).'; alphaVec(:).'], 'CB');
[~, gradHat, lapHat] = module2_cpinn_phi_grad_lap(net, XYA); %#ok<ASGLU>

rhoFull = batch.rhoFullInterior(:, stageIndex);
if opts.useChargeContinuation
    rhoStage = alpha .* rhoFull;
else
    rhoStage = rhoFull;
end
rho = dlarray(rhoStage(:).', 'CB');
residual = params.eps_si * scales.V .* (lapHat.x ./ params.Lx^2 + lapHat.y ./ params.Ly^2) + rho;
lossPDE = mean((residual ./ scales.rho).^2, 'all');

% Dirichlet boundary loss at this stage.
if isempty(batch.xHatDirichlet)
    lossDirichlet = dlarray(0.0);
else
    alphaBc = alpha * ones(size(batch.xHatDirichlet));
    XYA_bc = dlarray([batch.xHatDirichlet(:).'; batch.yHatDirichlet(:).'; alphaBc(:).'], 'CB');
    phiHatBc = forward(net, XYA_bc);
    targetValue = continuation_scale(alpha, opts.useBoundaryContinuation) .* batch.phiDirichletFinal(:).';
    targetHat = dlarray(targetValue ./ scales.V, 'CB');
    lossDirichlet = mean((phiHatBc - targetHat).^2, 'all');
end

% Neumann boundary loss, expressed in physical V/m and then normalized.
if isempty(batch.xHatNeumann)
    lossNeumann = dlarray(0.0);
else
    alphaNeu = alpha * ones(size(batch.xHatNeumann));
    XYA_neu = dlarray([batch.xHatNeumann(:).'; batch.yHatNeumann(:).'; alphaNeu(:).'], 'CB');
    [~, gradHatNeu, ~] = module2_cpinn_phi_grad_lap(net, XYA_neu);
    nx = dlarray(batch.normalX(:).', 'CB');
    ny = dlarray(batch.normalY(:).', 'CB');
    targetValue = continuation_scale(alpha, opts.useBoundaryContinuation) .* batch.dphidnFinal(:).';
    target = dlarray(targetValue, 'CB');
    dphidnPred = scales.V .* (nx .* gradHatNeu.x ./ params.Lx + ny .* gradHatNeu.y ./ params.Ly);
    lossNeumann = mean(((dphidnPred - target) ./ scales.gradPhi).^2, 'all');
end

% Optional sparse anchor-data loss at this stage.  Since the continuation is
% linear for the current Poisson model, alpha*phi_final is a consistent stage
% target whenever both source and nonzero boundary values are alpha-scaled.
if isempty(batch.xHatData)
    lossData = dlarray(0.0);
else
    alphaData = alpha * ones(size(batch.xHatData));
    XYA_data = dlarray([batch.xHatData(:).'; batch.yHatData(:).'; alphaData(:).'], 'CB');
    phiHatDataPred = forward(net, XYA_data);
    targetData = continuation_scale(alpha, opts.useBoundaryContinuation || opts.useChargeContinuation) .* batch.phiHatDataFinal(:).';
    phiHatDataTarget = dlarray(targetData, 'CB');
    lossData = mean((phiHatDataPred - phiHatDataTarget).^2, 'all');
end

lossStage = opts.wPDE .* lossPDE + opts.wDirichlet .* lossDirichlet + ...
            opts.wNeumann .* lossNeumann + opts.wData .* lossData;

parts.pde = lossPDE;
parts.dirichlet = lossDirichlet;
parts.neumann = lossNeumann;
parts.data = lossData;
end

function c = continuation_scale(alpha, enabled)
if enabled
    c = alpha;
else
    c = 1.0;
end
end

function weights = compute_module2_cpinn_causal_weights(stageRawLoss, opts)
numStages = numel(stageRawLoss);
weights = ones(1, numStages);
for k = 2:numStages
    cumulativePreviousLoss = sum(stageRawLoss(1:(k-1)));
    weights(k) = exp(-opts.causalEpsilon * cumulativePreviousLoss);
    weights(k) = max(opts.causalWeightFloor, weights(k));
end
end

function [phiHat, gradHat, lapHat] = module2_cpinn_phi_grad_lap(net, XYA)
phiHat = forward(net, XYA);
gradPhi = dlgradient(sum(phiHat, 'all'), XYA, 'EnableHigherDerivatives', true);

dphidxHat = gradPhi(1, :);
dphidyHat = gradPhi(2, :);

gradX = dlgradient(sum(dphidxHat, 'all'), XYA, 'EnableHigherDerivatives', true);
gradY = dlgradient(sum(dphidyHat, 'all'), XYA, 'EnableHigherDerivatives', true);

gradHat.x = dphidxHat;
gradHat.y = dphidyHat;
lapHat.x = gradX(1, :);
lapHat.y = gradY(2, :);
end

function val = scalar_extract(x)
val = double(gather(extractdata(x)));
end

function cpinn = evaluate_module2_cpinn_on_mesh(net, mesh, params, scales, alpha, opts)
nodes = mesh.nodes;
xHat = nodes(:,1) ./ params.Lx;
yHat = nodes(:,2) ./ params.Ly;
rhoFull = build_space_charge_module2_2d(nodes, params);
if opts.useChargeContinuation
    rho = alpha .* rhoFull;
else
    rho = rhoFull;
end
[phi, Ex, Ey, residual] = dlfeval(@evaluate_module2_cpinn_dl, net, xHat, yHat, rho, params, scales, alpha);

cpinn.alpha = alpha;
cpinn.phi = phi;
cpinn.rho = rho;
cpinn.field.Ex_nodal = Ex;
cpinn.field.Ey_nodal = Ey;
cpinn.field.Enodal = [Ex, Ey];
cpinn.field.Emag_nodal = sqrt(Ex.^2 + Ey.^2);
cpinn.residual = residual;
cpinn.maxAbsPhi = max(abs(phi));
cpinn.maxAbsE = max(cpinn.field.Emag_nodal);
cpinn.maxAbsResidual = max(abs(residual));
end

function [phi, Ex, Ey, residual] = evaluate_module2_cpinn_dl(net, xHat, yHat, rho, params, scales, alpha)
alphaVec = alpha * ones(size(xHat(:).'));
XYA = dlarray([xHat(:).'; yHat(:).'; alphaVec], 'CB');
[phiHat, gradHat, lapHat] = module2_cpinn_phi_grad_lap(net, XYA);

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

function metrics = compute_module2_cpinn_metrics(fem, cpinn)
err = cpinn.phi - fem.phi;
refNorm = norm(fem.phi, 2);
if refNorm <= 0
    refNorm = 1.0;
end
metrics.relativePhiL2 = norm(err, 2) / refNorm;
metrics.maxAbsPhiError = max(abs(err));
metrics.meanAbsPhiError = mean(abs(err));
metrics.maxAbsResidual = max(abs(cpinn.residual));
metrics.rmsResidual = sqrt(mean(cpinn.residual.^2));
metrics.maxAbsE = cpinn.maxAbsE;
end

function plotFiles = plot_module2_cpinn_results(fem, cpinn, history, params, outputDir, stages)
mesh = fem.mesh;
nodes = mesh.nodes;
elems = mesh.elems;
caseName = params.caseName;
plotFiles = struct();

plotFiles.femPotential = save_trisurf_plot(elems, nodes, fem.phi, ...
    ['Module 2 FEM potential: ', strrep(caseName, '_', '\_')], ...
    'phi_{FEM} [V]', fullfile(outputDir, [caseName, '_fem_potential_reference.png']));

plotFiles.cpinnPotential = save_trisurf_plot(elems, nodes, cpinn.phi, ...
    ['Module 2 Causal PINN potential at alpha=1: ', strrep(caseName, '_', '\_')], ...
    'phi_{CPINN} [V]', fullfile(outputDir, [caseName, '_cpinn_potential.png']));

plotFiles.absError = save_trisurf_plot(elems, nodes, abs(cpinn.phi - fem.phi), ...
    ['Module 2 Causal PINN absolute potential error: ', strrep(caseName, '_', '\_')], ...
    '|phi_{CPINN}-phi_{FEM}| [V]', fullfile(outputDir, [caseName, '_cpinn_abs_potential_error.png']));

plotFiles.cpinnField = save_trisurf_plot(elems, nodes, cpinn.field.Emag_nodal, ...
    ['Module 2 Causal PINN electric-field magnitude: ', strrep(caseName, '_', '\_')], ...
    '|E_{CPINN}| [V/m]', fullfile(outputDir, [caseName, '_cpinn_electric_field_magnitude.png']));

plotFiles.residual = save_trisurf_plot(elems, nodes, cpinn.residual, ...
    ['Module 2 Causal PINN PDE residual: ', strrep(caseName, '_', '\_')], ...
    'eps laplacian(phi)+rho [C/m^3]', fullfile(outputDir, [caseName, '_cpinn_pde_residual.png']));

fig = figure('Visible', 'off');
semilogy(history.iteration, history.total, 'LineWidth', 1.5); hold on;
semilogy(history.iteration, history.pde, 'LineWidth', 1.0);
semilogy(history.iteration, history.dirichlet, 'LineWidth', 1.0);
semilogy(history.iteration, history.neumann, 'LineWidth', 1.0);
semilogy(history.iteration, history.data, 'LineWidth', 1.0);
semilogy(history.iteration, history.causalWeightedStageLoss, 'LineWidth', 1.0);
grid on;
xlabel('training iteration');
ylabel('loss');
title(['Module 2 Causal PINN training losses: ', strrep(caseName, '_', '\_')]);
legend({'total','mean PDE','mean Dirichlet','mean Neumann','mean data','causal weighted stage'}, 'Location', 'northeast');
plotFiles.lossHistory = fullfile(outputDir, [caseName, '_cpinn_training_loss.png']);
saveas(fig, plotFiles.lossHistory);
close(fig);

fig = figure('Visible', 'off');
plot(history.iteration, history.stageWeights, 'LineWidth', 1.0);
grid on;
xlabel('training iteration');
ylabel('causal weight');
title(['Module 2 Causal PINN stage weights: ', strrep(caseName, '_', '\_')]);
legend(make_stage_labels(stages), 'Location', 'eastoutside');
plotFiles.stageWeights = fullfile(outputDir, [caseName, '_cpinn_causal_stage_weights.png']);
saveas(fig, plotFiles.stageWeights);
close(fig);
end

function labels = make_stage_labels(stages)
labels = cell(1, numel(stages));
for k = 1:numel(stages)
    labels{k} = sprintf('alpha=%.2g', stages(k));
end
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

function summaryFile = write_module2_cpinn_summary(params, opts, scales, metrics, outputDir, stages)
summaryFile = fullfile(outputDir, [params.caseName, '_module2_cpinn_summary.txt']);
fid = fopen(summaryFile, 'w');
if fid < 0
    error('Could not open summary file: %s', summaryFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Module 2 causal physics-informed neural-network summary\n');
fprintf(fid, '=======================================================\n');
fprintf(fid, 'Case: %s\n', params.caseName);
fprintf(fid, 'PDE: div(eps_si grad(phi)) = -rho\n');
fprintf(fid, 'Residual minimized: eps_si*(d2phi/dx2 + d2phi/dy2) + rho\n');
fprintf(fid, 'Causal variable: alpha continuation over source/boundary loading\n');
fprintf(fid, 'Final prediction evaluated at alpha = %.6e\n', opts.finalAlpha);
fprintf(fid, 'Domain: Lx = %.6e m, Ly = %.6e m\n', params.Lx, params.Ly);
fprintf(fid, 'Mesh used for reference plots: nx = %d, ny = %d\n', params.nx, params.ny);
fprintf(fid, 'eps_si = %.6e F/m\n', params.eps_si);
fprintf(fid, '\nNetwork and training\n');
fprintf(fid, '--------------------\n');
fprintf(fid, 'Inputs: x/Lx, y/Ly, alpha\n');
fprintf(fid, 'Hidden layers: %d\n', opts.numHiddenLayers);
fprintf(fid, 'Neurons/layer: %d\n', opts.numNeurons);
fprintf(fid, 'Activation: tanh\n');
fprintf(fid, 'Iterations: %d\n', opts.maxIterations);
fprintf(fid, 'Learning rate: %.6e\n', opts.learnRate);
fprintf(fid, 'Causal stages: %d\n', opts.numStages);
fprintf(fid, 'Stage alpha values: ');
fprintf(fid, '%.6g ', stages);
fprintf(fid, '\n');
fprintf(fid, 'Interior collocation points/stage/iteration: %d\n', opts.numInteriorPerStage);
fprintf(fid, 'Boundary points/side/iteration: %d\n', opts.numBoundaryPerSide);
fprintf(fid, 'FEM anchor data enabled: %d\n', opts.useDataAnchors);
fprintf(fid, 'FEM anchor points: %d\n', opts.numDataAnchors);
fprintf(fid, 'Charge continuation enabled: %d\n', opts.useChargeContinuation);
fprintf(fid, 'Boundary continuation enabled: %d\n', opts.useBoundaryContinuation);
fprintf(fid, 'Causal epsilon: %.6e\n', opts.causalEpsilon);
fprintf(fid, 'Causal weight floor: %.6e\n', opts.causalWeightFloor);
fprintf(fid, 'Loss weights: PDE %.3e, Dirichlet %.3e, Neumann %.3e, Data %.3e\n', ...
    opts.wPDE, opts.wDirichlet, opts.wNeumann, opts.wData);
fprintf(fid, '\nScales\n');
fprintf(fid, '------\n');
fprintf(fid, 'Potential scale V = %.6e V\n', scales.V);
fprintf(fid, 'Charge-density scale rho = %.6e C/m^3\n', scales.rho);
fprintf(fid, 'Gradient scale = %.6e V/m\n', scales.gradPhi);
fprintf(fid, '\nReference-comparison metrics at alpha = 1\n');
fprintf(fid, '-----------------------------------------\n');
fprintf(fid, 'Relative phi L2 error = %.6e\n', metrics.relativePhiL2);
fprintf(fid, 'Max absolute phi error = %.6e V\n', metrics.maxAbsPhiError);
fprintf(fid, 'Mean absolute phi error = %.6e V\n', metrics.meanAbsPhiError);
fprintf(fid, 'Max absolute PDE residual = %.6e C/m^3\n', metrics.maxAbsResidual);
fprintf(fid, 'RMS PDE residual = %.6e C/m^3\n', metrics.rmsResidual);
fprintf(fid, 'Max CPINN |E| = %.6e V/m\n', metrics.maxAbsE);
end
