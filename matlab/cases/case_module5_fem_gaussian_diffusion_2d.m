function params = case_module5_fem_gaussian_diffusion_2d()
% CASE_MODULE5_FEM_GAUSSIAN_DIFFUSION_2D Diffusion of a local excess carrier packet.
params = default_module5_fem_params();
params.domain.nx = 51;
params.domain.ny = 31;
params.time.dt = 2.0e-11;
params.time.numSteps = 80;
params.field.Ex = 0.0;
params.field.Ey = 0.0;
params.source.type = 'none';
params.recombination.type = 'none';
params.init.type = 'gaussian_excess';
params.init.n0 = 1.0e16;
params.init.p0 = 1.0e16;
params.init.excess_n = 5.0e16;
params.init.excess_p = 5.0e16;
params.init.sigma = 0.8e-6;
params.verification.type = 'gaussian_diffusion_inventory';
params.io.writeMatFile = true;
params.io.saveEvery = 10;
end
