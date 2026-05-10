function write_module4_fem_summary(params, metrics, outPath)
% WRITE_MODULE4_FEM_SUMMARY Write scalar diagnostics for Module 4 FEM run.

fid = fopen(outPath, 'w');
if fid < 0
    error('Could not open summary file: %s', outPath);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Module 4 FEM ballistic-diffusive thermal summary\n');
fprintf(fid, '================================================\n\n');
fprintf(fid, 'caseName: %s\n', metrics.caseName);
fprintf(fid, 'verificationType: %s\n', metrics.verificationType);
fprintf(fid, 'domain: Lx = %.6e m, Ly = %.6e m, nx = %d, ny = %d\n', ...
    params.domain.Lx, params.domain.Ly, params.domain.nx, params.domain.ny);
fprintf(fid, 'dt = %.6e s, tEnd = %.6e s\n', params.time.dt, params.time.tEnd);
fprintf(fid, 'rho = %.6e kg/m^3\n', params.physics.rho);
fprintf(fid, 'cp = %.6e J/(kg K)\n', params.physics.cp);
fprintf(fid, 'Cvol = %.6e J/(m^3 K)\n', params.physics.Cvol);
fprintf(fid, 'k = %.6e W/(m K)\n', params.physics.k);
fprintf(fid, 'alpha = %.6e m^2/s\n', params.physics.alpha);
fprintf(fid, 'tau = %.6e s\n', params.physics.tau);
fprintf(fid, 'mfp = %.6e m\n', params.physics.mfp);
fprintf(fid, 'initialEnergy = %.12e\n', metrics.initialEnergy);
fprintf(fid, 'finalEnergy = %.12e\n', metrics.finalEnergy);
fprintf(fid, 'deltaEnergy = %.12e\n', metrics.deltaEnergy);
fprintf(fid, 'TmaxInitial = %.12e K\n', metrics.TmaxInitial);
fprintf(fid, 'TmaxFinal = %.12e K\n', metrics.TmaxFinal);
fprintf(fid, 'TminFinal = %.12e K\n', metrics.TminFinal);
fprintf(fid, 'maxTemperatureRateRMS = %.12e K/s\n', metrics.maxTemperatureRateRMS);
fprintf(fid, 'maxBallisticFlux = %.12e W/m^2\n', metrics.maxBallisticFlux);
fprintf(fid, 'finalL2Error = %.12e\n', metrics.finalL2Error);
end
