function test_module2_batch_dataset_contract_2d(dataset, options)
% TEST_MODULE2_BATCH_DATASET_CONTRACT_2D Verify shapes, tags, and diagnostics.
setup_project_paths;
if nargin < 2 || isempty(options)
    options = default_module2_batch_fem_options_2d();
end
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d(options);
end

report = validate_module2_batch_fem_dataset_2d( ...
    dataset, options.validation, true);
assert(report.passed, 'Batch dataset validation report did not pass.');
assert(strcmp(dataset.coordinateNames{2}, 'z'), ...
    'The Module 9 dataset second coordinate must be named z.');
assert(strcmp(dataset.parameterNames{3}, 'z_c'), ...
    'The public conditional parameter contract must use z_c.');
assert(strcmp(dataset.boundaryConditions.jjTreatment, ...
    'scoring_interface_only'), ...
    'JJ-sensitive region was not preserved as a scoring interface.');

fprintf(['test_module2_batch_dataset_contract_2d passed: ', ...
    '%d/%d checks.\n'], report.nPassed, report.nChecks);
end
