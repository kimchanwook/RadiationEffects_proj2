function chargeField = make_module2_charge_field_2d(mesh, rho, sourceType, metadata)
% MAKE_MODULE2_CHARGE_FIELD_2D Build the canonical Module 2 field input.
%
%   chargeField = MAKE_MODULE2_CHARGE_FIELD_2D(mesh,rho) validates and
%   packages an arbitrary nodal total charge-density field. The canonical
%   Module 2 electrostatics input is rho(x,y) (or rho(x,z) for Module 9),
%   represented by one value per FEM node in C/m^3.
%
%   chargeField = MAKE_MODULE2_CHARGE_FIELD_2D(mesh,rho,sourceType,metadata)
%   also records provenance. sourceType is descriptive only; it does not
%   change the electrostatic solve.

if nargin < 3 || isempty(sourceType)
    sourceType = 'external_nodal_total_charge_density';
end
if nargin < 4 || isempty(metadata)
    metadata = struct();
end

if ~isstruct(mesh) || ~isfield(mesh, 'nodes')
    error('Module2ChargeField:InvalidMesh', ...
        'mesh must be a structure containing mesh.nodes.');
end
numNodes = size(mesh.nodes, 1);

if ~isnumeric(rho) || ~isreal(rho) || numel(rho) ~= numNodes
    error('Module2ChargeField:InvalidRhoSize', ...
        'rho must be a real numeric value for every FEM node (%d values).', ...
        numNodes);
end
rho = rho(:);
if any(~isfinite(rho))
    error('Module2ChargeField:NonfiniteRho', ...
        'Every nodal charge-density value must be finite.');
end
if ~(ischar(sourceType) || (isstring(sourceType) && isscalar(sourceType)))
    error('Module2ChargeField:InvalidSourceType', ...
        'sourceType must be a character vector or scalar string.');
end
if ~isstruct(metadata)
    error('Module2ChargeField:InvalidMetadata', ...
        'metadata must be a structure.');
end

chargeField.schema = 'module2_charge_field_v1';
chargeField.representation = 'nodal_total_charge_density';
chargeField.location = 'fem_nodes';
chargeField.units = 'C/m^3';
chargeField.sourceType = char(sourceType);
chargeField.nNodes = numNodes;
chargeField.rho = rho;
chargeField.metadata = metadata;
end
