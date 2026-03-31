function Cnew = step_defect_diffusion_reaction_2d(C, gridData, physics, dt)

L = laplacian_2d_neumann(C, gridData.dx, gridData.dy);

diffusionTerm = physics.D * L;
reactionTerm  = -physics.kAnn * C;

Cnew = C + dt * (diffusionTerm + reactionTerm);

% Optional safety clamp for small numerical negatives
Cnew(Cnew < 0) = 0;
end
