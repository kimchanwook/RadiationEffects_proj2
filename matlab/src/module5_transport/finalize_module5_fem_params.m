function params = finalize_module5_fem_params(params, caseName)
% FINALIZE_MODULE5_FEM_PARAMS Fill derived values and create output folder.

if nargin < 2
    caseName = 'module5_fem_case';
end
params.caseName = caseName;

if ~isfield(params, 'io') || ~isfield(params.io, 'outputDir') || isempty(params.io.outputDir)
    matlabRoot = fileparts(fileparts(fileparts(mfilename('fullpath'))));
    params.io.outputDir = fullfile(matlabRoot, 'outputs', 'module5_fem_2d');
end
if ~exist(params.io.outputDir, 'dir')
    mkdir(params.io.outputDir);
end

if ~isfield(params.io, 'saveEvery') || params.io.saveEvery < 1
    params.io.saveEvery = max(1, floor(params.time.numSteps/10));
end

% Update source and initial Gaussian centers if they were left empty.
if ~isfield(params.source, 'x0') || isempty(params.source.x0); params.source.x0 = params.domain.Lx/2; end
if ~isfield(params.source, 'y0') || isempty(params.source.y0); params.source.y0 = params.domain.Ly/2; end
if ~isfield(params.init, 'x0') || isempty(params.init.x0); params.init.x0 = params.domain.Lx/2; end
if ~isfield(params.init, 'y0') || isempty(params.init.y0); params.init.y0 = params.domain.Ly/2; end
if ~isfield(params.defects, 'x0') || isempty(params.defects.x0); params.defects.x0 = params.domain.Lx/2; end
if ~isfield(params.defects, 'y0') || isempty(params.defects.y0); params.defects.y0 = params.domain.Ly/2; end

if params.physics.useEinstein
    Vt = params.physics.kB * params.physics.temperature / params.physics.q;
    params.physics.D_n = params.physics.mu_n_ref * Vt;
    params.physics.D_p = params.physics.mu_p_ref * Vt;
end
end
