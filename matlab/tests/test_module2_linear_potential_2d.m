function test_module2_linear_potential_2d()
% TEST_MODULE2_LINEAR_POTENTIAL_2D Verify exact linear Laplace solution.
setup_project_paths;
params = default_module2_params('linear_potential');
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);
x = result.mesh.nodes(:,1);
phiExact = x ./ params.Lx;
err = max(abs(result.phi - phiExact));
assert(err < 1e-10, 'Linear-potential test failed: max error = %.3e', err);
fprintf('test_module2_linear_potential_2d passed: max error = %.3e\n', err);
end
