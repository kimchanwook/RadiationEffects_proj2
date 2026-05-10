function test_module4_fem_uniform_source_2d()
% TEST_MODULE4_FEM_UNIFORM_SOURCE_2D
% Uniform heating should remain spatially uniform and match the analytic
% uniform ballistic-diffusive temporal response.

setup_project_paths();
out = main_module4_fem_ballistic_diffusive_thermal('uniform_source');
err = out.metrics.finalL2Error;
assert(err < 1.0e-7, 'Module 4 FEM uniform-source analytic error too large: %.3e', err);
spatialSpread = max(out.Tfinal) - min(out.Tfinal);
assert(spatialSpread < 1.0e-8, 'Uniform source produced spatial nonuniformity: %.3e K', spatialSpread);
fprintf('PASS: Module 4 FEM uniform source, final analytic L2 error = %.3e K\n', err);
end
