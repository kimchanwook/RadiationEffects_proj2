function out = main_module3_2d_defect_evolution(caseName)
% MAIN_MODULE3_2D_DEFECT_EVOLUTION
% Driver for 2D defect diffusion-reaction evolution.
%
% Supported cases:
%   'gaussian_diffusion'
%   'pure_annealing'
%   'imported_map'

if nargin < 1
    caseName = 'gaussian_diffusion';
end

setup_project_paths();

switch lower(caseName)
    case 'gaussian_diffusion'
        params = case_module3_gaussian_diffusion_2d();
    case 'pure_annealing'
        params = case_module3_pure_annealing_2d();
    case 'imported_map'
        params = case_module3_imported_map_2d();
    otherwise
        error('Unknown caseName: %s', caseName);
end

params = finalize_module3_params(params, caseName);
gridData = make_grid_2d(params.domain);

if isfield(params.init, 'sourceType') && strcmpi(params.init.sourceType, 'geant4_csv')
    C = import_geant4_damage_map_2d(params.init.csvPath, gridData, params.init);
else
    C = initialize_defect_field_2d(gridData, params.init);
end

nSteps = round(params.time.tEnd / params.time.dt);
saveEvery = params.io.saveEvery;

history = struct([]);
saveIdx = 0;
tHistory = zeros(nSteps, 1);
massHistory = zeros(nSteps, 1);
cmaxHistory = zeros(nSteps, 1);
l2ErrorHistory = nan(nSteps, 1);

C0 = C;
initialMass = compute_mass_2d(C, gridData);
expectedMass = initialMass;

if strcmpi(params.verification.type, 'pure_annealing')
    expectedMass = initialMass .* exp(-params.physics.kAnn .* params.time.tEnd);
end

for n = 1:nSteps
    t = n * params.time.dt;
    C = step_defect_diffusion_reaction_2d(C, gridData, params.physics, params.time.dt);

    tHistory(n) = t;
    massHistory(n) = compute_mass_2d(C, gridData);
    cmaxHistory(n) = max(C, [], 'all');

    switch lower(params.verification.type)
        case 'pure_annealing'
            Cexact = exact_uniform_annealing_2d(C0, params.physics.kAnn, t);
            l2ErrorHistory(n) = compute_l2_error_2d(C, Cexact, gridData);
        case 'gaussian_diffusion'
            % No closed-form finite-domain mirrored-boundary solution used here.
            % Keep conservation and broadening diagnostics instead.
        otherwise
            % Imported-map case: diagnostics only.
    end

    if mod(n, saveEvery) == 0 || n == 1 || n == nSteps
        saveIdx = saveIdx + 1;
        history(saveIdx) = save_history_2d(C, gridData, t); %#ok<AGROW>
    end
end

metrics = struct();
metrics.caseName = caseName;
metrics.initialMass = initialMass;
metrics.finalMass = massHistory(end);
metrics.relativeMassChange = (massHistory(end) - initialMass) / max(initialMass, eps);
metrics.cmaxInitial = max(C0, [], 'all');
metrics.cmaxFinal = max(C, [], 'all');
metrics.verificationType = params.verification.type;
metrics.outputDir = params.io.outputDir;
metrics.expectedFinalMass = expectedMass;
metrics.finalMassErrorAbs = massHistory(end) - expectedMass;
metrics.finalMassErrorRel = (massHistory(end) - expectedMass) / max(abs(expectedMass), eps);

if strcmpi(params.verification.type, 'pure_annealing')
    metrics.finalL2Error = l2ErrorHistory(end);
else
    metrics.finalL2Error = NaN;
end

plot_field_2d(gridData, C, sprintf('Final defect concentration: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_final_field.png']));
plot_centerline_cuts_2d(gridData, C0, C, ...
    sprintf('Centerline cuts: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_centerline_cuts.png']));
plot_history_metrics_2d(tHistory, massHistory, cmaxHistory, l2ErrorHistory, params, ...
    fullfile(params.io.outputDir, [caseName '_history_metrics.png']));

write_module3_summary(params, metrics, tHistory, massHistory, cmaxHistory, l2ErrorHistory, ...
    fullfile(params.io.outputDir, [caseName '_summary.txt']));

out.history = history;
out.grid = gridData;
out.params = params;
out.Cinitial = C0;
out.Cfinal = C;
out.metrics = metrics;
out.tHistory = tHistory;
out.massHistory = massHistory;
out.cmaxHistory = cmaxHistory;
out.l2ErrorHistory = l2ErrorHistory;

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, [caseName '_results.mat']), 'out');
end
end
