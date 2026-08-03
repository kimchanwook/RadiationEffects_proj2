function tags = tag_module9_transmon_mesh_2d(mesh, params)
% TAG_MODULE9_TRANSMON_MESH_2D Assign named surface tags to boundary edges.
%
%   tags = TAG_MODULE9_TRANSMON_MESH_2D(mesh,params) identifies the top and
%   bottom boundary edges that belong to each Module 9 feature.  Tags may
%   intentionally overlap: for example, the normal-metal trap overlays part of
%   the right aluminum pad, while the left lead overlaps the left pad slightly.

% Use a tight geometry-scale tolerance because every endpoint is a mesh anchor.
scale = max([params.domain.width, params.domain.thickness, 1e-12]);
tol = 1e3 * eps(scale);

% Create tags for the four complete substrate boundaries.
tags.boundary.left = select_all_edges(mesh, 'left');
tags.boundary.right = select_all_edges(mesh, 'right');
tags.boundary.bottom = select_all_edges(mesh, 'bottom');
tags.boundary.top = select_all_edges(mesh, 'top');

% Tag every physical top-surface feature from its exact x interval.
tags.top.left_pad = select_x_range(mesh, 'top', params.regions.leftPad.xRange, tol);
tags.top.right_pad = select_x_range(mesh, 'top', params.regions.rightPad.xRange, tol);
tags.top.left_lead = select_x_range(mesh, 'top', params.regions.leftLead.xRange, tol);
tags.top.jj_sensitive = select_x_range(mesh, 'top', params.regions.jj.xRange, tol);
tags.top.right_lead = select_x_range(mesh, 'top', params.regions.rightLead.xRange, tol);
tags.top.normal_trap = select_x_range(mesh, 'top', params.regions.normalTrap.xRange, tol);
tags.top.left_bond_pad = select_x_range(mesh, 'top', params.regions.leftBondPad.xRange, tol);
tags.top.right_bond_pad = select_x_range(mesh, 'top', params.regions.rightBondPad.xRange, tol);

% Tag the centered thermalization patch on the bottom substrate boundary.
tags.bottom.backside_sink = select_x_range( ...
    mesh, 'bottom', params.regions.backsideSink.xRange, tol);

% Create solver-oriented electrode groups while retaining the JJ separately.
tags.electrode.left_electrode = union_tags( ...
    mesh, 'top', tags.top.left_pad, tags.top.left_lead);
tags.electrode.right_electrode = union_tags( ...
    mesh, 'top', tags.top.right_pad, tags.top.right_lead);

% The connected visual metal chain includes the effective JJ segment.  This
% derived tag is geometric only and must not later impose equal potential on
% the left and right electrodes.
tags.derived.central_metal_chain = union_tags( ...
    mesh, 'top', tags.top.left_pad, tags.top.left_lead, ...
    tags.top.jj_sensitive, tags.top.right_lead, tags.top.right_pad);

% Preserve the nominal large-pad gap as a reference window.  The centerline
% lead/JJ chain covers this window, so the exclusive exposed-gap tag is empty.
tags.reference.pad_gap_window = select_x_range( ...
    mesh, 'top', params.reference.padGap.xRange, tol);
coveredGapIds = intersect( ...
    tags.reference.pad_gap_window.edgeIds, ...
    tags.derived.central_metal_chain.edgeIds);
exposedGapIds = setdiff(tags.reference.pad_gap_window.edgeIds, coveredGapIds);
tags.reference.exposed_pad_gap = tag_from_ids(mesh, 'top', exposedGapIds);

% Exposed top substrate excludes all primary aluminum surface features.  The
% trap is an overlay on the right pad and therefore does not remove extra edge
% length beyond the right-pad coverage.
primaryMetal = union_tags( ...
    mesh, 'top', tags.top.left_bond_pad, tags.top.left_pad, ...
    tags.top.left_lead, tags.top.jj_sensitive, tags.top.right_lead, ...
    tags.top.right_pad, tags.top.right_bond_pad);
allTopIds = (1:size(mesh.boundaryEdges.top, 1)).';
exposedTopIds = setdiff(allTopIds, primaryMetal.edgeIds);
tags.derived.exposed_substrate_top = tag_from_ids(mesh, 'top', exposedTopIds);

% State explicitly that no edge, node, or region tag represents a curved wire.
tags.omissions.curved_wire_arcs.present = false;
tags.omissions.curved_wire_arcs.representation = params.modeling.wireRepresentation;
end

function tag = select_all_edges(mesh, side)
% SELECT_ALL_EDGES Convert an entire named mesh boundary to a tag structure.
edgeIds = (1:size(mesh.boundaryEdges.(side), 1)).';
tag = tag_from_ids(mesh, side, edgeIds);
end

function tag = select_x_range(mesh, side, xRange, tol)
% SELECT_X_RANGE Select boundary edges whose midpoints lie in a closed x range.
edges = mesh.boundaryEdges.(side);
xMid = 0.5 * (mesh.nodes(edges(:, 1), 1) + mesh.nodes(edges(:, 2), 1));
mask = xMid >= xRange(1) - tol & xMid <= xRange(2) + tol;
tag = tag_from_ids(mesh, side, find(mask));
tag.requestedXRange = xRange;
end

function tag = union_tags(mesh, side, varargin)
% UNION_TAGS Form a duplicate-free union of edge IDs from compatible tags.
edgeIds = zeros(0, 1);
for k = 1:numel(varargin)
    edgeIds = [edgeIds; varargin{k}.edgeIds(:)]; %#ok<AGROW>
end
tag = tag_from_ids(mesh, side, unique(edgeIds));
end

function tag = tag_from_ids(mesh, side, edgeIds)
% TAG_FROM_IDS Build edge, node, midpoint, and analytical-length metadata.
edgeIds = unique(edgeIds(:));
allEdges = mesh.boundaryEdges.(side);
edges = allEdges(edgeIds, :);

% Empty tags remain valid and carry zero length and zero nodes.
if isempty(edges)
    nodeIds = zeros(0, 1);
    midpoints = zeros(0, 2);
    totalLength = 0;
else
    nodeIds = unique(edges(:));
    p1 = mesh.nodes(edges(:, 1), :);
    p2 = mesh.nodes(edges(:, 2), :);
    midpoints = 0.5 * (p1 + p2);
    totalLength = sum(sqrt(sum((p2 - p1).^2, 2)));
end

tag.side = side;
tag.edgeIds = edgeIds;
tag.edges = edges;
tag.nodeIds = nodeIds;
tag.midpoints = midpoints;
tag.length = totalLength;
end
