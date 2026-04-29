function boundary = default_bd_boundary_conditions_2d()
% DEFAULT_BD_BOUNDARY_CONDITIONS_2D
% Return a struct with all ballistic-emission boundaries disabled.

side = struct();
side.type = 'off';
side.deltaT = 0.0;
side.t0 = 0.0;
side.profile = 'uniform';
side.profileCenter = 0.0;
side.profileWidth = 1.0;
side.duration = 0.0;
side.riseTime = 0.0;
side.sigmaT = 1.0;

boundary.left = side;
boundary.right = side;
boundary.bottom = side;
boundary.top = side;
end
