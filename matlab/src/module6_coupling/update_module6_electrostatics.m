function state = update_module6_electrostatics(mesh, state, params)
% UPDATE_MODULE6_ELECTROSTATICS Build rho and solve Poisson on the shared mesh.

q = params.constants.q;
rho = q .* (state.p - state.n + params.electrostatic.NDplus - ...
    params.electrostatic.NAminus + params.defect.zDef .* state.C);
[K, rhs, elementData] = assemble_poisson_fem_2d(mesh, rho, params.electrostatic.epsSi);
fixedNodes = [mesh.boundary.left(:); mesh.boundary.right(:)];
fixedValues = [params.electrostatic.leftVoltage .* ones(numel(mesh.boundary.left),1); ...
    params.electrostatic.rightVoltage .* ones(numel(mesh.boundary.right),1)];
[Kbc, rhsbc] = apply_dirichlet_bc(K, rhs, fixedNodes, fixedValues);
phi = Kbc \ rhsbc;
field = compute_electric_field_from_potential_2d(mesh, phi);

state.rho = rho;
state.phi = phi;
state.E = field.Enodal;
state.field = field;
state.poisson.K = K;
state.poisson.rhs = rhs;
state.poisson.fixedNodes = fixedNodes;
state.poisson.fixedValues = fixedValues;
state.poisson.elementData = elementData;
end
