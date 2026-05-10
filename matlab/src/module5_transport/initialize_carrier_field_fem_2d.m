function c = initialize_carrier_field_fem_2d(mesh, init, carrierName)
% INITIALIZE_CARRIER_FIELD_FEM_2D Initialize nodal electron or hole density.

switch lower(carrierName)
    case 'electron'
        base = init.n0;
        excess = init.excess_n;
    case 'hole'
        base = init.p0;
        excess = init.excess_p;
    otherwise
        error('carrierName must be electron or hole.');
end

x = mesh.nodes(:,1);
y = mesh.nodes(:,2);

switch lower(init.type)
    case 'uniform'
        c = base * ones(size(x));
    case 'gaussian_excess'
        r2 = (x - init.x0).^2 + (y - init.y0).^2;
        c = base + excess * exp(-r2 ./ (2.0 * init.sigma^2));
    otherwise
        error('Unknown carrier initialization type: %s', init.type);
end
end
