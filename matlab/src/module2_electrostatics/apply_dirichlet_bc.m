function [Kmod, rhsmod] = apply_dirichlet_bc(K, rhs, fixedNodes, fixedValues)
% APPLY_DIRICHLET_BC Strongly impose nodal Dirichlet conditions.
%
%   [Kmod,rhsmod] = APPLY_DIRICHLET_BC(K,rhs,fixedNodes,fixedValues) modifies
%   K*phi=rhs so phi(fixedNodes)=fixedValues. fixedValues can be scalar or
%   the same length as fixedNodes.

fixedNodes = fixedNodes(:);
if isempty(fixedNodes)
    Kmod = K;
    rhsmod = rhs;
    return;
end

if isscalar(fixedValues)
    fixedValues = fixedValues * ones(size(fixedNodes));
else
    fixedValues = fixedValues(:);
end
if numel(fixedNodes) ~= numel(fixedValues)
    error('fixedNodes and fixedValues must have compatible sizes.');
end

% Remove duplicates while preserving the last supplied value for a node.
[fixedNodes, ia] = unique(fixedNodes, 'stable');
fixedValues = fixedValues(ia);

Kmod = K;
rhsmod = rhs;

% Account for known values before overwriting rows and columns.
rhsmod = rhsmod - Kmod(:, fixedNodes) * fixedValues;

Kmod(fixedNodes, :) = 0;
Kmod(:, fixedNodes) = 0;
for i = 1:numel(fixedNodes)
    node = fixedNodes(i);
    Kmod(node, node) = 1;
    rhsmod(node) = fixedValues(i);
end
end
