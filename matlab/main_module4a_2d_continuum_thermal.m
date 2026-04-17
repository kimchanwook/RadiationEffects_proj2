function out = main_module4a_2d_continuum_thermal(caseName)
% MAIN_MODULE4A_2D_CONTINUUM_THERMAL
% Driver for 2D continuum thermal transport in Module 4a.
%
% Supported cases:
%   'uniform_equilibrium'
%   'hotspot_diffusion'
%   'steady_source'

if nargin < 1
    caseName = 'hotspot_diffusion';
end

setup_project_paths();

switch lower(caseName)
    case 'uniform_equilibrium'
        params = case_module4a_uniform_equilibrium_2d();
    case 'hotspot_diffusion'
        params = case_module4a_hotspot_diffusion_2d();
    case 'steady_source'
        params = case_module4a_steady_source_2d();
    otherwise
        error('Unknown caseName: %s', caseName);
end

params = finalize_module4a_params(params, caseName);
gridData = make_grid_2d(params.domain);
T = initialize_temperature_field_2d(gridData, params.init);
Q = initialize_heat_source_2d(gridData, params.source);

nSteps = round(params.time.tEnd / params.time.dt);
saveEvery = params.io.saveEvery;

history = struct([]);
saveIdx = 0;
tHistory = zeros(nSteps, 1);
energyHistory = zeros(nSteps, 1);
tmaxHistory = zeros(nSteps, 1);
l2ErrorHistory = nan(nSteps, 1);

T0 = T;
for n = 1:nSteps
    t = n * params.time.dt;
    T = step_heat_equation_2d(T, Q, gridData, params.physics, params.time.dt);

    tHistory(n) = t;
    energyHistory(n) = compute_thermal_energy_2d(T, gridData, params.physics);
    tmaxHistory(n) = max(T, [], 'all');

    if strcmpi(params.verification.type, 'uniform_equilibrium')
        Texact = T0;
        l2ErrorHistory(n) = compute_l2_error_2d(T, Texact, gridData);
    end

    if mod(n, saveEvery) == 0 || n == 1 || n == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx) = save_thermal_history_2d(T, gridData, t, params.physics); %#ok<AGROW>
    end
end

metrics = struct();
metrics.caseName = caseName;
metrics.initialEnergy = energyHistory(1);
metrics.finalEnergy = energyHistory(end);
metrics.deltaEnergy = energyHistory(end) - energyHistory(1);
metrics.TmaxInitial = max(T0, [], 'all');
metrics.TmaxFinal = max(T, [], 'all');
metrics.verificationType = params.verification.type;
if strcmpi(params.verification.type, 'uniform_equilibrium')
    metrics.finalL2Error = l2ErrorHistory(end);
else
    metrics.finalL2Error = NaN;
end

plot_field_2d(gridData, T, sprintf('Final temperature field: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_final_field.png']));
plot_centerline_cuts_2d(gridData, T0, T, ...
    sprintf('Temperature centerline cuts: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_centerline_cuts.png']));
plot_history_metrics_2d(tHistory, energyHistory, tmaxHistory, l2ErrorHistory, params, ...
    fullfile(params.io.outputDir, [caseName '_history_metrics.png']));

write_module4a_summary(params, metrics, tHistory, energyHistory, tmaxHistory, l2ErrorHistory, ...
    fullfile(params.io.outputDir, [caseName '_summary.txt']));

out.history = history;
out.grid = gridData;
out.params = params;
out.Tinitial = T0;
out.Tfinal = T;
out.Q = Q;
out.metrics = metrics;
out.tHistory = tHistory;
out.energyHistory = energyHistory;
out.tmaxHistory = tmaxHistory;
out.l2ErrorHistory = l2ErrorHistory;

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, [caseName '_results.mat']), 'out');
end
end
