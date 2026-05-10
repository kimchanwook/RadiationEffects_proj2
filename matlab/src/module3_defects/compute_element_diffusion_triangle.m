function [Ke, area, gradN] = compute_element_diffusion_triangle(xe, Dvalue)
% COMPUTE_ELEMENT_DIFFUSION_TRIANGLE Linear triangular diffusion matrix.
%
% Ke_ab = integral_A D grad(N_a).grad(N_b) dA.

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
Ke = Dvalue * area * (gradN * gradN.');
end
