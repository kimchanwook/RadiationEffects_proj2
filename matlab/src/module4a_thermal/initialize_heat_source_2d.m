function Q = initialize_heat_source_2d(gridData, source)
switch lower(source.type)
    case 'zero'
        Q = zeros(gridData.Ny, gridData.Nx);
    case 'gaussian'
        Q = source.A .* exp( ...
            -((gridData.X - source.x0).^2 ./ (2*source.sx^2) ...
            + (gridData.Y - source.y0).^2 ./ (2*source.sy^2)) );
    otherwise
        error('Unknown source.type: %s', source.type);
end
end
