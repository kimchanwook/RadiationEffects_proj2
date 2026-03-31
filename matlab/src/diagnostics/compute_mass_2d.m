function mass = compute_mass_2d(C, gridData)
mass = sum(C, 'all') * gridData.dx * gridData.dy;
end
