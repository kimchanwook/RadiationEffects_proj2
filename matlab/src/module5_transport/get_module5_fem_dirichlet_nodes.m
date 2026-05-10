function [nodes, values] = get_module5_fem_dirichlet_nodes(mesh, bcSpec, carrierName)
% GET_MODULE5_FEM_DIRICHLET_NODES Return Dirichlet carrier nodes and values.

switch lower(carrierName)
    case 'electron'
        spec = bcSpec.n;
    case 'hole'
        spec = bcSpec.p;
    otherwise
        error('carrierName must be electron or hole.');
end

nodes = [];
values = [];
faces = {'left','right','bottom','top'};
for k = 1:numel(faces)
    f = faces{k};
    if isfield(spec, f) && ~isempty(spec.(f))
        thisNodes = mesh.boundary.(f)(:);
        nodes = [nodes; thisNodes]; %#ok<AGROW>
        values = [values; spec.(f) * ones(numel(thisNodes),1)]; %#ok<AGROW>
    end
end

[nodes, ia] = unique(nodes, 'stable');
values = values(ia);
end
