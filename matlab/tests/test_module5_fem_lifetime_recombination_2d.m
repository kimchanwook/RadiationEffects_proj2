function test_module5_fem_lifetime_recombination_2d()
% TEST_MODULE5_FEM_LIFETIME_RECOMBINATION_2D
% Uniform lifetime recombination should match the backward-Euler recurrence.

setup_project_paths();
out = main_module5_drift_diffusion('lifetime_recombination');
err = out.metrics.finalL2Error;
assert(err < 1.0e6, 'Module 5 FEM lifetime recombination error too large: %.3e', err);
fprintf('PASS: Module 5 FEM lifetime recombination, final BE L2 error = %.3e\n', err);
end
