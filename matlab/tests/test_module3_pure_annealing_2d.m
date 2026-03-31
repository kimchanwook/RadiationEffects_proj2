function test_module3_pure_annealing_2d()
setup_project_paths();
out = main_module3_2d_defect_evolution('pure_annealing');

assert(abs(out.metrics.finalMassErrorRel) < 5e-4, ...
    'Pure annealing mass should match the analytical exponential decay closely.');
assert(out.metrics.finalL2Error < 5e-4, ...
    'Pure annealing field should match the analytical uniform decay solution closely.');

disp('Pure annealing 2D test passed.');
end
