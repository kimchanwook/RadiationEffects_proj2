function setup_project_paths()
% SETUP_PROJECT_PATHS Add the relevant project folders to the MATLAB path.
thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);
addpath(thisDir);
addpath(fullfile(thisDir, 'cases'));
addpath(fullfile(thisDir, 'tests'));
addpath(fullfile(thisDir, 'pinn'));
addpath(genpath(fullfile(thisDir, 'src')));
end
