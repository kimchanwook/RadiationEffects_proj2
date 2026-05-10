function params = case_module4_fem_uniform_source_2d()
% CASE_MODULE4_FEM_UNIFORM_SOURCE_2D
% Uniform volumetric heating with insulated boundaries. The spatial solution
% should remain uniform. For tau = 0, T(t)=T0+Q0*t/Cvol. For tau > 0 and
% zero initial temperature rate, T(t)=T0+(Q0/Cvol)*(t-tau*(1-exp(-t/tau))).

params = default_module4_fem_params();
params.domain.Lx = 1.0e-6;
params.domain.Ly = 1.0e-6;
params.domain.nx = 25;
params.domain.ny = 25;

params.physics.tau = 1.0e-11;
params.physics.mfp = params.physics.vBallistic * params.physics.tau;

params.time.dt = 1.0e-13;
params.time.tEnd = 5.0e-11;

params.init.type = 'uniform';
params.init.T0 = 300.0;
params.init.dTdt0 = 0.0;

params.source.type = 'uniform';
params.source.Q0 = 1.0e15; % W/m^3
params.boundary = default_bd_boundary_conditions_2d();

params.verification.type = 'uniform_source';
params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
params.io.saveEvery = 25;
end
