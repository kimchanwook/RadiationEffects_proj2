function params = default_module2_params(caseName)
% DEFAULT_MODULE2_PARAMS Default parameters for Module 2 electrostatics.
%
%   params = DEFAULT_MODULE2_PARAMS(caseName) returns a structure used by
%   the Module 2 two-dimensional finite-element Poisson solver. The solver
%   treats the electrostatic potential phi as the nodal unknown and solves
%
%       div(eps_si grad(phi)) = -rho
%
%   in weak form on a triangular mesh.
%
%   Supported case names:
%       'zero_charge'
%       'linear_potential'
%       'uniform_space_charge'
%       'localized_defect_charge'
%
%   Units are SI unless explicitly stated.

if nargin < 1 || isempty(caseName)
    caseName = 'localized_defect_charge';
end

params.caseName = char(caseName);

% Physical constants.
params.q = 1.602176634e-19;            % elementary charge magnitude [C]
params.eps0 = 8.8541878128e-12;        % vacuum permittivity [F/m]
params.eps_rel_si = 11.7;              % relative permittivity of Si [-]
params.eps_si = params.eps_rel_si * params.eps0;

% Rectangular computational domain.
params.Lx = 10e-6;                     % x-length [m]
params.Ly = 4e-6;                      % y-length [m]
params.nx = 41;                        % number of grid points in x
params.ny = 21;                        % number of grid points in y

% Default semiconductor concentrations [m^-3]. These can be overwritten or
% set by a case file. Only their signed combination enters rho.
params.n = 0.0;
params.p = 0.0;
params.ND_plus = 0.0;
params.NA_minus = 0.0;

% Effective single-defect population. In coupled use, replace Cdef with a
% field imported from Module 3 and set zdef according to the reduced charge
% state being modeled.
params.Cdef_background = 0.0;
params.Cdef_peak = 2.0e20;             % peak defect concentration [m^-3]
params.Cdef_x0 = 0.50 * params.Lx;
params.Cdef_y0 = 0.50 * params.Ly;
params.Cdef_sigma_x = 0.10 * params.Lx;
params.Cdef_sigma_y = 0.15 * params.Ly;
params.zdef = 1.0;

% Boundary conditions. Dirichlet conditions are imposed strongly. Neumann
% boundaries are natural in the weak form and are zero-normal-field unless
% edge fluxes are explicitly provided.
params.bc.left.type = 'dirichlet';
params.bc.left.value = 0.0;
params.bc.right.type = 'dirichlet';
params.bc.right.value = 0.0;
params.bc.bottom.type = 'neumann';
params.bc.bottom.dphidn = 0.0;
params.bc.top.type = 'neumann';
params.bc.top.dphidn = 0.0;

% Output controls.
params.outputDir = fullfile('outputs', 'module2_2d');
params.makePlots = true;
params.saveMat = true;

switch lower(params.caseName)
    case 'zero_charge'
        params.Cdef_peak = 0.0;
        params.bc.left.value = 0.0;
        params.bc.right.value = 0.0;

    case 'linear_potential'
        params.Cdef_peak = 0.0;
        params.bc.left.value = 0.0;
        params.bc.right.value = 1.0;

    case 'uniform_space_charge'
        params.Cdef_peak = 0.0;
        params.rho_uniform = 5.0e-4;   % uniform fixed charge density [C/m^3]
        params.bc.left.value = 0.0;
        params.bc.right.value = 0.0;

    case 'localized_defect_charge'
        params.Cdef_peak = 2.0e20;
        params.zdef = 1.0;
        params.bc.left.value = 0.0;
        params.bc.right.value = 0.0;

    otherwise
        error('Unknown Module 2 case name: %s', params.caseName);
end
end
