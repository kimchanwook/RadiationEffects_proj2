function out = solve_ballistic_diffusive_thermal_fem_2d(mesh, params)
% SOLVE_BALLISTIC_DIFFUSIVE_THERMAL_FEM_2D
% Linear triangular FEM solver for the reduced Module 4 equation.
%
% Temperature form:
%   tau*C*T_tt + C*T_t - div(k grad T) = Q + tau*Q_t - div(q_b).
%
% The time discretization is backward Euler in the first-order variable pair
% (T, V), where V = T_t. Eliminating V gives one linear solve for T^{n+1}.

fem = assemble_thermal_fem_2d(mesh, params.physics);
M = fem.M;
K = fem.K;
dt = params.time.dt;
tau = params.physics.tau;

T = initialize_module4_fem_temperature_2d(mesh, params.init);
V = initialize_module4_fem_temperature_rate_2d(mesh, params.init);
T0 = T;

[bcNodes, bcValues] = get_module4_fem_dirichlet_nodes(mesh, params.dirichlet);
if ~isempty(bcNodes)
    T(bcNodes) = bcValues;
    V(bcNodes) = 0.0;
end

nSteps = params.numerics.numSteps;
tHistory = zeros(nSteps, 1);
energyHistory = zeros(nSteps, 1);
tmaxHistory = zeros(nSteps, 1);
rateNormHistory = zeros(nSteps, 1);
qbmaxHistory = zeros(nSteps, 1);
l2ErrorHistory = nan(nSteps, 1);
history = struct([]);
saveIdx = 0;

if tau <= eps
    A = M ./ dt + K;
else
    A = (tau ./ dt^2) .* M + (1.0 ./ dt) .* M + K;
end

source = struct();
for n = 1:nSteps
    t = n * dt;
    source = evaluate_module4_fem_source_2d(mesh, params, t);
    F = assemble_thermal_source_fem_2d(mesh, source.Snode);

    if tau <= eps
        rhs = F + (M ./ dt) * T;
    else
        rhs = F + ((tau ./ dt^2) + (1.0 ./ dt)) .* (M * T) + (tau ./ dt) .* (M * V);
    end

    [Amod, rhsmod] = apply_module4_dirichlet_bc(A, rhs, bcNodes, bcValues);
    Tnew = Amod \ rhsmod;
    Vnew = (Tnew - T) ./ dt;
    if ~isempty(bcNodes)
        Vnew(bcNodes) = 0.0;
    end

    T = Tnew;
    V = Vnew;

    tHistory(n) = t;
    energyHistory(n) = compute_fem_thermal_energy(M, T);
    tmaxHistory(n) = max(T);
    rateNormHistory(n) = sqrt(mean(V.^2));
    qbmaxHistory(n) = max(abs(source.ballistic.qmag));

    switch lower(params.verification.type)
        case 'uniform_equilibrium'
            l2ErrorHistory(n) = sqrt(mean((T - T0).^2));
        case 'uniform_source'
            exactT = params.init.T0 + params.source.Q0 / params.physics.Cvol * t;
            if tau > eps
                exactT = params.init.T0 + params.source.Q0 / params.physics.Cvol * ...
                    (t - tau * (1 - exp(-t/tau)));
            end
            l2ErrorHistory(n) = sqrt(mean((T - exactT).^2));
    end

    if mod(n, params.io.saveEvery) == 0 || n == 1 || n == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx).t = t; %#ok<AGROW>
        history(saveIdx).T = T;
        history(saveIdx).dTdt = V;
        history(saveIdx).thermalEnergy = energyHistory(n);
        history(saveIdx).Tmax = tmaxHistory(n);
        history(saveIdx).Tmin = min(T);
        history(saveIdx).rateRMS = rateNormHistory(n);
        history(saveIdx).qbMax = qbmaxHistory(n);
    end
end

out.mesh = mesh;
out.fem = fem;
out.params = params;
out.Tinitial = T0;
out.Tfinal = T;
out.dTdtFinal = V;
out.history = history;
out.tHistory = tHistory;
out.energyHistory = energyHistory;
out.tmaxHistory = tmaxHistory;
out.rateNormHistory = rateNormHistory;
out.qbmaxHistory = qbmaxHistory;
out.l2ErrorHistory = l2ErrorHistory;
out.finalSource = source;
out.metrics = build_metrics(params, M, T0, T, V, energyHistory, tmaxHistory, rateNormHistory, qbmaxHistory, l2ErrorHistory);
end

function energy = compute_fem_thermal_energy(M, T)
% If M contains Cvol, then ones'*M*T approximates integral Cvol*T dA.
energy = sum(M * T);
end

function metrics = build_metrics(params, M, T0, T, V, energyHistory, tmaxHistory, rateNormHistory, qbmaxHistory, l2ErrorHistory)
metrics.caseName = params.caseName;
metrics.initialEnergy = compute_fem_thermal_energy(M, T0);
metrics.finalEnergy = compute_fem_thermal_energy(M, T);
metrics.deltaEnergy = metrics.finalEnergy - metrics.initialEnergy;
metrics.TmaxInitial = max(T0);
metrics.TmaxFinal = max(T);
metrics.TminFinal = min(T);
metrics.maxTemperatureRateRMS = max(rateNormHistory);
metrics.maxBallisticFlux = max(qbmaxHistory);
metrics.finalRateRMS = sqrt(mean(V.^2));
metrics.verificationType = params.verification.type;
metrics.finalL2Error = l2ErrorHistory(end);
metrics.outputDir = params.io.outputDir;
metrics.energyHistoryFinal = energyHistory(end);
metrics.tmaxHistoryFinal = tmaxHistory(end);
end
