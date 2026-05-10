function test_module5_fem_uniform_no_field_2d()
% TEST_MODULE5_FEM_UNIFORM_NO_FIELD_2D
% Uniform no-field, no-source, no-recombination carrier fields should remain uniform.

setup_project_paths();
out = main_module5_drift_diffusion('uniform_no_field');
err = out.metrics.finalL2Error;
assert(err < 1.0e6, 'Module 5 FEM uniform no-field preservation error too large: %.3e', err);
spreadN = max(out.nFinal) - min(out.nFinal);
spreadP = max(out.pFinal) - min(out.pFinal);
assert(spreadN < 1.0e6, 'Electron field became nonuniform: %.3e m^-3', spreadN);
assert(spreadP < 1.0e6, 'Hole field became nonuniform: %.3e m^-3', spreadP);
fprintf('PASS: Module 5 FEM uniform no-field preservation, L2 error = %.3e\n', err);
end
