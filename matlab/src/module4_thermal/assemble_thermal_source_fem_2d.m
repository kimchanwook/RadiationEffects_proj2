function F = assemble_thermal_source_fem_2d(mesh, Snode)
% ASSEMBLE_THERMAL_SOURCE_FEM_2D Assemble source load vector for Module 4.
%
% Snode is the nodal source density [W/m^3] entering the weak form:
%   F_i = integral N_i S dA.
% The source may include volumetric heating Q, the tau*dQ/dt correction,
% and the reduced ballistic source contribution -div(q_b).

nodes = mesh.nodes;
elems = mesh.elems;
numNodes = size(nodes, 1);
F = zeros(numNodes, 1);
Snode = Snode(:);

if numel(Snode) ~= numNodes
    error('Snode must have one value per mesh node.');
end

for e = 1:size(elems,1)
    enodes = elems(e,:);
    xe = nodes(enodes,:);
    [~, area] = compute_element_conductivity_triangle(xe, 1.0);
    Me_unit = area / 12.0 * [2 1 1; 1 2 1; 1 1 2];
    fe = Me_unit * Snode(enodes);
    F(enodes) = F(enodes) + fe;
end
end
