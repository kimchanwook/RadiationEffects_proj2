function Me = compute_element_mass_triangle(area)
% COMPUTE_ELEMENT_MASS_TRIANGLE Consistent mass matrix for a T3 element.
%
% Me_ab = integral_A N_a N_b dA for a three-node linear triangle.

Me = (area/12.0) * [2 1 1; 1 2 1; 1 1 2];
end
