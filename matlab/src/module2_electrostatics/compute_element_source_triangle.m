function fe = compute_element_source_triangle(area, rhoe)
% COMPUTE_ELEMENT_SOURCE_TRIANGLE Consistent source vector for linear triangle.
%
%   fe_a = integral_A N_a * rho dA, where rho is linearly interpolated from
%   its three nodal values rhoe.

Mlin = (area/12) * [2 1 1; 1 2 1; 1 1 2];
fe = Mlin * rhoe(:);
end
