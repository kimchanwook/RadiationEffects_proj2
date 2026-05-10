function out = main_module3_fem_defect_evolution(caseName)
% MAIN_MODULE3_FEM_DEFECT_EVOLUTION
% Driver for the Module 3 finite-element diffusion-reaction solver.
%
% Supported cases:
%   'gaussian_diffusion'
%   'pure_annealing'
%   'uniform_state'
%
% This is a FEM path parallel to main_module3_2d_defect_evolution.m. The
% existing structured-grid solver is retained; this driver demonstrates the
% linear-triangle FEM formulation documented in the Module 3 physics note.

if nargin < 1 || isempty(caseName)
    caseName = 'gaussian_diffusion';
end

setup_project_paths();
params = default_module3_fem_params(caseName);
out = solve_defect_diffusion_reaction_fem_2d(params);

if params.io.makePlots
    plot_module3_fem_result_2d(out, params.io.outputDir);
end
write_module3_fem_summary(out, params.io.outputDir);

if params.io.writeMatFile
    if ~exist(params.io.outputDir, 'dir')
        mkdir(params.io.outputDir);
    end
    save(fullfile(params.io.outputDir, [params.caseName '_fem_results.mat']), 'out');
end
end
