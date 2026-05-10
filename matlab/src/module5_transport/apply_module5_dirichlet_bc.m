function [Amod, rhsmod] = apply_module5_dirichlet_bc(A, rhs, bcNodes, bcValues)
% APPLY_MODULE5_DIRICHLET_BC Strongly impose nodal Dirichlet values.

Amod = A;
rhsmod = rhs;
for k = 1:numel(bcNodes)
    i = bcNodes(k);
    Amod(i,:) = 0;
    Amod(i,i) = 1;
    rhsmod(i) = bcValues(k);
end
end
