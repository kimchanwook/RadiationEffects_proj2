function gridData = make_grid_2d(domain)

gridData.x = linspace(domain.xmin, domain.xmax, domain.Nx);
gridData.y = linspace(domain.ymin, domain.ymax, domain.Ny);

gridData.dx = gridData.x(2) - gridData.x(1);
gridData.dy = gridData.y(2) - gridData.y(1);

[X, Y] = meshgrid(gridData.x, gridData.y);

gridData.X = X;
gridData.Y = Y;

gridData.Nx = domain.Nx;
gridData.Ny = domain.Ny;
end
