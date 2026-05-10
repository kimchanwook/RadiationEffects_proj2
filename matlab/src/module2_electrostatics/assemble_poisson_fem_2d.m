function [K, rhs, elementData] = assemble_poisson_fem_2d(mesh, rho, epsValue)
% ASSEMBLE_POISSON_FEM_2D Assemble global FEM system for Module 2.
%
%   [K, rhs, elementData] = ASSEMBLE_POISSON_FEM_2D(mesh,rho,epsValue)
%   builds the linear system
%       K * phi = rhs
%   from the weak form of div(eps grad phi) = -rho:
%       integral eps grad(w).grad(phi) dA = integral w rho dA
%   with homogeneous natural Neumann conditions unless explicit boundary
%   terms are added elsewhere.

nodes = mesh.nodes;
elems = mesh.elems;
numNodes = size(nodes,1);
numElems = size(elems,1);

I = zeros(9*numElems,1);
J = zeros(9*numElems,1);
V = zeros(9*numElems,1);
rhs = zeros(numNodes,1);
areas = zeros(numElems,1);
centroids = zeros(numElems,2);

idx = 0;
for e = 1:numElems
    enodes = elems(e,:);
    xe = nodes(enodes,:);
    rhoe = rho(enodes);

    [Ke, area] = compute_element_stiffness_triangle(xe, epsValue);
    fe = compute_element_source_triangle(area, rhoe);

    areas(e) = area;
    centroids(e,:) = mean(xe, 1);

    for a = 1:3
        A = enodes(a);
        rhs(A) = rhs(A) + fe(a);
        for b = 1:3
            idx = idx + 1;
            I(idx) = A;
            J(idx) = enodes(b);
            V(idx) = Ke(a,b);
        end
    end
end

K = sparse(I, J, V, numNodes, numNodes);

elementData.areas = areas;
elementData.centroids = centroids;
end
