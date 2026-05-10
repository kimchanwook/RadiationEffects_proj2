function out = main_module6_multiphysics(caseName)
% MAIN_MODULE6_MULTIPHYSICS Run the Module 6 coupled FEM integration driver.
%
% Usage:
%   setup_project_paths
%   out = main_module6_multiphysics('smoke');
%   out = main_module6_multiphysics('defect_field_coupling');
%   out = main_module6_multiphysics('thermal_feedback');

if nargin < 1 || isempty(caseName)
    caseName = 'smoke';
end

params = default_module6_fem_params(caseName);
out = solve_coupled_multiphysics_fem_2d(params);

if ~exist(params.io.outputDir, 'dir')
    mkdir(params.io.outputDir);
end

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, 'module6_fem_results.mat'), 'out', '-v7.3');
end

write_module6_fem_summary(out, fullfile(params.io.outputDir, 'module6_fem_summary.txt'));
if params.io.makePlots
    plot_module6_fem_result_2d(out);
end

fprintf('Module 6 coupled FEM case %s complete.\n', params.caseName);
fprintf('  Final coupling metric: %.3e\n', out.metrics.finalCouplingMetric);
fprintf('  Max |E| [V/m]: %.3e\n', out.metrics.maxElectricField);
fprintf('  Max T [K]: %.3f\n', out.metrics.maxTemperature);
end
