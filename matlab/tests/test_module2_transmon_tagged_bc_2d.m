function test_module2_transmon_tagged_bc_2d()
% TEST_MODULE2_TRANSMON_TAGGED_BC_2D Verify Module 9 electrode constraints.
setup_project_paths;
params = default_module2_params('transmon_laplace');
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);

tags = result.geometry.tags;
leftNodes = tags.electrode.left_electrode.nodeIds(:);
rightNodes = tags.electrode.right_electrode.nodeIds(:);
expectedFixed = unique([leftNodes; rightNodes]);

assert(result.geometry.validation.passed, ...
    'The supplied Module 9 geometry failed its aggregate validation.');
assert(isequal(result.fixedNodes, expectedFixed), ...
    'Fixed-node set does not equal the union of the two electrode tags.');
assert(isempty(intersect(leftNodes, rightNodes)), ...
    'Left and right electrode tags share a node and would be shorted.');
assert(max(abs(result.phi(leftNodes) - 0.0)) < 1e-12, ...
    'Left-electrode voltage was not imposed exactly.');
assert(max(abs(result.phi(rightNodes) - 1.0e-3)) < 1e-12, ...
    'Right-electrode voltage was not imposed exactly.');
assert(min(result.phi) >= -1e-12 && max(result.phi) <= 1.0e-3 + 1e-12, ...
    'Charge-free mixed-BC solution violates the discrete maximum range.');
assert(result.diagnostics.freeResidualRelative < 1e-9, ...
    'Free-node residual is too large: %.3e', ...
    result.diagnostics.freeResidualRelative);
assert(result.diagnostics.globalBalanceRelative < 1e-9, ...
    'Global reaction balance is too large: %.3e', ...
    result.diagnostics.globalBalanceRelative);

% Exercise all three transmon plot paths invisibly.  This catches graphics
% compatibility errors before the top-level driver writes presentation files.
plotDir = tempname;
mkdir(plotDir);
cleanupObject = onCleanup(@() remove_plot_directory(plotDir)); %#ok<NASGU>
plot_module2_result_2d(result, plotDir);
plotNames = { ...
    'transmon_laplace_potential.png', ...
    'transmon_laplace_space_charge.png', ...
    'transmon_laplace_electric_field_magnitude.png'};
for k = 1:numel(plotNames)
    assert(isfile(fullfile(plotDir, plotNames{k})), ...
        'Expected transmon plot was not written: %s', plotNames{k});
end

fprintf(['test_module2_transmon_tagged_bc_2d passed: ', ...
    '%d tagged Dirichlet nodes, residual %.3e.\n'], ...
    numel(result.fixedNodes), result.diagnostics.freeResidualRelative);
end

function remove_plot_directory(plotDir)
% REMOVE_PLOT_DIRECTORY Delete only the unique system-temp test directory.
if exist(plotDir, 'dir')
    rmdir(plotDir, 's');
end
end
