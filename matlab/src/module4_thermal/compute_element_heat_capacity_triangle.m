function Me = compute_element_heat_capacity_triangle(area, Cvol)
% COMPUTE_ELEMENT_HEAT_CAPACITY_TRIANGLE
% Consistent three-node triangular heat-capacity matrix.
%
% For a linear triangular element and constant volumetric heat capacity Cvol,
%   Me_ij = integral_omegae Cvol * N_i * N_j dA
%         = Cvol * area/12 * [2 1 1; 1 2 1; 1 1 2].

Me = Cvol * area / 12.0 * [2 1 1; 1 2 1; 1 1 2];
end
