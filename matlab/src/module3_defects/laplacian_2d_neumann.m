function L = laplacian_2d_neumann(C, dx, dy)
% 2D Laplacian with zero-normal-gradient (Neumann) boundaries
% implemented by mirrored ghost-cell logic.

[Ny, Nx] = size(C);

Cp = zeros(Ny+2, Nx+2);
Cp(2:end-1, 2:end-1) = C;

% Left/right mirror
Cp(2:end-1, 1)   = C(:,2);
Cp(2:end-1, end) = C(:,end-1);

% Bottom/top mirror
Cp(1, 2:end-1)   = C(2,:);
Cp(end, 2:end-1) = C(end-1,:);

% Corners
Cp(1,1)       = C(2,2);
Cp(1,end)     = C(2,end-1);
Cp(end,1)     = C(end-1,2);
Cp(end,end)   = C(end-1,end-1);

L = (Cp(2:end-1,3:end) - 2*Cp(2:end-1,2:end-1) + Cp(2:end-1,1:end-2)) / dx^2 ...
  + (Cp(3:end,2:end-1) - 2*Cp(2:end-1,2:end-1) + Cp(1:end-2,2:end-1)) / dy^2;
end
