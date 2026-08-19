function options = default_module2_batch_fem_options_2d()
% DEFAULT_MODULE2_BATCH_FEM_OPTIONS_2D Controls the field-to-field pilot.
%
%   The default pilot still uses deterministic Gaussian charge clouds to
%   synthesize diverse nodal rho fields, but the saved dataset contract is
%   now rho(x,z) -> phi(x,z). Gaussian parameters are provenance only.

options.schema = 'module2_batch_fem_options_v2';
options.datasetName = 'module2_transmon_field_to_field_gaussian_pilot_v2';
options.design = make_module2_gaussian_field_pilot_design_2d();

% Leave empty to construct the validated baseline Module 9 geometry once.
options.module9Geometry = [];

% Fixed electrode voltages for this first linear Poisson field dataset.
options.leftElectrodeVoltage = 0.0;   % [V]
options.rightElectrodeVoltage = 0.0;  % [V]

% rho is mandatory in the v2 field-to-field dataset because it is the neural
% surrogate input, not optional audit metadata.
options.storeRho = true;
options.outputDir = fullfile('outputs', 'module2_batch_fem_2d');
options.datasetFileName = ...
    'module2_transmon_field_to_field_gaussian_pilot_v2.mat';
options.summaryFileName = ...
    'module2_transmon_field_to_field_gaussian_pilot_v2_summary.txt';
options.saveDataset = true;

% Batch-safe default: no plots.
options.makeRepresentativePlots = false;
options.representativeCaseNames = { ...
    'zero_control', 'center_shallow_high', ...
    'left_pad_shallow', 'right_deep_broad'};

% Acceptance thresholds.
options.validation.freeResidualRelative = 1.0e-9;
options.validation.globalBalanceRelative = 1.0e-9;
options.validation.dirichletErrorInf = 1.0e-12;
options.validation.requireCompleteSplits = true;
end
