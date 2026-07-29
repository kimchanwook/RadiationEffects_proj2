function test_module3_cpinn_pure_annealing()
% TEST_MODULE3_CPINN_PURE_ANNEALING Causal-PINN regression and physics test.
%
% This deliberately short run tests software invariants rather than claiming
% neural-network convergence in four gradient updates. It verifies:
%   1. the complete Module 3 causal-PINN pipeline is callable;
%   2. ordered time slices and causal-prefix arrays have the expected shape;
%   3. stop-gradient causal weights are finite, bounded, and nonincreasing
%      from early to late time within each update;
%   4. the independent pure-annealing reference equals C0*exp(-kAnn*t);
%   5. predicted concentrations, residuals, and validation metrics are finite.

setup_project_paths;

if ~module3_cpinn_has_deep_learning_toolbox()
    fprintf(['test_module3_cpinn_pure_annealing skipped: MATLAB Deep Learning ', ...
             'Toolbox functions were not found.\n']);
    return;
end

opts = struct();
opts.randomSeed = 37;
opts.numHiddenLayers = 2;
opts.numNeurons = 16;
opts.epsilonSchedule = [0.1, 1.0];
opts.maxIterationsPerEpsilon = 2;
opts.learnRate = 1.0e-3;
opts.numTimeSlices = 3;
opts.timeSlicePower = 1.0;
opts.numInteriorPerSlice = 16;
opts.numInitial = 24;
opts.numBoundaryPerSide = 8;
opts.useDataAnchors = false;
opts.numDataAnchors = 0;
opts.wInitial = 1.0;
opts.wPDE = 1.0;
opts.wBoundary = 1.0;
opts.wData = 0.0;
opts.causalWeightFloor = 1.0e-8;
opts.resampleCollocation = false;
opts.makePlots = false;
opts.saveMat = false;
opts.writeSummary = false;
opts.verbose = false;
opts.printEvery = opts.maxIterationsPerEpsilon;

out = main_module3_CPINN_Defect_Evolution('pure_annealing', opts);

assert(isstruct(out), 'Module 3 causal PINN did not return a structure.');
assert(isfield(out, 'reference'), 'Returned structure is missing its reference.');
assert(isfield(out, 'cpinn'), 'Returned structure is missing its cPIN result.');
assert(isfield(out, 'trainingHistory'), 'Training history is missing.');
assert(isfield(out, 'metrics'), 'Validation metrics are missing.');

expectedTimes = opts.numTimeSlices + 1;
expectedIterations = numel(opts.epsilonSchedule) * opts.maxIterationsPerEpsilon;
assert(numel(out.causalTimes) == expectedTimes, ...
    'Unexpected number of ordered causal times.');
assert(abs(out.causalTimes(1)) < 1.0e-14, ...
    'The first causal time must be t = 0.');
assert(abs(out.causalTimes(end) - out.params.time.tEnd) < 1.0e-14, ...
    'The final causal time must equal tEnd.');
assert(all(diff(out.causalTimes) > 0), ...
    'Causal times must be strictly increasing.');

history = out.trainingHistory;
assert(numel(history.total) == expectedIterations, ...
    'Unexpected number of recorded gradient updates.');
assert(all(size(history.rawCausalLoss) == [expectedIterations, expectedTimes]), ...
    'Raw causal-prefix loss history has the wrong size.');
assert(all(size(history.causalWeights) == [expectedIterations, expectedTimes]), ...
    'Causal-weight history has the wrong size.');
assert(all(size(history.slicePDE) == [expectedIterations, opts.numTimeSlices]), ...
    'Per-time PDE-loss history has the wrong size.');

assert(all(isfinite(history.total)), 'Total loss contains NaN or Inf.');
assert(all(isfinite(history.rawCausalLoss(:))), ...
    'Raw causal-prefix losses contain NaN or Inf.');
assert(all(history.rawCausalLoss(:) >= 0), ...
    'A causal-prefix loss is negative.');
assert(all(isfinite(history.causalWeights(:))), ...
    'Causal weights contain NaN or Inf.');
assert(all(history.causalWeights(:) >= opts.causalWeightFloor), ...
    'A causal weight fell below its numerical floor.');
assert(all(history.causalWeights(:) <= 1.0 + 1.0e-12), ...
    'A causal weight exceeded one.');
assert(all(abs(history.causalWeights(:, 1) - 1.0) < 1.0e-12), ...
    'The initial-slice causal weight must remain one.');
assert(all(diff(history.causalWeights, 1, 2) <= 1.0e-12, 'all'), ...
    'Causal weights must be nonincreasing from early to late time.');

C0 = out.reference.Cinitial;
expectedFinal = C0 .* exp(-out.params.physics.kAnn .* out.params.time.tEnd);
referenceError = norm(out.reference.Cfinal - expectedFinal, 2) / ...
    max(norm(expectedFinal, 2), eps);
assert(referenceError < 1.0e-12, ...
    'Pure-annealing reference does not match the exact exponential solution.');
assert(strcmp(out.reference.method, 'analytic_uniform_reaction_source'), ...
    'Pure annealing should use the independent analytic reference.');

numNodes = size(out.reference.mesh.nodes, 1);
assert(all(size(out.cpinn.C) == [numNodes, expectedTimes]), ...
    'Predicted concentration history has the wrong size.');
assert(all(size(out.cpinn.residualHat) == [numNodes, expectedTimes]), ...
    'Residual history has the wrong size.');
assert(all(isfinite(out.cpinn.C(:))), ...
    'Predicted concentration contains NaN or Inf.');
assert(all(isfinite(out.cpinn.residualHat(:))), ...
    'Dimensionless PDE residual contains NaN or Inf.');
assert(all(isfinite(out.metrics.relativeFieldL2)), ...
    'Relative field errors contain NaN or Inf.');
assert(isfinite(out.metrics.finalInventoryRelativeError), ...
    'Final inventory error is not finite.');
assert(isfinite(out.metrics.rmsResidualHat), ...
    'RMS dimensionless residual is not finite.');

fprintf(['test_module3_cpinn_pure_annealing passed: final total loss %.3e, ', ...
         'final-slice weight %.3e, analytic reference error %.3e\n'], ...
    history.total(end), history.causalWeights(end, end), referenceError);
end

function tf = module3_cpinn_has_deep_learning_toolbox()
required = {'dlarray', 'dlnetwork', 'dlgradient', 'dlfeval', 'adamupdate'};
tf = true;
for k = 1:numel(required)
    name = required{k};
    if ~(exist(name, 'file') == 2 || exist(name, 'class') == 8)
        tf = false;
        return;
    end
end
end
