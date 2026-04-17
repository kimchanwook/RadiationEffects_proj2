function params = case_module4a_uniform_equilibrium_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 1.0;
params.domain.ymin = 0.0;
params.domain.ymax = 1.0;
params.domain.Nx   = 81;
params.domain.Ny   = 81;

params.physics.rho = 2330.0;
params.physics.cp  = 700.0;
params.physics.k   = 148.0;

params.time.dt   = 1e-4;
params.time.tEnd = 2e-2;

params.init.type = 'uniform';
params.init.T0   = 300.0;

params.source.type = 'zero';

params.io.saveEvery    = 20;
params.io.writeMatFile = true;
params.io.outputDir    = fullfile('matlab', 'outputs', 'module4a_2d');

params.verification.type = 'uniform_equilibrium';
end
