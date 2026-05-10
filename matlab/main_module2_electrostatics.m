function result = main_module2_electrostatics(caseName)
% MAIN_MODULE2_ELECTROSTATICS Run Module 2 2D FEM electrostatics.
%
%   result = MAIN_MODULE2_ELECTROSTATICS(caseName) solves the electrostatic
%   Poisson problem with defect-dependent space charge using linear triangular
%   finite elements. If caseName is omitted, the localized charged-defect case
%   is used.
%
%   Example:
%       setup_project_paths
%       result = main_module2_electrostatics('localized_defect_charge');

if nargin < 1 || isempty(caseName)
    caseName = 'localized_defect_charge';
end

params = default_module2_params(caseName);
result = solve_poisson_defect_space_charge_2d(params);

outputDir = fullfile(fileparts(mfilename('fullpath')), params.outputDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

if params.saveMat
    save(fullfile(outputDir, [params.caseName, '_results.mat']), 'result');
end

if params.makePlots
    plot_module2_result_2d(result, outputDir);
end
write_module2_summary(result, outputDir);

fprintf('Module 2 case "%s" complete.\n', params.caseName);
fprintf('  nodes      : %d\n', size(result.mesh.nodes,1));
fprintf('  triangles  : %d\n', size(result.mesh.elems,1));
fprintf('  phi range  : [%.4e, %.4e] V\n', min(result.phi), max(result.phi));
fprintf('  max |E|    : %.4e V/m\n', result.maxAbsE);
fprintf('  output dir : %s\n', outputDir);
end
