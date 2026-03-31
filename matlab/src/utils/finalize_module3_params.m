function params = finalize_module3_params(params, caseName)
% FINALIZE_MODULE3_PARAMS Populate default fields and check stability.
if nargin < 2
    caseName = 'module3_case';
end

if ~isfield(params, 'io')
    params.io = struct();
end
if ~isfield(params.io, 'saveEvery')
    params.io.saveEvery = 10;
end
if ~isfield(params.io, 'writeMatFile')
    params.io.writeMatFile = true;
end
if ~isfield(params.io, 'outputDir')
    params.io.outputDir = fullfile('matlab', 'outputs', 'module3_2d', caseName);
end
if ~exist(params.io.outputDir, 'dir')
    mkdir(params.io.outputDir);
end
if ~isfield(params, 'verification')
    params.verification.type = 'diagnostic_only';
end

% Explicit 2D diffusion stability estimate.
dx = (params.domain.xmax - params.domain.xmin) / max(params.domain.Nx - 1, 1);
dy = (params.domain.ymax - params.domain.ymin) / max(params.domain.Ny - 1, 1);
D = params.physics.D;
if D > 0
    dtStable = 1.0 / (2.0 * D * (1.0/dx^2 + 1.0/dy^2));
else
    dtStable = inf;
end
params.numerics.explicitDtStableEstimate = dtStable;
params.numerics.isExplicitDiffusionStable = params.time.dt <= dtStable;
if ~params.numerics.isExplicitDiffusionStable
    warning(['Time step may violate the explicit diffusion stability estimate. ' ...
             'dt = %g, estimated stable dt <= %g'], params.time.dt, dtStable);
end
end
