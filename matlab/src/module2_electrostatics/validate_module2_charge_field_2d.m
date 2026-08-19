function chargeField = validate_module2_charge_field_2d(mesh, chargeField)
% VALIDATE_MODULE2_CHARGE_FIELD_2D Validate the canonical Module 2 input.
%
%   Numeric input is accepted as a convenience and is wrapped as an external
%   nodal field. Structure input must follow module2_charge_field_v1.

if isnumeric(chargeField)
    chargeField = make_module2_charge_field_2d(mesh, chargeField);
    return;
end

if ~isstruct(chargeField)
    error('Module2ChargeField:InvalidInput', ...
        'chargeField must be either a nodal numeric vector or a structure.');
end

required = {'schema', 'representation', 'location', 'units', ...
    'sourceType', 'nNodes', 'rho'};
for k = 1:numel(required)
    if ~isfield(chargeField, required{k})
        error('Module2ChargeField:MissingField', ...
            'chargeField is missing required field "%s".', required{k});
    end
end
if ~strcmp(chargeField.schema, 'module2_charge_field_v1')
    error('Module2ChargeField:UnexpectedSchema', ...
        'Expected schema module2_charge_field_v1, received %s.', ...
        char(chargeField.schema));
end
if ~strcmp(chargeField.representation, 'nodal_total_charge_density') || ...
        ~strcmp(chargeField.location, 'fem_nodes') || ...
        ~strcmp(chargeField.units, 'C/m^3')
    error('Module2ChargeField:UnexpectedRepresentation', ...
        ['Module 2 currently requires nodal total charge density at FEM ', ...
         'nodes in C/m^3.']);
end

numNodes = size(mesh.nodes, 1);
if chargeField.nNodes ~= numNodes || numel(chargeField.rho) ~= numNodes
    error('Module2ChargeField:MeshMismatch', ...
        ['chargeField contains %d nodal values but the active mesh contains ', ...
         '%d nodes.'], numel(chargeField.rho), numNodes);
end
if ~isnumeric(chargeField.rho) || ~isreal(chargeField.rho) || ...
        any(~isfinite(chargeField.rho(:)))
    error('Module2ChargeField:InvalidRhoValues', ...
        'chargeField.rho must contain finite real numeric values.');
end

chargeField.rho = chargeField.rho(:);
chargeField.nNodes = numNodes;
if ~isfield(chargeField, 'metadata') || isempty(chargeField.metadata)
    chargeField.metadata = struct();
elseif ~isstruct(chargeField.metadata)
    error('Module2ChargeField:InvalidMetadata', ...
        'chargeField.metadata must be a structure.');
end
end
