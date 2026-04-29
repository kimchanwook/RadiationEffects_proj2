function test_module4_bd_boundary_heating_2d()
out = main_module4_2d_ballistic_diffusive_thermal('boundary_heating');
disp(out.metrics);
disp('Module 4 ballistic-diffusive boundary-heating test finished.');
end
