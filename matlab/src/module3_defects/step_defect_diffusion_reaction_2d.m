function Cnew = step_defect_diffusion_reaction_2d(C, gridData, physics, dt)
% STEP_DEFECT_DIFFUSION_REACTION_2D
% Advance the Module 3 defect field by one explicit time step.
%
% Supports both:
%   1. legacy constant coefficients using physics.D and physics.kAnn
%   2. material-aware reduced coefficients through
%      physics.kineticsModel.enabled = true

coeffs = compute_defect_kinetics_coefficients(gridData, physics);

if isscalar(coeffs.D) && isscalar(coeffs.kAnn)
    L = laplacian_2d_neumann(C, gridData.dx, gridData.dy);
    diffusionTerm = coeffs.D .* L;
else
    diffusionTerm = laplacian_2d_neumann_variable_D(C, coeffs.D, gridData.dx, gridData.dy);
end

reactionTerm = -coeffs.kAnn .* C;
Cnew = C + dt .* (diffusionTerm + reactionTerm);

% Optional safety clamp for small numerical negatives.
Cnew(Cnew < 0) = 0;
end
