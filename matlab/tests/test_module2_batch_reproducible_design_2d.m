function test_module2_batch_reproducible_design_2d(dataset)
% TEST_MODULE2_BATCH_REPRODUCIBLE_DESIGN_2D Verify generator reproducibility.
setup_project_paths;
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d();
end

designA = make_module2_gaussian_field_pilot_design_2d();
designB = make_module2_gaussian_field_pilot_design_2d();
assert(isequal(designA.generatorParameters, designB.generatorParameters), ...
    'Gaussian field-generator design is not deterministic.');
assert(isequal(dataset.syntheticGenerator.parameters, ...
    designA.generatorParameters), ...
    'Saved generator provenance does not match the deterministic design.');
assert(all(dataset.rho(:, 1) == 0), ...
    'The first field must remain an exact zero-charge control.');

fprintf('test_module2_batch_reproducible_design_2d passed.\n');
end
