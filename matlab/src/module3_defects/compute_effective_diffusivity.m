function [Deff, details] = compute_effective_diffusivity(state, kinetics)
% COMPUTE_EFFECTIVE_DIFFUSIVITY
% Reduced constitutive model for effective defect diffusivity.
%
% Inputs:
%   state.T             temperature field [K]
%   state.chargeState   effective defect charge-state field [-]
%   state.Ndop          dopant environment field [m^-3 or normalized proxy]
%   state.Eabs          electric-field magnitude [V/m]
%   state.strain        optional strain field [-]
%   state.interfaceProximity optional interface measure
%   kinetics            parameter struct from default_defect_kinetics_params

T = max(state.T, kinetics.minTemperature);
qd = abs(state.chargeState);
Ndop = max(state.Ndop, eps);
Eabs = abs(state.Eabs);

logDop = log10(Ndop ./ kinetics.NdopRef);
D0eff = kinetics.D0_base .* max(kinetics.prefactorFloor, ...
    1.0 + kinetics.D0_charge_slope .* qd + kinetics.D0_dop_slope .* logDop);

EDeff = kinetics.ED_base_eV ...
      + kinetics.ED_charge_slope_eV .* qd ...
      + kinetics.ED_dop_slope_eV .* logDop ...
      - kinetics.ED_field_lowering_eV_per_Vpm .* Eabs;

if kinetics.useStrain && isfield(state, 'strain')
    EDeff = EDeff + kinetics.ED_strain_slope_eV .* state.strain;
end
if kinetics.useInterfaceProximity && isfield(state, 'interfaceProximity')
    EDeff = EDeff + kinetics.ED_interface_slope_eV .* state.interfaceProximity;
end

Deff = D0eff .* exp(-EDeff ./ (kinetics.kB_eV .* T));
Deff = max(Deff, kinetics.minCoefficient);

details = struct();
details.D0eff = D0eff;
details.EDeff_eV = EDeff;
details.logDop = logDop;
details.EfieldBarrierLowering_eV = kinetics.ED_field_lowering_eV_per_Vpm .* Eabs;
end
