function snapshot = save_thermal_history_2d(T, gridData, t, physics)
snapshot.t = t;
snapshot.T = T;
snapshot.thermalEnergy = compute_thermal_energy_2d(T, gridData, physics);
snapshot.Tmax = max(T, [], 'all');
snapshot.Tmin = min(T, [], 'all');
end
