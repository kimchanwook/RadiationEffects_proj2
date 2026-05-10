function C0 = initialize_defect_field_fem_2d(mesh, init)
% INITIALIZE_DEFECT_FIELD_FEM_2D Build nodal initial defect concentration.

nodes = mesh.nodes;
x = nodes(:,1);
y = nodes(:,2);

switch lower(init.type)
    case 'uniform'
        if isfield(init, 'value')
            val = init.value;
        else
            val = init.background;
        end
        C0 = val * ones(size(nodes,1), 1);

    case 'gaussian'
        C0 = init.background + init.peak .* exp( ...
            -0.5*((x - init.x0)./init.sigmaX).^2 ...
            -0.5*((y - init.y0)./init.sigmaY).^2);

    case 'nodal'
        C0 = init.values(:);
        if numel(C0) ~= size(nodes,1)
            error('Nodal initial condition has %d entries but mesh has %d nodes.', ...
                numel(C0), size(nodes,1));
        end

    otherwise
        error('Unknown FEM initial condition type: %s', init.type);
end
end
