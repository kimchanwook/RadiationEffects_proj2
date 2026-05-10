function params = default_module3_fem_params(caseName)
% DEFAULT_MODULE3_FEM_PARAMS Default parameters for Module 3 FEM cases.
%
% The FEM model solves
%   dC/dt = div(D grad C) - kAnn*C + S
% on a triangular mesh using a weak form and backward Euler stepping.

if nargin < 1 || isempty(caseName)
    caseName = 'gaussian_diffusion';
end

params.caseName = char(caseName);

% Rectangular computational domain.
params.domain.Lx = 10e-6;       % m
params.domain.Ly = 4e-6;        % m
params.domain.nx = 41;          % nodal points in x
params.domain.ny = 21;          % nodal points in y

% Defect-kinetics parameters.
params.physics.D = 2.0e-12;     % m^2/s
params.physics.kAnn = 0.0;      % s^-1
params.physics.source = 0.0;    % m^-3 s^-1, scalar or nodal vector

% Time integration.
params.time.dt = 0.02;          % s
params.time.tEnd = 0.50;        % s
params.time.saveEvery = 5;

% Initial condition.
params.init.type = 'gaussian';
params.init.background = 0.0;
params.init.peak = 1.0e21;      % m^-3
params.init.x0 = 0.50 * params.domain.Lx;
params.init.y0 = 0.50 * params.domain.Ly;
params.init.sigmaX = 0.08 * params.domain.Lx;
params.init.sigmaY = 0.12 * params.domain.Ly;

% Boundary conditions. Homogeneous zero-flux is natural in the weak form and
% therefore requires no explicit matrix modification. Dirichlet is included
% for later extension but is off by default.
params.bc.useDirichlet = false;
params.bc.dirichletNodes = [];
params.bc.dirichletValue = 0.0;

% Output controls.
params.io.outputDir = fullfile('outputs', 'module3_fem_2d', params.caseName);
params.io.makePlots = true;
params.io.writeMatFile = true;

% Verification labels used by tests and summaries.
params.verification.type = 'diagnostic_only';

switch lower(params.caseName)
    case 'gaussian_diffusion'
        params.physics.D = 2.0e-12;
        params.physics.kAnn = 0.0;
        params.time.dt = 0.02;
        params.time.tEnd = 0.50;
        params.init.type = 'gaussian';
        params.verification.type = 'mass_conservation';

    case 'pure_annealing'
        params.physics.D = 0.0;
        params.physics.kAnn = 2.0;    % s^-1
        params.time.dt = 0.002;
        params.time.tEnd = 0.50;
        params.init.type = 'uniform';
        params.init.value = 1.0e21;
        params.verification.type = 'pure_annealing';

    case 'uniform_state'
        params.physics.D = 2.0e-12;
        params.physics.kAnn = 0.0;
        params.time.dt = 0.02;
        params.time.tEnd = 0.20;
        params.init.type = 'uniform';
        params.init.value = 1.0e21;
        params.verification.type = 'uniform_preservation';

    otherwise
        error('Unknown Module 3 FEM case name: %s', params.caseName);
end
end
