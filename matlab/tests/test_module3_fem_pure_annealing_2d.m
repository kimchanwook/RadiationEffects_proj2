function test_module3_fem_pure_annealing_2d()
% TEST_MODULE3_FEM_PURE_ANNEALING_2D Verify uniform first-order decay.

setup_project_paths();
params = default_module3_fem_params('pure_annealing');
params.io.makePlots = false;
params.io.writeMatFile = false;
out = solve_defect_diffusion_reaction_fem_2d(params);

if out.metrics.finalL2Error > 5e-3
    error('Pure annealing FEM relative L2 error too large: %.3e', out.metrics.finalL2Error);
end
if abs(out.metrics.finalInventoryErrorRel) > 5e-3
    error('Pure annealing FEM inventory error too large: %.3e', out.metrics.finalInventoryErrorRel);
end
fprintf('test_module3_fem_pure_annealing_2d passed. Final relative L2 error = %.3e\n', out.metrics.finalL2Error);
end
