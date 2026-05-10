function [bcNodes, bcValues] = get_module4_fem_dirichlet_nodes(mesh, dirichlet)
% GET_MODULE4_FEM_DIRICHLET_NODES Build fixed-temperature node list.

bcNodes = [];
bcValues = [];
if ~isfield(dirichlet, 'enabled') || ~dirichlet.enabled
    return;
end

if ~isfield(dirichlet, 'sides')
    error('dirichlet.sides must be specified when Dirichlet BCs are enabled.');
end

for i = 1:numel(dirichlet.sides)
    sideName = lower(dirichlet.sides{i});
    if ~isfield(mesh.boundary, sideName)
        error('Unknown boundary side for Module 4 FEM Dirichlet BC: %s', sideName);
    end
    nodes = mesh.boundary.(sideName)(:);
    values = evaluate_dirichlet_value(mesh, nodes, dirichlet, sideName);
    bcNodes = [bcNodes; nodes]; %#ok<AGROW>
    bcValues = [bcValues; values]; %#ok<AGROW>
end

[bcNodes, ia] = unique(bcNodes, 'stable');
bcValues = bcValues(ia);
end

function values = evaluate_dirichlet_value(mesh, nodes, dirichlet, sideName)
if isfield(dirichlet, 'values') && isfield(dirichlet.values, sideName)
    v = dirichlet.values.(sideName);
else
    v = dirichlet.value;
end

if isa(v, 'function_handle')
    x = mesh.nodes(nodes,1);
    y = mesh.nodes(nodes,2);
    values = v(x, y);
elseif isscalar(v)
    values = v * ones(numel(nodes), 1);
else
    values = v(:);
    if numel(values) ~= numel(nodes)
        error('Dirichlet value for side %s must be scalar, function, or one value per side node.', sideName);
    end
end
end
