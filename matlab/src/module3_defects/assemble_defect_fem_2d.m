function fem = assemble_defect_fem_2d(mesh, physics)
% ASSEMBLE_DEFECT_FEM_2D Assemble Module 3 FEM matrices.
%
% Builds the semi-discrete system
%   M dC/dt + (Kdiff + Kreac) C = f
% for a scalar diffusion-reaction equation with optional nodal fields D,
% kAnn, and source.

nodes = mesh.nodes;
elems = mesh.elems;
numNodes = size(nodes,1);
numElems = size(elems,1);

Dnodal = scalar_or_nodal_field(physics.D, numNodes, 'D');
kNodal = scalar_or_nodal_field(physics.kAnn, numNodes, 'kAnn');
Snode = scalar_or_nodal_field(getfield_default(physics, 'source', 0.0), numNodes, 'source');

I = zeros(9*numElems,1);
J = zeros(9*numElems,1);
VM = zeros(9*numElems,1);
VK = zeros(9*numElems,1);
VR = zeros(9*numElems,1);
f = zeros(numNodes,1);
areas = zeros(numElems,1);
centroids = zeros(numElems,2);

idx = 0;
for e = 1:numElems
    enodes = elems(e,:);
    xe = nodes(enodes,:);
    Dbar = mean(Dnodal(enodes));
    kbar = mean(kNodal(enodes));
    Slocal = Snode(enodes);

    [Kde, area, gradN] = compute_element_diffusion_triangle(xe, Dbar); %#ok<ASGLU>
    Me = compute_element_mass_triangle(area);
    Kre = kbar * Me;
    fe = Me * Slocal(:);

    areas(e) = area;
    centroids(e,:) = mean(xe, 1);

    for a = 1:3
        A = enodes(a);
        f(A) = f(A) + fe(a);
        for b = 1:3
            idx = idx + 1;
            I(idx) = A;
            J(idx) = enodes(b);
            VM(idx) = Me(a,b);
            VK(idx) = Kde(a,b);
            VR(idx) = Kre(a,b);
        end
    end
end

M = sparse(I, J, VM, numNodes, numNodes);
Kdiff = sparse(I, J, VK, numNodes, numNodes);
Kreact = sparse(I, J, VR, numNodes, numNodes);

fem.M = M;
fem.Kdiff = Kdiff;
fem.Kreact = Kreact;
fem.Ktotal = Kdiff + Kreact;
fem.f = f;
fem.areas = areas;
fem.centroids = centroids;
fem.Dnodal = Dnodal;
fem.kNodal = kNodal;
fem.sourceNodal = Snode;
end

function out = scalar_or_nodal_field(value, n, name)
if isscalar(value)
    out = value * ones(n, 1);
else
    out = value(:);
    if numel(out) ~= n
        error('%s must be scalar or have one value per mesh node.', name);
    end
end
end

function value = getfield_default(s, fieldName, defaultValue)
if isfield(s, fieldName)
    value = s.(fieldName);
else
    value = defaultValue;
end
end
