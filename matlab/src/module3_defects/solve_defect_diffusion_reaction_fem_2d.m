function out = solve_defect_diffusion_reaction_fem_2d(params)
% SOLVE_DEFECT_DIFFUSION_REACTION_FEM_2D Advance Module 3 FEM in time.
%
% Uses backward Euler:
%   [M + dt*(Kdiff + Kreact)] C^{n+1} = M*C^n + dt*f.

mesh = make_rectangular_tri_mesh_2d(params.domain.Lx, params.domain.Ly, ...
    params.domain.nx, params.domain.ny);
C = initialize_defect_field_fem_2d(mesh, params.init);
Cinitial = C;

fem = assemble_defect_fem_2d(mesh, params.physics);
M = fem.M;
Ktotal = fem.Ktotal;
f = fem.f;

dt = params.time.dt;
nSteps = round(params.time.tEnd / dt);
saveEvery = params.time.saveEvery;

A = M + dt * Ktotal;

if isfield(params.bc, 'useDirichlet') && params.bc.useDirichlet
    fixedNodes = params.bc.dirichletNodes(:);
    fixedValue = params.bc.dirichletValue;
    if isscalar(fixedValue)
        fixedValues = fixedValue * ones(size(fixedNodes));
    else
        fixedValues = fixedValue(:);
    end
else
    fixedNodes = [];
    fixedValues = [];
end

initialInventory = ones(1, size(M,1)) * M * Cinitial;

history = struct([]);
saveIdx = 0;
tHistory = zeros(nSteps,1);
inventoryHistory = zeros(nSteps,1);
cmaxHistory = zeros(nSteps,1);
l2ErrorHistory = nan(nSteps,1);

for n = 1:nSteps
    t = n * dt;
    rhs = M * C + dt * f;

    if ~isempty(fixedNodes)
        [Abc, rhsbc] = apply_dirichlet_bc(A, rhs, fixedNodes, fixedValues);
        C = Abc \ rhsbc;
    else
        C = A \ rhs;
    end

    % Small negative values can occur from numerical roundoff or from
    % high-order consistent mass effects. Clamp only tiny negatives.
    minC = min(C);
    if minC < 0 && abs(minC) < 1e-12 * max(max(abs(C)), 1.0)
        C(C < 0) = 0;
    end

    tHistory(n) = t;
    inventoryHistory(n) = ones(1, size(M,1)) * M * C;
    cmaxHistory(n) = max(C);

    switch lower(params.verification.type)
        case 'pure_annealing'
            Cexact = Cinitial .* exp(-params.physics.kAnn * t);
            diff = C - Cexact;
            l2ErrorHistory(n) = sqrt((diff.' * M * diff) / max(Cexact.' * M * Cexact, eps));
        case 'uniform_preservation'
            Cexact = Cinitial;
            diff = C - Cexact;
            l2ErrorHistory(n) = sqrt((diff.' * M * diff) / max(Cexact.' * M * Cexact, eps));
    end

    if mod(n, saveEvery) == 0 || n == 1 || n == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx).t = t; %#ok<AGROW>
        history(saveIdx).C = C; %#ok<AGROW>
    end
end

metrics = struct();
metrics.initialInventory = initialInventory;
metrics.finalInventory = inventoryHistory(end);
metrics.relativeInventoryChange = (inventoryHistory(end) - initialInventory) / max(abs(initialInventory), eps);
metrics.cmaxInitial = max(Cinitial);
metrics.cmaxFinal = max(C);
metrics.verificationType = params.verification.type;
metrics.finalL2Error = l2ErrorHistory(end);
if strcmpi(params.verification.type, 'pure_annealing')
    expected = initialInventory * exp(-params.physics.kAnn * params.time.tEnd);
else
    expected = initialInventory;
end
metrics.expectedFinalInventory = expected;
metrics.finalInventoryErrorAbs = metrics.finalInventory - expected;
metrics.finalInventoryErrorRel = metrics.finalInventoryErrorAbs / max(abs(expected), eps);

out.params = params;
out.mesh = mesh;
out.fem = fem;
out.Cinitial = Cinitial;
out.Cfinal = C;
out.history = history;
out.tHistory = tHistory;
out.inventoryHistory = inventoryHistory;
out.cmaxHistory = cmaxHistory;
out.l2ErrorHistory = l2ErrorHistory;
out.metrics = metrics;
out.fixedNodes = fixedNodes;
out.fixedValues = fixedValues;
end
