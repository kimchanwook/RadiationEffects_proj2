function [Ke, area, gradN] = compute_element_conductivity_triangle(xe, kValue)
% COMPUTE_ELEMENT_CONDUCTIVITY_TRIANGLE
% Element conductivity matrix for a linear triangular thermal element.
%
% The weak diffusion term is
%   integral_omegae k grad(N_i).grad(N_j) dA.
% For a three-node linear triangle the basis gradients are constant inside
% the element, so the integral reduces to k*area*(gradN*gradN').

x1 = xe(1,1); y1 = xe(1,2);
x2 = xe(2,1); y2 = xe(2,2);
x3 = xe(3,1); y3 = xe(3,2);

signedArea2 = (x2-x1)*(y3-y1) - (x3-x1)*(y2-y1);
area = 0.5 * signedArea2;
if area <= 0
    error('Triangle area must be positive. Check node ordering.');
end

b = [y2-y3; y3-y1; y1-y2];
c = [x3-x2; x1-x3; x2-x1];
gradN = [b c] ./ (2.0 * area);

Ke = kValue * area * (gradN * gradN.');
end
