function params = case_module4_bd_localized_pulse_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 2.0e-6;
params.domain.ymin = 0.0;
params.domain.ymax = 2.0e-6;
params.domain.Nx   = 101;
params.domain.Ny   = 101;

params.physics.rho = 2330.0;
params.physics.cp  = 700.0;
params.physics.k   = 148.0;
params.physics.vBallistic = 6400.0;
params.physics.mfp = 150e-9;
params.physics.ballisticPrefactor = 0.25;

params.time.dt   = 2.0e-13;
params.time.tEnd = 2.5e-10;

params.init.type = 'gaussian';
params.init.Tbase = 300.0;
params.init.A     = 25.0;
params.init.x0    = 1.0e-6;
params.init.y0    = 1.0e-6;
params.init.sx    = 0.12e-6;
params.init.sy    = 0.12e-6;

params.source.type = 'zero';
params.boundary = default_bd_boundary_conditions_2d();

params.io.saveEvery    = 25;
params.io.writeMatFile = true;
params.io.outputDir    = fullfile('matlab', 'outputs', 'module4_2d_ballistic_diffusive');

params.verification.type = 'localized_pulse';
end
