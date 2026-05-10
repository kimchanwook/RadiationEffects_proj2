function out = main_module5_drift_diffusion(caseName)
% MAIN_MODULE5_DRIFT_DIFFUSION
% Driver for the first linear triangular FEM Module 5 carrier solver.
%
% Supported cases:
%   'uniform_no_field'
%   'lifetime_recombination'
%   'gaussian_diffusion'
%   'field_drift'
%
% The first implementation solves reduced electron and hole drift-diffusion
% equations using known electrostatic, thermal, and defect fields.

if nargin < 1
    caseName = 'gaussian_diffusion';
end

setup_project_paths();

switch lower(caseName)
    case 'uniform_no_field'
        params = case_module5_fem_uniform_no_field_2d();
    case 'lifetime_recombination'
        params = case_module5_fem_lifetime_recombination_2d();
    case 'gaussian_diffusion'
        params = case_module5_fem_gaussian_diffusion_2d();
    case 'field_drift'
        params = case_module5_fem_field_drift_2d();
    otherwise
        error('Unknown Module 5 FEM caseName: %s', caseName);
end

params = finalize_module5_fem_params(params, caseName);
mesh = make_rectangular_tri_mesh_2d(params.domain.Lx, params.domain.Ly, params.domain.nx, params.domain.ny);
out = solve_drift_diffusion_carrier_fem_2d(mesh, params);

plot_module5_fem_result_2d(mesh, out.nFinal, ...
    sprintf('Module 5 FEM final electron density: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_final_electrons.png']));
plot_module5_fem_result_2d(mesh, out.pFinal, ...
    sprintf('Module 5 FEM final hole density: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_final_holes.png']));
plot_module5_fem_result_2d(mesh, out.coeffFinal.Cdef, ...
    sprintf('Module 5 FEM defect field: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_defect_field.png']));
plot_module5_fem_current_2d(mesh, out.current, ...
    sprintf('Module 5 FEM total current: %s', caseName), ...
    fullfile(params.io.outputDir, [caseName '_fem_total_current.png']));

write_module5_fem_summary(params, out.metrics, ...
    fullfile(params.io.outputDir, [caseName '_fem_summary.txt']));

if params.io.writeMatFile
    save(fullfile(params.io.outputDir, [caseName '_fem_results.mat']), 'out');
end
end
