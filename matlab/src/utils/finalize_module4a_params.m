function params = finalize_module4a_params(params, caseName)
params.caseName = caseName;
if ~isfield(params, 'io')
    params.io = struct();
end
if ~isfield(params.io, 'outputDir')
    params.io.outputDir = fullfile('matlab', 'outputs', 'module4a_2d');
end
if ~exist(params.io.outputDir, 'dir')
    mkdir(params.io.outputDir);
end
alpha = params.physics.k / (params.physics.rho * params.physics.cp);
dx = (params.domain.xmax - params.domain.xmin) / (params.domain.Nx - 1);
dy = (params.domain.ymax - params.domain.ymin) / (params.domain.Ny - 1);
params.physics.alpha = alpha;
params.numerics.dx = dx;
params.numerics.dy = dy;
params.numerics.explicitStabilityDt = 1.0 / (2.0 * alpha * (1.0/dx^2 + 1.0/dy^2));
end
