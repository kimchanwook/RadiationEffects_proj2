function test_module4_bd_localized_pulse_2d()
out = main_module4_2d_ballistic_diffusive_thermal('localized_pulse');
disp(out.metrics);
disp('Module 4 ballistic-diffusive localized-pulse test finished.');
end
