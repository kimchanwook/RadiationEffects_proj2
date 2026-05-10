function out = solve_coupled_multiphysics_fem_2d(params)
% SOLVE_COUPLED_MULTIPHYSICS_FEM_2D First staggered Module 6 FEM driver.
%
% This driver is intentionally reduced. It demonstrates the coupled FEM data
% flow on a common triangular mesh:
%   C -> rho_def -> phi,E -> carrier drift/recombination -> Joule heat -> T.
% It is a defensible integration scaffold, not yet a production device TCAD
% model.

mesh = make_rectangular_tri_mesh_2d(params.domain.Lx, params.domain.Ly, ...
    params.domain.nx, params.domain.ny);
state = initialize_module6_fem_state(mesh, params);
state = update_module6_electrostatics(mesh, state, params);

nSteps = params.time.numSteps;
dt = params.time.dt;
numNodes = size(mesh.nodes,1);

history = struct([]);
convergenceHistory = nan(nSteps, params.coupling.maxIterations);
iterationCount = zeros(nSteps,1);
chargeMismatchHistory = zeros(nSteps,1);
maxFieldHistory = zeros(nSteps,1);
maxTemperatureHistory = zeros(nSteps,1);
maxDefectHistory = zeros(nSteps,1);
nInventory = zeros(nSteps,1);
pInventory = zeros(nSteps,1);
CInventory = zeros(nSteps,1);

massFem = assemble_defect_fem_2d(mesh, struct('D',0.0,'kAnn',0.0,'source',0.0));
Mscalar = massFem.M;

for step = 1:nSteps
    stateOldTime = state;
    converged = false;

    for iter = 1:params.coupling.maxIterations
        previous = state;

        raw = state;
        raw.C = update_defect_state(mesh, state, params, dt);
        raw = update_module6_electrostatics(mesh, raw, params);
        raw = update_carrier_state(mesh, raw, params, dt);
        raw.T = update_thermal_state(mesh, raw, params, dt);
        raw = update_module6_electrostatics(mesh, raw, params);
        raw.t = stateOldTime.t + dt;

        state = relax_module6_state(previous, raw, params.coupling.relaxation);
        state.t = raw.t;
        state = update_module6_electrostatics(mesh, state, params);

        metric = compute_module6_coupling_metric(previous, state, params.coupling.floor);
        convergenceHistory(step, iter) = metric;
        if metric < params.coupling.tolerance
            converged = true;
            break;
        end
    end

    iterationCount(step) = iter;
    if ~converged
        % Continue with the last relaxed state. The summary reports the final
        % coupling metric so the user can tighten settings if needed.
    end

    maxFieldHistory(step) = max(sqrt(sum(state.E.^2,2)));
    maxTemperatureHistory(step) = max(state.T);
    maxDefectHistory(step) = max(state.C);
    CInventory(step) = sum(Mscalar * state.C);
    nInventory(step) = sum(Mscalar * state.n);
    pInventory(step) = sum(Mscalar * state.p);
    chargeMismatchHistory(step) = compute_charge_residual_norm(mesh, state, params);

    if mod(step, params.io.saveEvery) == 0 || step == 1 || step == nSteps
        history(end+1).t = state.t; %#ok<AGROW>
        history(end).C = state.C;
        history(end).T = state.T;
        history(end).phi = state.phi;
        history(end).n = state.n;
        history(end).p = state.p;
        history(end).E = state.E;
        history(end).iterations = iter;
        history(end).finalCouplingMetric = convergenceHistory(step, iter);
    end
end

out.params = params;
out.mesh = mesh;
out.stateFinal = state;
out.history = history;
out.convergenceHistory = convergenceHistory;
out.iterationCount = iterationCount;
out.chargeMismatchHistory = chargeMismatchHistory;
out.maxFieldHistory = maxFieldHistory;
out.maxTemperatureHistory = maxTemperatureHistory;
out.maxDefectHistory = maxDefectHistory;
out.CInventory = CInventory;
out.nInventory = nInventory;
out.pInventory = pInventory;
out.metrics = compute_module6_metrics(out);
end

function Cnew = update_defect_state(mesh, state, params, dt)
T = max(state.T, 1.0);
D = params.defect.Dref * ones(size(T));
if params.defect.temperatureActivationEnergy > 0
    Ea = params.defect.temperatureActivationEnergy;
    kB = params.constants.kB;
    Tref = params.thermal.Tref;
    D = params.defect.Dref .* exp(-(Ea/kB) .* (1./T - 1./Tref));
end
kAnn = params.defect.kAnnRef * ones(size(T));
source = evaluate_module6_gaussian_source(mesh, params.defect.source, 'S0');
physics.D = D;
physics.kAnn = kAnn;
physics.source = source;
fem = assemble_defect_fem_2d(mesh, physics);
A = fem.M + dt * fem.Ktotal;
rhs = fem.M * state.C + dt * fem.f;
Cnew = A \ rhs;
Cnew = max(Cnew, 0.0);
end

function state = update_carrier_state(mesh, state, params, dt)
coeff = evaluate_carrier_coefficients(mesh, state, params);

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
rhsN = (femN.M ./ dt) * state.n + femN.FG + femN.FR;
nNew = AN \ rhsN;

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
rhsP = (femP.M ./ dt) * state.p + femP.FG + femP.FR;
pNew = AP \ rhsP;

state.n = max(nNew, 0.0);
state.p = max(pNew, 0.0);
state.carrierCoeff = coeff;
state.carrierFEMElectron = femN;
state.carrierFEMHole = femP;
state.current = compute_current_density_fem_2d(mesh, state.n, state.p, coeff, femN.elementGradN);
end

function Tnew = update_thermal_state(mesh, state, params, dt)
physics.Cvol = params.thermal.Cvol;
physics.k = params.thermal.k;
fem = assemble_thermal_fem_2d(mesh, physics);
Q = evaluate_module6_thermal_source(mesh, state, params);
F = assemble_thermal_source_fem_2d(mesh, Q);
A = fem.M ./ dt + fem.K;
rhs = (fem.M ./ dt) * state.T + F;
Tnew = A \ rhs;
Tnew = max(Tnew, 1.0);
end

function coeff = evaluate_carrier_coefficients(mesh, state, params)
q = params.constants.q;
kB = params.constants.kB;
T = max(state.T, 1.0);
Tref = params.thermal.Tref;
muN0 = params.carrier.muNref .* (T ./ Tref).^(-params.carrier.mobilityTemperaturePowerN);
muP0 = params.carrier.muPref .* (T ./ Tref).^(-params.carrier.mobilityTemperaturePowerP);
mu_n = muN0 ./ (1.0 + params.carrier.alphaDefN .* state.C);
mu_p = muP0 ./ (1.0 + params.carrier.alphaDefP .* state.C);
D_n = mu_n .* kB .* T ./ q;
D_p = mu_p .* kB .* T ./ q;
G = evaluate_module6_carrier_generation(mesh, params.carrier.generation);
trapInvN = params.carrier.trapCaptureCoeffN .* state.C;
trapInvP = params.carrier.trapCaptureCoeffP .* state.C;
coeff.q = q;
coeff.Ex = state.E(:,1);
coeff.Ey = state.E(:,2);
coeff.mu_n = mu_n;
coeff.mu_p = mu_p;
coeff.D_n = D_n;
coeff.D_p = D_p;
coeff.tauInv_n = (1.0 ./ params.carrier.tauN0) + trapInvN;
coeff.tauInv_p = (1.0 ./ params.carrier.tauP0) + trapInvP;
coeff.G = G;
coeff.n_eq = params.carrier.ni * ones(size(state.C));
coeff.p_eq = params.carrier.ni * ones(size(state.C));
end

function source = evaluate_module6_carrier_generation(mesh, g)
N = size(mesh.nodes,1);
switch lower(g.type)
    case 'none'
        source = zeros(N,1);
    case 'uniform'
        source = g.G0 * ones(N,1);
    otherwise
        error('Unknown Module 6 carrier generation type: %s', g.type);
end
end

function Q = evaluate_module6_thermal_source(mesh, state, params)
Q = evaluate_module6_gaussian_source(mesh, params.thermal.qRadHeat, 'Q0');
if params.thermal.useJouleHeating && isfield(state, 'current') && isfield(state, 'carrierCoeff')
    Q = Q + params.thermal.jouleScale .* element_joule_to_nodes(mesh, state.current, state.carrierCoeff);
end
end

function qnode = element_joule_to_nodes(mesh, current, coeff)
numNodes = size(mesh.nodes,1);
qsum = zeros(numNodes,1);
asum = zeros(numNodes,1);
for e = 1:size(mesh.elems,1)
    idx = mesh.elems(e,:);
    Eelem = [mean(coeff.Ex(idx)), mean(coeff.Ey(idx))];
    Qe = dot(current.Jtotal(e,:), Eelem);
    area = triangle_area(mesh.nodes(idx,:));
    qsum(idx) = qsum(idx) + area * Qe / 3.0;
    asum(idx) = asum(idx) + area / 3.0;
end
qnode = qsum ./ max(asum, eps);
qnode = max(qnode, 0.0);
end

function source = evaluate_module6_gaussian_source(mesh, s, fieldName)
N = size(mesh.nodes,1);
if ~isfield(s, 'type') || strcmpi(s.type, 'none')
    source = zeros(N,1);
elseif strcmpi(s.type, 'uniform')
    source = s.(fieldName) * ones(N,1);
elseif strcmpi(s.type, 'gaussian')
    x = mesh.nodes(:,1);
    y = mesh.nodes(:,2);
    source = s.(fieldName) .* exp(-0.5*((x-s.x0)./s.sigma).^2 -0.5*((y-s.y0)./s.sigma).^2);
else
    error('Unknown Gaussian source type: %s', s.type);
end
end

function area = triangle_area(xe)
area = 0.5 * abs((xe(2,1)-xe(1,1))*(xe(3,2)-xe(1,2)) - (xe(3,1)-xe(1,1))*(xe(2,2)-xe(1,2)));
end

function state = relax_module6_state(oldState, rawState, omega)
state = rawState;
fields = {'C','T','n','p','phi'};
for k = 1:numel(fields)
    f = fields{k};
    state.(f) = (1.0 - omega) .* oldState.(f) + omega .* rawState.(f);
end
state.E = (1.0 - omega) .* oldState.E + omega .* rawState.E;
end

function metric = compute_module6_coupling_metric(oldState, state, floorValue)
fields = {'C','T','n','p','phi'};
metric = 0.0;
for k = 1:numel(fields)
    f = fields{k};
    num = norm(state.(f) - oldState.(f), 2);
    den = norm(state.(f), 2) + floorValue;
    metric = max(metric, num/den);
end
end

function residual = compute_charge_residual_norm(mesh, state, params)
rhoExpected = params.constants.q .* (state.p - state.n + ...
    params.electrostatic.NDplus - params.electrostatic.NAminus + params.defect.zDef .* state.C);
[~, rhs, ~] = assemble_poisson_fem_2d(mesh, rhoExpected, params.electrostatic.epsSi); %#ok<ASGLU>
[~, rhsCheck, ~] = assemble_poisson_fem_2d(mesh, state.rho, params.electrostatic.epsSi); %#ok<ASGLU>
residual = norm(rhs-rhsCheck,2) / max(norm(rhsCheck,2), eps);
end
