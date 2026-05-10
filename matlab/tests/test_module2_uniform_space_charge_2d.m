function test_module2_uniform_space_charge_2d()
% TEST_MODULE2_UNIFORM_SPACE_CHARGE_2D Compare against 1D quadratic limit.
setup_project_paths;
params = default_module2_params('uniform_space_charge');
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);
x = result.mesh.nodes(:,1);
rho0 = params.rho_uniform;
phiExact = (rho0/(2*params.eps_si)) .* x .* (params.Lx - x);
errAbs = max(abs(result.phi - phiExact));
scale = max(abs(phiExact)) + eps;
errRel = errAbs / scale;
assert(errRel < 5e-3, 'Uniform-charge test failed: rel error = %.3e', errRel);
fprintf('test_module2_uniform_space_charge_2d passed: rel error = %.3e\n', errRel);
end
