function C = import_geant4_damage_map_2d(csvPath, gridData, init)
% IMPORT_GEANT4_DAMAGE_MAP_2D
% Import a simple CSV-based 2D damage map and interpolate onto the solver grid.
%
% Required CSV columns are provided in init.xColumn, init.yColumn, init.valueColumn.

if ~isfile(csvPath)
    error('Damage-map CSV file not found: %s', csvPath);
end

T = readtable(csvPath);
requiredNames = {init.xColumn, init.yColumn, init.valueColumn};
for k = 1:numel(requiredNames)
    if ~ismember(requiredNames{k}, T.Properties.VariableNames)
        error('Missing required column "%s" in %s', requiredNames{k}, csvPath);
    end
end

x = T.(init.xColumn);
y = T.(init.yColumn);
v = T.(init.valueColumn);

F = scatteredInterpolant(x, y, v, 'linear', 'nearest');
C = F(gridData.X, gridData.Y);

if isfield(init, 'fillValue')
    C(~isfinite(C)) = init.fillValue;
else
    C(~isfinite(C)) = 0.0;
end

if isfield(init, 'scaleFactor')
    C = init.scaleFactor .* C;
end

C(C < 0) = 0;
end
