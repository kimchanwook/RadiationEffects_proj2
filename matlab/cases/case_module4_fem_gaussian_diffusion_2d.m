function params = case_module4_fem_gaussian_diffusion_2d()
% CASE_MODULE4_FEM_GAUSSIAN_DIFFUSION_2D
% Insulated-domain Gaussian temperature perturbation. This checks that the
% FEM solver smooths a localized thermal field and approximately conserves
% total thermal energy when source and boundary emission are absent.

params = default_module4_fem_params();
params.domain.Lx = 2.0e-6;
params.domain.Ly = 2.0e-6;
params.domain.nx = 51;
params.domain.ny = 51;

params.physics.tau = 0.0;  % pure backward-Euler Fourier limit for this test
params.physics.mfp = 0.0;

params.time.dt = 5.0e-13;
params.time.tEnd = 1.0e-10;

params.init.type = 'gaussian';
params.init.Tbase = 300.0;
params.init.A = 20.0;
params.init.x0 = 1.0e-6;
params.init.y0 = 1.0e-6;
params.init.sx = 0.15e-6;
params.init.sy = 0.15e-6;
params.init.dTdt0 = 0.0;

params.source.type = 'zero';
params.boundary = default_bd_boundary_conditions_2d();
params.verification.type = 'energy_conservation';
params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
params.io.saveEvery = 20;
end
