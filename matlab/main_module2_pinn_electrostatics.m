function out = main_module2_pinn_electrostatics(caseName, opts)
% MAIN_MODULE2_PINN_ELECTROSTATICS Run the modular Module 2 electrostatic PINN.
%
%   out = MAIN_MODULE2_PINN_ELECTROSTATICS(caseName, opts) trains a smooth
%   multilayer perceptron for one fixed Module 2 Poisson problem.  The loss
%   combines:
%
%       1. interior Poisson-equation residual,
%       2. soft Dirichlet boundary mismatch,
%       3. soft Neumann boundary mismatch,
%       4. optional sparse FEM anchor mismatch.
%
%   The implementation is divided among the six files in matlab/pinn:
%       module2_pinn_network.m
%       module2_pinn_loss.m
%       module2_pinn_train.m
%       module2_pinn_predict.m
%       module2_pinn_make_dataset.m
%       module2_pinn_verify.m
%
%   Example:
%       setup_project_paths
%       out = main_module2_pinn_electrostatics('localized_defect_charge');
%
%   Fast smoke example:
%       opts.maxIterations = 25;
%       opts.numInterior = 128;
%       opts.numBoundaryPerSide = 16;
%       opts.makePlots = false;
%       out = main_module2_pinn_electrostatics('linear_potential', opts);
%
%   Requirement: MATLAB Deep Learning Toolbox.

% Select the Gaussian charged-defect case when the caller omits a case name.
if nargin < 1 || isempty(caseName)
    caseName = 'localized_defect_charge';
end

% Begin with an empty options structure when no overrides were supplied.
if nargin < 2 || isempty(opts)
    opts = struct();
end

% Identify the project MATLAB directory from the location of this driver.
projectMatlabDirectory = fileparts(mfilename('fullpath'));

% Add the established FEM source routines used by data generation and rho(x,y).
addpath(genpath(fullfile(projectMatlabDirectory, 'src')));

% Add verification case definitions maintained by the existing FEM project.
addpath(fullfile(projectMatlabDirectory, 'cases'));

% Add the new modular PINN functions requested in Section 16.2 of the notes.
addpath(fullfile(projectMatlabDirectory, 'pinn'));

% Fail early with a clear explanation if automatic differentiation is unavailable.
local_require_deep_learning_toolbox();

% Fill every unspecified training and output option with a documented default.
opts = local_default_options(opts);

% Make FEM-anchor selection and stochastic collocation reproducible.
rng(opts.randomSeed, 'twister');

% Resolve the output directory relative to this MATLAB project unless absolute.
if local_is_absolute_path(opts.outputDir)
    outputDirectory = opts.outputDir;
else
    outputDirectory = fullfile(projectMatlabDirectory, opts.outputDir);
end

% Create the output directory before verification or result saving uses it.
if ~exist(outputDirectory, 'dir')
    mkdir(outputDirectory);
end

% Print the run configuration before the potentially long optimization starts.
fprintf('Module 2 PINN case "%s" starting.\n', char(caseName));
fprintf('  Output directory: %s\n', outputDirectory);
fprintf('  Training iterations: %d\n', opts.maxIterations);

% Generate the FEM reference, scaling constants, and optional sparse anchors.
dataset = module2_pinn_make_dataset(caseName, opts);

% Construct an untrained two-input smooth multilayer perceptron.
net = module2_pinn_network(opts);

% Optimize the network using the physics, boundary, and optional data losses.
[net, history, trainingInfo] = module2_pinn_train(net, dataset, opts);

% Evaluate potential, electric field, and PDE residual on the FEM mesh nodes.
pinn = module2_pinn_predict(...
    net, dataset.fem.mesh, dataset.params, dataset.scales);

% Compare PINN predictions with FEM and available analytical solutions.
verification = module2_pinn_verify(...
    dataset.fem, pinn, history, dataset.params, opts, dataset.scales, ...
    outputDirectory);

% Package physical parameters and run options for reproducibility.
out.params = dataset.params;
out.options = opts;
out.scales = dataset.scales;

% Package the trained network and the exact FEM anchors used in training.
out.net = net;
out.anchors = dataset.anchors;

% Package reference and surrogate spatial fields.
out.fem = dataset.fem;
out.pinn = pinn;

% Package training curves, timing information, and verification products.
out.trainingHistory = history;
out.trainingInfo = trainingInfo;
out.metrics = verification.metrics;
out.analytic = verification.analytic;
out.plotFiles = verification.plotFiles;
out.summaryFile = verification.summaryFile;
out.outputDir = outputDirectory;

% Construct one deterministic MAT filename for the complete trained result.
resultFile = fullfile(outputDirectory, ...
    [dataset.params.caseName, '_module2_pinn_results.mat']);

% Save the trained network and diagnostics only when requested by the caller.
if opts.saveResults
    save(resultFile, 'out', '-v7.3');
    out.resultFile = resultFile;
else
    out.resultFile = '';
end

% Print the principal accuracy and physics diagnostics at handoff.
fprintf('Module 2 PINN case "%s" complete.\n', dataset.params.caseName);
fprintf('  relative phi L2 error : %.4e\n', ...
    out.metrics.relativePhiL2);
fprintf('  relative E L2 error   : %.4e\n', ...
    out.metrics.relativeElectricFieldL2);
fprintf('  RMS normalized PDE residual : %.4e\n', ...
    out.metrics.rmsNormalizedResidual);
fprintf('  training time         : %.3f s\n', ...
    out.trainingInfo.elapsedSeconds);
fprintf('  output directory      : %s\n', outputDirectory);
end

function local_require_deep_learning_toolbox()
% LOCAL_REQUIRE_DEEP_LEARNING_TOOLBOX Check all custom-training dependencies.

% List the functions/classes essential to this PINN implementation.
requiredNames = {'dlarray', 'dlnetwork', 'dlgradient', ...
    'dlfeval', 'adamupdate'};

% Test each dependency independently so a partial installation fails clearly.
for nameIndex = 1:numel(requiredNames)
    % Extract the current dependency name from the cell array.
    requiredName = requiredNames{nameIndex};

    % A dependency may be exposed as either a file or a MATLAB class.
    dependencyExists = exist(requiredName, 'file') == 2 || ...
        exist(requiredName, 'class') == 8;

    % Stop before dataset generation if any required operation is missing.
    if ~dependencyExists
        error('main_module2_pinn_electrostatics:MissingToolbox', ...
            ['Module 2 PINN requires MATLAB Deep Learning Toolbox. ', ...
             'Missing required function or class: %s'], requiredName);
    end
end
end

function opts = local_default_options(opts)
% LOCAL_DEFAULT_OPTIONS Add defaults while preserving all caller overrides.

% Reproducibility and network-architecture controls.
opts = local_set_default(opts, 'randomSeed', 7);
opts = local_set_default(opts, 'numHiddenLayers', 4);
opts = local_set_default(opts, 'numNeurons', 48);

% Adam optimization controls.
opts = local_set_default(opts, 'maxIterations', 1200);
opts = local_set_default(opts, 'learnRate', 2.0e-3);
opts = local_set_default(opts, 'gradientDecayFactor', 0.9);
opts = local_set_default(opts, 'squaredGradientDecayFactor', 0.999);

% Stochastic collocation and optional FEM-supervision controls.
opts = local_set_default(opts, 'numInterior', 1024);
opts = local_set_default(opts, 'numBoundaryPerSide', 96);
opts = local_set_default(opts, 'numDataAnchors', 160);
opts = local_set_default(opts, 'useDataAnchors', true);

% Dimensionless loss weights; Dirichlet voltage receives extra emphasis.
opts = local_set_default(opts, 'wPDE', 1.0);
opts = local_set_default(opts, 'wDirichlet', 20.0);
opts = local_set_default(opts, 'wNeumann', 2.0);
opts = local_set_default(opts, 'wData', 2.0);

% Console and file-output controls.
opts = local_set_default(opts, 'verbose', true);
opts = local_set_default(opts, 'printEvery', 100);
opts = local_set_default(opts, 'makePlots', true);
opts = local_set_default(opts, 'writeSummary', true);
opts = local_set_default(opts, 'saveResults', true);
opts = local_set_default(opts, 'outputDir', ...
    fullfile('outputs', 'module2_pinn_2d'));

% Validate integer sample and iteration counts before any arrays are allocated.
validateattributes(opts.maxIterations, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.maxIterations');
validateattributes(opts.numInterior, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.numInterior');
validateattributes(opts.numBoundaryPerSide, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.numBoundaryPerSide');
validateattributes(opts.numDataAnchors, {'numeric'}, ...
    {'scalar', 'integer', 'nonnegative', 'finite'}, mfilename, ...
    'opts.numDataAnchors');
validateattributes(opts.printEvery, {'numeric'}, ...
    {'scalar', 'integer', 'positive', 'finite'}, mfilename, ...
    'opts.printEvery');

% Validate positive optimizer parameters.
validateattributes(opts.learnRate, {'numeric'}, ...
    {'scalar', 'positive', 'finite'}, mfilename, 'opts.learnRate');
validateattributes(opts.gradientDecayFactor, {'numeric'}, ...
    {'scalar', '>=', 0, '<', 1, 'finite'}, mfilename, ...
    'opts.gradientDecayFactor');
validateattributes(opts.squaredGradientDecayFactor, {'numeric'}, ...
    {'scalar', '>=', 0, '<', 1, 'finite'}, mfilename, ...
    'opts.squaredGradientDecayFactor');

% Validate all loss weights as finite nonnegative scalars.
weightNames = {'wPDE', 'wDirichlet', 'wNeumann', 'wData'};
for weightIndex = 1:numel(weightNames)
    weightName = weightNames{weightIndex};
    validateattributes(opts.(weightName), {'numeric'}, ...
        {'scalar', 'nonnegative', 'finite'}, mfilename, ...
        ['opts.', weightName]);
end
end

function structure = local_set_default(structure, fieldName, defaultValue)
% LOCAL_SET_DEFAULT Set one structure field only when it is absent or empty.

% Preserve every explicit nonempty caller choice.
if ~isfield(structure, fieldName) || isempty(structure.(fieldName))
    structure.(fieldName) = defaultValue;
end
end

function tf = local_is_absolute_path(pathValue)
% LOCAL_IS_ABSOLUTE_PATH Recognize Unix and Windows absolute path syntax.

% Normalize MATLAB string input to a character vector for indexing.
pathValue = char(pathValue);

% An empty path is not absolute.
if isempty(pathValue)
    tf = false;
    return;
end

% Unix paths begin with a forward slash.
isUnixAbsolute = pathValue(1) == '/';

% Windows drive-letter paths have the form C:\... or C:/....
isWindowsDriveAbsolute = numel(pathValue) >= 3 && ...
    isletter(pathValue(1)) && pathValue(2) == ':' && ...
    any(pathValue(3) == ['\', '/']);

% Windows network paths begin with two backslashes.
isWindowsNetworkAbsolute = numel(pathValue) >= 2 && ...
    pathValue(1) == '\' && pathValue(2) == '\';

% Return true when any supported absolute-path syntax matched.
tf = isUnixAbsolute || isWindowsDriveAbsolute || isWindowsNetworkAbsolute;
end
