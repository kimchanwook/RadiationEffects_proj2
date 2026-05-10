function rho = build_space_charge_module2_2d(nodes, params)
% BUILD_SPACE_CHARGE_MODULE2_2D Evaluate nodal space-charge density.
%
%   rho = BUILD_SPACE_CHARGE_MODULE2_2D(nodes, params) returns the nodal
%   charge density [C/m^3] used by the Module 2 Poisson problem.
%
%   The default model is
%       rho = q*(p - n + ND_plus - NA_minus + zdef*Cdef),
%   unless params.rho_uniform is present, in which case that explicit
%   uniform charge density is used for verification.

if isfield(params, 'rho_uniform')
    rho = params.rho_uniform * ones(size(nodes,1), 1);
    return;
end

x = nodes(:,1);
y = nodes(:,2);

Cdef = params.Cdef_background + params.Cdef_peak .* exp( ...
    -0.5*((x - params.Cdef_x0)./params.Cdef_sigma_x).^2 ...
    -0.5*((y - params.Cdef_y0)./params.Cdef_sigma_y).^2);

rho = params.q * (params.p - params.n + params.ND_plus - params.NA_minus + params.zdef .* Cdef);
end
