function out = main_module3_CPINN_Defect_Evolution(caseName, opts)
% MAIN_MODULE3_CPINN_DEFECT_EVOLUTION Causal PINN for Module 3 defect evolution.
%
%   out = MAIN_MODULE3_CPINN_DEFECT_EVOLUTION(caseName) trains a causal
%   physics-informed neural network for
%
%       dC/dt = D*(d2C/dx2 + d2C/dy2) - kAnn*C + S
%
%   on the rectangular Module 3 domain. The network represents the
%   dimensionless concentration Chat(x/Lx,y/Ly,t/tEnd). The initial-condition
%   loss and the PDE residuals at ordered time slices form the causal prefix:
%
%       w(1) = 1,
%       w(i) = exp(-epsilon*stopgrad(sum_{j<i} L(j))).
%
%   Boundary and optional reference-data terms are enforced outside that
%   prefix, matching the residual-only causal weighting recommended in
%   docs/physics_notes/module3_cPIN.pdf. Extracting each prefix loss before
%   constructing w implements the required stop-gradient operation.
%
%   Supported first-study cases:
%       'pure_annealing'    - spatially uniform exact exponential benchmark
%       'gaussian_diffusion' - localized cloud with the FEM path as reference
%       'uniform_state'      - constant-state preservation benchmark
%
%   Example:
%       setup_project_paths
%       out = main_module3_CPINN_Defect_Evolution('pure_annealing');
%
%   Faster smoke run:
%       opts.epsilonSchedule = [0.1, 1.0];
%       opts.maxIterationsPerEpsilon = 10;
%       opts.numTimeSlices = 3;
%       opts.numInteriorPerSlice = 32;
%       opts.numInitial = 48;
%       opts.numBoundaryPerSide = 12;
%       opts.makePlots = false;
%       opts.saveMat = false;
%       out = main_module3_CPINN_Defect_Evolution('pure_annealing', opts);
%
%   Requirements:
%       MATLAB Deep Learning Toolbox (dlarray, dlnetwork, dlgradient,
%       dlfeval, and adamupdate).

if nargin < 1 || isempty(caseName)
    caseName = 'pure_annealing';
end
if nargin < 2 || isempty(opts)
    opts = struct();
end

projectMatlabDir = fileparts(mfilename('fullpath'));
addpath(projectMatlabDir);
addpath(fullfile(projectMatlabDir, 'cases'));
addpath(genpath(fullfile(projectMatlabDir, 'src')));

require_deep_learning_toolbox_for_module3_cpinn();
opts = default_module3_cpinn_options(opts);
rng(opts.randomSeed, 'twister');

params = default_module3_fem_params(caseName);
validate_module3_cpinn_problem(params);

timeHat = make_module3_cpinn_time_slices(opts);
timePhysical = params.time.tEnd .* timeHat;
reference = build_module3_cpinn_reference(params, timePhysical);
scales = compute_module3_cpinn_scales(params, reference);
anchors = make_module3_cpinn_anchor_data(reference, scales, opts);
net = initialize_module3_cpinn_network(opts);

outputDir = fullfile(projectMatlabDir, 'outputs', 'module3_cpinn_2d', params.caseName);
if (opts.makePlots || opts.saveMat || opts.writeSummary) && ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

numScheduleStages = numel(opts.epsilonSchedule);
totalIterations = numScheduleStages * opts.maxIterationsPerEpsilon;
history = initialize_module3_cpinn_history(totalIterations, opts.numTimeSlices);
trailingAvg = [];
trailingAvgSq = [];
globalIteration = 0;

fprintf('Module 3 causal PINN case "%s" starting.\n', params.caseName);
fprintf('  Causal time slices: %d residual slices plus the initial slice\n', opts.numTimeSlices);
fprintf('  Epsilon schedule: ');
fprintf('%.4g ', opts.epsilonSchedule);
fprintf('\n');
fprintf('  Planned gradient updates: %d\n', totalIterations);

fixedBatch = [];
if ~opts.resampleCollocation
    fixedBatch = sample_module3_cpinn_batch(params, scales, opts, anchors);
end

for epsilonIndex = 1:numScheduleStages
    epsilon = opts.epsilonSchedule(epsilonIndex);

    for localIteration = 1:opts.maxIterationsPerEpsilon
        globalIteration = globalIteration + 1;
        if opts.resampleCollocation
            batch = sample_module3_cpinn_batch(params, scales, opts, anchors);
        else
            batch = fixedBatch;
        end

        [loss, gradients, terms] = dlfeval(@module3_cpinn_model_loss, ...
            net, batch, params, scales, opts, timeHat, epsilon);
        [net, trailingAvg, trailingAvgSq] = adamupdate(net, gradients, ...
            trailingAvg, trailingAvgSq, globalIteration, opts.learnRate, ...
            opts.gradientDecayFactor, opts.squaredGradientDecayFactor);

        history.total(globalIteration) = scalar_extract(loss);
        history.causal(globalIteration) = terms.causal;
        history.initial(globalIteration) = terms.initial;
        history.pde(globalIteration) = terms.pde;
        history.boundary(globalIteration) = terms.boundary;
        history.data(globalIteration) = terms.data;
        history.rawCausalLoss(globalIteration, :) = terms.rawCausalLoss;
        history.causalWeights(globalIteration, :) = terms.causalWeights;
        history.slicePDE(globalIteration, :) = terms.slicePDE;
        history.sliceBoundary(globalIteration, :) = terms.sliceBoundary;
        history.sliceData(globalIteration, :) = terms.sliceData;
        history.epsilon(globalIteration) = epsilon;
        history.epsilonStage(globalIteration) = epsilonIndex;

        if opts.verbose && (localIteration == 1 || ...
                mod(localIteration, opts.printEvery) == 0 || ...
                localIteration == opts.maxIterationsPerEpsilon)
            fprintf(['  eps %.3e | local %4d/%4d | global %5d | total %.3e ', ...
                     '| IC %.3e | PDE %.3e | BC %.3e | data %.3e ', ...
                     '| min w %.3e | final w %.3e\n'], ...
                epsilon, localIteration, opts.maxIterationsPerEpsilon, ...
                globalIteration, history.total(globalIteration), ...
                history.initial(globalIteration), history.pde(globalIteration), ...
                history.boundary(globalIteration), history.data(globalIteration), ...
                min(history.causalWeights(globalIteration, :)), ...
                history.causalWeights(globalIteration, end));
        end
    end
end

history = trim_module3_cpinn_history(history, globalIteration);
cpinn = evaluate_module3_cpinn(net, reference.mesh, timeHat, params, scales);
metrics = compute_module3_cpinn_metrics(reference, cpinn);

if opts.makePlots
    plotFiles = plot_module3_cpinn_results(reference, cpinn, history, ...
        params, outputDir, timePhysical);
else
    plotFiles = struct();
end

if opts.writeSummary
    summaryFile = write_module3_cpinn_summary(params, opts, scales, ...
        metrics, history, reference, outputDir, timePhysical);
else
    summaryFile = '';
end

out.params = params;
out.options = opts;
out.options.totalIterations = globalIteration;
out.causalTimesHat = timeHat;
out.causalTimes = timePhysical;
out.scales = scales;
out.net = net;
out.reference = reference;
out.femReference = reference;
out.cpinn = cpinn;
out.pinn = cpinn;
out.trainingHistory = history;
out.metrics = metrics;
out.outputDir = outputDir;
out.plotFiles = plotFiles;
out.summaryFile = summaryFile;

if opts.saveMat
    save(fullfile(outputDir, [params.caseName, ...
        '_module3_cpinn_results.mat']), 'out', '-v7.3');
end

fprintf('Module 3 causal PINN case "%s" complete.\n', params.caseName);
fprintf('  final relative field L2 error : %.4e\n', metrics.finalRelativeFieldL2);
fprintf('  final inventory error         : %.4e\n', metrics.finalInventoryRelativeError);
fprintf('  RMS dimensionless residual    : %.4e\n', metrics.rmsResidualHat);
if opts.makePlots || opts.saveMat || opts.writeSummary
    fprintf('  output dir                    : %s\n', outputDir);
end
end

function require_deep_learning_toolbox_for_module3_cpinn()
required = {'dlarray', 'dlnetwork', 'dlgradient', 'dlfeval', 'adamupdate'};
for k = 1:numel(required)
    name = required{k};
    if ~(exist(name, 'file') == 2 || exist(name, 'class') == 8)
        error(['Module 3 causal PINN requires MATLAB Deep Learning Toolbox. ', ...
               'Missing required function or class: %s.'], name);
    end
end
end

function opts = default_module3_cpinn_options(opts)
% Defaults provide a reproducible first experiment rather than a production
% convergence guarantee. The exact test uses much smaller values.
opts = set_default(opts, 'randomSeed', 17);
opts = set_default(opts, 'numHiddenLayers', 4);
opts = set_default(opts, 'numNeurons', 64);
opts = set_default(opts, 'epsilonSchedule', [1.0e-2, 1.0e-1, 1.0, 10.0]);
opts = set_default(opts, 'maxIterationsPerEpsilon', 300);
opts = set_default(opts, 'learnRate', 1.0e-3);
opts = set_default(opts, 'gradientDecayFactor', 0.9);
opts = set_default(opts, 'squaredGradientDecayFactor', 0.999);
opts = set_default(opts, 'numTimeSlices', 8);
opts = set_default(opts, 'timeSlicePower', 1.0);
opts = set_default(opts, 'numInteriorPerSlice', 256);
opts = set_default(opts, 'numInitial', 512);
opts = set_default(opts, 'numBoundaryPerSide', 64);
opts = set_default(opts, 'useDataAnchors', false);
opts = set_default(opts, 'numDataAnchors', 96);
opts = set_default(opts, 'wInitial', 1.0);
opts = set_default(opts, 'wPDE', 1.0);
opts = set_default(opts, 'wBoundary', 1.0);
opts = set_default(opts, 'wData', 1.0);
opts = set_default(opts, 'causalWeightFloor', 1.0e-8);
opts = set_default(opts, 'causalStopThreshold', 0.99);
opts = set_default(opts, 'resampleCollocation', true);
opts = set_default(opts, 'makePlots', true);
opts = set_default(opts, 'saveMat', true);
opts = set_default(opts, 'writeSummary', true);
opts = set_default(opts, 'verbose', true);
opts = set_default(opts, 'printEvery', 50);

opts.epsilonSchedule = reshape(opts.epsilonSchedule, 1, []);

must_be_positive_integer(opts.numHiddenLayers, 'opts.numHiddenLayers');
must_be_positive_integer(opts.numNeurons, 'opts.numNeurons');
must_be_positive_integer(opts.maxIterationsPerEpsilon, 'opts.maxIterationsPerEpsilon');
must_be_positive_integer(opts.numTimeSlices, 'opts.numTimeSlices');
must_be_positive_integer(opts.numInteriorPerSlice, 'opts.numInteriorPerSlice');
must_be_positive_integer(opts.numInitial, 'opts.numInitial');
must_be_positive_integer(opts.numBoundaryPerSide, 'opts.numBoundaryPerSide');
if opts.numDataAnchors < 0 || opts.numDataAnchors ~= floor(opts.numDataAnchors)
    error('opts.numDataAnchors must be a nonnegative integer.');
end
if isempty(opts.epsilonSchedule) || any(~isfinite(opts.epsilonSchedule)) || ...
        any(opts.epsilonSchedule < 0)
    error('opts.epsilonSchedule must contain finite nonnegative values.');
end
if opts.timeSlicePower <= 0 || ~isfinite(opts.timeSlicePower)
    error('opts.timeSlicePower must be finite and positive.');
end
if opts.learnRate <= 0 || ~isfinite(opts.learnRate)
    error('opts.learnRate must be finite and positive.');
end
if opts.causalWeightFloor < 0 || opts.causalWeightFloor > 1
    error('opts.causalWeightFloor must lie in [0,1].');
end
if opts.causalStopThreshold <= 0 || opts.causalStopThreshold > 1
    error('opts.causalStopThreshold must lie in (0,1].');
end
if any([opts.wInitial, opts.wPDE, opts.wBoundary, opts.wData] < 0)
    error('All loss weights must be nonnegative.');
end
end

function s = set_default(s, fieldName, value)
if ~isfield(s, fieldName) || isempty(s.(fieldName))
    s.(fieldName) = value;
end
end

function must_be_positive_integer(value, name)
if ~isscalar(value) || ~isfinite(value) || value < 1 || value ~= floor(value)
    error('%s must be a positive integer.', name);
end
end

function validate_module3_cpinn_problem(params)
if ~isscalar(params.physics.D) || ~isscalar(params.physics.kAnn) || ...
        ~isscalar(params.physics.source)
    error(['The first Module 3 causal-PINN implementation requires scalar D, ', ...
           'kAnn, and source. Variable coefficients are a planned extension.']);
end
if params.physics.D < 0
    error('The diffusivity D must be nonnegative.');
end
if params.physics.kAnn < 0
    error('The annealing rate kAnn must be nonnegative.');
end
if params.time.tEnd <= 0
    error('The final time must be positive.');
end
supported = {'uniform', 'gaussian'};
if ~any(strcmpi(params.init.type, supported))
    error('Unsupported Module 3 causal-PINN initial-condition type: %s.', params.init.type);
end
if isfield(params.bc, 'useDirichlet') && params.bc.useDirichlet
    error(['The first Module 3 causal-PINN implementation supports the ', ...
           'project default homogeneous zero-flux boundary condition only.']);
end
end

function timeHat = make_module3_cpinn_time_slices(opts)
base = linspace(0.0, 1.0, opts.numTimeSlices + 1);
timeHat = base .^ opts.timeSlicePower;
timeHat(1) = 0.0;
timeHat(end) = 1.0;
timeHat = reshape(timeHat, 1, []);
end

function reference = build_module3_cpinn_reference(params, targetTimes)
mesh = make_rectangular_tri_mesh_2d(params.domain.Lx, params.domain.Ly, ...
    params.domain.nx, params.domain.ny);
C0 = initialize_defect_field_fem_2d(mesh, params.init);
assembled = assemble_defect_fem_2d(mesh, params.physics);

isUniform = max(C0) - min(C0) <= 1.0e-12 * max(max(abs(C0)), 1.0);
if isUniform
    Ctarget = zeros(numel(C0), numel(targetTimes));
    for j = 1:numel(targetTimes)
        Ctarget(:, j) = exact_uniform_reaction_source( ...
            C0, targetTimes(j), params.physics.kAnn, params.physics.source);
    end
    method = 'analytic_uniform_reaction_source';
else
    referenceParams = params;
    referenceParams.time.saveEvery = 1;
    referenceParams.io.makePlots = false;
    referenceParams.io.writeMatFile = false;
    femOut = solve_defect_diffusion_reaction_fem_2d(referenceParams);

    rawTimes = [0.0; femOut.tHistory(:)];
    rawC = zeros(numel(C0), numel(rawTimes));
    rawC(:, 1) = femOut.Cinitial;
    for j = 1:numel(femOut.history)
        rawC(:, j + 1) = femOut.history(j).C;
    end
    Ctarget = interp1(rawTimes, rawC.', targetTimes(:), 'linear').';
    method = 'module3_linear_triangle_fem_backward_euler';
end

reference.method = method;
reference.mesh = mesh;
reference.M = assembled.M;
reference.time = reshape(targetTimes, 1, []);
reference.C = Ctarget;
reference.Cinitial = Ctarget(:, 1);
reference.Cfinal = Ctarget(:, end);
reference.inventory = compute_inventory_history(assembled.M, Ctarget);
end

function C = exact_uniform_reaction_source(C0, t, kAnn, source)
if kAnn > 0
    C = C0 .* exp(-kAnn .* t) + (source ./ kAnn) .* ...
        (1.0 - exp(-kAnn .* t));
else
    C = C0 + source .* t;
end
end

function scales = compute_module3_cpinn_scales(params, reference)
Cscale = max(abs(reference.Cinitial));
if Cscale <= 0 || ~isfinite(Cscale)
    Cscale = 1.0;
end

scales.x = params.domain.Lx;
scales.y = params.domain.Ly;
scales.t = params.time.tEnd;
scales.C = Cscale;
scales.diffusionX = params.physics.D .* scales.t ./ scales.x.^2;
scales.diffusionY = params.physics.D .* scales.t ./ scales.y.^2;
scales.reaction = params.physics.kAnn .* scales.t;
scales.source = params.physics.source .* scales.t ./ scales.C;
scales.dimensionalResidual = scales.C ./ scales.t;
end

function anchors = make_module3_cpinn_anchor_data(reference, scales, opts)
anchors.xHat = [];
anchors.yHat = [];
anchors.CHat = [];

if ~opts.useDataAnchors || opts.numDataAnchors <= 0
    return;
end

numNodes = size(reference.mesh.nodes, 1);
numAnchors = min(opts.numDataAnchors, numNodes);
idx = randperm(numNodes, numAnchors);
xy = reference.mesh.nodes(idx, :);

anchors.xHat = xy(:, 1) ./ scales.x;
anchors.yHat = xy(:, 2) ./ scales.y;
anchors.CHat = reference.C(idx, 2:end) ./ scales.C;
end

function net = initialize_module3_cpinn_network(opts)
layers = featureInputLayer(3, 'Normalization', 'none', 'Name', 'input');
for k = 1:opts.numHiddenLayers
    layers = [layers
        fullyConnectedLayer(opts.numNeurons, 'Name', sprintf('fc_%d', k))
        tanhLayer('Name', sprintf('tanh_%d', k))]; %#ok<AGROW>
end
layers = [layers
    fullyConnectedLayer(1, 'Name', 'C_hat')];
net = dlnetwork(layerGraph(layers));
end

function history = initialize_module3_cpinn_history(numIterations, numTimeSlices)
history.iteration = (1:numIterations).';
history.total = nan(numIterations, 1);
history.causal = nan(numIterations, 1);
history.initial = nan(numIterations, 1);
history.pde = nan(numIterations, 1);
history.boundary = nan(numIterations, 1);
history.data = nan(numIterations, 1);
history.rawCausalLoss = nan(numIterations, numTimeSlices + 1);
history.causalWeights = nan(numIterations, numTimeSlices + 1);
history.slicePDE = nan(numIterations, numTimeSlices);
history.sliceBoundary = nan(numIterations, numTimeSlices);
history.sliceData = nan(numIterations, numTimeSlices);
history.epsilon = nan(numIterations, 1);
history.epsilonStage = nan(numIterations, 1);
end

function history = trim_module3_cpinn_history(history, n)
fields = fieldnames(history);
for k = 1:numel(fields)
    name = fields{k};
    value = history.(name);
    if ~isempty(value) && size(value, 1) >= n
        history.(name) = value(1:n, :);
    end
end
end

function batch = sample_module3_cpinn_batch(params, scales, opts, anchors)
numSlices = opts.numTimeSlices;
batch.xHatInterior = rand(opts.numInteriorPerSlice, numSlices);
batch.yHatInterior = rand(opts.numInteriorPerSlice, numSlices);

batch.xHatInitial = rand(opts.numInitial, 1);
batch.yHatInitial = rand(opts.numInitial, 1);
batch.CHatInitial = evaluate_initial_condition_hat( ...
    batch.xHatInitial, batch.yHatInitial, params, scales.C);

[batch.xHatBoundary, batch.yHatBoundary, ...
    batch.normalX, batch.normalY] = sample_rectangle_boundary(opts.numBoundaryPerSide);

batch.xHatData = anchors.xHat;
batch.yHatData = anchors.yHat;
batch.CHatData = anchors.CHat;
end

function CHat = evaluate_initial_condition_hat(xHat, yHat, params, Cscale)
switch lower(params.init.type)
    case 'uniform'
        if isfield(params.init, 'value')
            value = params.init.value;
        else
            value = params.init.background;
        end
        C = value .* ones(size(xHat));

    case 'gaussian'
        x = params.domain.Lx .* xHat;
        y = params.domain.Ly .* yHat;
        C = params.init.background + params.init.peak .* exp( ...
            -0.5 .* ((x - params.init.x0) ./ params.init.sigmaX).^2 ...
            -0.5 .* ((y - params.init.y0) ./ params.init.sigmaY).^2);

    otherwise
        error('Unsupported initial-condition type: %s.', params.init.type);
end
CHat = C ./ Cscale;
end

function [xHat, yHat, normalX, normalY] = sample_rectangle_boundary(nPerSide)
s = rand(nPerSide, 1);
xHat = [zeros(nPerSide, 1); ones(nPerSide, 1); s; s];
yHat = [s; s; zeros(nPerSide, 1); ones(nPerSide, 1)];
normalX = [-ones(nPerSide, 1); ones(nPerSide, 1); ...
    zeros(2 * nPerSide, 1)];
normalY = [zeros(2 * nPerSide, 1); -ones(nPerSide, 1); ...
    ones(nPerSide, 1)];
end

function [loss, gradients, terms] = module3_cpinn_model_loss( ...
        net, batch, params, scales, opts, timeHat, epsilon)
numSlices = numel(timeHat) - 1;

XYT0 = dlarray([batch.xHatInitial(:).'; batch.yHatInitial(:).'; ...
    zeros(1, numel(batch.xHatInitial))], 'CB');
CHat0 = forward(net, XYT0);
target0 = dlarray(batch.CHatInitial(:).', 'CB');
lossInitial = mean((CHat0 - target0).^2, 'all');

rawLossCell = cell(1, numSlices + 1);
boundaryLossCell = cell(1, numSlices);
dataLossCell = cell(1, numSlices);
rawLossCell{1} = opts.wInitial .* lossInitial;
slicePDE = zeros(1, numSlices);
sliceBoundary = zeros(1, numSlices);
sliceData = zeros(1, numSlices);

for i = 1:numSlices
    tau = timeHat(i + 1);
    [lossPDE, lossBoundary, lossData] = module3_cpinn_slice_losses( ...
        net, batch, scales, opts, tau, i);
    rawLossCell{i + 1} = opts.wPDE .* lossPDE;
    boundaryLossCell{i} = lossBoundary;
    dataLossCell{i} = lossData;
    slicePDE(i) = scalar_extract(lossPDE);
    sliceBoundary(i) = scalar_extract(lossBoundary);
    sliceData(i) = scalar_extract(lossData);
end

rawCausalLoss = zeros(1, numSlices + 1);
for i = 1:(numSlices + 1)
    rawCausalLoss(i) = scalar_extract(rawLossCell{i});
end

% rawCausalLoss is numeric here, so the weights are deliberately detached
% from automatic differentiation: this is stop-gradient causal weighting.
causalWeights = compute_module3_causal_weights( ...
    rawCausalLoss, epsilon, opts.causalWeightFloor);

lossCausal = dlarray(0.0);
for i = 1:(numSlices + 1)
    lossCausal = lossCausal + causalWeights(i) .* rawLossCell{i};
end
lossCausal = lossCausal ./ (numSlices + 1);

lossBoundaryMean = dlarray(0.0);
lossDataMean = dlarray(0.0);
for i = 1:numSlices
    lossBoundaryMean = lossBoundaryMean + boundaryLossCell{i};
    lossDataMean = lossDataMean + dataLossCell{i};
end
lossBoundaryMean = lossBoundaryMean ./ numSlices;
lossDataMean = lossDataMean ./ numSlices;

loss = lossCausal + opts.wBoundary .* lossBoundaryMean + ...
    opts.wData .* lossDataMean;
gradients = dlgradient(loss, net.Learnables);

terms.causal = scalar_extract(lossCausal);
terms.initial = scalar_extract(lossInitial);
terms.pde = mean(slicePDE);
terms.boundary = mean(sliceBoundary);
terms.data = mean(sliceData);
terms.rawCausalLoss = rawCausalLoss;
terms.causalWeights = causalWeights;
terms.slicePDE = slicePDE;
terms.sliceBoundary = sliceBoundary;
terms.sliceData = sliceData;
end

function [lossPDE, lossBoundary, lossData] = module3_cpinn_slice_losses( ...
        net, batch, scales, opts, tau, sliceIndex)
xHat = batch.xHatInterior(:, sliceIndex);
yHat = batch.yHatInterior(:, sliceIndex);
tauInterior = tau .* ones(size(xHat));
XYT = dlarray([xHat(:).'; yHat(:).'; tauInterior(:).'], 'CB');
[CHat, derivatives] = module3_cpinn_state_derivatives(net, XYT);

residualHat = derivatives.t ...
    - scales.diffusionX .* derivatives.xx ...
    - scales.diffusionY .* derivatives.yy ...
    + scales.reaction .* CHat ...
    - scales.source;
lossPDE = mean(residualHat.^2, 'all');

fluxScale = max(abs([scales.diffusionX, scales.diffusionY]));
if fluxScale <= eps
    lossBoundary = dlarray(0.0);
else
    tauBoundary = tau .* ones(size(batch.xHatBoundary));
    XYTb = dlarray([batch.xHatBoundary(:).'; batch.yHatBoundary(:).'; ...
        tauBoundary(:).'], 'CB');
    [~, gradBoundary] = module3_cpinn_state_gradient(net, XYTb);
    nx = dlarray(batch.normalX(:).', 'CB');
    ny = dlarray(batch.normalY(:).', 'CB');
    fluxHat = (nx .* scales.diffusionX .* gradBoundary.x + ...
        ny .* scales.diffusionY .* gradBoundary.y) ./ fluxScale;
    lossBoundary = mean(fluxHat.^2, 'all');
end

if isempty(batch.xHatData) || ~opts.useDataAnchors
    lossData = dlarray(0.0);
else
    tauData = tau .* ones(size(batch.xHatData));
    XYTd = dlarray([batch.xHatData(:).'; batch.yHatData(:).'; ...
        tauData(:).'], 'CB');
    prediction = forward(net, XYTd);
    target = dlarray(batch.CHatData(:, sliceIndex).', 'CB');
    lossData = mean((prediction - target).^2, 'all');
end
end

function [CHat, derivatives] = module3_cpinn_state_derivatives(net, XYT)
[CHat, derivatives] = module3_cpinn_state_gradient(net, XYT);

gradX = dlgradient(sum(derivatives.x, 'all'), XYT, ...
    'EnableHigherDerivatives', true);
gradY = dlgradient(sum(derivatives.y, 'all'), XYT, ...
    'EnableHigherDerivatives', true);
derivatives.xx = gradX(1, :);
derivatives.yy = gradY(2, :);
end

function [CHat, derivatives] = module3_cpinn_state_gradient(net, XYT)
CHat = forward(net, XYT);
gradC = dlgradient(sum(CHat, 'all'), XYT, 'EnableHigherDerivatives', true);
derivatives.x = gradC(1, :);
derivatives.y = gradC(2, :);
derivatives.t = gradC(3, :);
end

function weights = compute_module3_causal_weights(rawLoss, epsilon, floorValue)
numSlices = numel(rawLoss);
weights = ones(1, numSlices);
prefix = 0.0;
for i = 2:numSlices
    prefix = prefix + rawLoss(i - 1);
    exponent = -epsilon .* prefix;
    weights(i) = max(floorValue, exp(max(exponent, log(realmin('double')))));
end
end

function value = scalar_extract(x)
value = double(gather(extractdata(x)));
end

function cpinn = evaluate_module3_cpinn(net, mesh, timeHat, params, scales)
nodes = mesh.nodes;
xHat = nodes(:, 1) ./ scales.x;
yHat = nodes(:, 2) ./ scales.y;
numNodes = size(nodes, 1);
numTimes = numel(timeHat);

C = zeros(numNodes, numTimes);
residualHat = zeros(numNodes, numTimes);
for j = 1:numTimes
    [C(:, j), residualHat(:, j)] = dlfeval(@evaluate_module3_cpinn_dl, ...
        net, xHat, yHat, timeHat(j), scales);
end

cpinn.mesh = mesh;
cpinn.timeHat = timeHat;
cpinn.time = params.time.tEnd .* timeHat;
cpinn.C = C;
cpinn.Cinitial = C(:, 1);
cpinn.Cfinal = C(:, end);
cpinn.residualHat = residualHat;
cpinn.residual = scales.dimensionalResidual .* residualHat;
cpinn.minC = min(C, [], 'all');
cpinn.maxC = max(C, [], 'all');
end

function [C, residualHat] = evaluate_module3_cpinn_dl( ...
        net, xHat, yHat, tau, scales)
tauVector = tau .* ones(size(xHat(:).'));
XYT = dlarray([xHat(:).'; yHat(:).'; tauVector], 'CB');
[CHat, derivatives] = module3_cpinn_state_derivatives(net, XYT);
residual = derivatives.t ...
    - scales.diffusionX .* derivatives.xx ...
    - scales.diffusionY .* derivatives.yy ...
    + scales.reaction .* CHat ...
    - scales.source;

C = scales.C .* double(gather(extractdata(CHat))).';
residualHat = double(gather(extractdata(residual))).';
end

function metrics = compute_module3_cpinn_metrics(reference, cpinn)
numTimes = numel(reference.time);
relativeFieldL2 = zeros(1, numTimes);
maxAbsFieldError = zeros(1, numTimes);
for j = 1:numTimes
    errorField = cpinn.C(:, j) - reference.C(:, j);
    numerator = errorField.' * reference.M * errorField;
    denominator = reference.C(:, j).' * reference.M * reference.C(:, j);
    relativeFieldL2(j) = sqrt(max(numerator, 0.0) / max(denominator, eps));
    maxAbsFieldError(j) = max(abs(errorField));
end

inventoryPrediction = compute_inventory_history(reference.M, cpinn.C);
inventoryReference = reference.inventory;
inventoryRelativeError = (inventoryPrediction - inventoryReference) ./ ...
    max(abs(inventoryReference), eps);

metrics.relativeFieldL2 = relativeFieldL2;
metrics.finalRelativeFieldL2 = relativeFieldL2(end);
metrics.maxAbsFieldError = maxAbsFieldError;
metrics.finalMaxAbsFieldError = maxAbsFieldError(end);
metrics.inventoryPrediction = inventoryPrediction;
metrics.inventoryReference = inventoryReference;
metrics.inventoryRelativeError = inventoryRelativeError;
metrics.finalInventoryRelativeError = inventoryRelativeError(end);
metrics.rmsResidualHat = sqrt(mean(cpinn.residualHat.^2, 'all'));
metrics.maxAbsResidualHat = max(abs(cpinn.residualHat), [], 'all');
metrics.rmsResidual = sqrt(mean(cpinn.residual.^2, 'all'));
metrics.maxAbsResidual = max(abs(cpinn.residual), [], 'all');
metrics.minimumPredictedConcentration = min(cpinn.C, [], 'all');
metrics.maximumPredictedConcentration = max(cpinn.C, [], 'all');
end

function inventory = compute_inventory_history(M, C)
inventory = ones(1, size(M, 1)) * M * C;
end

function plotFiles = plot_module3_cpinn_results(reference, cpinn, history, ...
        params, outputDir, timePhysical)
mesh = reference.mesh;
nodes = mesh.nodes;
elems = mesh.elems;
caseName = params.caseName;
plotFiles = struct();

plotFiles.referenceFinal = save_trisurf_plot(elems, nodes, ...
    reference.Cfinal, ['Module 3 reference final C: ', ...
    strrep(caseName, '_', '\_')], 'C_{reference} [m^{-3}]', ...
    fullfile(outputDir, [caseName, '_reference_final_concentration.png']));

plotFiles.cpinnFinal = save_trisurf_plot(elems, nodes, ...
    cpinn.Cfinal, ['Module 3 causal PINN final C: ', ...
    strrep(caseName, '_', '\_')], 'C_{cPIN} [m^{-3}]', ...
    fullfile(outputDir, [caseName, '_cpinn_final_concentration.png']));

plotFiles.finalAbsError = save_trisurf_plot(elems, nodes, ...
    abs(cpinn.Cfinal - reference.Cfinal), ...
    ['Module 3 causal PINN final absolute error: ', ...
    strrep(caseName, '_', '\_')], '|C_{cPIN}-C_{reference}| [m^{-3}]', ...
    fullfile(outputDir, [caseName, '_cpinn_final_absolute_error.png']));

fig = figure('Visible', 'off');
semilogy(history.iteration, history.total, 'LineWidth', 1.4); hold on;
semilogy(history.iteration, history.causal, 'LineWidth', 1.0);
semilogy(history.iteration, history.initial, 'LineWidth', 1.0);
semilogy(history.iteration, history.pde, 'LineWidth', 1.0);
semilogy(history.iteration, history.boundary, 'LineWidth', 1.0);
if any(history.data > 0)
    semilogy(history.iteration, history.data, 'LineWidth', 1.0);
    labels = {'total', 'causal prefix', 'IC', 'mean PDE', 'mean BC', 'mean data'};
else
    labels = {'total', 'causal prefix', 'IC', 'mean PDE', 'mean BC'};
end
grid on;
xlabel('gradient update');
ylabel('dimensionless loss');
title(['Module 3 causal PINN losses: ', strrep(caseName, '_', '\_')]);
legend(labels, 'Location', 'northeast');
plotFiles.lossHistory = fullfile(outputDir, ...
    [caseName, '_cpinn_training_loss.png']);
saveas(fig, plotFiles.lossHistory);
close(fig);

fig = figure('Visible', 'off');
imagesc(timePhysical, history.iteration, history.causalWeights);
axis xy;
colorbar;
xlabel('physical time [s]');
ylabel('gradient update');
title(['Module 3 causal activation weights: ', strrep(caseName, '_', '\_')]);
plotFiles.causalWeights = fullfile(outputDir, ...
    [caseName, '_cpinn_causal_weights.png']);
saveas(fig, plotFiles.causalWeights);
close(fig);

fig = figure('Visible', 'off');
yyaxis left;
semilogy(timePhysical, max(compute_relative_error_for_plot( ...
    reference, cpinn), eps), 'o-', 'LineWidth', 1.2);
ylabel('relative field L2 error');
yyaxis right;
plot(timePhysical, (compute_inventory_history(reference.M, cpinn.C) - ...
    reference.inventory) ./ max(abs(reference.inventory), eps), ...
    's-', 'LineWidth', 1.2);
ylabel('relative inventory error');
xlabel('physical time [s]');
grid on;
title(['Module 3 causal PINN validation: ', strrep(caseName, '_', '\_')]);
plotFiles.validation = fullfile(outputDir, ...
    [caseName, '_cpinn_validation_history.png']);
saveas(fig, plotFiles.validation);
close(fig);
end

function relativeError = compute_relative_error_for_plot(reference, cpinn)
numTimes = size(reference.C, 2);
relativeError = zeros(1, numTimes);
for j = 1:numTimes
    err = cpinn.C(:, j) - reference.C(:, j);
    relativeError(j) = sqrt(max(err.' * reference.M * err, 0.0) / ...
        max(reference.C(:, j).' * reference.M * reference.C(:, j), eps));
end
end

function fileName = save_trisurf_plot(elems, nodes, values, titleText, ...
        colorbarLabel, fileName)
fig = figure('Visible', 'off');
trisurf(elems, nodes(:, 1), nodes(:, 2), values, 'EdgeColor', 'none');
view(2);
axis equal tight;
cb = colorbar;
ylabel(cb, colorbarLabel);
xlabel('x [m]');
ylabel('y [m]');
title(titleText);
saveas(fig, fileName);
close(fig);
end

function summaryFile = write_module3_cpinn_summary(params, opts, scales, ...
        metrics, history, reference, outputDir, timePhysical)
summaryFile = fullfile(outputDir, ...
    [params.caseName, '_module3_cpinn_summary.txt']);
fid = fopen(summaryFile, 'w');
if fid < 0
    error('Could not open summary file: %s.', summaryFile);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Module 3 causal physics-informed neural-network summary\n');
fprintf(fid, '=======================================================\n');
fprintf(fid, 'Case: %s\n', params.caseName);
fprintf(fid, 'PDE: dC/dt = D*(d2C/dx2 + d2C/dy2) - kAnn*C + S\n');
fprintf(fid, 'Causal coordinate: physical evolution time\n');
fprintf(fid, 'Reference method: %s\n', reference.method);
fprintf(fid, 'Domain Lx = %.6e m, Ly = %.6e m\n', ...
    params.domain.Lx, params.domain.Ly);
fprintf(fid, 'Final time = %.6e s\n', params.time.tEnd);
fprintf(fid, 'D = %.6e m^2/s\n', params.physics.D);
fprintf(fid, 'kAnn = %.6e 1/s\n', params.physics.kAnn);
fprintf(fid, 'S = %.6e m^-3 s^-1\n', params.physics.source);

fprintf(fid, '\nNondimensionalization\n');
fprintf(fid, '---------------------\n');
fprintf(fid, 'x scale = %.6e m\n', scales.x);
fprintf(fid, 'y scale = %.6e m\n', scales.y);
fprintf(fid, 'time scale = %.6e s\n', scales.t);
fprintf(fid, 'concentration scale = %.6e m^-3\n', scales.C);
fprintf(fid, 'dimensionless diffusion x coefficient = %.6e\n', scales.diffusionX);
fprintf(fid, 'dimensionless diffusion y coefficient = %.6e\n', scales.diffusionY);
fprintf(fid, 'dimensionless reaction coefficient = %.6e\n', scales.reaction);
fprintf(fid, 'dimensionless source = %.6e\n', scales.source);

fprintf(fid, '\nNetwork and optimization\n');
fprintf(fid, '------------------------\n');
fprintf(fid, 'Inputs: x/Lx, y/Ly, t/tEnd\n');
fprintf(fid, 'Output: C/Cscale\n');
fprintf(fid, 'Hidden layers: %d\n', opts.numHiddenLayers);
fprintf(fid, 'Neurons per layer: %d\n', opts.numNeurons);
fprintf(fid, 'Activation: tanh\n');
fprintf(fid, 'Learning rate: %.6e\n', opts.learnRate);
fprintf(fid, 'Iterations per epsilon: %d\n', opts.maxIterationsPerEpsilon);
fprintf(fid, 'Total gradient updates: %d\n', numel(history.iteration));
fprintf(fid, 'Epsilon schedule: ');
fprintf(fid, '%.6g ', opts.epsilonSchedule);
fprintf(fid, '\n');
fprintf(fid, 'Causal weight floor: %.6e\n', opts.causalWeightFloor);
fprintf(fid, 'Causal diagnostic stop threshold: %.6e\n', opts.causalStopThreshold);
fprintf(fid, 'Loss weights IC %.6e, PDE %.6e, BC %.6e, data %.6e\n', ...
    opts.wInitial, opts.wPDE, opts.wBoundary, opts.wData);
fprintf(fid, 'Data anchors enabled: %d\n', opts.useDataAnchors);
fprintf(fid, 'Data-anchor count: %d\n', opts.numDataAnchors);
fprintf(fid, 'Collocation resampling enabled: %d\n', opts.resampleCollocation);

fprintf(fid, '\nOrdered causal slices\n');
fprintf(fid, '---------------------\n');
fprintf(fid, 'Physical times [s]: ');
fprintf(fid, '%.6g ', timePhysical);
fprintf(fid, '\n');
fprintf(fid, 'Final causal weights: ');
fprintf(fid, '%.6g ', history.causalWeights(end, :));
fprintf(fid, '\n');
fprintf(fid, 'Minimum final causal weight: %.6e\n', ...
    min(history.causalWeights(end, :)));
fprintf(fid, 'All-slices-active diagnostic: %d\n', ...
    min(history.causalWeights(end, :)) >= opts.causalStopThreshold);

fprintf(fid, '\nValidation metrics\n');
fprintf(fid, '------------------\n');
fprintf(fid, 'Final relative field L2 error = %.6e\n', ...
    metrics.finalRelativeFieldL2);
fprintf(fid, 'Final maximum absolute field error = %.6e m^-3\n', ...
    metrics.finalMaxAbsFieldError);
fprintf(fid, 'Final relative inventory error = %.6e\n', ...
    metrics.finalInventoryRelativeError);
fprintf(fid, 'RMS dimensionless PDE residual = %.6e\n', ...
    metrics.rmsResidualHat);
fprintf(fid, 'Maximum absolute dimensionless PDE residual = %.6e\n', ...
    metrics.maxAbsResidualHat);
fprintf(fid, 'Minimum predicted concentration = %.6e m^-3\n', ...
    metrics.minimumPredictedConcentration);
fprintf(fid, 'Maximum predicted concentration = %.6e m^-3\n', ...
    metrics.maximumPredictedConcentration);
end
