function test_module3_gaussian_diffusion_2d()
setup_project_paths();
out = main_module3_2d_defect_evolution('gaussian_diffusion');

assert(out.metrics.finalMass > 0.0, 'Final mass should remain positive.');
assert(abs(out.metrics.relativeMassChange) < 5e-3, ...
    'Pure diffusion should conserve mass to within a small numerical tolerance.');
assert(out.metrics.cmaxFinal < out.metrics.cmaxInitial, ...
    'Gaussian diffusion should reduce the peak concentration.');

disp('Gaussian diffusion 2D test passed.');
end
