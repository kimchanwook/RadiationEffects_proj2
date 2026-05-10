function params = finalize_module4_fem_params(params, caseName)
% FINALIZE_MODULE4_FEM_PARAMS Fill derived Module 4 FEM parameters.

params.caseName = caseName;

if ~isfield(params, 'io')
    params.io = struct();
end
if ~isfield(params.io, 'outputDir')
    params.io.outputDir = fullfile('matlab', 'outputs', 'module4_fem_2d');
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

params.physics.Cvol = params.physics.rho * params.physics.cp;
params.physics.alpha = params.physics.k / params.physics.Cvol;

if ~isfield(params.physics, 'tau')
    params.physics.tau = params.physics.mfp / params.physics.vBallistic;
end
if ~isfield(params.physics, 'mfp')
    params.physics.mfp = params.physics.vBallistic * params.physics.tau;
end
if ~isfield(params.physics, 'ballisticPrefactor')
    params.physics.ballisticPrefactor = 0.25;
end

params.numerics.dx = params.domain.Lx / (params.domain.nx - 1);
params.numerics.dy = params.domain.Ly / (params.domain.ny - 1);
params.numerics.numSteps = round(params.time.tEnd / params.time.dt);
params.time.tEnd = params.numerics.numSteps * params.time.dt;

if ~isfield(params, 'dirichlet')
    params.dirichlet.enabled = false;
    params.dirichlet.sides = {};
    params.dirichlet.value = 300.0;
end
end
