function test_module2_batch_split_integrity_2d(dataset)
% TEST_MODULE2_BATCH_SPLIT_INTEGRITY_2D Prevent configuration-level leakage.
setup_project_paths;
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d();
end

train = dataset.trainCases(:);
validation = dataset.validationCases(:);
test = dataset.testCases(:);
allCases = [train; validation; test];
assert(isempty(intersect(train, validation)), ...
    'Training and validation configurations overlap.');
assert(isempty(intersect(train, test)), ...
    'Training and test configurations overlap.');
assert(isempty(intersect(validation, test)), ...
    'Validation and test configurations overlap.');
assert(isequal(sort(allCases), (1:dataset.nCases).'), ...
    'Complete-case splits do not cover the dataset exactly once.');

fprintf(['test_module2_batch_split_integrity_2d passed: ', ...
    '%d/%d/%d complete cases.\n'], ...
    numel(train), numel(validation), numel(test));
end
