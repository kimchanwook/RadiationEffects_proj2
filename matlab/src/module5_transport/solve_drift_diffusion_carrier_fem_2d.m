function out = solve_drift_diffusion_carrier_fem_2d(mesh, params)
% SOLVE_DRIFT_DIFFUSION_CARRIER_FEM_2D First FEM Module 5 carrier solver.
%
% The solver uses backward Euler and treats electrostatic field, temperature,
% defect field, mobility, diffusivity, generation, and linearized
% recombination coefficients as known during each time step.

n = initialize_carrier_field_fem_2d(mesh, params.init, 'electron');
p = initialize_carrier_field_fem_2d(mesh, params.init, 'hole');
n0 = n;
p0 = p;

dt = params.time.dt;
nSteps = params.time.numSteps;

[bcNNodes, bcNValues] = get_module5_fem_dirichlet_nodes(mesh, params.dirichlet, 'electron');
[bcPNodes, bcPValues] = get_module5_fem_dirichlet_nodes(mesh, params.dirichlet, 'hole');
if ~isempty(bcNNodes); n(bcNNodes) = bcNValues; end
if ~isempty(bcPNodes); p(bcPNodes) = bcPValues; end

% Initial mass matrix for diagnostics.
coeff0 = evaluate_module5_fem_coefficients_2d(mesh, params, 0.0);
scalar0.D = coeff0.D_n; scalar0.mu = coeff0.mu_n; scalar0.Ex = coeff0.Ex; scalar0.Ey = coeff0.Ey;
scalar0.tauInv = coeff0.tauInv_n; scalar0.G = coeff0.G; scalar0.ceq = coeff0.n_eq; scalar0.driftSign = +1;
fem0 = assemble_carrier_fem_2d(mesh, scalar0);
Mdiag = fem0.M;

tHistory = zeros(nSteps,1);
nInventory = zeros(nSteps,1);
pInventory = zeros(nSteps,1);
nMaxHistory = zeros(nSteps,1);
pMaxHistory = zeros(nSteps,1);
l2ErrorHistory = nan(nSteps,1);
history = struct([]);
saveIdx = 0;

lastCoeff = coeff0;
lastFEMn = [];
lastFEMp = [];

for k = 1:nSteps
    t = k * dt;
    coeff = evaluate_module5_fem_coefficients_2d(mesh, params, t);

    scalarN.D = coeff.D_n;
    scalarN.mu = coeff.mu_n;
    scalarN.Ex = coeff.Ex;
    scalarN.Ey = coeff.Ey;
    scalarN.tauInv = coeff.tauInv_n;
    scalarN.G = coeff.G;
    scalarN.ceq = coeff.n_eq;
    scalarN.driftSign = +1;
    femN = assemble_carrier_fem_2d(mesh, scalarN);
    AN = femN.M ./ dt + femN.KD + femN.KE + femN.KR;
    rhsN = (femN.M ./ dt) * n + femN.FG + femN.FR;
    [ANmod, rhsNmod] = apply_module5_dirichlet_bc(AN, rhsN, bcNNodes, bcNValues);
    nNew = ANmod \ rhsNmod;

    scalarP.D = coeff.D_p;
    scalarP.mu = coeff.mu_p;
    scalarP.Ex = coeff.Ex;
    scalarP.Ey = coeff.Ey;
    scalarP.tauInv = coeff.tauInv_p;
    scalarP.G = coeff.G;
    scalarP.ceq = coeff.p_eq;
    scalarP.driftSign = -1;
    femP = assemble_carrier_fem_2d(mesh, scalarP);
    AP = femP.M ./ dt + femP.KD + femP.KE + femP.KR;
    rhsP = (femP.M ./ dt) * p + femP.FG + femP.FR;
    [APmod, rhsPmod] = apply_module5_dirichlet_bc(AP, rhsP, bcPNodes, bcPValues);
    pNew = APmod \ rhsPmod;

    n = max(nNew, 0.0);
    p = max(pNew, 0.0);

    tHistory(k) = t;
    nInventory(k) = sum(Mdiag * n);
    pInventory(k) = sum(Mdiag * p);
    nMaxHistory(k) = max(n);
    pMaxHistory(k) = max(p);

    switch lower(params.verification.type)
        case 'uniform_no_field'
            l2ErrorHistory(k) = sqrt(mean((n - n0).^2 + (p - p0).^2));
        case 'lifetime_recombination'
            rn = (1.0 / (1.0 + dt / params.recombination.tau_n))^k;
            rp = (1.0 / (1.0 + dt / params.recombination.tau_p))^k;
            nExpected = params.recombination.n_eq + (params.init.n0 - params.recombination.n_eq) * rn;
            pExpected = params.recombination.p_eq + (params.init.p0 - params.recombination.p_eq) * rp;
            l2ErrorHistory(k) = sqrt(mean((n - nExpected).^2 + (p - pExpected).^2));
    end

    if mod(k, params.io.saveEvery) == 0 || k == 1 || k == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx).t = t; %#ok<AGROW>
        history(saveIdx).n = n;
        history(saveIdx).p = p;
        history(saveIdx).nInventory = nInventory(k);
        history(saveIdx).pInventory = pInventory(k);
        history(saveIdx).nMax = nMaxHistory(k);
        history(saveIdx).pMax = pMaxHistory(k);
    end

    lastCoeff = coeff;
    lastFEMn = femN;
    lastFEMp = femP;
end

current = compute_current_density_fem_2d(mesh, n, p, lastCoeff, lastFEMn.elementGradN);

out.mesh = mesh;
out.params = params;
out.nInitial = n0;
out.pInitial = p0;
out.nFinal = n;
out.pFinal = p;
out.history = history;
out.tHistory = tHistory;
out.nInventory = nInventory;
out.pInventory = pInventory;
out.nMaxHistory = nMaxHistory;
out.pMaxHistory = pMaxHistory;
out.l2ErrorHistory = l2ErrorHistory;
out.coeffFinal = lastCoeff;
out.femElectron = lastFEMn;
out.femHole = lastFEMp;
out.current = current;
out.metrics = build_module5_metrics(params, Mdiag, n0, p0, n, p, nInventory, pInventory, nMaxHistory, pMaxHistory, l2ErrorHistory, current);
end

function metrics = build_module5_metrics(params, M, n0, p0, n, p, nInventory, pInventory, nMaxHistory, pMaxHistory, l2ErrorHistory, current)
metrics.caseName = params.caseName;
metrics.initialElectronInventory = sum(M * n0);
metrics.finalElectronInventory = sum(M * n);
metrics.initialHoleInventory = sum(M * p0);
metrics.finalHoleInventory = sum(M * p);
metrics.electronInventoryChange = metrics.finalElectronInventory - metrics.initialElectronInventory;
metrics.holeInventoryChange = metrics.finalHoleInventory - metrics.initialHoleInventory;
metrics.nMaxInitial = max(n0);
metrics.nMaxFinal = max(n);
metrics.pMaxInitial = max(p0);
metrics.pMaxFinal = max(p);
metrics.nMaxHistoryFinal = nMaxHistory(end);
metrics.pMaxHistoryFinal = pMaxHistory(end);
metrics.verificationType = params.verification.type;
metrics.finalL2Error = l2ErrorHistory(end);
metrics.maxAbsJn = max(sqrt(sum(current.Jn.^2,2)));
metrics.maxAbsJp = max(sqrt(sum(current.Jp.^2,2)));
metrics.maxAbsJtotal = max(sqrt(sum(current.Jtotal.^2,2)));
metrics.outputDir = params.io.outputDir;
end
