function snapshot = save_history_2d(C, gridData, t)
snapshot.t = t;
snapshot.C = C;
snapshot.mass = sum(C, 'all') * gridData.dx * gridData.dy;
snapshot.Cmax = max(C, [], 'all');
snapshot.Cmin = min(C, [], 'all');
end
