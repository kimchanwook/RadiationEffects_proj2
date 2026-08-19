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
%       'transmon_laplace'
%       'transmon_trapped_charge'
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

% Select the source of the FEM mesh.  Legacy cases keep the original
% rectangle.  Module 9 cases use its validated substrate mesh and surface
% tags.  A caller may put a prebuilt Module 9 geometry structure in
% params.module9Geometry so the exact same mesh can be reused downstream.
params.geometryMode = 'rectangle';
params.module9Geometry = [];
params.coordinateNames = {'x', 'y'};

% Rectangular computational domain.
params.Lx = 10e-6;                     % x-length [m]
params.Ly = 4e-6;                      % y-length [m]
params.nx = 41;                        % number of grid points in x
params.ny = 21;                        % number of grid points in y

% Default semiconductor concentrations [m^-3] used by built-in synthetic
% demonstration cases. Coupled production use should normally construct an
% explicit nodal charge field with compose_module2_charge_field_2d.
params.n = 0.0;
params.p = 0.0;
params.ND_plus = 0.0;
params.NA_minus = 0.0;

% Effective single-defect population used only by the built-in synthetic
% Gaussian field generator. These scalar parameters are not the canonical
% Module 2 input contract; arbitrary nodal rho fields are accepted directly.
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

% Named boundary conditions are empty for the legacy rectangular cases.
% Transmon cases populate this structure with Module 9 tag names.
params.bc.named = struct();

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

    case 'transmon_laplace'
        % Diagnostic 1 mV electrode bias on the validated Module 9 geometry.
        % This is a numerical boundary-condition test, not a claim about the
        % operating voltage of a specific transmon device.
        params = configure_transmon_geometry(params);
        params.Cdef_peak = 0.0;
        params.bc.named.left_electrode.value = 0.0;
        params.bc.named.right_electrode.value = 1.0e-3;

    case 'transmon_trapped_charge'
        % Ground both electrodes so the solved perturbation is attributable
        % to a localized positive charged-defect population below the JJ.
        params = configure_transmon_geometry(params);
        params.Cdef_peak = 2.0e16;
        params.Cdef_x0 = 0.0;
        params.Cdef_y0 = -20.0e-6;
        params.Cdef_sigma_x = 25.0e-6;
        params.Cdef_sigma_y = 10.0e-6;
        params.zdef = 1.0;
        params.bc.named.left_electrode.value = 0.0;
        params.bc.named.right_electrode.value = 0.0;

    otherwise
        error('Unknown Module 2 case name: %s', params.caseName);
end
end

function params = configure_transmon_geometry(params)
% CONFIGURE_TRANSMON_GEOMETRY Select Module 9 mesh and named electrodes.
params.geometryMode = 'module9_transmon';
params.coordinateNames = {'x', 'z'};
params.Lx = 3.0e-3;
params.Ly = 0.5e-3;

% Whole chip sides remain natural zero-flux boundaries.  Dirichlet voltages
% are applied only on the named top-surface electrode segments.
params.bc.left.type = 'neumann';
params.bc.right.type = 'neumann';
params.bc.bottom.type = 'neumann';
params.bc.top.type = 'neumann';
params.bc.named.left_electrode = named_dirichlet( ...
    'electrode', 'left_electrode', 0.0);
params.bc.named.right_electrode = named_dirichlet( ...
    'electrode', 'right_electrode', 0.0);
params.outputDir = fullfile('outputs', 'module2_transmon_2d');
end

function bc = named_dirichlet(tagGroup, tagName, value)
% NAMED_DIRICHLET Build one boundary condition tied to a Module 9 tag.
bc.type = 'dirichlet';
bc.value = value;
bc.tagGroup = tagGroup;
bc.tagName = tagName;
end
