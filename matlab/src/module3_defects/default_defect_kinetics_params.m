function kinetics = default_defect_kinetics_params()
% DEFAULT_DEFECT_KINETICS_PARAMS
% Default reduced constitutive parameters for Module 3 material-aware
% defect diffusivity and annealing coefficient models.
%
% The first implemented reduced dependence set is
%   D = D(T, q_d, N_dop, |E|)
%   k_ann = k_ann(T, q_d, N_dop, |E|)
%
% Bonding, local lattice geometry, and electronic structure are treated as
% the microscopic origin of the effective barriers and prefactors encoded
% below. Strain and interface effects are reserved for later refinement.

kinetics.enabled = false;

% Reference scales
kinetics.Tref = 300.0;                 % K
kinetics.NdopRef = 1.0e21;             % m^-3
kinetics.EfieldRef = 1.0e5;            % V/m
kinetics.kB_eV = 8.617333262145e-5;    % eV/K
kinetics.minTemperature = 1.0;         % K
kinetics.minCoefficient = 0.0;

% Baseline Arrhenius parameters.
kinetics.D0_base = 1.0e-3;             % m^2/s
kinetics.ED_base_eV = 0.45;            % eV
kinetics.k0_base = 1.0e5;              % s^-1
kinetics.Eann_base_eV = 0.60;          % eV

% Weak prefactor dependence on charge state and dopant environment.
kinetics.D0_charge_slope = 0.05;       % per unit |q_d|
kinetics.D0_dop_slope = 0.03;          % per dopant decade
kinetics.k0_charge_slope = 0.04;       % per unit |q_d|
kinetics.k0_dop_slope = 0.02;          % per dopant decade
kinetics.prefactorFloor = 0.10;

% Barrier shifts due to charge state and dopant environment.
kinetics.ED_charge_slope_eV = 0.03;    % eV per unit |q_d|
kinetics.ED_dop_slope_eV = 0.01;       % eV per dopant decade
kinetics.Eann_charge_slope_eV = 0.04;  % eV per unit |q_d|
kinetics.Eann_dop_slope_eV = 0.015;    % eV per dopant decade

% Simple field-induced barrier lowering coefficients.
kinetics.ED_field_lowering_eV_per_Vpm = 1.0e-8;
kinetics.Eann_field_lowering_eV_per_Vpm = 0.5e-8;

% Optional future-refinement placeholders kept off by default.
kinetics.useStrain = false;
kinetics.useInterfaceProximity = false;
kinetics.ED_strain_slope_eV = 0.0;
kinetics.Eann_strain_slope_eV = 0.0;
kinetics.ED_interface_slope_eV = 0.0;
kinetics.Eann_interface_slope_eV = 0.0;
end
