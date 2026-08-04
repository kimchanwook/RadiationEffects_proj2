function test_module2_fem_all_2d()
% TEST_MODULE2_FEM_ALL_2D Run legacy and transmon Module 2 FEM regressions.
setup_project_paths;
test_module2_zero_charge_2d;
test_module2_linear_potential_2d;
test_module2_uniform_space_charge_2d;
test_module2_localized_defect_charge_2d;
test_module2_transmon_integration_2d;
test_module2_batch_fem_dataset_2d;
fprintf(['All legacy, Module 9-aware, and batch-dataset Module 2 FEM ', ...
    'tests passed.\n']);
end
