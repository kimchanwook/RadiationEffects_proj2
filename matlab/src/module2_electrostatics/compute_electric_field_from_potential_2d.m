function field = compute_electric_field_from_potential_2d(mesh, phi)
% COMPUTE_ELECTRIC_FIELD_FROM_POTENTIAL_2D Element and nodal electric fields.
%
%   field = COMPUTE_ELECTRIC_FIELD_FROM_POTENTIAL_2D(mesh,phi) computes the
%   elementwise constant electric field E=-grad(phi) for each linear triangle
%   and a nodal field obtained by area-weighted averaging of neighboring
%   element fields.

nodes = mesh.nodes;
elems = mesh.elems;
numElems = size(elems,1);
numNodes = size(nodes,1);

Eelem = zeros(numElems,2);
centroids = zeros(numElems,2);
areas = zeros(numElems,1);

EnodalSum = zeros(numNodes,2);
areaSum = zeros(numNodes,1);

for e = 1:numElems
    enodes = elems(e,:);
    xe = nodes(enodes,:);
    [~, area, gradN] = compute_element_stiffness_triangle(xe, 1.0);
    gradPhi = gradN.' * phi(enodes);
    E = -gradPhi(:).';

    Eelem(e,:) = E;
    centroids(e,:) = mean(xe,1);
    areas(e) = area;

    for a = 1:3
        node = enodes(a);
        EnodalSum(node,:) = EnodalSum(node,:) + area * E;
        areaSum(node) = areaSum(node) + area;
    end
end

Enodal = EnodalSum ./ max(areaSum, eps);

field.Eelem = Eelem;
field.Ex_elem = Eelem(:,1);
field.Ey_elem = Eelem(:,2);
field.centroids = centroids;
field.areas = areas;
field.Enodal = Enodal;
field.Ex_nodal = Enodal(:,1);
field.Ey_nodal = Enodal(:,2);
field.Emag_nodal = sqrt(sum(Enodal.^2, 2));
field.Emag_elem = sqrt(sum(Eelem.^2, 2));
end
