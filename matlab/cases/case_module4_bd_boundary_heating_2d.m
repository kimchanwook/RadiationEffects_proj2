function params = case_module4_bd_boundary_heating_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 2.0e-6;
params.domain.ymin = 0.0;
params.domain.ymax = 1.5e-6;
params.domain.Nx   = 121;
params.domain.Ny   = 91;

params.physics.rho = 2330.0;
params.physics.cp  = 700.0;
params.physics.k   = 148.0;
params.physics.vBallistic = 6400.0;
params.physics.mfp = 150e-9;
params.physics.ballisticPrefactor = 0.25;

params.time.dt   = 2.0e-13;
params.time.tEnd = 6.0e-10;

params.init.type = 'uniform';
params.init.T0   = 300.0;

params.source.type = 'zero';
params.boundary = default_bd_boundary_conditions_2d();
params.boundary.left.type = 'step';
params.boundary.left.deltaT = 12.0;
params.boundary.left.t0 = 0.0;
params.boundary.left.profile = 'uniform';

params.io.saveEvery    = 30;
params.io.writeMatFile = true;
params.io.outputDir    = fullfile('matlab', 'outputs', 'module4_2d_ballistic_diffusive');

params.verification.type = 'boundary_heating';
end
