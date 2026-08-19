function test_module2_charge_component_fields_2d()
% TEST_MODULE2_CHARGE_COMPONENT_FIELDS_2D Verify spatial component assembly.
setup_project_paths;
params = default_module2_params('zero_charge');
params.makePlots = false;
params.saveMat = false;
[mesh, ~, ~] = resolve_module2_mesh_2d(params);
numNodes = size(mesh.nodes, 1);
x = mesh.nodes(:, 1);

components.p = 1.0e15 .* (1.0 + x ./ params.Lx);
components.n = 0.25e15;
components.ND_plus = 2.0e15;
components.NA_minus = 0.5e15 .* ones(numNodes, 1);
components.Cdef = 3.0e14 .* (x ./ params.Lx).^2;
components.zdef = -1.0;
chargeField = compose_module2_charge_field_2d(mesh, components, params.q);

rhoExpected = params.q .* ( ...
    components.p - components.n + components.ND_plus - ...
    components.NA_minus + components.zdef .* components.Cdef);
assert(max(abs(chargeField.rho - rhoExpected)) < ...
    1e-13 * max(max(abs(rhoExpected)), 1.0), ...
    'Spatial component fields were combined with the wrong sign or scale.');
assert(strcmp(chargeField.sourceType, ...
    'composed_physical_component_fields'), ...
    'Unexpected component-field source type.');

fprintf('test_module2_charge_component_fields_2d passed.\n');
end
