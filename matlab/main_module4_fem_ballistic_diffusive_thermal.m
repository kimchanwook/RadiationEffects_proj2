function out = main_module4_fem_ballistic_diffusive_thermal(caseName)
% MAIN_MODULE4_FEM_BALLISTIC_DIFFUSIVE_THERMAL
% Driver for the linear triangular FEM version of Module 4.
%
% Supported cases:
%   'uniform_equilibrium'
%   'gaussian_diffusion'
%   'uniform_source'
%   'boundary_heating'
%
% Governing equation:
%   tau*C*T_tt + C*T_t - div(k grad T) = Q + tau*Q_t - div(q_b)
%
% FEM form:
%   tau*M*Tddot + M*Tdot + K*T = F(t)

if nargin < 1
    caseName = 'gaussian_diffusion';
end

setup_project_paths();

switch lower(caseName)
    case 'uniform_equilibrium'
        params = case_module4_fem_uniform_equilibrium_2d();
    case 'gaussian_diffusion'
        params = case_module4_fem_gaussian_diffusion_2d();
    case 'uniform_source'
        params = case_module4_fem_uniform_source_2d();
    case 'boundary_heating'
        params = case_module4_fem_boundary_heating_2d();
    otherwise
        error('Unknown Module 4 FEM caseName: %s', caseName);
end

params = finalize_module4_fem_params(params, caseName);
mesh = make_rectangular_tri_mesh_2d(params.domain.Lx, params.domain.Ly, params.domain.nx, params.domain.ny);
out = solve_ballistic_diffusive_thermal_fem_2d(mesh, params);

plot_module4_fem_result_2d(mesh, out.Tfinal, ...
    sprintf('Module 4 FEM final temperature: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_final_temperature.png']));
plot_module4_fem_result_2d(mesh, out.finalSource.Snode, ...
    sprintf('Module 4 FEM final source S: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_final_source.png']));
plot_module4_fem_result_2d(mesh, out.finalSource.ballistic.divqb, ...
    sprintf('Module 4 FEM final div(q_b): %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_final_ballistic_divergence.png']));

plot_module4_bd_history_metrics_2d(out.tHistory, out.energyHistory, out.tmaxHistory, ...
    out.rateNormHistory, out.qbmaxHistory, out.l2ErrorHistory, params, ...
    fullfile(params.io.outputDir, [caseName '_fem_history_metrics.png']));

write_module4_fem_summary(params, out.metrics, ...
    fullfile(params.io.outputDir, [caseName '_fem_summary.txt']));

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, [caseName '_fem_results.mat']), 'out');
end
end
