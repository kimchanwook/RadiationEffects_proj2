function divq = compute_flux_divergence_2d(qx, qy, dx, dy)
% COMPUTE_FLUX_DIVERGENCE_2D
% Compute divergence of a cell-centered flux field with one-sided edges.

[Ny, Nx] = size(qx);
divq = zeros(Ny, Nx);

% x-derivative
if Nx > 2
    divq(:, 2:Nx-1) = divq(:, 2:Nx-1) + (qx(:, 3:Nx) - qx(:, 1:Nx-2)) ./ (2 * dx);
end
divq(:, 1) = divq(:, 1) + (qx(:, min(2, Nx)) - qx(:, 1)) ./ dx;
divq(:, Nx) = divq(:, Nx) + (qx(:, Nx) - qx(:, max(Nx-1, 1))) ./ dx;

% y-derivative
if Ny > 2
    divq(2:Ny-1, :) = divq(2:Ny-1, :) + (qy(3:Ny, :) - qy(1:Ny-2, :)) ./ (2 * dy);
end
divq(1, :) = divq(1, :) + (qy(min(2, Ny), :) - qy(1, :)) ./ dy;
divq(Ny, :) = divq(Ny, :) + (qy(Ny, :) - qy(max(Ny-1, 1), :)) ./ dy;
end
