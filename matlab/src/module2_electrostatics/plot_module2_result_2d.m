function plot_module2_result_2d(result, outputDir)
% PLOT_MODULE2_RESULT_2D Save Module 2 fields with optional Module 9 overlays.

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile('outputs', 'module2_2d');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

mesh = result.mesh;
nodes = mesh.nodes;
elems = mesh.elems;
phi = result.phi;
rho = result.rho;
Emag = result.field.Emag_nodal;
caseName = result.params.caseName;
[coordinateScale, xLabelText, yLabelText] = plot_coordinates(result);
xPlot = nodes(:,1) * coordinateScale;
yPlot = nodes(:,2) * coordinateScale;

fig = figure('Visible','off');
trisurf(elems, xPlot, yPlot, phi, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 potential: ', strrep(caseName, '_', '\_')]);
xlabel(xLabelText); ylabel(yLabelText);
overlay_module9_electrodes(result, coordinateScale);
saveas(fig, fullfile(outputDir, [caseName, '_potential.png']));
close(fig);

fig = figure('Visible','off');
trisurf(elems, xPlot, yPlot, rho, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 space charge: ', strrep(caseName, '_', '\_')]);
xlabel(xLabelText); ylabel(yLabelText);
overlay_module9_electrodes(result, coordinateScale);
saveas(fig, fullfile(outputDir, [caseName, '_space_charge.png']));
close(fig);

fig = figure('Visible','off');
trisurf(elems, xPlot, yPlot, Emag, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 electric-field magnitude: ', strrep(caseName, '_', '\_')]);
xlabel(xLabelText); ylabel(yLabelText);
overlay_module9_electrodes(result, coordinateScale);
saveas(fig, fullfile(outputDir, [caseName, '_electric_field_magnitude.png']));
close(fig);
end

function [scale, xText, yText] = plot_coordinates(result)
% PLOT_COORDINATES Use millimetres and x-z labels for the chip geometry.
if strcmpi(result.params.geometryMode, 'module9_transmon')
    scale = 1e3;
    xText = 'x [mm]';
    yText = 'z [mm]';
else
    scale = 1.0;
    xText = 'x [m]';
    yText = 'y [m]';
end
end

function overlay_module9_electrodes(result, coordinateScale)
% OVERLAY_MODULE9_ELECTRODES Draw solver-facing tags on transmon field plots.
if isempty(result.geometry) || ~isfield(result.geometry, 'tags')
    return;
end
hold on;
draw_tag(result.mesh, ...
    result.geometry.tags.electrode.left_electrode, coordinateScale, ...
    [0.10, 0.35, 0.95], 2.5);
draw_tag(result.mesh, ...
    result.geometry.tags.electrode.right_electrode, coordinateScale, ...
    [0.90, 0.20, 0.15], 2.5);
draw_tag(result.mesh, ...
    result.geometry.tags.top.jj_sensitive, coordinateScale, ...
    [0.75, 0.10, 0.75], 4.0);
hold off;
end

function draw_tag(mesh, tag, coordinateScale, colorValue, lineWidth)
% DRAW_TAG Draw boundary-edge segments without release-sensitive APIs.
for k = 1:size(tag.edges, 1)
    edge = tag.edges(k, :);
    points = mesh.nodes(edge, :) * coordinateScale;
    plot(points(:, 1), points(:, 2), '-', ...
        'Color', colorValue, 'LineWidth', lineWidth);
end
end
