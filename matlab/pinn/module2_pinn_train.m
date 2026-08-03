function [net, history, trainingInfo] = module2_pinn_train(net, dataset, opts)
% MODULE2_PINN_TRAIN Train the Module 2 electrostatic PINN with Adam.
%
%   [net, history, trainingInfo] = MODULE2_PINN_TRAIN(net, dataset, opts)
%   repeatedly resamples interior and boundary collocation points, evaluates
%   module2_pinn_loss through dlfeval, and updates the dlnetwork parameters.
%
%   The returned history contains the total loss and every unweighted loss
%   component.  Inspecting those curves separately is important because a
%   decreasing total loss can hide an unsatisfied PDE or boundary condition.

% Extract frequently used structures once to keep the loop readable.
params = dataset.params;
scales = dataset.scales;
anchors = dataset.anchors;

% Preallocate all history arrays so the training loop does not grow them.
history.iteration = (1:opts.maxIterations).';
history.total = nan(opts.maxIterations, 1);
history.pde = nan(opts.maxIterations, 1);
history.dirichlet = nan(opts.maxIterations, 1);
history.neumann = nan(opts.maxIterations, 1);
history.data = nan(opts.maxIterations, 1);

% Adam stores exponentially averaged first moments in trailingAverage.
trailingAverage = [];

% Adam stores exponentially averaged second moments in trailingAverageSquared.
trailingAverageSquared = [];

% Start a wall-clock timer for honest training-cost reporting.
trainingTimer = tic;

% Perform the requested number of stochastic optimization iterations.
for iteration = 1:opts.maxIterations
    % Draw new collocation and boundary points for this optimization step.
    batch = local_sample_batch(params, anchors, opts);

    % Evaluate the differentiable loss function and its network gradients.
    [loss, gradients, terms] = dlfeval(@module2_pinn_loss, ...
        net, batch, params, scales, opts);

    % Apply one Adam update to every learnable network parameter.
    [net, trailingAverage, trailingAverageSquared] = adamupdate(...
        net, gradients, trailingAverage, trailingAverageSquared, iteration, ...
        opts.learnRate, opts.gradientDecayFactor, ...
        opts.squaredGradientDecayFactor);

    % Store the scalar weighted objective for this iteration.
    history.total(iteration) = local_scalar_value(loss);

    % Store each unweighted term to expose loss-scale competition.
    history.pde(iteration) = local_scalar_value(terms.pde);
    history.dirichlet(iteration) = local_scalar_value(terms.dirichlet);
    history.neumann(iteration) = local_scalar_value(terms.neumann);
    history.data(iteration) = local_scalar_value(terms.data);

    % Print progress only at the first, requested periodic, and final iterations.
    shouldPrint = opts.verbose && (...
        iteration == 1 || ...
        mod(iteration, opts.printEvery) == 0 || ...
        iteration == opts.maxIterations);

    % Report every loss term separately when progress output is enabled.
    if shouldPrint
        fprintf(['  iter %5d | total %.3e | PDE %.3e | ', ...
                 'Dir %.3e | Neu %.3e | Data %.3e\n'], ...
            iteration, ...
            history.total(iteration), ...
            history.pde(iteration), ...
            history.dirichlet(iteration), ...
            history.neumann(iteration), ...
            history.data(iteration));
    end
end

% Record the complete elapsed time after the final optimizer step.
trainingInfo.elapsedSeconds = toc(trainingTimer);

% Record the number of updates actually applied to the network.
trainingInfo.numIterations = opts.maxIterations;

% Record the last weighted loss as a convenient scalar training diagnostic.
trainingInfo.finalLoss = history.total(end);
end

function batch = local_sample_batch(params, anchors, opts)
% LOCAL_SAMPLE_BATCH Draw one stochastic set of PINN training points.

% Draw normalized interior x coordinates uniformly inside the unit interval.
xHatInterior = rand(opts.numInterior, 1);

% Draw normalized interior y coordinates independently.
yHatInterior = rand(opts.numInterior, 1);

% Convert x back to meters before evaluating the physical charge model.
xInterior = params.Lx .* xHatInterior;

% Convert y back to meters before evaluating the physical charge model.
yInterior = params.Ly .* yHatInterior;

% Evaluate rho(x,y) using exactly the same source routine as the FEM solver.
rhoInterior = build_space_charge_module2_2d(...
    [xInterior, yInterior], params);

% Store interior coordinates and charge density in the loss-function batch.
batch.xHatInterior = xHatInterior;
batch.yHatInterior = yHatInterior;
batch.rhoInterior = rhoInterior;

% Sample all sides carrying fixed-potential Dirichlet conditions.
[batch.xHatDirichlet, ...
 batch.yHatDirichlet, ...
 batch.phiDirichlet] = local_sample_dirichlet(params, ...
    opts.numBoundaryPerSide);

% Sample all sides carrying prescribed-normal-gradient Neumann conditions.
[batch.xHatNeumann, ...
 batch.yHatNeumann, ...
 batch.normalX, ...
 batch.normalY, ...
 batch.dphidn] = local_sample_neumann(params, ...
    opts.numBoundaryPerSide);

% Reuse the fixed sparse FEM anchors selected by the dataset generator.
batch.xHatData = anchors.xHat;
batch.yHatData = anchors.yHat;
batch.phiHatData = anchors.phiHat;
end

function [xHat, yHat, phiValue] = local_sample_dirichlet(params, nPerSide)
% LOCAL_SAMPLE_DIRICHLET Sample every boundary side with fixed potential.

% Begin with empty arrays because a general case may have no Dirichlet side.
xHat = zeros(0, 1);
yHat = zeros(0, 1);
phiValue = zeros(0, 1);

% Append points on the left side xHat=0 when it is Dirichlet.
if local_is_boundary_type(params, 'left', 'dirichlet')
    % Sample y uniformly along the left vertical edge.
    ySample = rand(nPerSide, 1);

    % Append normalized coordinates and the prescribed physical voltage.
    xHat = [xHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; ySample]; %#ok<AGROW>
    phiValue = [phiValue; ...
        params.bc.left.value .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Append points on the right side xHat=1 when it is Dirichlet.
if local_is_boundary_type(params, 'right', 'dirichlet')
    % Sample y uniformly along the right vertical edge.
    ySample = rand(nPerSide, 1);

    % Append normalized coordinates and the prescribed physical voltage.
    xHat = [xHat; ones(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; ySample]; %#ok<AGROW>
    phiValue = [phiValue; ...
        params.bc.right.value .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Append points on the bottom side yHat=0 when it is Dirichlet.
if local_is_boundary_type(params, 'bottom', 'dirichlet')
    % Sample x uniformly along the bottom horizontal edge.
    xSample = rand(nPerSide, 1);

    % Append normalized coordinates and the prescribed physical voltage.
    xHat = [xHat; xSample]; %#ok<AGROW>
    yHat = [yHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    phiValue = [phiValue; ...
        params.bc.bottom.value .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Append points on the top side yHat=1 when it is Dirichlet.
if local_is_boundary_type(params, 'top', 'dirichlet')
    % Sample x uniformly along the top horizontal edge.
    xSample = rand(nPerSide, 1);

    % Append normalized coordinates and the prescribed physical voltage.
    xHat = [xHat; xSample]; %#ok<AGROW>
    yHat = [yHat; ones(nPerSide, 1)]; %#ok<AGROW>
    phiValue = [phiValue; ...
        params.bc.top.value .* ones(nPerSide, 1)]; %#ok<AGROW>
end
end

function [xHat, yHat, normalX, normalY, dphidn] = ...
    local_sample_neumann(params, nPerSide)
% LOCAL_SAMPLE_NEUMANN Sample boundary points and outward normal vectors.

% Initialize empty arrays because a general case may have no Neumann side.
xHat = zeros(0, 1);
yHat = zeros(0, 1);
normalX = zeros(0, 1);
normalY = zeros(0, 1);
dphidn = zeros(0, 1);

% Add bottom-edge samples with outward unit normal (0,-1).
if local_is_boundary_type(params, 'bottom', 'neumann')
    % Sample normalized x uniformly along yHat=0.
    xSample = rand(nPerSide, 1);

    % Append coordinates, normal components, and target normal derivative.
    xHat = [xHat; xSample]; %#ok<AGROW>
    yHat = [yHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalX = [normalX; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; -ones(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; ...
        params.bc.bottom.dphidn .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Add top-edge samples with outward unit normal (0,+1).
if local_is_boundary_type(params, 'top', 'neumann')
    % Sample normalized x uniformly along yHat=1.
    xSample = rand(nPerSide, 1);

    % Append coordinates, normal components, and target normal derivative.
    xHat = [xHat; xSample]; %#ok<AGROW>
    yHat = [yHat; ones(nPerSide, 1)]; %#ok<AGROW>
    normalX = [normalX; zeros(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; ones(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; ...
        params.bc.top.dphidn .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Add left-edge samples with outward unit normal (-1,0).
if local_is_boundary_type(params, 'left', 'neumann')
    % Sample normalized y uniformly along xHat=0.
    ySample = rand(nPerSide, 1);

    % Append coordinates, normal components, and target normal derivative.
    xHat = [xHat; zeros(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; ySample]; %#ok<AGROW>
    normalX = [normalX; -ones(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; zeros(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; ...
        params.bc.left.dphidn .* ones(nPerSide, 1)]; %#ok<AGROW>
end

% Add right-edge samples with outward unit normal (+1,0).
if local_is_boundary_type(params, 'right', 'neumann')
    % Sample normalized y uniformly along xHat=1.
    ySample = rand(nPerSide, 1);

    % Append coordinates, normal components, and target normal derivative.
    xHat = [xHat; ones(nPerSide, 1)]; %#ok<AGROW>
    yHat = [yHat; ySample]; %#ok<AGROW>
    normalX = [normalX; ones(nPerSide, 1)]; %#ok<AGROW>
    normalY = [normalY; zeros(nPerSide, 1)]; %#ok<AGROW>
    dphidn = [dphidn; ...
        params.bc.right.dphidn .* ones(nPerSide, 1)]; %#ok<AGROW>
end
end

function tf = local_is_boundary_type(params, sideName, requestedType)
% LOCAL_IS_BOUNDARY_TYPE Safely test the type assigned to one boundary side.

% The side must exist before its type field can be inspected.
sideExists = isfield(params.bc, sideName);

% Return false immediately for an unspecified boundary side.
if ~sideExists
    tf = false;
    return;
end

% Compare boundary-type names without making capitalization significant.
tf = strcmpi(params.bc.(sideName).type, requestedType);
end

function value = local_scalar_value(deepLearningValue)
% LOCAL_SCALAR_VALUE Move one scalar dlarray value to ordinary CPU double.

% Remove dlarray tracing metadata, gather GPU data if needed, and cast to double.
value = double(gather(extractdata(deepLearningValue)));
end
