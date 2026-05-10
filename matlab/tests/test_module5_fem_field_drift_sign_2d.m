function test_module5_fem_field_drift_sign_2d()
% TEST_MODULE5_FEM_FIELD_DRIFT_SIGN_2D
% With positive Ex and positive carriers, conventional electron and hole drift
% current contributions should have positive x direction.

setup_project_paths();
out = main_module5_drift_diffusion('field_drift');
meanJnX = mean(out.current.Jn(:,1));
meanJpX = mean(out.current.Jp(:,1));
assert(meanJnX > 0, 'Mean electron conventional current is not along +E.');
assert(meanJpX > 0, 'Mean hole conventional current is not along +E.');
fprintf('PASS: Module 5 FEM field drift current signs, mean Jnx=%.3e, mean Jpx=%.3e\n', meanJnX, meanJpX);
end
