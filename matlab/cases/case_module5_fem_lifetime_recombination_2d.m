function params = case_module5_fem_lifetime_recombination_2d()
% CASE_MODULE5_FEM_LIFETIME_RECOMBINATION_2D Uniform lifetime recombination.
params = default_module5_fem_params();
params.domain.nx = 25;
params.domain.ny = 13;
params.time.dt = 2.0e-10;
params.time.numSteps = 60;
params.field.Ex = 0.0;
params.field.Ey = 0.0;
params.source.type = 'none';
params.recombination.type = 'linear_lifetime';
params.recombination.tau_n = 5.0e-9;
params.recombination.tau_p = 8.0e-9;
params.recombination.n_eq = 1.0e16;
params.recombination.p_eq = 1.0e16;
params.init.type = 'uniform';
params.init.n0 = 5.0e16;
params.init.p0 = 4.0e16;
params.verification.type = 'lifetime_recombination';
params.io.writeMatFile = true;
params.io.saveEvery = 10;
end
