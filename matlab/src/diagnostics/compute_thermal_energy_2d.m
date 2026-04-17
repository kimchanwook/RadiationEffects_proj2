function E = compute_thermal_energy_2d(T, gridData, physics)
E = physics.rho * physics.cp * sum(T, 'all') * gridData.dx * gridData.dy;
end
