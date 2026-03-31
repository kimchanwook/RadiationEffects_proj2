function setup_project_paths()
% SETUP_PROJECT_PATHS Add the relevant project folders to the MATLAB path.
thisFile = mfilename('fullpath');
thisDir = fileparts(thisFile);
addpath(thisDir);
addpath(fullfile(thisDir, 'cases'));
addpath(genpath(fullfile(thisDir, 'src')));
end
