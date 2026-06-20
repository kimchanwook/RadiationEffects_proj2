function test_module2_pinn_electrostatics()
% TEST_MODULE2_PINN_ELECTROSTATICS Lightweight Module 2 PINN smoke test.
%
% This test is intentionally small. It is not a scientific convergence or
% accuracy validation. Its job is to verify that the Module 2 physics-inspired
% neural-network pipeline is callable, that the Poisson residual training loop
% produces finite losses, and that the returned FEM/PINN structures have the
% expected fields and array sizes.
%
% The test uses the charge-free linear-potential case because the FEM reference
% is simple and deterministic. The PINN is only trained for a few iterations so
% that the test remains suitable as a quick regression check.

setup_project_paths;

if ~module2_pinn_has_deep_learning_toolbox()
    fprintf(['test_module2_pinn_electrostatics skipped: MATLAB Deep Learning ', ...
             'Toolbox functions were not found.\n']);
    return;
end

opts = struct();
opts.randomSeed = 23;
opts.numHiddenLayers = 2;
opts.numNeurons = 16;
opts.maxIterations = 8;
opts.learnRate = 2.0e-3;
opts.numInterior = 64;
opts.numBoundaryPerSide = 12;
opts.numDataAnchors = 32;
opts.useDataAnchors = true;
opts.wPDE = 1.0;
opts.wDirichlet = 20.0;
opts.wNeumann = 2.0;
opts.wData = 5.0;
opts.verbose = false;
opts.printEvery = opts.maxIterations;

out = main_module2_pinn_electrostatics('linear_potential', opts);

assert(isstruct(out), 'Module 2 PINN did not return a structure.');
assert(isfield(out, 'fem'), 'Returned structure is missing FEM reference result.');
assert(isfield(out, 'pinn'), 'Returned structure is missing PINN result.');
assert(isfield(out, 'trainingHistory'), 'Returned structure is missing training history.');
assert(isfield(out, 'metrics'), 'Returned structure is missing metrics.');

numNodes = size(out.fem.mesh.nodes, 1);
assert(numel(out.fem.phi) == numNodes, 'FEM potential length does not match mesh node count.');
assert(numel(out.pinn.phi) == numNodes, 'PINN potential length does not match mesh node count.');
assert(numel(out.pinn.residual) == numNodes, 'PINN residual length does not match mesh node count.');
assert(size(out.pinn.field.Enodal, 1) == numNodes, 'PINN electric-field array has wrong node count.');
assert(size(out.pinn.field.Enodal, 2) == 2, 'PINN electric-field array should have Ex and Ey columns.');

assert(numel(out.trainingHistory.total) == opts.maxIterations, ...
    'Training-history length does not match requested iteration count.');
assert(all(isfinite(out.trainingHistory.total)), 'Total loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.pde)), 'PDE loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.dirichlet)), 'Dirichlet loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.neumann)), 'Neumann loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.data)), 'Anchor-data loss contains NaN or Inf.');

assert(all(isfinite(out.pinn.phi)), 'PINN potential contains NaN or Inf.');
assert(all(isfinite(out.pinn.field.Enodal(:))), 'PINN electric field contains NaN or Inf.');
assert(all(isfinite(out.pinn.residual)), 'PINN PDE residual contains NaN or Inf.');

assert(isfinite(out.metrics.relativePhiL2), 'Relative phi L2 metric is not finite.');
assert(isfinite(out.metrics.maxAbsPhiError), 'Max potential-error metric is not finite.');
assert(isfinite(out.metrics.maxAbsResidual), 'Max residual metric is not finite.');

if isfield(out, 'summaryFile') && ~isempty(out.summaryFile)
    assert(exist(out.summaryFile, 'file') == 2, 'Expected PINN summary file was not written.');
end

fprintf('test_module2_pinn_electrostatics passed: final total loss = %.3e, relative phi L2 = %.3e\n', ...
    out.trainingHistory.total(end), out.metrics.relativePhiL2);
end

function tf = module2_pinn_has_deep_learning_toolbox()
required = {'dlarray', 'dlnetwork', 'dlgradient', 'adamupdate'};
tf = true;
for k = 1:numel(required)
    name = required{k};
    if ~(exist(name, 'file') == 2 || exist(name, 'class') == 8)
        tf = false;
        return;
    end
end
end
