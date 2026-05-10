function test_module2_localized_defect_charge_2d()
% TEST_MODULE2_LOCALIZED_DEFECT_CHARGE_2D Sanity check for localized defect charge.
setup_project_paths;
params = default_module2_params('localized_defect_charge');
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);
assert(all(isfinite(result.phi)), 'Localized defect test failed: non-finite potential.');
assert(max(result.rho) > 0, 'Localized defect test failed: charge source is not positive.');
assert(max(result.phi) > 0, 'Localized defect test failed: expected positive potential perturbation.');
fprintf('test_module2_localized_defect_charge_2d passed: max phi = %.3e V\n', max(result.phi));
end
