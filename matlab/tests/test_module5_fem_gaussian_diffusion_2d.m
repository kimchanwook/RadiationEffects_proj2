function test_module5_fem_gaussian_diffusion_2d()
% TEST_MODULE5_FEM_GAUSSIAN_DIFFUSION_2D
% Pure diffusion with natural zero-flux boundaries should conserve inventory.

setup_project_paths();
out = main_module5_drift_diffusion('gaussian_diffusion');
relN = abs(out.nInventory(end) - out.nInventory(1)) / max(abs(out.nInventory(1)), eps);
relP = abs(out.pInventory(end) - out.pInventory(1)) / max(abs(out.pInventory(1)), eps);
assert(relN < 1.0e-8, 'Electron inventory changed too much: %.3e', relN);
assert(relP < 1.0e-8, 'Hole inventory changed too much: %.3e', relP);
assert(out.nMaxHistory(end) < out.nMaxHistory(1), 'Electron Gaussian did not smooth.');
assert(out.pMaxHistory(end) < out.pMaxHistory(1), 'Hole Gaussian did not smooth.');
fprintf('PASS: Module 5 FEM Gaussian diffusion inventory rel errors n=%.3e, p=%.3e\n', relN, relP);
end
