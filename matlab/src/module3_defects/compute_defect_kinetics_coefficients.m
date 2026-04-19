function coeffs = compute_defect_kinetics_coefficients(gridData, physics)
% COMPUTE_DEFECT_KINETICS_COEFFICIENTS
% Build effective diffusivity and annealing-rate fields for Module 3.
%
% If physics.kineticsModel.enabled is false or absent, this function falls
% back to the legacy constant-coefficient behavior using physics.D and
% physics.kAnn.

coeffs = struct();

if ~isfield(physics, 'kineticsModel') || ~isfield(physics.kineticsModel, 'enabled') || ~physics.kineticsModel.enabled
    coeffs.D = physics.D;
    coeffs.kAnn = physics.kAnn;
    coeffs.modelUsed = 'legacy_constant';
    coeffs.details = struct();
    return;
end

kinetics = physics.kineticsModel;
if isempty(kinetics)
    kinetics = default_defect_kinetics_params();
    kinetics.enabled = true;
end

state = struct();
state.T = get_field_or_scalar(physics, {'temperatureField', 'Tfield', 'T'}, kinetics.Tref, gridData);
state.chargeState = get_field_or_scalar(physics, {'chargeStateField', 'chargeState', 'qd'}, 0.0, gridData);
state.Ndop = get_field_or_scalar(physics, {'dopantField', 'NdopField', 'Ndop'}, kinetics.NdopRef, gridData);
state.Eabs = get_field_or_scalar(physics, {'electricFieldMagnitude', 'EabsField', 'Eabs'}, 0.0, gridData);
state.strain = get_field_or_scalar(physics, {'strainField', 'strain'}, 0.0, gridData);
state.interfaceProximity = get_field_or_scalar(physics, {'interfaceProximityField', 'interfaceProximity'}, 0.0, gridData);

[coeffs.D, dDetails] = compute_effective_diffusivity(state, kinetics);
[coeffs.kAnn, kDetails] = compute_effective_annealing_rate(state, kinetics);
coeffs.modelUsed = 'material_aware_reduced';
coeffs.details = struct('diffusivity', dDetails, 'annealing', kDetails);
end

function value = get_field_or_scalar(physics, names, defaultValue, gridData)
value = [];
for i = 1:numel(names)
    if isfield(physics, names{i})
        value = physics.(names{i});
        break;
    end
end
if isempty(value)
    value = defaultValue;
end
if isscalar(value)
    value = value .* ones(gridData.Ny, gridData.Nx);
end
end
