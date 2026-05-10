function fem = assemble_thermal_fem_2d(mesh, physics)
% ASSEMBLE_THERMAL_FEM_2D Assemble Module 4 FEM matrices.
%
% The semi-discrete thermal equation is
%   tau*M*Tddot + M*Tdot + K*T = F(t),
% where
%   M_ij = integral Cvol N_i N_j dA,
%   K_ij = integral k grad(N_i).grad(N_j) dA.
%
% Natural zero conductive-flux boundaries are included by default because
% the boundary integral vanishes when k*grad(T).n = 0.

nodes = mesh.nodes;
elems = mesh.elems;
numNodes = size(nodes, 1);
numElems = size(elems, 1);

Cnodal = scalar_or_nodal_field(physics.Cvol, numNodes, 'Cvol');
knodal = scalar_or_nodal_field(physics.k, numNodes, 'k');

I = zeros(9*numElems, 1);
J = zeros(9*numElems, 1);
VM = zeros(9*numElems, 1);
VK = zeros(9*numElems, 1);
areas = zeros(numElems, 1);
centroids = zeros(numElems, 2);

idx = 0;
for e = 1:numElems
    enodes = elems(e,:);
    xe = nodes(enodes,:);
    Cbar = mean(Cnodal(enodes));
    kbar = mean(knodal(enodes));

    [Ke, area, gradN] = compute_element_conductivity_triangle(xe, kbar); %#ok<ASGLU>
    Me = compute_element_heat_capacity_triangle(area, Cbar);

    areas(e) = area;
    centroids(e,:) = mean(xe, 1);

    for a = 1:3
        A = enodes(a);
        for b = 1:3
            idx = idx + 1;
            I(idx) = A;
            J(idx) = enodes(b);
            VM(idx) = Me(a,b);
            VK(idx) = Ke(a,b);
        end
    end
end

fem.M = sparse(I, J, VM, numNodes, numNodes);
fem.K = sparse(I, J, VK, numNodes, numNodes);
fem.areas = areas;
fem.centroids = centroids;
fem.Cnodal = Cnodal;
fem.knodal = knodal;
fem.numNodes = numNodes;
fem.numElems = numElems;
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
