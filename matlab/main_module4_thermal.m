function out = main_module4_thermal(caseName)
% MAIN_MODULE4_THERMAL
% Convenience alias for the revised Module 4 ballistic-diffusive solver.

if nargin < 1
    caseName = 'localized_pulse';
end

out = main_module4_2d_ballistic_diffusive_thermal(caseName);
end
