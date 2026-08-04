function rhs = assemble_poisson_source_rhs_2d(mesh, rho, elementAreas)
% ASSEMBLE_POISSON_SOURCE_RHS_2D Assemble only the Poisson source vector.
%
%   rhs = ASSEMBLE_POISSON_SOURCE_RHS_2D(mesh,rho,elementAreas) reuses the
%   element areas computed during the one-time stiffness assembly. This is
%   the inexpensive per-configuration operation in the batch FEM pipeline.

numNodes = size(mesh.nodes, 1);
numElems = size(mesh.elems, 1);

if numel(rho) ~= numNodes
    error('Module2BatchFEM:InvalidRhoSize', ...
        'rho must contain one value for each mesh node.');
end
if numel(elementAreas) ~= numElems
    error('Module2BatchFEM:InvalidAreaSize', ...
        'elementAreas must contain one value for each triangle.');
end

rho = rho(:);
rhs = zeros(numNodes, 1);
for e = 1:numElems
    enodes = mesh.elems(e, :);
    fe = compute_element_source_triangle(elementAreas(e), rho(enodes));
    rhs(enodes) = rhs(enodes) + fe;
end
end
