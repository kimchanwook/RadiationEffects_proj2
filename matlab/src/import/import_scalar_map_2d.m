function Fxy = import_scalar_map_2d(csvPath, gridData, opts)
% IMPORT_SCALAR_MAP_2D
% Import a generic 2D scalar field from CSV columns and interpolate it onto
% the solver grid.

if ~isfile(csvPath)
    error('Scalar-map CSV file not found: %s', csvPath);
end

T = readtable(csvPath);
requiredNames = {opts.xColumn, opts.yColumn, opts.valueColumn};
for k = 1:numel(requiredNames)
    if ~ismember(requiredNames{k}, T.Properties.VariableNames)
        error('Missing required column "%s" in %s', requiredNames{k}, csvPath);
    end
end

x = T.(opts.xColumn);
y = T.(opts.yColumn);
v = T.(opts.valueColumn);

F = scatteredInterpolant(x, y, v, 'linear', 'nearest');
Fxy = F(gridData.X, gridData.Y);

if isfield(opts, 'fillValue')
    Fxy(~isfinite(Fxy)) = opts.fillValue;
else
    Fxy(~isfinite(Fxy)) = 0.0;
end

if isfield(opts, 'scaleFactor')
    Fxy = opts.scaleFactor .* Fxy;
end
end
