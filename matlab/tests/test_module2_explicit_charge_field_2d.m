function test_module2_explicit_charge_field_2d()
% TEST_MODULE2_EXPLICIT_CHARGE_FIELD_2D Exercise arbitrary nodal rho input.
setup_project_paths;
params = default_module2_params('linear_potential');
params.makePlots = false;
params.saveMat = false;

% Resolve the exact mesh, create a smooth non-Gaussian nodal charge field,
% and pass it directly to the solver. This test proves that Module 2 no
% longer requires Gaussian location/width parameters to define the source.
[mesh, ~, ~] = resolve_module2_mesh_2d(params);
x = mesh.nodes(:, 1);
y = mesh.nodes(:, 2);
rho = 2.0e-4 .* sin(pi .* x ./ params.Lx) .* ...
    (0.25 + 0.75 .* cos(pi .* y ./ params.Ly).^2);
chargeField = make_module2_charge_field_2d( ...
    mesh, rho, 'non_gaussian_regression_field');
result = solve_poisson_defect_space_charge_2d(params, chargeField);

assert(max(abs(result.rho - rho)) == 0, ...
    'Explicit nodal charge field was not preserved exactly.');
assert(strcmp(result.chargeField.representation, ...
    'nodal_total_charge_density'), ...
    'Solver did not preserve the canonical charge-field contract.');
assert(all(isfinite(result.phi)), ...
    'Explicit-field solve produced non-finite potential values.');
assert(result.diagnostics.freeResidualRelative < 1e-9, ...
    'Explicit-field free-node residual is too large: %.3e', ...
    result.diagnostics.freeResidualRelative);

fprintf(['test_module2_explicit_charge_field_2d passed: ', ...
    '%d nodal rho values accepted.\n'], numel(rho));
end
