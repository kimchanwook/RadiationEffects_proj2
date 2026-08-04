function result = solve_poisson_defect_space_charge_2d(params)
% SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D Run the Module 2 FEM Poisson solver.
%
%   result = SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D(params) resolves either the
%   legacy rectangular mesh or the validated Module 9 transmon geometry,
%   evaluates the defect-dependent space charge, assembles the finite-element
%   electrostatic matrix, imposes side- or tag-based Dirichlet boundaries,
%   solves for potential, and postprocesses the electric field.

[mesh, geometry, params] = resolve_module2_mesh_2d(params);
rho = build_space_charge_module2_2d(mesh.nodes, params);

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
result.rho = rho;
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
