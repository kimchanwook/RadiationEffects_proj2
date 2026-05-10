function out = main_module5_fem_drift_diffusion(caseName)
% MAIN_MODULE5_FEM_DRIFT_DIFFUSION Compatibility wrapper for Module 5 FEM.
if nargin < 1
    caseName = 'gaussian_diffusion';
end
out = main_module5_drift_diffusion(caseName);
end
