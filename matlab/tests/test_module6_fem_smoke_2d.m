function test_module6_fem_smoke_2d()
% TEST_MODULE6_FEM_SMOKE_2D Basic coupled Module 6 smoke test.
setup_project_paths;
params = default_module6_fem_params('smoke');
params.io.writeMatFile = false;
params.io.makePlots = false;
out = solve_coupled_multiphysics_fem_2d(params);
assert(all(isfinite(out.stateFinal.C)), 'Defect field contains nonfinite values.');
assert(all(isfinite(out.stateFinal.phi)), 'Potential field contains nonfinite values.');
assert(all(isfinite(out.stateFinal.T)), 'Temperature field contains nonfinite values.');
assert(all(isfinite(out.stateFinal.n)), 'Electron field contains nonfinite values.');
assert(all(isfinite(out.stateFinal.p)), 'Hole field contains nonfinite values.');
assert(out.metrics.maxElectricField > 0, 'Expected nonzero electric field from contact bias.');
fprintf('test_module6_fem_smoke_2d passed.\n');
end
