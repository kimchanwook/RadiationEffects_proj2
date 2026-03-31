function params = case_module3_gaussian_diffusion_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 1.0;
params.domain.ymin = 0.0;
params.domain.ymax = 1.0;
params.domain.Nx   = 101;
params.domain.Ny   = 101;

params.physics.D = 1e-3;
params.physics.kAnn = 0.0;

params.time.dt   = 1e-4;
params.time.tEnd = 2e-2;

params.init.type = 'gaussian';
params.init.A    = 1.0;
params.init.x0   = 0.5;
params.init.y0   = 0.5;
params.init.sx   = 0.08;
params.init.sy   = 0.08;

params.io.saveEvery     = 20;
params.io.writeMatFile  = true;
params.io.outputDir     = fullfile('matlab', 'outputs', 'module3_2d', 'gaussian_diffusion');

params.verification.type = 'gaussian_diffusion';
end
