function test_module6_fem_charge_consistency_2d()
% TEST_MODULE6_FEM_CHARGE_CONSISTENCY_2D Check Module 6 charge mapping consistency.
setup_project_paths;
params = default_module6_fem_params('defect_field_coupling');
params.time.numSteps = 2;
params.coupling.maxIterations = 3;
params.io.writeMatFile = false;
params.io.makePlots = false;
out = solve_coupled_multiphysics_fem_2d(params);
assert(out.metrics.finalChargeMismatch < 1e-12, 'Poisson charge source is inconsistent with coupled fields.');
fprintf('test_module6_fem_charge_consistency_2d passed.\n');
end
