function params = case_module4a_hotspot_diffusion_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 1.0;
params.domain.ymin = 0.0;
params.domain.ymax = 1.0;
params.domain.Nx   = 101;
params.domain.Ny   = 101;

params.physics.rho = 2330.0;
params.physics.cp  = 700.0;
params.physics.k   = 148.0;

params.time.dt   = 1e-5;
params.time.tEnd = 1e-2;

params.init.type = 'gaussian';
params.init.Tbase = 300.0;
params.init.A     = 30.0;
params.init.x0    = 0.5;
params.init.y0    = 0.5;
params.init.sx    = 0.08;
params.init.sy    = 0.08;

params.source.type = 'zero';

params.io.saveEvery    = 25;
params.io.writeMatFile = true;
params.io.outputDir    = fullfile('matlab', 'outputs', 'module4a_2d');

params.verification.type = 'hotspot_diffusion';
end
