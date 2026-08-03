function out = main_module9_transmon_geometry_2d(params)
% MAIN_MODULE9_TRANSMON_GEOMETRY_2D Build, verify, and plot Module 9 geometry.
%
%   out = MAIN_MODULE9_TRANSMON_GEOMETRY_2D() uses the documented baseline.
%   Pass an edited parameter structure to perform a controlled geometry study:
%
%       setup_project_paths
%       params = default_module9_transmon_geometry_2d();
%       params.visualization.figureVisible = 'on';
%       out = main_module9_transmon_geometry_2d(params);
%
%   This driver does not call or modify Modules 2-6 or the Module 2 PINN.

% Load the documented baseline unless the caller provides explicit parameters.
if nargin < 1 || isempty(params)
    params = default_module9_transmon_geometry_2d();
end

% Build the substrate mesh and all named thin-film/boundary tags.
geom = build_module9_transmon_geometry_2d(params);

% Stop before saving outputs if any geometry invariant is violated.
validate_module9_transmon_geometry_2d(geom, true);

% Resolve the output directory relative to this MATLAB project directory.
matlabDir = fileparts(mfilename('fullpath'));
outputDir = fullfile(matlabDir, params.outputDir);
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

% Predeclare figure handles so the output structure remains consistent.
geometryFigure = [];
meshTagsFigure = [];
geometryPng = fullfile(outputDir, 'module9_transmon_geometry_2d.png');
meshTagsPng = fullfile(outputDir, 'module9_transmon_mesh_tags_2d.png');

% Produce both the presentation schematic and the true solver/tag view.
if params.makePlots
    if params.saveFigures
        geometryFigure = plot_module9_transmon_geometry_2d(geom, geometryPng);
        meshTagsFigure = plot_module9_transmon_mesh_tags_2d(geom, meshTagsPng);
    else
        geometryFigure = plot_module9_transmon_geometry_2d(geom);
        meshTagsFigure = plot_module9_transmon_mesh_tags_2d(geom);
    end
end

% Save only geometry data, not MATLAB graphics handles.
matFile = fullfile(outputDir, 'module9_transmon_geometry_2d.mat');
if params.saveMat
    geometry = geom; %#ok<NASGU>
    save(matFile, 'geometry');
end

% Write a compact, human-readable verification and geometry summary.
summaryFile = fullfile(outputDir, 'module9_transmon_geometry_summary.txt');
if params.saveSummary
    write_module9_geometry_summary(summaryFile, geom);
end

% Return the full reusable geometry plus generated-file locations and figures.
out.geometry = geom;
out.figures.geometry = geometryFigure;
out.figures.meshTags = meshTagsFigure;
out.files.geometryPng = geometryPng;
out.files.meshTagsPng = meshTagsPng;
out.files.mat = matFile;
out.files.summary = summaryFile;
out.outputDir = outputDir;

% Print the most useful run diagnostics to the MATLAB command window.
fprintf('Module 9 reduced transmon geometry complete.\n');
fprintf('  nodes             : %d\n', size(geom.mesh.nodes, 1));
fprintf('  triangles         : %d\n', size(geom.mesh.elems, 1));
fprintf('  validation checks : %d/%d passed\n', ...
    geom.validation.nPassed, geom.validation.nChecks);
fprintf('  curved wire arcs  : omitted; use bond-pad boundary conditions\n');
fprintf('  output dir        : %s\n', outputDir);
end

function write_module9_geometry_summary(filename, geom)
% WRITE_MODULE9_GEOMETRY_SUMMARY Write geometry dimensions and test status.
fileId = fopen(filename, 'w');
if fileId < 0
    error('Module9Geometry:SummaryOpenFailed', ...
        'Could not open Module 9 summary file: %s', filename);
end
cleanupObject = onCleanup(@() fclose(fileId)); %#ok<NASGU>

params = geom.params;
fprintf(fileId, 'Module 9 reduced 2D transmon geometry summary\n');
fprintf(fileId, '================================================\n\n');
fprintf(fileId, 'Schema: %s\n', geom.schema);
fprintf(fileId, 'All stored geometry lengths use SI metres.\n\n');
fprintf(fileId, 'Substrate x range: [%.9g, %.9g] m\n', params.domain.xRange);
fprintf(fileId, 'Substrate z range: [%.9g, %.9g] m\n', params.domain.zRange);
fprintf(fileId, 'Substrate area: %.9g m^2 (1.5 mm^2)\n', params.domain.area);
fprintf(fileId, 'Al thickness: %.9g m\n', params.thickness.aluminum);
fprintf(fileId, 'Trap thickness: %.9g m\n', params.thickness.normalTrap);
fprintf(fileId, 'Backside-sink effective thickness: %.9g m\n\n', ...
    params.thickness.backsideSink);

regionNames = fieldnames(params.regions);
fprintf(fileId, 'Named regions and surface intervals\n');
for k = 1:numel(regionNames)
    region = params.regions.(regionNames{k});
    fprintf(fileId, ['- %-18s x=[%+.9g,%+.9g] m; z=[%+.9g,%+.9g] m; ', ...
        'side=%s; material=%s\n'], ...
        region.key, region.xRange(1), region.xRange(2), ...
        region.zRange(1), region.zRange(2), region.side, region.material);
end

fprintf(fileId, '\nMesh\n');
fprintf(fileId, '- nodes: %d\n', size(geom.mesh.nodes, 1));
fprintf(fileId, '- triangles: %d\n', size(geom.mesh.elems, 1));
fprintf(fileId, '- x coordinates: %d\n', numel(geom.mesh.x));
fprintf(fileId, '- z coordinates: %d\n', numel(geom.mesh.z));

fprintf(fileId, '\nValidation\n');
fprintf(fileId, '- passed: %s\n', logical_text(geom.validation.passed));
fprintf(fileId, '- checks: %d/%d passed\n', ...
    geom.validation.nPassed, geom.validation.nChecks);
for k = 1:numel(geom.validation.checks)
    check = geom.validation.checks(k);
    fprintf(fileId, '  [%s] %s\n', pass_label(check.passed), check.name);
end

fprintf(fileId, '\nModeling decisions\n');
fprintf(fileId, '- Substrate is the only bulk FEM domain.\n');
fprintf(fileId, '- Nanometre metal stacks are tagged surface segments.\n');
fprintf(fileId, '- JJ is a sensitive interface, not an imposed electrical short.\n');
fprintf(fileId, '- Curved bond-wire arcs are not meshed.\n');
fprintf(fileId, '- Wire effects enter later at left_bond_pad/right_bond_pad tags.\n');
end

function textValue = logical_text(value)
% LOGICAL_TEXT Convert a scalar logical to a readable word.
if value
    textValue = 'true';
else
    textValue = 'false';
end
end

function label = pass_label(value)
% PASS_LABEL Format a validation result for the text summary.
if value
    label = 'PASS';
else
    label = 'FAIL';
end
end
