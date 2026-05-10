function test_module2_zero_charge_2d()
% TEST_MODULE2_ZERO_CHARGE_2D Verify constant zero potential for zero charge.
setup_project_paths;
params = default_module2_params('zero_charge');
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);
err = max(abs(result.phi));
assert(err < 1e-12, 'Zero-charge test failed: max |phi| = %.3e', err);
fprintf('test_module2_zero_charge_2d passed: max |phi| = %.3e\n', err);
end
