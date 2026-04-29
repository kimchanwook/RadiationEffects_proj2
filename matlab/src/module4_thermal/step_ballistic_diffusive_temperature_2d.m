function stepState = step_ballistic_diffusive_temperature_2d(T, dTdt, gridData, physics, boundary, sourceState, dt, t)
% STEP_BALLISTIC_DIFFUSIVE_TEMPERATURE_2D
% Advance the reduced 2D ballistic-diffusive thermal model by one explicit step.

[Q, dQdt] = evaluate_bd_source_term_2d(sourceState, t);
ballistic = compute_ballistic_flux_reduced_2d(gridData, t, physics, boundary);
L = laplacian_2d_neumann(T, gridData.dx, gridData.dy);
divqb = compute_flux_divergence_2d(ballistic.qbx, ballistic.qby, gridData.dx, gridData.dy);

rhs = physics.alpha .* L - divqb ./ physics.Cvol + (Q + physics.tau .* dQdt) ./ physics.Cvol;

if physics.tau <= eps
    dTdtNew = rhs;
    Tnew = T + dt .* dTdtNew;
else
    accel = (rhs - dTdt) ./ physics.tau;
    dTdtNew = dTdt + dt .* accel;
    Tnew = T + dt .* dTdtNew;
end

stepState = struct();
stepState.T = Tnew;
stepState.dTdt = dTdtNew;
stepState.ballistic = ballistic;
stepState.ballistic.divqb = divqb;
stepState.Q = Q;
stepState.dQdt = dQdt;
stepState.rhs = rhs;
end
