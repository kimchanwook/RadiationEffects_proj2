function sourceState = initialize_bd_source_2d(gridData, source)
% INITIALIZE_BD_SOURCE_2D
% Precompute spatial patterns for volumetric thermal sources.

sourceState = source;

switch lower(source.type)
    case 'zero'
        sourceState.spatialPattern = zeros(gridData.Ny, gridData.Nx);

    case {'gaussian', 'gaussian_pulse'}
        sourceState.spatialPattern = exp( ...
            -((gridData.X - source.x0).^2 ./ (2 * source.sx^2) ...
            + (gridData.Y - source.y0).^2 ./ (2 * source.sy^2)) );

    case {'csv_map', 'damage_map_csv'}
        sourceState.spatialPattern = import_scalar_map_2d(source.csvPath, gridData, source);

    otherwise
        error('Unknown source.type for Module 4: %s', source.type);
end
end
