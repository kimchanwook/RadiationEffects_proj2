function test_module3_fem_uniform_state_2d()
% TEST_MODULE3_FEM_UNIFORM_STATE_2D Verify diffusion preserves a uniform field.

setup_project_paths();
params = default_module3_fem_params('uniform_state');
params.io.makePlots = false;
params.io.writeMatFile = false;
out = solve_defect_diffusion_reaction_fem_2d(params);

relSpread = (max(out.Cfinal) - min(out.Cfinal)) / max(abs(mean(out.Cinitial)), eps);
if relSpread > 1e-10
    error('Uniform FEM state not preserved. Relative spread = %.3e', relSpread);
end
if abs(out.metrics.relativeInventoryChange) > 1e-10
    error('Uniform FEM inventory changed. Relative change = %.3e', out.metrics.relativeInventoryChange);
end
fprintf('test_module3_fem_uniform_state_2d passed. Relative spread = %.3e\n', relSpread);
end
