function [fixedNodes, fixedValues, info] = ...
    get_module2_dirichlet_nodes(mesh, params, geometry)
% GET_MODULE2_DIRICHLET_NODES Collect side- and tag-based Dirichlet nodes.
%
%   Legacy rectangular cases read params.bc.left/right/bottom/top.  Module 9
%   cases additionally read params.bc.named and resolve each entry through
%   geometry.tags.<tagGroup>.<tagName>.  Conflicting voltages on the same
%   node cause an error instead of being silently overwritten.

if nargin < 3
    geometry = [];
end

fixedNodes = [];
fixedValues = [];
nodeSources = cell(0, 1);
entries = struct('source', {}, 'type', {}, 'value', {}, 'nodeIds', {});

sides = {'left','right','bottom','top'};
for k = 1:numel(sides)
    side = sides{k};
    if isfield(params.bc, side) && strcmpi(params.bc.(side).type, 'dirichlet')
        nodes = mesh.boundary.(side)(:);
        vals = params.bc.(side).value * ones(size(nodes));
        fixedNodes = [fixedNodes; nodes]; %#ok<AGROW>
        fixedValues = [fixedValues; vals]; %#ok<AGROW>
        nodeSources = [nodeSources; ...
            repmat({['side.', side]}, numel(nodes), 1)]; %#ok<AGROW>
        entries(end + 1) = make_entry( ...
            ['side.', side], params.bc.(side), nodes); %#ok<AGROW>
    end
end

% Resolve solver-facing named surface tags such as the two Module 9
% electrodes.  The JJ-sensitive tag is deliberately absent from the default
% named-BC list and therefore never becomes an electrical short.
if isfield(params.bc, 'named') && ~isempty(fieldnames(params.bc.named))
    if isempty(geometry) || ~isfield(geometry, 'tags')
        error('Module2Electrostatics:NamedTagsNeedGeometry', ...
            'Named boundary conditions require a geometry.tags structure.');
    end
    namedFields = fieldnames(params.bc.named);
    for k = 1:numel(namedFields)
        bcName = namedFields{k};
        bc = params.bc.named.(bcName);
        if ~strcmpi(bc.type, 'dirichlet')
            continue;
        end
        if ~isfield(geometry.tags, bc.tagGroup) || ...
                ~isfield(geometry.tags.(bc.tagGroup), bc.tagName)
            error('Module2Electrostatics:UnknownBoundaryTag', ...
                'Unknown Module 9 boundary tag: %s.%s', ...
                bc.tagGroup, bc.tagName);
        end
        tag = geometry.tags.(bc.tagGroup).(bc.tagName);
        nodes = tag.nodeIds(:);
        if isempty(nodes)
            error('Module2Electrostatics:EmptyBoundaryTag', ...
                'Dirichlet tag %s.%s contains no nodes.', ...
                bc.tagGroup, bc.tagName);
        end
        vals = bc.value * ones(size(nodes));
        source = ['tag.', bc.tagGroup, '.', bc.tagName];
        fixedNodes = [fixedNodes; nodes]; %#ok<AGROW>
        fixedValues = [fixedValues; vals]; %#ok<AGROW>
        nodeSources = [nodeSources; repmat({source}, numel(nodes), 1)]; %#ok<AGROW>
        entries(end + 1) = make_entry(source, bc, nodes); %#ok<AGROW>
    end
end

% Consolidate duplicates while explicitly rejecting incompatible values.
rawNodes = fixedNodes;
rawValues = fixedValues;
rawSources = nodeSources;
uniqueNodes = unique(rawNodes);
uniqueValues = zeros(size(uniqueNodes));
uniqueSources = cell(size(uniqueNodes));
for k = 1:numel(uniqueNodes)
    mask = rawNodes == uniqueNodes(k);
    values = rawValues(mask);
    scale = max([1.0, abs(values(:).')]);
    if max(values) - min(values) > 1e-12 * scale
        sources = unique(rawSources(mask));
        error('Module2Electrostatics:ConflictingDirichletValues', ...
            'Node %d receives conflicting values from: %s', ...
            uniqueNodes(k), strjoin(sources, ', '));
    end
    uniqueValues(k) = values(1);
    uniqueSources{k} = strjoin(unique(rawSources(mask)), ', ');
end
fixedNodes = uniqueNodes;
fixedValues = uniqueValues;

info.entries = entries;
info.nodeSources = uniqueSources;
info.nFixedNodes = numel(fixedNodes);
info.usesNamedTags = isfield(params.bc, 'named') && ...
    ~isempty(fieldnames(params.bc.named));
end

function entry = make_entry(source, bc, nodes)
% MAKE_ENTRY Record how one set of Dirichlet nodes was selected.
entry.source = source;
entry.type = bc.type;
entry.value = bc.value;
entry.nodeIds = nodes(:);
end
