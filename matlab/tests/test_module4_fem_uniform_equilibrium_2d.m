function test_module4_fem_uniform_equilibrium_2d()
% TEST_MODULE4_FEM_UNIFORM_EQUILIBRIUM_2D
% Uniform state should remain uniform with zero source and natural no-flux BCs.

setup_project_paths();
out = main_module4_fem_ballistic_diffusive_thermal('uniform_equilibrium');
err = sqrt(mean((out.Tfinal - out.Tinitial).^2));
assert(err < 1.0e-9, 'Module 4 FEM uniform-equilibrium error too large: %.3e', err);
fprintf('PASS: Module 4 FEM uniform equilibrium, L2 error = %.3e K\n', err);
end
