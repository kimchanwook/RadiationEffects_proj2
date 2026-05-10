function params = default_module6_fem_params(caseName)
% DEFAULT_MODULE6_FEM_PARAMS Default parameters for Module 6 coupled FEM runs.
%
% The first Module 6 path is intentionally a reduced coupling driver. It
% places defect concentration C, electrostatic potential phi, temperature T,
% electron concentration n, and hole concentration p on one linear triangular
% mesh and advances them with a staggered Picard iteration.
%
% Supported case names:
%   'smoke'
%   'defect_field_coupling'
%   'thermal_feedback'

if nargin < 1 || isempty(caseName)
    caseName = 'smoke';
end

params.caseName = char(caseName);

% Shared rectangular FEM mesh.
params.domain.Lx = 10e-6;
params.domain.Ly = 4e-6;
params.domain.nx = 35;
params.domain.ny = 17;

% Constants and material properties.
params.constants.q = 1.602176634e-19;
params.constants.kB = 1.380649e-23;
params.electrostatic.eps0 = 8.8541878128e-12;
params.electrostatic.epsRelSi = 11.7;
params.electrostatic.epsSi = params.electrostatic.eps0 * params.electrostatic.epsRelSi;
params.thermal.rhoMass = 2330.0;
params.thermal.cp = 700.0;
params.thermal.Cvol = params.thermal.rhoMass * params.thermal.cp;
params.thermal.k = 148.0;
params.thermal.Tref = 300.0;

% Time stepping and coupling iteration.
params.time.dt = 1.0e-10;
params.time.numSteps = 10;
params.coupling.maxIterations = 8;
params.coupling.tolerance = 1.0e-5;
params.coupling.relaxation = 0.70;
params.coupling.floor = 1.0e-30;

% Defect model C_t = div(D grad C) - kAnn*C + S.
params.defect.Dref = 2.0e-16;
params.defect.kAnnRef = 0.0;
params.defect.temperatureActivationEnergy = 0.0;
params.defect.zDef = 1.0;
params.defect.source.type = 'none';
params.defect.source.S0 = 0.0;
params.defect.source.x0 = 0.50 * params.domain.Lx;
params.defect.source.y0 = 0.50 * params.domain.Ly;
params.defect.source.sigma = 0.12 * min(params.domain.Lx, params.domain.Ly);

% Electrostatic boundary conditions. Left/right contacts are Dirichlet;
% top/bottom are natural zero-normal-displacement boundaries.
params.electrostatic.leftVoltage = 0.0;
params.electrostatic.rightVoltage = 0.5;
params.electrostatic.NDplus = 1.0e21;
params.electrostatic.NAminus = 0.0;

% Carrier model. This is a reduced drift-diffusion-reaction update with known
% E during each subsolve.
params.carrier.ni = 1.0e16;
params.carrier.muNref = 0.135;
params.carrier.muPref = 0.048;
params.carrier.mobilityTemperaturePowerN = 2.2;
params.carrier.mobilityTemperaturePowerP = 2.2;
params.carrier.alphaDefN = 2.0e-23;
params.carrier.alphaDefP = 2.0e-23;
params.carrier.tauN0 = 5.0e-8;
params.carrier.tauP0 = 5.0e-8;
params.carrier.trapCaptureCoeffN = 0.0;
params.carrier.trapCaptureCoeffP = 0.0;
params.carrier.generation.type = 'none';
params.carrier.generation.G0 = 0.0;

% Initial conditions.
params.init.C.type = 'gaussian';
params.init.C.background = 0.0;
params.init.C.peak = 2.0e20;
params.init.C.x0 = 0.50 * params.domain.Lx;
params.init.C.y0 = 0.50 * params.domain.Ly;
params.init.C.sigmaX = 0.10 * params.domain.Lx;
params.init.C.sigmaY = 0.16 * params.domain.Ly;
params.init.T.type = 'uniform';
params.init.T.value = 300.0;
params.init.n.type = 'uniform';
params.init.n.value = params.carrier.ni;
params.init.p.type = 'uniform';
params.init.p.value = params.carrier.ni;

% Thermal sources. qRadHeat is a reduced radiation heat source; Joule heating
% can be enabled after carrier current is computed.
params.thermal.qRadHeat.type = 'none';
params.thermal.qRadHeat.Q0 = 0.0;
params.thermal.useJouleHeating = false;
params.thermal.jouleScale = 1.0;

% Output controls.
params.io.outputDir = fullfile('matlab', 'outputs', 'module6_fem_2d', params.caseName);
params.io.writeMatFile = true;
params.io.makePlots = true;
params.io.saveEvery = 1;

switch lower(params.caseName)
    case 'smoke'
        params.time.numSteps = 5;
        params.coupling.maxIterations = 4;
        params.electrostatic.rightVoltage = 0.25;

    case 'defect_field_coupling'
        params.time.numSteps = 8;
        params.init.C.peak = 5.0e20;
        params.defect.zDef = 1.0;
        params.electrostatic.rightVoltage = 0.5;
        params.carrier.alphaDefN = 5.0e-23;
        params.carrier.alphaDefP = 5.0e-23;
        params.carrier.trapCaptureCoeffN = 1.0e-5;
        params.carrier.trapCaptureCoeffP = 1.0e-5;

    case 'thermal_feedback'
        params.time.numSteps = 8;
        params.thermal.qRadHeat.type = 'gaussian';
        params.thermal.qRadHeat.Q0 = 5.0e15;
        params.thermal.qRadHeat.x0 = params.init.C.x0;
        params.thermal.qRadHeat.y0 = params.init.C.y0;
        params.thermal.qRadHeat.sigma = params.init.C.sigmaX;
        params.thermal.useJouleHeating = true;
        params.defect.temperatureActivationEnergy = 0.05 * params.constants.q;
        params.defect.Dref = 5.0e-17;

    otherwise
        error('Unknown Module 6 FEM case name: %s', params.caseName);
end
end
