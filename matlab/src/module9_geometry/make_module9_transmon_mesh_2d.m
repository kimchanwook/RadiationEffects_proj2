function mesh = make_module9_transmon_mesh_2d(params)
% MAKE_MODULE9_TRANSMON_MESH_2D Build the substrate-only nonuniform mesh.
%
%   mesh = MAKE_MODULE9_TRANSMON_MESH_2D(params) creates a structured set of
%   nodes in (x,z), then divides every quadrilateral into two counter-clockwise
%   linear triangles.  Every Module 9 feature endpoint is inserted exactly in
%   the x-coordinate vector so boundary tags have their analytical lengths.

% Permit direct use of the function without manually constructing parameters.
if nargin < 1 || isempty(params)
    params = default_module9_transmon_geometry_2d();
end

% Gather every x-coordinate that defines a surface feature or domain edge.
xAnchors = [ ...
    params.domain.xRange, ...
    params.regions.leftBondPad.xRange, ...
    params.regions.leftPad.xRange, ...
    params.regions.leftLead.xRange, ...
    params.reference.padGap.xRange, ...
    params.regions.jj.xRange, ...
    params.regions.rightLead.xRange, ...
    params.regions.rightPad.xRange, ...
    params.regions.normalTrap.xRange, ...
    params.regions.backsideSink.xRange, ...
    params.regions.rightBondPad.xRange];

% Remove duplicates and order the anchors from the left chip edge to the right.
xAnchors = unique(xAnchors(:).');

% Fill each anchor interval using a location-dependent target spacing.
x = xAnchors(1);
for k = 1:(numel(xAnchors) - 1)
    xLeft = xAnchors(k);
    xRight = xAnchors(k + 1);
    xMid = 0.5 * (xLeft + xRight);

    % Resolve the central pad-gap/lead/JJ neighborhood most finely.
    if abs(xMid) <= 0.060e-3
        targetDx = params.mesh.centralDx;
    % Refine intervals that intersect the trap, bond pads, or central pads.
    elseif interval_intersects([xLeft, xRight], params.regions.normalTrap.xRange) || ...
            interval_intersects([xLeft, xRight], params.regions.leftBondPad.xRange) || ...
            interval_intersects([xLeft, xRight], params.regions.rightBondPad.xRange) || ...
            abs(xMid) <= 0.700e-3
        targetDx = params.mesh.featureDx;
    else
        targetDx = params.mesh.bulkDx;
    end

    % Ceil guarantees that no generated interval exceeds the target spacing.
    nIntervals = max(1, ceil((xRight - xLeft) / targetDx));
    xLocal = linspace(xLeft, xRight, nIntervals + 1);

    % Skip the first local value because it is already the last value in x.
    x = [x, xLocal(2:end)]; %#ok<AGROW>
end

% Refine the substrate in z near the top metal stack and at the bottom sink.
zBreaks = unique([ ...
    params.domain.zRange(1), ...
    params.domain.zRange(1) + params.mesh.surfaceRefinementDepth, ...
    -params.mesh.surfaceRefinementDepth, ...
    params.domain.zRange(2)]);

% Fill the z intervals, using finer layers near either physical surface.
z = zBreaks(1);
for k = 1:(numel(zBreaks) - 1)
    zBottom = zBreaks(k);
    zTop = zBreaks(k + 1);
    nearBottom = zTop <= ...
        params.domain.zRange(1) + params.mesh.surfaceRefinementDepth;
    nearTop = zBottom >= -params.mesh.surfaceRefinementDepth;
    if nearBottom || nearTop
        targetDz = params.mesh.surfaceDz;
    else
        targetDz = params.mesh.bulkDz;
    end
    nIntervals = max(1, ceil((zTop - zBottom) / targetDz));
    zLocal = linspace(zBottom, zTop, nIntervals + 1);
    z = [z, zLocal(2:end)]; %#ok<AGROW>
end

% Create nodes with z varying fastest, matching the existing Module 2 layout.
[X, Z] = meshgrid(x, z);
nodes = [X(:), Z(:)];
nx = numel(x);
nz = numel(z);

% Allocate exactly two triangles per structured quadrilateral cell.
elems = zeros(2 * (nx - 1) * (nz - 1), 3);
elementIndex = 0;
for ix = 1:(nx - 1)
    for iz = 1:(nz - 1)
        n1 = sub2ind([nz, nx], iz, ix);
        n2 = sub2ind([nz, nx], iz, ix + 1);
        n3 = sub2ind([nz, nx], iz + 1, ix + 1);
        n4 = sub2ind([nz, nx], iz + 1, ix);

        % Alternate the diagonal direction to reduce a global directional bias.
        if params.mesh.alternateCellDiagonals && mod(ix + iz, 2) == 1
            elementIndex = elementIndex + 1;
            elems(elementIndex, :) = [n1, n2, n4];
            elementIndex = elementIndex + 1;
            elems(elementIndex, :) = [n2, n3, n4];
        else
            elementIndex = elementIndex + 1;
            elems(elementIndex, :) = [n1, n2, n3];
            elementIndex = elementIndex + 1;
            elems(elementIndex, :) = [n1, n3, n4];
        end
    end
end

% Store boundary-node sets in increasing physical coordinate order.
leftNodes = (1:nz).';
rightNodes = ((nx - 1) * nz + (1:nz)).';
bottomNodes = (1:nz:(nx - 1) * nz + 1).';
topNodes = (nz:nz:nx * nz).';

% Store explicit boundary edges so later solvers can integrate segmented flux,
% Robin, or electrode conditions along named pieces of a chip surface.
boundaryEdges.left = [leftNodes(1:end-1), leftNodes(2:end)];
boundaryEdges.right = [rightNodes(1:end-1), rightNodes(2:end)];
boundaryEdges.bottom = [bottomNodes(1:end-1), bottomNodes(2:end)];
boundaryEdges.top = [topNodes(1:end-1), topNodes(2:end)];

% Return both the general FEM arrays and structured-coordinate metadata.
mesh.nodes = nodes;
mesh.elems = elems;
mesh.x = x;
mesh.z = z;
mesh.y = z;  % Compatibility alias for existing generic 2D FEM utilities.
mesh.nx = nx;
mesh.nz = nz;
mesh.ny = nz;
mesh.Lx = params.domain.width;
mesh.Lz = params.domain.thickness;
mesh.Ly = params.domain.thickness;
mesh.origin = [params.domain.xRange(1), params.domain.zRange(1)];
mesh.boundary.left = leftNodes;
mesh.boundary.right = rightNodes;
mesh.boundary.bottom = bottomNodes;
mesh.boundary.top = topNodes;
mesh.boundaryEdges = boundaryEdges;
mesh.description = 'Nonuniform triangular mesh of the Module 9 substrate bulk domain.';
end

function tf = interval_intersects(intervalA, intervalB)
% INTERVAL_INTERSECTS Return true when two closed one-dimensional ranges overlap.
tf = max(intervalA(1), intervalB(1)) <= min(intervalA(2), intervalB(2));
end
