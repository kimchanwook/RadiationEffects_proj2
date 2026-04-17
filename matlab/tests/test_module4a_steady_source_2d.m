function test_module4a_steady_source_2d()
out = main_module4a_2d_continuum_thermal('steady_source');
disp(out.metrics);
disp('Module 4a steady source test finished.');
end
