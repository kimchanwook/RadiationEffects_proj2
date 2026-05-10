function params = default_module4_fem_params()
% DEFAULT_MODULE4_FEM_PARAMS Baseline parameters for Module 4 FEM runs.

params.domain.Lx = 2.0e-6;
params.domain.Ly = 2.0e-6;
params.domain.nx = 41;
params.domain.ny = 41;

params.physics.rho = 2330.0;       % kg/m^3, silicon density
params.physics.cp = 700.0;         % J/(kg K), approximate heat capacity
params.physics.k = 148.0;          % W/(m K), silicon thermal conductivity
params.physics.vBallistic = 6400.0; % m/s, representative phonon speed
params.physics.mfp = 150e-9;       % m, representative mean free path
params.physics.ballisticPrefactor = 0.25;

params.time.dt = 2.0e-13;
params.time.tEnd = 2.0e-10;

params.init.type = 'uniform';
params.init.T0 = 300.0;
params.init.dTdt0 = 0.0;

params.source.type = 'zero';
params.boundary = default_bd_boundary_conditions_2d();

params.dirichlet.enabled = false;
params.dirichlet.sides = {};
params.dirichlet.value = 300.0;

params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
params.io.saveEvery = 10;
params.io.writeMatFile = true;

params.verification.type = 'none';
end
