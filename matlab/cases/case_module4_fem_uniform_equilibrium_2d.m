function params = case_module4_fem_uniform_equilibrium_2d()
% CASE_MODULE4_FEM_UNIFORM_EQUILIBRIUM_2D
% Uniform initial temperature, no source, no ballistic emission. With natural
% zero-flux boundaries, the solution should remain exactly uniform up to
% solver tolerance.

params = default_module4_fem_params();
params.domain.Lx = 2.0e-6;
params.domain.Ly = 2.0e-6;
params.domain.nx = 31;
params.domain.ny = 31;

params.physics.tau = 2.0e-11;
params.physics.mfp = params.physics.vBallistic * params.physics.tau;

params.time.dt = 2.0e-13;
params.time.tEnd = 5.0e-11;

params.init.type = 'uniform';
params.init.T0 = 300.0;
params.init.dTdt0 = 0.0;
params.source.type = 'zero';
params.boundary = default_bd_boundary_conditions_2d();

params.verification.type = 'uniform_equilibrium';
params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
params.io.saveEvery = 25;
end
