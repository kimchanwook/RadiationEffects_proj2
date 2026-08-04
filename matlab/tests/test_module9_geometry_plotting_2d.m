function test_module9_geometry_plotting_2d()
% TEST_MODULE9_GEOMETRY_PLOTTING_2D Smoke-test both Module 9 plot functions.
%
%   This regression test verifies that the presentation schematic and the
%   solver mesh/tag view can be constructed without a graphics API error. It
%   intentionally keeps both figures invisible and does not replace manual
%   visual inspection of the exported PNG files.

setup_project_paths;
params = default_module9_transmon_geometry_2d();
params.visualization.figureVisible = 'off';
geom = build_module9_transmon_geometry_2d(params);

% Test the presentation schematic first and guarantee cleanup on later error.
geometryFigure = plot_module9_transmon_geometry_2d(geom);
geometryCleanup = onCleanup(@() close_test_figure(geometryFigure)); %#ok<NASGU>
assert(ishandle(geometryFigure), ...
    'The Module 9 presentation plot did not return a valid figure handle.');

% This call exercises the solver mesh edge drawing that previously failed on
% MATLAB releases whose triplot function does not accept an axes-first call.
meshTagsFigure = plot_module9_transmon_mesh_tags_2d(geom);
meshTagsCleanup = onCleanup(@() close_test_figure(meshTagsFigure)); %#ok<NASGU>
assert(ishandle(meshTagsFigure), ...
    'The Module 9 mesh/tag plot did not return a valid figure handle.');
assert(~isempty(findobj(meshTagsFigure, 'Type', 'line')), ...
    'The Module 9 mesh/tag figure contains no line objects.');

fprintf('test_module9_geometry_plotting_2d passed.\n');
end

function close_test_figure(fig)
% CLOSE_TEST_FIGURE Close an invisible test figure when it still exists.
if ~isempty(fig) && ishandle(fig)
    close(fig);
end
end
