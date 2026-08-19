function result = solve_poisson_defect_space_charge_2d(params, chargeField)
% SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D Run the Module 2 FEM Poisson solver.
%
%   result = SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D(params,chargeField)
%   solves the electrostatic problem for an arbitrary nodal total
%   charge-density field. chargeField may be either
%
%       - a module2_charge_field_v1 structure, or
%       - a numeric nNodes-by-1 rho vector [C/m^3].
%
%   This explicit field input is the canonical Module 2 contract.
%
%   result = SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D(params) remains supported
%   for legacy named cases. In that compatibility path, the old scalar/
%   Gaussian parameters are first converted into a synthetic nodal field by
%   GENERATE_MODULE2_GAUSSIAN_CHARGE_FIELD_2D, after which the FEM solve is
%   identical to the arbitrary-field path.

[mesh, geometry, params] = resolve_module2_mesh_2d(params);

if nargin < 2 || isempty(chargeField)
    chargeField = generate_module2_gaussian_charge_field_2d(mesh, params);
else
    chargeField = validate_module2_charge_field_2d(mesh, chargeField);
end
rho = chargeField.rho;

[K, rhs, elementData] = assemble_poisson_fem_2d(mesh, rho, params.eps_si);
[fixedNodes, fixedValues, bcInfo] = ...
    get_module2_dirichlet_nodes(mesh, params, geometry);
if isempty(fixedNodes)
    error('Module2Electrostatics:NoDirichletNodes', ...
        ['At least one Dirichlet node is required to remove the constant ', ...
         'null space of the electrostatic Poisson problem.']);
end
[Kbc, rhsbc] = apply_dirichlet_bc(K, rhs, fixedNodes, fixedValues);

phi = Kbc \ rhsbc;
field = compute_electric_field_from_potential_2d(mesh, phi);
diagnostics = compute_module2_fem_diagnostics_2d( ...
    K, rhs, phi, fixedNodes, fixedValues);

% Do not duplicate a caller-supplied full geometry inside result.params; the
% authoritative geometry is returned once as result.geometry.
storedParams = params;
if isfield(storedParams, 'module9Geometry')
    storedParams.module9Geometry = [];
end
result.params = storedParams;
result.mesh = mesh;
result.geometry = geometry;
result.chargeField = chargeField;
result.rho = rho; % Convenience alias retained for downstream compatibility.
result.K = K;
result.rhs = rhs;
result.Kbc = Kbc;
result.rhsbc = rhsbc;
result.fixedNodes = fixedNodes;
result.fixedValues = fixedValues;
result.bcInfo = bcInfo;
result.phi = phi;
result.field = field;
result.elementData = elementData;
result.diagnostics = diagnostics;
result.maxAbsPhi = max(abs(phi));
result.maxAbsE = max(field.Emag_nodal);
end
