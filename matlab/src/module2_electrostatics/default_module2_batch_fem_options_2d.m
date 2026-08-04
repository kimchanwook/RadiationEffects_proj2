function options = default_module2_batch_fem_options_2d()
% DEFAULT_MODULE2_BATCH_FEM_OPTIONS_2D Controls the pilot batch generator.
%
%   All quantities use SI units. The default design is deterministic and is
%   deliberately small enough for an acceptance run before scaling to
%   hundreds of charge configurations.

options.schema = 'module2_batch_fem_options_v1';
options.datasetName = 'module2_transmon_gaussian_batch_v1';
options.design = make_module2_batch_parameter_design_2d();

% Leave empty to construct the validated baseline Module 9 geometry once.
% A caller may inject a prebuilt geometry object to guarantee exact reuse
% across several data-generation jobs.
options.module9Geometry = [];

% Fixed electrode voltages for this first linear Poisson dataset. Voltage
% sweeps are intentionally deferred: their Laplace contribution can later be
% represented exactly by superposition rather than learned redundantly.
options.leftElectrodeVoltage = 0.0;   % [V]
options.rightElectrodeVoltage = 0.0;  % [V]

% Store rho because it is useful for dataset auditing and later PINN loss
% evaluation. The mesh is stored once, not repeated per case.
options.storeRho = true;
options.outputDir = fullfile('outputs', 'module2_batch_fem_2d');
options.datasetFileName = 'module2_transmon_gaussian_batch_v1.mat';
options.summaryFileName = 'module2_transmon_gaussian_batch_summary.txt';
options.saveDataset = true;

% Batch-safe default: no plots. Set this flag manually only when a few
% representative cases should be exported for inspection.
options.makeRepresentativePlots = false;
options.representativeCaseNames = { ...
    'zero_control', 'center_shallow_high', ...
    'left_pad_shallow', 'right_deep_broad'};

% Acceptance thresholds. These match the validated single-case FEM path.
options.validation.freeResidualRelative = 1.0e-9;
options.validation.globalBalanceRelative = 1.0e-9;
options.validation.dirichletErrorInf = 1.0e-12;
options.validation.requireCompleteSplits = true;
end
