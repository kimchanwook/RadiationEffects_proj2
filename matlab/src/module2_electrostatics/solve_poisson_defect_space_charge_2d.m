function result = solve_poisson_defect_space_charge_2d(params)
% SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D Run the Module 2 FEM Poisson solver.
%
%   result = SOLVE_POISSON_DEFECT_SPACE_CHARGE_2D(params) builds the mesh,
%   evaluates the defect-dependent space charge, assembles the finite-element
%   electrostatic matrix, imposes Dirichlet boundaries, solves for potential,
%   and postprocesses the electric field.

mesh = make_rectangular_tri_mesh_2d(params.Lx, params.Ly, params.nx, params.ny);
rho = build_space_charge_module2_2d(mesh.nodes, params);

[K, rhs, elementData] = assemble_poisson_fem_2d(mesh, rho, params.eps_si);
[fixedNodes, fixedValues] = get_module2_dirichlet_nodes(mesh, params);
[Kbc, rhsbc] = apply_dirichlet_bc(K, rhs, fixedNodes, fixedValues);

phi = Kbc \ rhsbc;
field = compute_electric_field_from_potential_2d(mesh, phi);

result.params = params;
result.mesh = mesh;
result.rho = rho;
result.K = K;
result.rhs = rhs;
result.Kbc = Kbc;
result.rhsbc = rhsbc;
result.fixedNodes = fixedNodes;
result.fixedValues = fixedValues;
result.phi = phi;
result.field = field;
result.elementData = elementData;
result.maxAbsPhi = max(abs(phi));
result.maxAbsE = max(field.Emag_nodal);
end
