function divDgradC = laplacian_2d_neumann_variable_D(C, D, dx, dy)
% LAPLACIAN_2D_NEUMANN_VARIABLE_D
% Compute div(D grad C) on a structured 2D grid with zero-normal-flux
% boundaries using face-centered fluxes.

[Ny, Nx] = size(C);
if isscalar(D)
    D = D .* ones(Ny, Nx);
end

% x-face fluxes j_x = -D dC/dx
fluxX = zeros(Ny, Nx+1);
DfaceX = 0.5 .* (D(:,1:end-1) + D(:,2:end));
fluxX(:,2:Nx) = -DfaceX .* (C(:,2:end) - C(:,1:end-1)) ./ dx;

% y-face fluxes j_y = -D dC/dy
fluxY = zeros(Ny+1, Nx);
DfaceY = 0.5 .* (D(1:end-1,:) + D(2:end,:));
fluxY(2:Ny,:) = -DfaceY .* (C(2:end,:) - C(1:end-1,:)) ./ dy;

% PDE diffusion term = -div(j)
divDgradC = -(fluxX(:,2:end) - fluxX(:,1:end-1)) ./ dx ...
            -(fluxY(2:end,:) - fluxY(1:end-1,:)) ./ dy;
end
