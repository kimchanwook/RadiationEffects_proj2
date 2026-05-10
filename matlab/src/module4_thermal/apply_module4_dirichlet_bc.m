function [Amod, bmod] = apply_module4_dirichlet_bc(A, b, bcNodes, bcValues)
% APPLY_MODULE4_DIRICHLET_BC Strongly impose nodal temperature values.

Amod = A;
bmod = b;
if isempty(bcNodes)
    return;
end

bcNodes = bcNodes(:);
bcValues = bcValues(:);

bmod = bmod - Amod(:, bcNodes) * bcValues;
Amod(:, bcNodes) = 0;
Amod(bcNodes, :) = 0;
for i = 1:numel(bcNodes)
    n = bcNodes(i);
    Amod(n, n) = 1.0;
    bmod(n) = bcValues(i);
end
end
