function write_module4_bd_summary(params, metrics, tHistory, energyHistory, tmaxHistory, ...
    rateNormHistory, qbmaxHistory, l2ErrorHistory, savePath)
% WRITE_MODULE4_BD_SUMMARY
% Write a plain-text summary for the ballistic-diffusive Module 4 runs.

fid = fopen(savePath, 'w');
if fid < 0
    error('Could not open summary file for writing: %s', savePath);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'RadiationEffects Project 2 - Module 4 Summary\n');
fprintf(fid, '=============================================\n\n');

fprintf(fid, 'Case: %s\n', metrics.caseName);
fprintf(fid, 'Verification type: %s\n', metrics.verificationType);
fprintf(fid, 'Output directory: %s\n\n', metrics.outputDir);

fprintf(fid, 'Domain\n');
fprintf(fid, '------\n');
fprintf(fid, 'x in [%g, %g], Nx = %d\n', params.domain.xmin, params.domain.xmax, params.domain.Nx);
fprintf(fid, 'y in [%g, %g], Ny = %d\n\n', params.domain.ymin, params.domain.ymax, params.domain.Ny);

fprintf(fid, 'Physics\n');
fprintf(fid, '-------\n');
fprintf(fid, 'rho = %.6e kg/m^3\n', params.physics.rho);
fprintf(fid, 'cp = %.6e J/(kg K)\n', params.physics.cp);
fprintf(fid, 'k = %.6e W/(m K)\n', params.physics.k);
fprintf(fid, 'Cvol = %.6e J/(m^3 K)\n', params.physics.Cvol);
fprintf(fid, 'alpha = %.6e m^2/s\n', params.physics.alpha);
fprintf(fid, 'vBallistic = %.6e m/s\n', params.physics.vBallistic);
fprintf(fid, 'mfp = %.6e m\n', params.physics.mfp);
fprintf(fid, 'tau = %.6e s\n', params.physics.tau);
fprintf(fid, 'ballisticPrefactor = %.6e\n\n', params.physics.ballisticPrefactor);

fprintf(fid, 'Time stepping\n');
fprintf(fid, '------------\n');
fprintf(fid, 'dt = %.6e s\n', params.time.dt);
fprintf(fid, 'tEnd = %.6e s\n', params.time.tEnd);
fprintf(fid, 'recommended dt <= %.6e s\n', params.numerics.recommendedDt);
fprintf(fid, 'diffusive explicit dt <= %.6e s\n', params.numerics.explicitDiffusiveDt);
fprintf(fid, 'relaxation dt <= %.6e s\n', params.numerics.relaxationDt);
fprintf(fid, 'ballistic flight-resolution dt <= %.6e s\n\n', params.numerics.ballisticFlightDt);

fprintf(fid, 'Metrics\n');
fprintf(fid, '-------\n');
fprintf(fid, 'Initial energy = %.6e J/m\n', metrics.initialEnergy);
fprintf(fid, 'Final energy = %.6e J/m\n', metrics.finalEnergy);
fprintf(fid, 'Delta energy = %.6e J/m\n', metrics.deltaEnergy);
fprintf(fid, 'Initial Tmax = %.6e K\n', metrics.TmaxInitial);
fprintf(fid, 'Final Tmax = %.6e K\n', metrics.TmaxFinal);
fprintf(fid, 'Final Tmin = %.6e K\n', metrics.TminFinal);
fprintf(fid, 'Peak RMS temperature-rate = %.6e K/s\n', metrics.maxTemperatureRateRMS);
fprintf(fid, 'Peak ballistic flux magnitude = %.6e W/m^2\n', metrics.maxBallisticFlux);
fprintf(fid, 'Final L2 error = %.6e\n\n', metrics.finalL2Error);

fprintf(fid, 'History samples\n');
fprintf(fid, '---------------\n');
fprintf(fid, 'Final time = %.6e s\n', tHistory(end));
fprintf(fid, 'Final energy history value = %.6e J/m\n', energyHistory(end));
fprintf(fid, 'Final Tmax history value = %.6e K\n', tmaxHistory(end));
fprintf(fid, 'Final RMS rate = %.6e K/s\n', rateNormHistory(end));
fprintf(fid, 'Final ballistic flux max = %.6e W/m^2\n', qbmaxHistory(end));
if ~all(isnan(l2ErrorHistory))
    fprintf(fid, 'Maximum L2 error over time = %.6e\n', max(l2ErrorHistory, [], 'omitnan'));
end
end
