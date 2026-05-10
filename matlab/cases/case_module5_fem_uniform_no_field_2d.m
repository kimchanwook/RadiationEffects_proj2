function params = case_module5_fem_uniform_no_field_2d()
% CASE_MODULE5_FEM_UNIFORM_NO_FIELD_2D Uniform carrier field preservation.
params = default_module5_fem_params();
params.domain.nx = 25;
params.domain.ny = 13;
params.time.dt = 1.0e-10;
params.time.numSteps = 20;
params.field.Ex = 0.0;
params.field.Ey = 0.0;
params.source.type = 'none';
params.recombination.type = 'none';
params.init.type = 'uniform';
params.init.n0 = 2.0e16;
params.init.p0 = 1.5e16;
params.verification.type = 'uniform_no_field';
params.io.writeMatFile = true;
params.io.saveEvery = 5;
end
