function params = case_module3_pure_annealing_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 1.0;
params.domain.ymin = 0.0;
params.domain.ymax = 1.0;
params.domain.Nx   = 81;
params.domain.Ny   = 81;

params.physics.D = 0.0;
params.physics.kAnn = 5.0;

params.time.dt   = 1e-4;
params.time.tEnd = 2e-1;

params.init.type = 'uniform';
params.init.C0   = 1.0;

params.io.saveEvery     = 50;
params.io.writeMatFile  = true;
params.io.outputDir     = fullfile('matlab', 'outputs', 'module3_2d', 'pure_annealing');

params.verification.type = 'pure_annealing';
end
