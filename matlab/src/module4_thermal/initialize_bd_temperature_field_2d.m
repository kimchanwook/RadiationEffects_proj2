function T = initialize_bd_temperature_field_2d(gridData, init)
switch lower(init.type)
    case 'uniform'
        T = init.T0 * ones(gridData.Ny, gridData.Nx);
    case 'gaussian'
        T = init.Tbase + init.A .* exp( ...
            -((gridData.X - init.x0).^2 ./ (2 * init.sx^2) ...
            + (gridData.Y - init.y0).^2 ./ (2 * init.sy^2)) );
    otherwise
        error('Unknown init.type for Module 4: %s', init.type);
end
end
