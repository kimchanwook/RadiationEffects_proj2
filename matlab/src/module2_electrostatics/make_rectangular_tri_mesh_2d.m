function mesh = make_rectangular_tri_mesh_2d(Lx, Ly, nx, ny)
% MAKE_RECTANGULAR_TRI_MESH_2D Build a structured rectangular triangular mesh.
%
%   mesh = MAKE_RECTANGULAR_TRI_MESH_2D(Lx,Ly,nx,ny) creates nodes on a
%   rectangular domain [0,Lx] x [0,Ly] and splits each quadrilateral cell
%   into two counter-clockwise three-node triangles.

if nx < 2 || ny < 2
    error('nx and ny must each be at least 2.');
end

x = linspace(0, Lx, nx);
y = linspace(0, Ly, ny);
[X, Y] = meshgrid(x, y);
nodes = [X(:), Y(:)];

elems = zeros(2*(nx-1)*(ny-1), 3);
e = 0;
for j = 1:(ny-1)
    for i = 1:(nx-1)
        n1 = sub2ind([ny, nx], j,   i);
        n2 = sub2ind([ny, nx], j,   i+1);
        n3 = sub2ind([ny, nx], j+1, i+1);
        n4 = sub2ind([ny, nx], j+1, i);
        e = e + 1;
        elems(e,:) = [n1, n2, n3];
        e = e + 1;
        elems(e,:) = [n1, n3, n4];
    end
end

% Boundary node sets.
tol = 100 * eps(max([Lx, Ly, 1]));
left   = find(abs(nodes(:,1) - 0)  <= tol);
right  = find(abs(nodes(:,1) - Lx) <= tol);
bottom = find(abs(nodes(:,2) - 0)  <= tol);
top    = find(abs(nodes(:,2) - Ly) <= tol);

mesh.nodes = nodes;
mesh.elems = elems;
mesh.x = x;
mesh.y = y;
mesh.nx = nx;
mesh.ny = ny;
mesh.Lx = Lx;
mesh.Ly = Ly;
mesh.boundary.left = left;
mesh.boundary.right = right;
mesh.boundary.bottom = bottom;
mesh.boundary.top = top;
end
