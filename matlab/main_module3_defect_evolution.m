function main_module3_defect_evolution(varargin)
% MAIN_MODULE3_DEFECT_EVOLUTION
% Compatibility wrapper that forwards to the new 2D Module 3 driver.

if nargin == 0
    main_module3_2d_defect_evolution('gaussian_diffusion');
else
    main_module3_2d_defect_evolution(varargin{:});
end
end
