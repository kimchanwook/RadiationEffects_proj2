function test_module2_batch_single_case_equivalence_2d(dataset)
% TEST_MODULE2_BATCH_SINGLE_CASE_EQUIVALENCE_2D Compare against the old path.
setup_project_paths;
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d();
end

caseIndex = find(strcmp(dataset.caseNames, 'center_shallow_high'), 1);
assert(~isempty(caseIndex), ...
    'Pilot design is missing the single-case regression configuration.');

params = default_module2_params('transmon_trapped_charge');
params.makePlots = false;
params.saveMat = false;
single = solve_poisson_defect_space_charge_2d(params);

assert(isequal(dataset.mesh.nodes, single.mesh.nodes), ...
    'Batch and single-case paths did not use identical Module 9 nodes.');
assert(isequal(dataset.mesh.elems, single.mesh.elems), ...
    'Batch and single-case paths did not use identical Module 9 triangles.');
phiScale = max(max(abs(single.phi)), realmin);
rhoScale = max(max(abs(single.rho)), realmin);
phiError = max(abs(dataset.phi(:, caseIndex) - single.phi)) / phiScale;
rhoError = max(abs(dataset.rho(:, caseIndex) - single.rho)) / rhoScale;
assert(phiError < 1e-11, ...
    'Batch potential differs from the single-case FEM path: %.3e', phiError);
assert(rhoError < 1e-14, ...
    'Batch charge differs from the single-case FEM path: %.3e', rhoError);

fprintf(['test_module2_batch_single_case_equivalence_2d passed: ', ...
    'relative phi error %.3e.\n'], phiError);
end
