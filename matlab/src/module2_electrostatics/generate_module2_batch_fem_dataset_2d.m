function dataset = generate_module2_batch_fem_dataset_2d(options)
% GENERATE_MODULE2_BATCH_FEM_DATASET_2D Solve many sources with one operator.
%
%   This function performs no plotting and no file I/O. It is therefore safe
%   for tests, parameter sweeps, and later scripted dataset expansion.

if nargin < 1 || isempty(options)
    options = default_module2_batch_fem_options_2d();
end
validate_options(options);

design = options.design;
baseParams = default_module2_params('transmon_trapped_charge');
baseParams.makePlots = false;
baseParams.saveMat = false;
baseParams.module9Geometry = options.module9Geometry;
baseParams.bc.named.left_electrode.value = options.leftElectrodeVoltage;
baseParams.bc.named.right_electrode.value = options.rightElectrodeVoltage;

% Geometry, mesh, boundary nodes, and the electrostatic stiffness matrix are
% resolved exactly once for the entire batch.
[mesh, geometry, baseParams] = resolve_module2_mesh_2d(baseParams);
if any(design.parameters(:, 2) < geometry.domain.xRange(1)) || ...
        any(design.parameters(:, 2) > geometry.domain.xRange(2)) || ...
        any(design.parameters(:, 3) < geometry.domain.zRange(1)) || ...
        any(design.parameters(:, 3) > geometry.domain.zRange(2))
    error('Module2BatchFEM:ChargeCenterOutsideDomain', ...
        'Every Gaussian center must lie inside the supplied Module 9 domain.');
end
[fixedNodes, fixedValues, bcInfo] = ...
    get_module2_dirichlet_nodes(mesh, baseParams, geometry);
if isempty(fixedNodes)
    error('Module2BatchFEM:NoDirichletNodes', ...
        'The batch operator requires at least one tagged Dirichlet node.');
end

zeroRho = zeros(size(mesh.nodes, 1), 1);
[K, ~, elementData] = assemble_poisson_fem_2d( ...
    mesh, zeroRho, baseParams.eps_si);
[Kbc, ~] = apply_dirichlet_bc( ...
    K, zeros(size(mesh.nodes, 1), 1), fixedNodes, fixedValues);

% Kbc is symmetric positive definite after strong Dirichlet enforcement.
% Cholesky exposes an explicit, countable one-time factorization and avoids
% refactorization inside MATLAB's backslash operator for every case.
factorizationStart = tic;
[L, cholFlag] = chol(Kbc, 'lower');
factorizationSeconds = toc(factorizationStart);
if cholFlag ~= 0
    error('Module2BatchFEM:FactorizationFailure', ...
        'The tagged-boundary FEM matrix is not positive definite (flag %d).', ...
        cholFlag);
end

numNodes = size(mesh.nodes, 1);
numCases = size(design.parameters, 1);
phi = zeros(numNodes, numCases);
if options.storeRho
    rhoAll = zeros(numNodes, numCases);
else
    rhoAll = [];
end
diagnostics = repmat(empty_case_diagnostics(), numCases, 1);
solveSeconds = zeros(numCases, 1);

for k = 1:numCases
    caseParams = apply_parameter_row(baseParams, design.parameters(k, :));
    rho = build_space_charge_module2_2d(mesh.nodes, caseParams);
    rhs = assemble_poisson_source_rhs_2d( ...
        mesh, rho, elementData.areas);

    % Apply the same fixed values to a new right-hand side without modifying
    % or rebuilding Kbc. This is algebraically identical to apply_dirichlet_bc.
    rhsbc = rhs - K(:, fixedNodes) * fixedValues;
    rhsbc(fixedNodes) = fixedValues;

    solveStart = tic;
    y = L \ rhsbc;
    phi(:, k) = L' \ y;
    solveSeconds(k) = toc(solveStart);

    fullDiagnostics = compute_module2_fem_diagnostics_2d( ...
        K, rhs, phi(:, k), fixedNodes, fixedValues);
    diagnostics(k) = compact_diagnostics( ...
        fullDiagnostics, phi(:, k), rho);
    if options.storeRho
        rhoAll(:, k) = rho;
    end
end

storedParams = baseParams;
storedParams.module9Geometry = [];

dataset.schema = 'module2_batch_fem_dataset_v1';
dataset.name = options.datasetName;
dataset.optionsSchema = options.schema;
dataset.designSchema = design.schema;
dataset.geometryMode = baseParams.geometryMode;
dataset.coordinateNames = baseParams.coordinateNames;
dataset.domain = geometry.domain;
dataset.materials.substrate = geometry.materials.substrate;
dataset.mesh = mesh;
dataset.tags = geometry.tags;
dataset.parameterization = 'single_elliptical_gaussian';
dataset.parameterNames = design.parameterNames;
dataset.parameterUnits = design.parameterUnits;
dataset.parameters = design.parameters;
dataset.caseNames = design.caseNames;
dataset.nCases = numCases;
dataset.rho = rhoAll;
dataset.phi = phi;
dataset.diagnostics = diagnostics;
dataset.trainCases = design.trainCases(:).';
dataset.validationCases = design.validationCases(:).';
dataset.testCases = design.testCases(:).';
dataset.boundaryConditions.leftTag = 'electrode.left_electrode';
dataset.boundaryConditions.rightTag = 'electrode.right_electrode';
dataset.boundaryConditions.leftVoltage = options.leftElectrodeVoltage;
dataset.boundaryConditions.rightVoltage = options.rightElectrodeVoltage;
dataset.boundaryConditions.otherBoundaries = 'homogeneous_natural_neumann';
dataset.boundaryConditions.jjTreatment = 'scoring_interface_only';
dataset.fixedNodes = fixedNodes;
dataset.fixedValues = fixedValues;
dataset.bcInfo = bcInfo;
dataset.baseParams = storedParams;
dataset.provenance.stiffnessAssemblyCount = 1;
dataset.provenance.sourceAssemblyCount = numCases;
dataset.provenance.factorizationCount = 1;
dataset.provenance.linearSolveCount = numCases;
dataset.provenance.factorizationMethod = 'sparse_cholesky';
dataset.provenance.factorizationSeconds = factorizationSeconds;
dataset.provenance.solveSeconds = solveSeconds;
dataset.provenance.stiffnessNnz = nnz(K);
dataset.provenance.meshReusedForEveryCase = true;
dataset.provenance.numericalGeneratorCreatesPlots = false;
end

function params = apply_parameter_row(params, mu)
% APPLY_PARAMETER_ROW Map the public five-parameter contract to FEM names.
params.Cdef_peak = mu(1);
params.Cdef_x0 = mu(2);
params.Cdef_y0 = mu(3);       % second solver coordinate is z for Module 9
params.Cdef_sigma_x = mu(4);
params.Cdef_sigma_y = mu(5);  % sigma_z in the public dataset contract
end

function item = empty_case_diagnostics()
% EMPTY_CASE_DIAGNOSTICS Fixed scalar schema for compact per-case auditing.
item.freeResidualInf = 0.0;
item.freeResidualRelative = 0.0;
item.dirichletErrorInf = 0.0;
item.constraintReactionSum = 0.0;
item.assembledSourceSum = 0.0;
item.globalBalance = 0.0;
item.globalBalanceRelative = 0.0;
item.minPhi = 0.0;
item.maxPhi = 0.0;
item.maxAbsPhi = 0.0;
item.minRho = 0.0;
item.maxRho = 0.0;
end

function item = compact_diagnostics(fullItem, phi, rho)
% COMPACT_DIAGNOSTICS Omit full residual vectors from the saved dataset.
item = empty_case_diagnostics();
item.freeResidualInf = fullItem.freeResidualInf;
item.freeResidualRelative = fullItem.freeResidualRelative;
item.dirichletErrorInf = fullItem.dirichletErrorInf;
item.constraintReactionSum = fullItem.constraintReactionSum;
item.assembledSourceSum = fullItem.assembledSourceSum;
item.globalBalance = fullItem.globalBalance;
item.globalBalanceRelative = fullItem.globalBalanceRelative;
item.minPhi = min(phi);
item.maxPhi = max(phi);
item.maxAbsPhi = max(abs(phi));
item.minRho = min(rho);
item.maxRho = max(rho);
end

function validate_options(options)
% VALIDATE_OPTIONS Reject malformed parameter designs before expensive work.
required = {'datasetName', 'design', 'module9Geometry', ...
    'leftElectrodeVoltage', 'rightElectrodeVoltage', 'storeRho'};
for k = 1:numel(required)
    if ~isfield(options, required{k})
        error('Module2BatchFEM:MissingOption', ...
            'Missing batch option: %s', required{k});
    end
end

design = options.design;
requiredDesign = {'parameterNames', 'parameterUnits', 'parameters', ...
    'caseNames', 'trainCases', 'validationCases', 'testCases'};
for k = 1:numel(requiredDesign)
    if ~isfield(design, requiredDesign{k})
        error('Module2BatchFEM:InvalidDesign', ...
            'Parameter design is missing field: %s', requiredDesign{k});
    end
end

if size(design.parameters, 2) ~= 5 || ...
        size(design.parameters, 1) ~= numel(design.caseNames)
    error('Module2BatchFEM:InvalidDesignSize', ...
        'Design parameters must be nCases-by-5 and match caseNames.');
end
if any(~isfinite(design.parameters(:))) || ...
        any(design.parameters(:, 1) < 0) || ...
        any(any(design.parameters(:, 4:5) <= 0))
    error('Module2BatchFEM:InvalidDesignValues', ...
        'Design values must be finite, C_peak >= 0, and widths > 0.');
end
if numel(unique(design.caseNames)) ~= numel(design.caseNames)
    error('Module2BatchFEM:DuplicateCaseNames', ...
        'Every batch case name must be unique.');
end
expectedNames = {'C_peak', 'x_c', 'z_c', 'sigma_x', 'sigma_z'};
if ~isequal(design.parameterNames, expectedNames)
    error('Module2BatchFEM:UnexpectedParameterOrder', ...
        ['The v1 dataset contract requires parameter order ', ...
         '[C_peak, x_c, z_c, sigma_x, sigma_z].']);
end
if ~isscalar(options.storeRho) || ...
        ~(islogical(options.storeRho) || isnumeric(options.storeRho)) || ...
        ~ismember(double(options.storeRho), [0, 1])
    error('Module2BatchFEM:InvalidStoreRho', ...
        'options.storeRho must be a scalar logical flag.');
end
if ~isscalar(options.leftElectrodeVoltage) || ...
        ~isscalar(options.rightElectrodeVoltage) || ...
        ~isfinite(options.leftElectrodeVoltage) || ...
        ~isfinite(options.rightElectrodeVoltage)
    error('Module2BatchFEM:InvalidElectrodeVoltage', ...
        'Both fixed electrode voltages must be finite scalars.');
end
end
