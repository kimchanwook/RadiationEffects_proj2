function test_module4a_hotspot_diffusion_2d()
out = main_module4a_2d_continuum_thermal('hotspot_diffusion');
disp(out.metrics);
disp('Module 4a hotspot diffusion test finished.');
end
