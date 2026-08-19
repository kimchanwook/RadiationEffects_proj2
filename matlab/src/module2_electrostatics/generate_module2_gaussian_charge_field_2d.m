function chargeField = generate_module2_gaussian_charge_field_2d(mesh, params)
% GENERATE_MODULE2_GAUSSIAN_CHARGE_FIELD_2D Synthetic Module 2 field utility.
%
%   This function is intentionally a DATA-GENERATION UTILITY, not the
%   canonical Module 2 physics input contract. It converts the legacy scalar
%   carrier/dopant settings plus one elliptical Gaussian defect population
%   into the arbitrary nodal total charge field consumed by Module 2.
%
%   The canonical solver input is the returned chargeField.rho array.

numNodes = size(mesh.nodes, 1);

if isfield(params, 'rho_uniform')
    rho = params.rho_uniform .* ones(numNodes, 1);
    metadata.generator = 'uniform_total_charge_density';
    metadata.rho_uniform = params.rho_uniform;
    chargeField = make_module2_charge_field_2d( ...
        mesh, rho, 'synthetic_uniform_field', metadata);
    return;
end

x = mesh.nodes(:, 1);
y = mesh.nodes(:, 2);
Cdef = params.Cdef_background + params.Cdef_peak .* exp( ...
    -0.5*((x - params.Cdef_x0)./params.Cdef_sigma_x).^2 ...
    -0.5*((y - params.Cdef_y0)./params.Cdef_sigma_y).^2);

components.p = params.p;
components.n = params.n;
components.ND_plus = params.ND_plus;
components.NA_minus = params.NA_minus;
components.Cdef = Cdef;
components.zdef = params.zdef;
chargeField = compose_module2_charge_field_2d(mesh, components, params.q);
chargeField.sourceType = 'synthetic_single_elliptical_gaussian';
chargeField.metadata.generator = 'single_elliptical_gaussian_defect_concentration';
chargeField.metadata.Cdef_background = params.Cdef_background;
chargeField.metadata.Cdef_peak = params.Cdef_peak;
chargeField.metadata.Cdef_x0 = params.Cdef_x0;
chargeField.metadata.Cdef_y0 = params.Cdef_y0;
chargeField.metadata.Cdef_sigma_x = params.Cdef_sigma_x;
chargeField.metadata.Cdef_sigma_y = params.Cdef_sigma_y;
chargeField.metadata.zdef = params.zdef;
end
