function test_module4_fem_gaussian_diffusion_2d()
% TEST_MODULE4_FEM_GAUSSIAN_DIFFUSION_2D
% A Gaussian perturbation should smooth under insulated pure diffusion while
% approximately conserving total thermal energy.

setup_project_paths();
out = main_module4_fem_ballistic_diffusive_thermal('gaussian_diffusion');
E0 = out.metrics.initialEnergy;
E1 = out.metrics.finalEnergy;
rel = abs(E1 - E0) / max(abs(E0), eps);
assert(rel < 1.0e-8, 'Module 4 FEM Gaussian diffusion energy drift too large: %.3e', rel);
assert(out.metrics.TmaxFinal < out.metrics.TmaxInitial, 'Gaussian peak did not decrease.');
fprintf('PASS: Module 4 FEM Gaussian diffusion, relative energy drift = %.3e\n', rel);
end
