function params = finalize_module4_bd_params(params, caseName)
params.caseName = caseName;

if ~isfield(params, 'io')
    params.io = struct();
end
if ~isfield(params.io, 'outputDir')
    params.io.outputDir = fullfile('matlab', 'outputs', 'module4_2d_ballistic_diffusive');
end
if ~exist(params.io.outputDir, 'dir')
    mkdir(params.io.outputDir);
end
if ~isfield(params.io, 'saveEvery')
    params.io.saveEvery = 10;
end
if ~isfield(params.io, 'writeMatFile')
    params.io.writeMatFile = true;
end

if ~isfield(params, 'boundary')
    params.boundary = default_bd_boundary_conditions_2d();
end

params.physics.Cvol = params.physics.rho * params.physics.cp;
params.physics.alpha = params.physics.k / params.physics.Cvol;

if ~isfield(params.physics, 'tau')
    if isfield(params.physics, 'mfp') && isfield(params.physics, 'vBallistic')
        params.physics.tau = params.physics.mfp / params.physics.vBallistic;
    else
        error('Module 4 requires either physics.tau or both physics.mfp and physics.vBallistic.');
    end
end
if ~isfield(params.physics, 'mfp')
    params.physics.mfp = params.physics.vBallistic * params.physics.tau;
end
if ~isfield(params.physics, 'ballisticPrefactor')
    params.physics.ballisticPrefactor = 0.25;
end
if ~isfield(params.physics, 'Tref')
    if isfield(params.init, 'T0')
        params.physics.Tref = params.init.T0;
    elseif isfield(params.init, 'Tbase')
        params.physics.Tref = params.init.Tbase;
    else
        params.physics.Tref = 300.0;
    end
end

params.numerics.dx = (params.domain.xmax - params.domain.xmin) / (params.domain.Nx - 1);
params.numerics.dy = (params.domain.ymax - params.domain.ymin) / (params.domain.Ny - 1);
params.numerics.explicitDiffusiveDt = 1.0 / (2.0 * params.physics.alpha * ...
    (1.0 / params.numerics.dx^2 + 1.0 / params.numerics.dy^2));
params.numerics.relaxationDt = 0.2 * params.physics.tau;
params.numerics.ballisticFlightDt = 0.35 * min(params.numerics.dx, params.numerics.dy) / ...
    max(params.physics.vBallistic, eps);
params.numerics.recommendedDt = min([params.numerics.explicitDiffusiveDt, ...
    params.numerics.relaxationDt, params.numerics.ballisticFlightDt]);

if params.time.dt > params.numerics.recommendedDt
    warning(['Requested dt exceeds conservative recommended dt for Module 4. ', ...
        'requested dt = %.3e s, recommended dt = %.3e s.'], ...
        params.time.dt, params.numerics.recommendedDt);
end
end
