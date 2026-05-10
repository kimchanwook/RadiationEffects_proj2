function [fixedNodes, fixedValues] = get_module2_dirichlet_nodes(mesh, params)
% GET_MODULE2_DIRICHLET_NODES Collect Dirichlet nodes from the mesh boundary.

fixedNodes = [];
fixedValues = [];

sides = {'left','right','bottom','top'};
for k = 1:numel(sides)
    side = sides{k};
    if isfield(params.bc, side) && strcmpi(params.bc.(side).type, 'dirichlet')
        nodes = mesh.boundary.(side)(:);
        vals = params.bc.(side).value * ones(size(nodes));
        fixedNodes = [fixedNodes; nodes]; %#ok<AGROW>
        fixedValues = [fixedValues; vals]; %#ok<AGROW>
    end
end

% If a corner belongs to two Dirichlet sides with different values, the first
% occurrence in the side list above is retained. Avoid conflicting corner
% constraints by using left/right Dirichlet and top/bottom natural Neumann
% in the default cases.
[fixedNodes, ia] = unique(fixedNodes, 'stable');
fixedValues = fixedValues(ia);
end
