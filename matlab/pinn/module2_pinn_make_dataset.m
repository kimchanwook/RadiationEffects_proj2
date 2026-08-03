function dataset = module2_pinn_make_dataset(caseName, opts)
% MODULE2_PINN_MAKE_DATASET Generate one FEM reference case for PINN training.
%
%   dataset = MODULE2_PINN_MAKE_DATASET(caseName, opts) runs the existing
%   Module 2 finite-element solver, computes nondimensionalization scales,
%   and selects optional FEM anchor points.  The returned data are used by
%   module2_pinn_train and module2_pinn_verify.
%
%   This function implements the first staged Module 2 PINN: one network is
%   trained for one fixed electrostatic case.  A later parameterized surrogate
%   can call this generator for many parameter sets and add those parameters
%   to the network input vector.
%
%   Required fields in opts:
%       useDataAnchors   logical flag controlling sparse FEM supervision
%       numDataAnchors  requested number of FEM nodal anchors

% Use the localized charged-defect problem when no case was specified.
if nargin < 1 || isempty(caseName)
    caseName = 'localized_defect_charge';
end

% Require an options structure because the anchor policy comes from opts.
if nargin < 2 || ~isstruct(opts)
    error('module2_pinn_make_dataset:InvalidOptions', ...
        'Input opts must be a structure.');
end

% Convert MATLAB string input to a character vector for older releases.
caseName = char(caseName);

% Load the same physical parameters used by the reference FEM driver.
params = default_module2_params(caseName);

% Prevent the reference solve from writing its own plots or MAT file here.
params.makePlots = false;
params.saveMat = false;

% Solve the Poisson equation using the established triangular FEM code.
fem = solve_poisson_defect_space_charge_2d(params);

% Compute consistent scales for coordinates, potential, charge, and gradient.
scales = local_compute_scales(fem, params);

% Initialize an empty anchor structure so pure-PINN mode uses the same API.
anchors.nodeIndices = zeros(0, 1);
anchors.xHat = zeros(0, 1);
anchors.yHat = zeros(0, 1);
anchors.phiHat = zeros(0, 1);

% Select sparse FEM values only when hybrid physics/data training is enabled.
if opts.useDataAnchors && opts.numDataAnchors > 0
    % Count the available nodal values in the FEM reference solution.
    numNodes = size(fem.mesh.nodes, 1);

    % Never request more unique anchors than the mesh actually contains.
    numAnchors = min(round(opts.numDataAnchors), numNodes);

    % Draw unique nodal indices; the driver fixes the RNG seed beforehand.
    anchorIndices = randperm(numNodes, numAnchors).';

    % Extract physical x-y coordinates for the selected anchor nodes.
    anchorCoordinates = fem.mesh.nodes(anchorIndices, :);

    % Retain indices to make the sampled supervision reproducible and inspectable.
    anchors.nodeIndices = anchorIndices;

    % Normalize x to the unit interval used by the network input.
    anchors.xHat = anchorCoordinates(:, 1) ./ params.Lx;

    % Normalize y independently because the domain is rectangular.
    anchors.yHat = anchorCoordinates(:, 2) ./ params.Ly;

    % Normalize FEM potential to the order-one network output scale.
    anchors.phiHat = fem.phi(anchorIndices) ./ scales.V;
end

% Package the physical parameters used to generate this reference case.
dataset.params = params;

% Package the complete FEM solution for anchors and later verification.
dataset.fem = fem;

% Package all scaling constants used consistently in loss and prediction.
dataset.scales = scales;

% Package sparse supervised samples; these arrays are empty in pure-PINN mode.
dataset.anchors = anchors;

% Record the case name explicitly for diagnostics and saved metadata.
dataset.caseName = params.caseName;
end

function scales = local_compute_scales(fem, params)
% LOCAL_COMPUTE_SCALES Choose stable physical scales for nondimensionalization.

% Use the longer domain length as the characteristic length in estimates.
lengthScale = max(params.Lx, params.Ly);

% Measure the largest FEM potential, including prescribed boundary voltages.
boundaryVoltages = [params.bc.left.value, params.bc.right.value];
potentialMagnitude = max([abs(fem.phi(:)); abs(boundaryVoltages(:))]);

% Use a tiny nonzero voltage only to avoid a degenerate all-zero scale.
potentialForEstimate = max(potentialMagnitude, 1.0e-6);

% Convert a characteristic voltage curvature to an equivalent charge scale.
rhoFromVoltage = params.eps_si * potentialForEstimate / lengthScale^2;

% Measure the largest charge density present in the FEM case.
rhoMagnitude = max(abs(fem.rho(:)));

% Retain whichever charge scale is more restrictive for the PDE residual.
rhoScale = max([rhoMagnitude, rhoFromVoltage, realmin('double')]);

% Estimate the potential perturbation that this charge can create.
potentialFromCharge = rhoScale * lengthScale^2 / params.eps_si;

% The output scale must represent both applied voltage and source-driven voltage.
potentialScale = max([potentialMagnitude, potentialFromCharge, 1.0e-12]);

% Store coordinate scales separately for correct rectangular-domain derivatives.
scales.x = params.Lx;
scales.y = params.Ly;

% Store the common potential scale used for network targets and predictions.
scales.V = potentialScale;

% Store the charge scale used to make the Poisson residual dimensionless.
scales.rho = rhoScale;

% Scale normal derivatives by a characteristic potential gradient.
scales.gradPhi = potentialScale / lengthScale;

% Record the reference length for reporting and future nondimensional analysis.
scales.length = lengthScale;
end
