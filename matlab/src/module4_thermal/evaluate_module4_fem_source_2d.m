function source = evaluate_module4_fem_source_2d(mesh, params, t)
% EVALUATE_MODULE4_FEM_SOURCE_2D Evaluate nodal source terms for Module 4 FEM.
%
% Returns source.Snode [W/m^3], where
%   Snode = Q + tau*dQdt - div(q_b).
% For the first FEM path, q_b is evaluated using the same reduced
% rectangular-domain closure used by the structured-grid Module 4 solver.

nodes = mesh.nodes;
x = nodes(:,1);
y = nodes(:,2);

[Q, dQdt] = evaluate_volumetric_source(mesh, params.source, t);

ballistic = evaluate_nodal_ballistic(mesh, params.physics, params.boundary, t);
Snode = Q + params.physics.tau .* dQdt - ballistic.divqb;

source.Q = Q;
source.dQdt = dQdt;
source.ballistic = ballistic;
source.Snode = Snode;
source.x = x;
source.y = y;
end

function [Q, dQdt] = evaluate_volumetric_source(mesh, sourceSpec, t)
x = mesh.nodes(:,1);
y = mesh.nodes(:,2);

switch lower(sourceSpec.type)
    case 'zero'
        Q = zeros(size(x));
        dQdt = zeros(size(x));

    case 'uniform'
        Q = sourceSpec.Q0 * ones(size(x));
        dQdt = zeros(size(x));

    case 'gaussian'
        spatial = exp(-((x - sourceSpec.x0).^2 ./ (2 * sourceSpec.sx^2) ...
                      + (y - sourceSpec.y0).^2 ./ (2 * sourceSpec.sy^2)));
        Q = sourceSpec.A .* spatial;
        dQdt = zeros(size(x));

    case 'gaussian_pulse'
        spatial = exp(-((x - sourceSpec.x0).^2 ./ (2 * sourceSpec.sx^2) ...
                      + (y - sourceSpec.y0).^2 ./ (2 * sourceSpec.sy^2)));
        tau = (t - sourceSpec.t0) ./ sourceSpec.sigmaT;
        amp = sourceSpec.A0 .* exp(-0.5 .* tau.^2);
        dampdt = amp .* (-(t - sourceSpec.t0) ./ (sourceSpec.sigmaT.^2));
        Q = amp .* spatial;
        dQdt = dampdt .* spatial;

    otherwise
        error('Unknown Module 4 FEM source.type: %s', sourceSpec.type);
end
end

function ballistic = evaluate_nodal_ballistic(mesh, physics, boundary, t)
% The mesh is structured even though it is represented with triangles. This
% lets us reuse a simple finite-difference divergence for the reduced q_b.
Nx = mesh.nx;
Ny = mesh.ny;
X = reshape(mesh.nodes(:,1), Ny, Nx);
Y = reshape(mesh.nodes(:,2), Ny, Nx);

gridData = struct();
gridData.X = X;
gridData.Y = Y;
gridData.x = mesh.x;
gridData.y = mesh.y;
gridData.Nx = Nx;
gridData.Ny = Ny;
gridData.dx = mesh.Lx / (Nx - 1);
gridData.dy = mesh.Ly / (Ny - 1);

b = compute_ballistic_flux_reduced_2d(gridData, t, physics, boundary);
divqbGrid = compute_flux_divergence_2d(b.qbx, b.qby, gridData.dx, gridData.dy);

ballistic.qbx = b.qbx(:);
ballistic.qby = b.qby(:);
ballistic.qmag = b.qmag(:);
ballistic.divqb = divqbGrid(:);
end
