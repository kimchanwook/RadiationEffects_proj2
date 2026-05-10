function params = case_module4_fem_boundary_heating_2d()
% CASE_MODULE4_FEM_BOUNDARY_HEATING_2D
% Demonstration case for the reduced ballistic boundary-emission source in
% the FEM path. A Gaussian pulse emitted from the left boundary contributes
% to -div(q_b) in the thermal weak form.

params = default_module4_fem_params();
params.domain.Lx = 2.0e-6;
params.domain.Ly = 2.0e-6;
params.domain.nx = 51;
params.domain.ny = 51;

params.physics.tau = 2.0e-11;
params.physics.mfp = 150e-9;
params.physics.ballisticPrefactor = 0.25;

params.time.dt = 2.0e-13;
params.time.tEnd = 1.0e-10;

params.init.type = 'uniform';
params.init.T0 = 300.0;
params.init.dTdt0 = 0.0;
params.source.type = 'zero';

params.boundary = default_bd_boundary_conditions_2d();
params.boundary.left.type = 'gaussian_pulse';
params.boundary.left.deltaT = 10.0;
params.boundary.left.t0 = 2.0e-11;
params.boundary.left.sigmaT = 6.0e-12;
params.boundary.left.profile = 'gaussian';
params.boundary.left.profileCenter = 1.0e-6;
params.boundary.left.profileWidth = 0.35e-6;

params.verification.type = 'boundary_heating';
params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
params.io.saveEvery = 25;
end
