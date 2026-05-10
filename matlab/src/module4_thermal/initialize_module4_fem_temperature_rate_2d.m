function V = initialize_module4_fem_temperature_rate_2d(mesh, init)
% INITIALIZE_MODULE4_FEM_TEMPERATURE_RATE_2D Create nodal dT/dt field.

n = size(mesh.nodes, 1);
if isfield(init, 'dTdt0')
    if isscalar(init.dTdt0)
        V = init.dTdt0 * ones(n, 1);
    else
        V = init.dTdt0(:);
        if numel(V) ~= n
            error('init.dTdt0 must be scalar or have one value per mesh node.');
        end
    end
else
    V = zeros(n, 1);
end
end
