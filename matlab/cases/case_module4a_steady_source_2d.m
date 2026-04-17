function params = case_module4a_steady_source_2d()
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
params.time.tEnd = 2e-2;

params.init.type = 'uniform';
params.init.T0   = 300.0;

params.source.type = 'gaussian';
params.source.A    = 8e7;
params.source.x0   = 0.5;
params.source.y0   = 0.5;
params.source.sx   = 0.10;
params.source.sy   = 0.10;

params.io.saveEvery    = 25;
params.io.writeMatFile = true;
params.io.outputDir    = fullfile('matlab', 'outputs', 'module4a_2d');

params.verification.type = 'steady_source';
end
