function dataset = solve_module2_nodal_charge_batch_2d( ...
    baseParams, rhoMatrix, caseNames, splits)
% SOLVE_MODULE2_NODAL_CHARGE_BATCH_2D Generic field-to-field FEM generator.
%
%   dataset = SOLVE_MODULE2_NODAL_CHARGE_BATCH_2D(baseParams,rhoMatrix,...)
%   solves Poisson's equation for arbitrary nodal total charge-density fields
%   on one fixed geometry/mesh/boundary-condition configuration.
%
%   rhoMatrix must be nNodes-by-nCases [C/m^3]. Each column is one complete
%   input field. The output dataset stores the paired field mapping
%
%       rho(:,k)  ->  phi(:,k)
%
%   which is the canonical training contract for the Module 2 field-to-field
%   surrogate. The stiffness matrix and Cholesky factorization are reused for
%   every column.
%
%   splits is an optional structure with fields trainCases,
%   validationCases, and testCases. If omitted, every case is assigned to
%   trainCases.

if nargin < 3 || isempty(caseNames)
    caseNames = {};
end
if nargin < 4 || isempty(splits)
    splits = struct();
end

[mesh, geometry, baseParams] = resolve_module2_mesh_2d(baseParams);
numNodes = size(mesh.nodes, 1);

if ~isnumeric(rhoMatrix) || ~isreal(rhoMatrix) || ...
        size(rhoMatrix, 1) ~= numNodes || isempty(rhoMatrix)
    error('Module2FieldBatch:InvalidRhoMatrix', ...
        'rhoMatrix must be a nonempty nNodes-by-nCases real numeric array.');
end
if any(~isfinite(rhoMatrix(:)))
    error('Module2FieldBatch:NonfiniteRho', ...
        'Every value in rhoMatrix must be finite.');
end
numCases = size(rhoMatrix, 2);

if isempty(caseNames)
    caseNames = arrayfun(@(k) sprintf('field_case_%04d', k), ...
        (1:numCases).', 'UniformOutput', false);
elseif isstring(caseNames)
    caseNames = cellstr(caseNames(:));
elseif ischar(caseNames)
    caseNames = {caseNames};
end
caseNames = caseNames(:);
if ~iscell(caseNames) || ...
        any(~cellfun(@(name) ischar(name) && ~isempty(name), caseNames)) || ...
        numel(caseNames) ~= numCases || numel(unique(caseNames)) ~= numCases
    error('Module2FieldBatch:InvalidCaseNames', ...
        'caseNames must contain one unique nonempty name per charge field.');
end

[trainCases, validationCases, testCases] = ...
    normalize_splits(splits, numCases);

[fixedNodes, fixedValues, bcInfo] = ...
    get_module2_dirichlet_nodes(mesh, baseParams, geometry);
if isempty(fixedNodes)
    error('Module2FieldBatch:NoDirichletNodes', ...
        'The batch operator requires at least one Dirichlet node.');
end

zeroRho = zeros(numNodes, 1);
[K, ~, elementData] = assemble_poisson_fem_2d( ...
    mesh, zeroRho, baseParams.eps_si);
[Kbc, ~] = apply_dirichlet_bc( ...
    K, zeros(numNodes, 1), fixedNodes, fixedValues);

factorizationStart = tic;
[L, cholFlag] = chol(Kbc, 'lower');
factorizationSeconds = toc(factorizationStart);
if cholFlag ~= 0
    error('Module2FieldBatch:FactorizationFailure', ...
        'The Dirichlet-constrained FEM matrix is not positive definite.');
end

phi = zeros(numNodes, numCases);
diagnostics = repmat(empty_case_diagnostics(), numCases, 1);
solveSeconds = zeros(numCases, 1);
for k = 1:numCases
    rho = rhoMatrix(:, k);
    rhs = assemble_poisson_source_rhs_2d(mesh, rho, elementData.areas);
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
end

storedParams = baseParams;
if isfield(storedParams, 'module9Geometry')
    storedParams.module9Geometry = [];
end

dataset.schema = 'module2_field_to_field_fem_dataset_v2';
dataset.inputRepresentation = 'nodal_total_charge_density';
dataset.inputUnits = 'C/m^3';
dataset.outputRepresentation = 'nodal_electrostatic_potential';
dataset.outputUnits = 'V';
dataset.geometryMode = baseParams.geometryMode;
dataset.coordinateNames = baseParams.coordinateNames;
if isempty(geometry)
    dataset.domain = struct('Lx', baseParams.Lx, 'Ly', baseParams.Ly);
    dataset.tags = struct();
else
    dataset.domain = geometry.domain;
    dataset.tags = geometry.tags;
    dataset.materials.substrate = geometry.materials.substrate;
end
dataset.mesh = mesh;
dataset.caseNames = caseNames;
dataset.nCases = numCases;
dataset.rho = rhoMatrix;
dataset.phi = phi;
dataset.diagnostics = diagnostics;
dataset.trainCases = trainCases;
dataset.validationCases = validationCases;
dataset.testCases = testCases;
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

function [trainCases, validationCases, testCases] = normalize_splits(splits, nCases)
% NORMALIZE_SPLITS Validate complete-case dataset split indices.
if ~isfield(splits, 'trainCases')
    trainCases = 1:nCases;
else
    trainCases = splits.trainCases(:).';
end
if ~isfield(splits, 'validationCases')
    validationCases = [];
else
    validationCases = splits.validationCases(:).';
end
if ~isfield(splits, 'testCases')
    testCases = [];
else
    testCases = splits.testCases(:).';
end
allCases = [trainCases, validationCases, testCases];
if any(~isfinite(allCases)) || any(allCases ~= round(allCases)) || ...
        any(allCases < 1) || any(allCases > nCases) || ...
        numel(unique(allCases)) ~= numel(allCases)
    error('Module2FieldBatch:InvalidSplits', ...
        'Split indices must be unique integer case indices inside the batch.');
end
end

function item = empty_case_diagnostics()
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
