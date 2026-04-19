function [kAnnEff, details] = compute_effective_annealing_rate(state, kinetics)
% COMPUTE_EFFECTIVE_ANNEALING_RATE
% Reduced constitutive model for effective first-order annealing rate.

T = max(state.T, kinetics.minTemperature);
qd = abs(state.chargeState);
Ndop = max(state.Ndop, eps);
Eabs = abs(state.Eabs);

logDop = log10(Ndop ./ kinetics.NdopRef);
k0eff = kinetics.k0_base .* max(kinetics.prefactorFloor, ...
    1.0 + kinetics.k0_charge_slope .* qd + kinetics.k0_dop_slope .* logDop);

EannEff = kinetics.Eann_base_eV ...
         + kinetics.Eann_charge_slope_eV .* qd ...
         + kinetics.Eann_dop_slope_eV .* logDop ...
         - kinetics.Eann_field_lowering_eV_per_Vpm .* Eabs;

if kinetics.useStrain && isfield(state, 'strain')
    EannEff = EannEff + kinetics.Eann_strain_slope_eV .* state.strain;
end
if kinetics.useInterfaceProximity && isfield(state, 'interfaceProximity')
    EannEff = EannEff + kinetics.Eann_interface_slope_eV .* state.interfaceProximity;
end

kAnnEff = k0eff .* exp(-EannEff ./ (kinetics.kB_eV .* T));
kAnnEff = max(kAnnEff, kinetics.minCoefficient);

details = struct();
details.k0eff = k0eff;
details.EannEff_eV = EannEff;
details.logDop = logDop;
details.EfieldBarrierLowering_eV = kinetics.Eann_field_lowering_eV_per_Vpm .* Eabs;
end
