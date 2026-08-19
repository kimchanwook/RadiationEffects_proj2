function rho = build_space_charge_module2_2d(nodes, params)
% BUILD_SPACE_CHARGE_MODULE2_2D Legacy compatibility wrapper.
%
%   rho = BUILD_SPACE_CHARGE_MODULE2_2D(nodes,params) preserves the original
%   scalar/Gaussian helper used by the current pointwise PINN prototype and
%   older regression tests. New FEM and coupled-module code should instead
%   pass an explicit module2_charge_field_v1 object to
%   SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D.
%
%   The Gaussian model is now only a synthetic charge-field generator.

mesh.nodes = nodes;
chargeField = generate_module2_gaussian_charge_field_2d(mesh, params);
rho = chargeField.rho;
end
