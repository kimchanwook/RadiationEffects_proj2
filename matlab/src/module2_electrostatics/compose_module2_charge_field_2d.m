function chargeField = compose_module2_charge_field_2d(mesh, components, q)
% COMPOSE_MODULE2_CHARGE_FIELD_2D Combine physical charge-component fields.
%
%   chargeField = COMPOSE_MODULE2_CHARGE_FIELD_2D(mesh,components,q) forms
%
%       rho = q*(p - n + ND_plus - NA_minus + zdef.*Cdef)
%
%   on the active FEM nodes. Each component may be either a scalar (uniform
%   over the mesh) or an nNodes-by-1 nodal field. This is the intended
%   coupling utility for future Module 3/Module 5 spatial fields.
%
%   Required/recognized component fields:
%       p, n, ND_plus, NA_minus, Cdef, zdef
%   Missing fields default to zero, except zdef which defaults to 1.

if nargin < 3 || isempty(q)
    q = 1.602176634e-19;
end
if ~isscalar(q) || ~isnumeric(q) || ~isreal(q) || ~isfinite(q) || q <= 0
    error('Module2ChargeField:InvalidElementaryCharge', ...
        'q must be a finite positive scalar in coulombs.');
end
if ~isstruct(components)
    error('Module2ChargeField:InvalidComponents', ...
        'components must be a structure of scalar or nodal fields.');
end

numNodes = size(mesh.nodes, 1);
p = expand_component(components, 'p', 0.0, numNodes);
n = expand_component(components, 'n', 0.0, numNodes);
ND_plus = expand_component(components, 'ND_plus', 0.0, numNodes);
NA_minus = expand_component(components, 'NA_minus', 0.0, numNodes);
Cdef = expand_component(components, 'Cdef', 0.0, numNodes);
zdef = expand_component(components, 'zdef', 1.0, numNodes);

rhoMobileDopant = q .* (p - n + ND_plus - NA_minus);
rhoDefect = q .* zdef .* Cdef;
rho = rhoMobileDopant + rhoDefect;

metadata.componentConvention = ...
    'rho=q*(p-n+ND_plus-NA_minus+zdef.*Cdef)';
metadata.q = q;
metadata.containsComponentFields = true;

chargeField = make_module2_charge_field_2d( ...
    mesh, rho, 'composed_physical_component_fields', metadata);
chargeField.components.p = p;
chargeField.components.n = n;
chargeField.components.ND_plus = ND_plus;
chargeField.components.NA_minus = NA_minus;
chargeField.components.Cdef = Cdef;
chargeField.components.zdef = zdef;
chargeField.components.rhoMobileDopant = rhoMobileDopant;
chargeField.components.rhoDefect = rhoDefect;
end

function value = expand_component(components, name, defaultValue, numNodes)
% EXPAND_COMPONENT Convert a scalar or nodal component to a column vector.
if ~isfield(components, name) || isempty(components.(name))
    raw = defaultValue;
else
    raw = components.(name);
end
if ~isnumeric(raw) || ~isreal(raw) || any(~isfinite(raw(:)))
    error('Module2ChargeField:InvalidComponent', ...
        'Component %s must contain finite real numeric values.', name);
end
if isscalar(raw)
    value = repmat(raw, numNodes, 1);
elseif numel(raw) == numNodes
    value = raw(:);
else
    error('Module2ChargeField:InvalidComponentSize', ...
        'Component %s must be scalar or contain %d nodal values.', ...
        name, numNodes);
end
end
