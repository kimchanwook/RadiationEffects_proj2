function test_module2_fem_all_2d()
% TEST_MODULE2_FEM_ALL_2D Run Module 2 FEM and field-contract regressions.
setup_project_paths;
test_module2_zero_charge_2d;
test_module2_linear_potential_2d;
test_module2_uniform_space_charge_2d;
test_module2_localized_defect_charge_2d;
test_module2_explicit_charge_field_2d;
test_module2_charge_component_fields_2d;
test_module2_transmon_integration_2d;
test_module2_batch_fem_dataset_2d;
fprintf(['All legacy, explicit-field, Module 9-aware, and field-dataset ', ...
    'Module 2 FEM tests passed.\n']);
end
