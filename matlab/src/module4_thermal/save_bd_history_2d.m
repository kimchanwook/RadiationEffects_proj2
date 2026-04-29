function snapshot = save_bd_history_2d(T, dTdt, ballistic, gridData, t, physics)
snapshot.t = t;
snapshot.T = T;
snapshot.dTdt = dTdt;
snapshot.thermalEnergy = compute_thermal_energy_2d(T, gridData, physics);
snapshot.Tmax = max(T, [], 'all');
snapshot.Tmin = min(T, [], 'all');
snapshot.rateRMS = sqrt(mean(dTdt(:).^2));
snapshot.qbMax = max(ballistic.qmag, [], 'all');
end
