function params = case_module5_fem_field_drift_2d()
% CASE_MODULE5_FEM_FIELD_DRIFT_2D Drift sign and current-density sanity case.
params = default_module5_fem_params();
params.domain.nx = 41;
params.domain.ny = 21;
params.time.dt = 2.0e-12;
params.time.numSteps = 20;
params.field.Ex = 2.0e4;
params.field.Ey = 0.0;
params.source.type = 'none';
params.recombination.type = 'none';
params.init.type = 'gaussian_excess';
params.init.n0 = 1.0e16;
params.init.p0 = 1.0e16;
params.init.excess_n = 2.0e16;
params.init.excess_p = 2.0e16;
params.init.sigma = 0.7e-6;
params.defects.type = 'gaussian';
params.defects.C0 = 1.0e21;
params.defects.alpha_n = 2.0e-22;
params.defects.alpha_p = 3.0e-22;
params.verification.type = 'field_drift_sign';
params.io.writeMatFile = true;
params.io.saveEvery = 5;
end
