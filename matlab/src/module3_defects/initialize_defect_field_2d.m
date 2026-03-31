function C = initialize_defect_field_2d(gridData, init)

switch lower(init.type)
    case 'uniform'
        C = init.C0 * ones(gridData.Ny, gridData.Nx);

    case 'gaussian'
        C = init.A .* exp( ...
            -((gridData.X - init.x0).^2 ./ (2*init.sx^2) ...
            + (gridData.Y - init.y0).^2 ./ (2*init.sy^2)) );

    otherwise
        error('Unknown init.type: %s', init.type);
end
end
