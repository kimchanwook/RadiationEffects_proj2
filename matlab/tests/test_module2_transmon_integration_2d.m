function test_module2_transmon_integration_2d()
% TEST_MODULE2_TRANSMON_INTEGRATION_2D Run all Module 2-on-Module 9 tests.
setup_project_paths;
test_module2_transmon_tagged_bc_2d;
test_module2_transmon_trapped_charge_2d;
test_module2_transmon_mesh_reuse_2d;
test_module2_transmon_boundary_guards_2d;
fprintf('All Module 2-on-Module 9 FEM integration tests passed.\n');
end
