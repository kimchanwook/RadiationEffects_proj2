function test_module2_batch_reproducible_design_2d(dataset)
% TEST_MODULE2_BATCH_REPRODUCIBLE_DESIGN_2D Verify deterministic case design.
setup_project_paths;
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d();
end

designA = make_module2_batch_parameter_design_2d();
designB = make_module2_batch_parameter_design_2d();
assert(isequaln(designA, designB), ...
    'Repeated calls did not return an identical deterministic design.');
assert(isequal(dataset.parameters, designA.parameters), ...
    'Generated dataset parameters do not match the recorded pilot design.');
assert(isequal(dataset.caseNames, designA.caseNames), ...
    'Generated dataset case names do not match the recorded pilot design.');
assert(strcmp(dataset.caseNames{1}, 'zero_control') && ...
    dataset.parameters(1, 1) == 0, ...
    'The first deterministic configuration must remain the zero control.');

fprintf(['test_module2_batch_reproducible_design_2d passed: ', ...
    '%d deterministic configurations.\n'], dataset.nCases);
end
