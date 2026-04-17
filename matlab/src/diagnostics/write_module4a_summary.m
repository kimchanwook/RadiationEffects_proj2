function write_module4a_summary(params, metrics, tHistory, energyHistory, tmaxHistory, l2ErrorHistory, outPath)
fid = fopen(outPath, 'w');
fprintf(fid, 'Module 4a summary
');
fprintf(fid, '==================

');
fprintf(fid, 'Case: %s
', metrics.caseName);
fprintf(fid, 'Verification type: %s
', metrics.verificationType);
fprintf(fid, 'rho [kg/m^3]: %.6g
', params.physics.rho);
fprintf(fid, 'cp [J/(kg K)]: %.6g
', params.physics.cp);
fprintf(fid, 'k [W/(m K)]: %.6g
', params.physics.k);
fprintf(fid, 'alpha [m^2/s]: %.6g
', params.physics.alpha);
fprintf(fid, 'dt [s]: %.6g
', params.time.dt);
fprintf(fid, 'tEnd [s]: %.6g
', params.time.tEnd);
fprintf(fid, 'estimated explicit stability dt [s]: %.6g

', params.numerics.explicitStabilityDt);
fprintf(fid, 'Initial energy [J/m]: %.6e
', metrics.initialEnergy);
fprintf(fid, 'Final energy [J/m]: %.6e
', metrics.finalEnergy);
fprintf(fid, 'Delta energy [J/m]: %.6e
', metrics.deltaEnergy);
fprintf(fid, 'Initial Tmax [K]: %.6f
', metrics.TmaxInitial);
fprintf(fid, 'Final Tmax [K]: %.6f
', metrics.TmaxFinal);
if ~isnan(metrics.finalL2Error)
    fprintf(fid, 'Final L2 error: %.6e
', metrics.finalL2Error);
end
fprintf(fid, '
Final time [s]: %.6g
', tHistory(end));
fprintf(fid, 'Final Tmax from history [K]: %.6f
', tmaxHistory(end));
fprintf(fid, 'Final energy from history [J/m]: %.6e
', energyHistory(end));
if ~all(isnan(l2ErrorHistory))
    idx = find(~isnan(l2ErrorHistory), 1, 'last');
    fprintf(fid, 'Last recorded L2 error: %.6e
', l2ErrorHistory(idx));
end
fclose(fid);
end
