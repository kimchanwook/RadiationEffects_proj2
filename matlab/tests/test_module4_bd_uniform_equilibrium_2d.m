function test_module4_bd_uniform_equilibrium_2d()
out = main_module4_2d_ballistic_diffusive_thermal('uniform_equilibrium');
disp(out.metrics);
disp('Module 4 ballistic-diffusive uniform-equilibrium test finished.');
end
