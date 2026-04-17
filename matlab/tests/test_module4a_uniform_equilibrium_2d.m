function test_module4a_uniform_equilibrium_2d()
out = main_module4a_2d_continuum_thermal('uniform_equilibrium');
disp(out.metrics);
disp('Module 4a uniform equilibrium test finished.');
end
