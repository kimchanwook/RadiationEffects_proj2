function [Ke, area, gradN] = compute_element_stiffness_triangle(xe, epsValue)
% COMPUTE_ELEMENT_STIFFNESS_TRIANGLE Linear triangular Poisson stiffness.
%
%   [Ke, area, gradN] = COMPUTE_ELEMENT_STIFFNESS_TRIANGLE(xe, epsValue)
%   computes the element matrix
%       Ke_ab = integral_A epsValue * grad(N_a) dot grad(N_b) dA
%   for a three-node linear triangle. xe is 3-by-2 and stores [x,y] node
%   coordinates. gradN is 3-by-2, one row per shape-function gradient.

x1 = xe(1,1); y1 = xe(1,2);
x2 = xe(2,1); y2 = xe(2,2);
x3 = xe(3,1); y3 = xe(3,2);

twoA = det([1, x1, y1; 1, x2, y2; 1, x3, y3]);
area = 0.5 * twoA;
if area <= 0
    error('Triangle has non-positive area. Check element orientation.');
end

b = [y2 - y3; y3 - y1; y1 - y2];
c = [x3 - x2; x1 - x3; x2 - x1];
gradN = [b, c] ./ (2*area);
Ke = epsValue * area * (gradN * gradN.');
end
