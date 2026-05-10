function T = initialize_module4_fem_temperature_2d(mesh, init)
% INITIALIZE_MODULE4_FEM_TEMPERATURE_2D Create nodal initial temperature.

x = mesh.nodes(:,1);
y = mesh.nodes(:,2);

switch lower(init.type)
    case 'uniform'
        T = init.T0 * ones(size(x));
    case 'gaussian'
        T = init.Tbase + init.A .* exp( ...
            -((x - init.x0).^2 ./ (2 * init.sx^2) ...
            + (y - init.y0).^2 ./ (2 * init.sy^2)) );
    otherwise
        error('Unknown Module 4 FEM init.type: %s', init.type);
end
end
