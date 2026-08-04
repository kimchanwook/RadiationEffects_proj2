function test_module2_batch_factorization_reuse_2d(dataset)
% TEST_MODULE2_BATCH_FACTORIZATION_REUSE_2D Check the efficiency contract.
setup_project_paths;
if nargin < 1 || isempty(dataset)
    dataset = generate_module2_batch_fem_dataset_2d();
end

p = dataset.provenance;
assert(p.stiffnessAssemblyCount == 1, ...
    'The stiffness operator must be assembled exactly once.');
assert(p.factorizationCount == 1, ...
    'The tagged-boundary matrix must be factorized exactly once.');
assert(p.sourceAssemblyCount == dataset.nCases, ...
    'There must be one source-vector assembly per configuration.');
assert(p.linearSolveCount == dataset.nCases, ...
    'There must be one factorized solve per configuration.');
assert(p.meshReusedForEveryCase, ...
    'The same Module 9 mesh must be reused by all cases.');
assert(~p.numericalGeneratorCreatesPlots, ...
    'The numerical batch generator must remain plot-free.');

fprintf(['test_module2_batch_factorization_reuse_2d passed: ', ...
    '1 assembly, 1 factorization, %d solves.\n'], dataset.nCases);
end
