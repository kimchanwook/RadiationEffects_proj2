function dataset = generate_module2_batch_fem_dataset_2d(options)
% GENERATE_MODULE2_BATCH_FEM_DATASET_2D Build the default field-to-field set.
%
%   The numerical training contract is now
%
%       rho(:,case)  ->  phi(:,case),
%
%   where both arrays live on the same fixed Module 9 FEM mesh. The default
%   17-case pilot still uses Gaussian parameters only to SYNTHESIZE rho
%   fields. Those generator parameters are retained as provenance metadata
%   and are not the intended neural-network inputs.
%
%   This function performs no plotting and no file I/O.

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

% Resolve one accepted geometry so every synthetic input field is sampled on
% exactly the same FEM nodes as the resulting potential field.
[mesh, geometry, baseParams] = resolve_module2_mesh_2d(baseParams);
mu = design.generatorParameters;
if any(mu(:, 2) < geometry.domain.xRange(1)) || ...
        any(mu(:, 2) > geometry.domain.xRange(2)) || ...
        any(mu(:, 3) < geometry.domain.zRange(1)) || ...
        any(mu(:, 3) > geometry.domain.zRange(2))
    error('Module2BatchFEM:ChargeCenterOutsideDomain', ...
        'Every synthetic Gaussian center must lie inside the Module 9 domain.');
end

numNodes = size(mesh.nodes, 1);
numCases = size(mu, 1);
rhoMatrix = zeros(numNodes, numCases);
for k = 1:numCases
    caseParams = apply_generator_row(baseParams, mu(k, :));
    chargeField = generate_module2_gaussian_charge_field_2d(mesh, caseParams);
    rhoMatrix(:, k) = chargeField.rho;
end

% Reinject the already validated geometry so the generic field-batch solver
% reuses the exact same mesh object rather than constructing a new one.
baseParams.module9Geometry = geometry;
splits.trainCases = design.trainCases;
splits.validationCases = design.validationCases;
splits.testCases = design.testCases;
dataset = solve_module2_nodal_charge_batch_2d( ...
    baseParams, rhoMatrix, design.caseNames, splits);

dataset.name = options.datasetName;
dataset.optionsSchema = options.schema;
dataset.designSchema = design.schema;
dataset.syntheticGenerator.type = ...
    'single_elliptical_gaussian_defect_concentration';
dataset.syntheticGenerator.role = ...
    'training_field_generation_only_not_surrogate_input';
dataset.syntheticGenerator.parameterNames = design.generatorParameterNames;
dataset.syntheticGenerator.parameterUnits = design.generatorParameterUnits;
dataset.syntheticGenerator.parameters = design.generatorParameters;
dataset.boundaryConditions.leftTag = 'electrode.left_electrode';
dataset.boundaryConditions.rightTag = 'electrode.right_electrode';
dataset.boundaryConditions.leftVoltage = options.leftElectrodeVoltage;
dataset.boundaryConditions.rightVoltage = options.rightElectrodeVoltage;
dataset.boundaryConditions.otherBoundaries = 'homogeneous_natural_neumann';
dataset.boundaryConditions.jjTreatment = 'scoring_interface_only';
dataset.provenance.syntheticFieldGeneratorCount = numCases;
end

function params = apply_generator_row(params, mu)
% APPLY_GENERATOR_ROW Map Gaussian-generator metadata to legacy field names.
params.Cdef_peak = mu(1);
params.Cdef_x0 = mu(2);
params.Cdef_y0 = mu(3);       % second solver coordinate is z for Module 9
params.Cdef_sigma_x = mu(4);
params.Cdef_sigma_y = mu(5);  % sigma_z in generator metadata
end

function validate_options(options)
required = {'datasetName', 'design', 'module9Geometry', ...
    'leftElectrodeVoltage', 'rightElectrodeVoltage', 'storeRho'};
for k = 1:numel(required)
    if ~isfield(options, required{k})
        error('Module2BatchFEM:MissingOption', ...
            'Missing batch option: %s', required{k});
    end
end
if ~isequal(logical(options.storeRho), true)
    error('Module2BatchFEM:RhoRequiredForFieldContract', ...
        ['rho storage is mandatory because rho is the v2 field-to-field ', ...
         'surrogate input.']);
end

design = options.design;
requiredDesign = {'generatorParameterNames', 'generatorParameterUnits', ...
    'generatorParameters', 'caseNames', 'trainCases', ...
    'validationCases', 'testCases'};
for k = 1:numel(requiredDesign)
    if ~isfield(design, requiredDesign{k})
        error('Module2BatchFEM:InvalidDesign', ...
            'Gaussian field-generator design is missing field: %s', ...
            requiredDesign{k});
    end
end

mu = design.generatorParameters;
if size(mu, 2) ~= 5 || size(mu, 1) ~= numel(design.caseNames)
    error('Module2BatchFEM:InvalidDesignSize', ...
        'Generator parameters must be nCases-by-5 and match caseNames.');
end
if any(~isfinite(mu(:))) || any(mu(:, 1) < 0) || ...
        any(any(mu(:, 4:5) <= 0))
    error('Module2BatchFEM:InvalidDesignValues', ...
        'Generator values must be finite, C_peak >= 0, and widths > 0.');
end
expectedNames = {'C_peak', 'x_c', 'z_c', 'sigma_x', 'sigma_z'};
if ~isequal(design.generatorParameterNames, expectedNames)
    error('Module2BatchFEM:UnexpectedGeneratorParameterOrder', ...
        ['The v2 Gaussian pilot requires generator metadata order ', ...
         '[C_peak, x_c, z_c, sigma_x, sigma_z].']);
end
if numel(unique(design.caseNames)) ~= numel(design.caseNames)
    error('Module2BatchFEM:DuplicateCaseNames', ...
        'Every batch field case name must be unique.');
end
if ~isscalar(options.leftElectrodeVoltage) || ...
        ~isscalar(options.rightElectrodeVoltage) || ...
        ~isfinite(options.leftElectrodeVoltage) || ...
        ~isfinite(options.rightElectrodeVoltage)
    error('Module2BatchFEM:InvalidElectrodeVoltage', ...
        'Both fixed electrode voltages must be finite scalars.');
end
end
