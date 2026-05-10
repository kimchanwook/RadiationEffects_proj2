function test_module3_fem_gaussian_diffusion_2d()
% TEST_MODULE3_FEM_GAUSSIAN_DIFFUSION_2D Check inventory conservation and smoothing.

setup_project_paths();
params = default_module3_fem_params('gaussian_diffusion');
params.io.makePlots = false;
params.io.writeMatFile = false;
out = solve_defect_diffusion_reaction_fem_2d(params);

if abs(out.metrics.relativeInventoryChange) > 1e-6
    error('Gaussian FEM diffusion inventory changed too much: %.3e', out.metrics.relativeInventoryChange);
end
if out.metrics.cmaxFinal >= out.metrics.cmaxInitial
    error('Gaussian FEM diffusion did not reduce peak concentration.');
end
fprintf('test_module3_fem_gaussian_diffusion_2d passed. Relative inventory change = %.3e\n', out.metrics.relativeInventoryChange);
end
