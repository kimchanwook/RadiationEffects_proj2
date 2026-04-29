function out = main_module4_2d_ballistic_diffusive_thermal(caseName)
% MAIN_MODULE4_2D_BALLISTIC_DIFFUSIVE_THERMAL
% Driver for the first executable 2D ballistic-diffusive thermal solver.
%
% Supported cases:
%   'uniform_equilibrium'
%   'localized_pulse'
%   'boundary_heating'
%
% Governing equation in temperature form:
%   tau * T_tt + T_t = alpha * Lap(T) - div(q_b)/(rho*cp)
%                        + (Q + tau*dQdt)/(rho*cp)
%
% The ballistic flux q_b is modeled here with a reduced rectangular-domain
% closure based on attenuated boundary-emitted carrier populations.

if nargin < 1
    caseName = 'localized_pulse';
end

setup_project_paths();

switch lower(caseName)
    case 'uniform_equilibrium'
        params = case_module4_bd_uniform_equilibrium_2d();
    case 'localized_pulse'
        params = case_module4_bd_localized_pulse_2d();
    case 'boundary_heating'
        params = case_module4_bd_boundary_heating_2d();
    otherwise
        error('Unknown caseName: %s', caseName);
end

params = finalize_module4_bd_params(params, caseName);
gridData = make_grid_2d(params.domain);
T = initialize_bd_temperature_field_2d(gridData, params.init);
dTdt = initialize_bd_temperature_rate_2d(gridData, params.init);
sourceState = initialize_bd_source_2d(gridData, params.source);

nSteps = round(params.time.tEnd / params.time.dt);
saveEvery = params.io.saveEvery;

history = struct([]);
saveIdx = 0;
tHistory = zeros(nSteps, 1);
energyHistory = zeros(nSteps, 1);
tmaxHistory = zeros(nSteps, 1);
rateNormHistory = zeros(nSteps, 1);
qbmaxHistory = zeros(nSteps, 1);
l2ErrorHistory = nan(nSteps, 1);

T0 = T;
finalState = struct();
for n = 1:nSteps
    t = n * params.time.dt;
    stepState = step_ballistic_diffusive_temperature_2d( ...
        T, dTdt, gridData, params.physics, params.boundary, sourceState, params.time.dt, t);

    T = stepState.T;
    dTdt = stepState.dTdt;
    finalState = stepState;

    tHistory(n) = t;
    energyHistory(n) = compute_thermal_energy_2d(T, gridData, params.physics);
    tmaxHistory(n) = max(T, [], 'all');
    rateNormHistory(n) = sqrt(mean(dTdt(:).^2));
    qbmaxHistory(n) = max(stepState.ballistic.qmag, [], 'all');

    if strcmpi(params.verification.type, 'uniform_equilibrium')
        l2ErrorHistory(n) = compute_l2_error_2d(T, T0, gridData);
    end

    if mod(n, saveEvery) == 0 || n == 1 || n == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx) = save_bd_history_2d(T, dTdt, stepState.ballistic, gridData, t, params.physics); %#ok<AGROW>
    end
end

metrics = struct();
metrics.caseName = caseName;
metrics.initialEnergy = compute_thermal_energy_2d(T0, gridData, params.physics);
metrics.finalEnergy = energyHistory(end);
metrics.deltaEnergy = metrics.finalEnergy - metrics.initialEnergy;
metrics.TmaxInitial = max(T0, [], 'all');
metrics.TmaxFinal = max(T, [], 'all');
metrics.TminFinal = min(T, [], 'all');
metrics.maxTemperatureRateRMS = max(rateNormHistory);
metrics.maxBallisticFlux = max(qbmaxHistory);
metrics.verificationType = params.verification.type;
metrics.outputDir = params.io.outputDir;
if strcmpi(params.verification.type, 'uniform_equilibrium')
    metrics.finalL2Error = l2ErrorHistory(end);
else
    metrics.finalL2Error = NaN;
end

plot_field_2d(gridData, T, sprintf('Final temperature field: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_final_temperature.png']));
plot_field_2d(gridData, finalState.ballistic.divqb, ...
    sprintf('Final ballistic flux divergence: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_final_ballistic_divergence.png']));
plot_centerline_cuts_2d(gridData, T0, T, ...
    sprintf('Temperature centerline cuts: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_centerline_cuts.png']));
plot_module4_bd_history_metrics_2d(tHistory, energyHistory, tmaxHistory, ...
    rateNormHistory, qbmaxHistory, l2ErrorHistory, params, ...
    fullfile(params.io.outputDir, [caseName '_history_metrics.png']));

write_module4_bd_summary(params, metrics, tHistory, energyHistory, tmaxHistory, ...
    rateNormHistory, qbmaxHistory, l2ErrorHistory, ...
    fullfile(params.io.outputDir, [caseName '_summary.txt']));

out.history = history;
out.grid = gridData;
out.params = params;
out.Tinitial = T0;
out.Tfinal = T;
out.dTdtFinal = dTdt;
out.sourceState = sourceState;
out.finalBallistic = finalState.ballistic;
out.metrics = metrics;
out.tHistory = tHistory;
out.energyHistory = energyHistory;
out.tmaxHistory = tmaxHistory;
out.rateNormHistory = rateNormHistory;
out.qbmaxHistory = qbmaxHistory;
out.l2ErrorHistory = l2ErrorHistory;

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, [caseName '_results.mat']), 'out');
end
end
