function Tnew = step_heat_equation_2d(T, Q, gridData, physics, dt)
L = laplacian_2d_neumann(T, gridData.dx, gridData.dy);
alpha = physics.k / (physics.rho * physics.cp);
sourceTerm = Q / (physics.rho * physics.cp);
Tnew = T + dt * (alpha * L + sourceTerm);
end
