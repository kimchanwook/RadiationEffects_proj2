function test_module2_cpinn_electrostatics()
% TEST_MODULE2_CPINN_ELECTROSTATICS Lightweight Module 2 Causal PINN smoke test.
%
% This test is intentionally small. It is not a scientific convergence or
% accuracy validation. Its job is to verify that the Module 2 causal-PINN
% pipeline is callable, that causal stage weighting produces finite losses,
% and that the returned FEM/CPINN structures have the expected fields and
% array sizes.
%
% The test uses the charge-free linear-potential case because the FEM reference
% is simple and deterministic. The CPINN is only trained for a few iterations so
% that the test remains suitable as a quick regression check.

setup_project_paths;

if ~module2_cpinn_has_deep_learning_toolbox()
    fprintf(['test_module2_cpinn_electrostatics skipped: MATLAB Deep Learning ', ...
             'Toolbox functions were not found.\n']);
    return;
end

opts = struct();
opts.randomSeed = 29;
opts.numHiddenLayers = 2;
opts.numNeurons = 16;
opts.maxIterations = 8;
opts.learnRate = 2.0e-3;
opts.numStages = 3;
opts.stagePower = 1.0;
opts.numInteriorPerStage = 32;
opts.numBoundaryPerSide = 10;
opts.numDataAnchors = 32;
opts.useDataAnchors = true;
opts.useChargeContinuation = true;
opts.useBoundaryContinuation = true;
opts.wPDE = 1.0;
opts.wDirichlet = 20.0;
opts.wNeumann = 2.0;
opts.wData = 5.0;
opts.causalEpsilon = 2.0;
opts.causalWeightFloor = 1.0e-4;
opts.finalAlpha = 1.0;
opts.verbose = false;
opts.printEvery = opts.maxIterations;

out = main_module2_cpinn_electrostatics('linear_potential', opts);

assert(isstruct(out), 'Module 2 Causal PINN did not return a structure.');
assert(isfield(out, 'fem'), 'Returned structure is missing FEM reference result.');
assert(isfield(out, 'cpinn'), 'Returned structure is missing CPINN result.');
assert(isfield(out, 'pinn'), 'Returned structure is missing PINN-compatible alias.');
assert(isfield(out, 'causalStages'), 'Returned structure is missing causal stages.');
assert(isfield(out, 'trainingHistory'), 'Returned structure is missing training history.');
assert(isfield(out, 'metrics'), 'Returned structure is missing metrics.');

assert(numel(out.causalStages) == opts.numStages, 'Unexpected number of causal stages.');
assert(abs(out.causalStages(1)) < 1.0e-14, 'First causal stage should be alpha = 0.');
assert(abs(out.causalStages(end) - 1.0) < 1.0e-14, 'Final causal stage should be alpha = 1.');
assert(all(diff(out.causalStages) >= 0), 'Causal stages must be ordered.');

numNodes = size(out.fem.mesh.nodes, 1);
assert(numel(out.fem.phi) == numNodes, 'FEM potential length does not match mesh node count.');
assert(numel(out.cpinn.phi) == numNodes, 'CPINN potential length does not match mesh node count.');
assert(numel(out.cpinn.residual) == numNodes, 'CPINN residual length does not match mesh node count.');
assert(size(out.cpinn.field.Enodal, 1) == numNodes, 'CPINN electric-field array has wrong node count.');
assert(size(out.cpinn.field.Enodal, 2) == 2, 'CPINN electric-field array should have Ex and Ey columns.');

assert(numel(out.trainingHistory.total) == opts.maxIterations, ...
    'Training-history length does not match requested iteration count.');
assert(all(size(out.trainingHistory.stageWeights) == [opts.maxIterations, opts.numStages]), ...
    'Causal stage-weight history has wrong size.');
assert(all(size(out.trainingHistory.stageRawLoss) == [opts.maxIterations, opts.numStages]), ...
    'Causal raw stage-loss history has wrong size.');

assert(all(isfinite(out.trainingHistory.total)), 'Total loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.pde)), 'PDE loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.dirichlet)), 'Dirichlet loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.neumann)), 'Neumann loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.data)), 'Anchor-data loss contains NaN or Inf.');
assert(all(isfinite(out.trainingHistory.stageWeights(:))), 'Causal weights contain NaN or Inf.');
assert(all(isfinite(out.trainingHistory.stageRawLoss(:))), 'Raw stage losses contain NaN or Inf.');
assert(all(out.trainingHistory.stageWeights(:) >= opts.causalWeightFloor), ...
    'A causal weight fell below the requested floor.');
assert(all(out.trainingHistory.stageWeights(:) <= 1.0 + 1.0e-12), ...
    'A causal weight exceeded one.');
assert(all(abs(out.trainingHistory.stageWeights(:,1) - 1.0) < 1.0e-12), ...
    'The first causal stage weight should remain one.');

assert(all(isfinite(out.cpinn.phi)), 'CPINN potential contains NaN or Inf.');
assert(all(isfinite(out.cpinn.field.Enodal(:))), 'CPINN electric field contains NaN or Inf.');
assert(all(isfinite(out.cpinn.residual)), 'CPINN PDE residual contains NaN or Inf.');

assert(isfinite(out.metrics.relativePhiL2), 'Relative phi L2 metric is not finite.');
assert(isfinite(out.metrics.maxAbsPhiError), 'Max potential-error metric is not finite.');
assert(isfinite(out.metrics.maxAbsResidual), 'Max residual metric is not finite.');

if isfield(out, 'summaryFile') && ~isempty(out.summaryFile)
    assert(exist(out.summaryFile, 'file') == 2, 'Expected CPINN summary file was not written.');
end

fprintf('test_module2_cpinn_electrostatics passed: final total loss = %.3e, final-stage causal weight = %.3e, relative phi L2 = %.3e\n', ...
    out.trainingHistory.total(end), out.trainingHistory.stageWeights(end,end), out.metrics.relativePhiL2);
end

function tf = module2_cpinn_has_deep_learning_toolbox()
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
