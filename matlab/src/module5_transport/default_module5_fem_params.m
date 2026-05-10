function params = default_module5_fem_params()
% DEFAULT_MODULE5_FEM_PARAMS Default settings for Module 5 FEM carrier transport.
%
% The first Module 5 FEM path solves a reduced drift-diffusion-reaction
% system for electrons and holes on a linear triangular mesh.  The electric
% field, temperature, and defect-dependent coefficients are treated as known
% during one carrier solve.

params.domain.Lx = 10e-6;
params.domain.Ly = 5e-6;
params.domain.nx = 41;
params.domain.ny = 21;

params.time.dt = 1.0e-10;
params.time.numSteps = 100;

params.physics.q = 1.602176634e-19;
params.physics.kB = 1.380649e-23;
params.physics.Tref = 300.0;
params.physics.temperature = 300.0;
params.physics.ni = 1.0e16;          % m^-3, reduced room-temperature value
params.physics.mu_n_ref = 0.135;      % m^2/(V s), approximate electron mobility
params.physics.mu_p_ref = 0.048;      % m^2/(V s), approximate hole mobility
params.physics.gamma_n = 2.2;
params.physics.gamma_p = 2.2;
params.physics.useEinstein = true;
params.physics.D_n = 0.0035;          % used only if useEinstein=false
params.physics.D_p = 0.0012;

params.field.type = 'uniform';
params.field.Ex = 0.0;
params.field.Ey = 0.0;

params.defects.type = 'none';
params.defects.C0 = 0.0;
params.defects.x0 = params.domain.Lx/2;
params.defects.y0 = params.domain.Ly/2;
params.defects.sigma = min(params.domain.Lx, params.domain.Ly)/8;
params.defects.alpha_n = 0.0;         % m^3
params.defects.alpha_p = 0.0;         % m^3

params.recombination.type = 'none';   % 'none' or 'linear_lifetime'
params.recombination.tau_n = inf;
params.recombination.tau_p = inf;
params.recombination.n_eq = params.physics.ni;
params.recombination.p_eq = params.physics.ni;

params.source.type = 'none';          % 'none', 'uniform', or 'gaussian'
params.source.G0 = 0.0;
params.source.x0 = params.domain.Lx/2;
params.source.y0 = params.domain.Ly/2;
params.source.sigma = min(params.domain.Lx, params.domain.Ly)/8;

params.init.type = 'uniform';         % 'uniform' or 'gaussian_excess'
params.init.n0 = params.physics.ni;
params.init.p0 = params.physics.ni;
params.init.excess_n = 0.0;
params.init.excess_p = 0.0;
params.init.x0 = params.domain.Lx/2;
params.init.y0 = params.domain.Ly/2;
params.init.sigma = min(params.domain.Lx, params.domain.Ly)/8;

params.dirichlet.n.left = [];
params.dirichlet.n.right = [];
params.dirichlet.n.bottom = [];
params.dirichlet.n.top = [];
params.dirichlet.p.left = [];
params.dirichlet.p.right = [];
params.dirichlet.p.bottom = [];
params.dirichlet.p.top = [];

params.io.outputDir = fullfile(fileparts(fileparts(fileparts(mfilename('fullpath')))), 'outputs', 'module5_fem_2d');
params.io.writeMatFile = true;
params.io.saveEvery = 10;

params.verification.type = 'none';
params.caseName = 'default';
end
