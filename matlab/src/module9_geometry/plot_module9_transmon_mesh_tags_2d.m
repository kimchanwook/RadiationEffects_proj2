function fig = plot_module9_transmon_mesh_tags_2d(geom, outputFile)
% PLOT_MODULE9_TRANSMON_MESH_TAGS_2D Show the true substrate mesh and tags.
%
%   This solver-oriented view does not create artificial thin-film domains.
%   Colored lines lie exactly on z=0 or z=-0.5 mm and identify the boundary
%   segments that later FEM modules will consume.

if nargin < 2
    outputFile = '';
end

params = geom.params;
mesh = geom.mesh;
tags = geom.tags;
mm = 1e3;

% Create a two-panel figure: full chip plus central pad/lead/JJ detail.
fig = figure('Color', 'w', 'Visible', params.visualization.figureVisible, ...
    'Name', 'Module 9 substrate mesh and boundary tags');
axFull = subplot(2, 1, 1, 'Parent', fig);
axZoom = subplot(2, 1, 2, 'Parent', fig);

% Draw the same true mesh in both panels.
draw_mesh(axFull, mesh, mm);
draw_mesh(axZoom, mesh, mm);

% Plot all package and transmon tags in the full-chip view.
hold(axFull, 'on');
hLeftPad = plot_tag(axFull, mesh, tags.top.left_pad, mm, ...
    [0.12, 0.45, 0.85], 3.0, 'Left electrode');
hRightPad = plot_tag(axFull, mesh, tags.top.right_pad, mm, ...
    [0.12, 0.67, 0.38], 3.0, 'Right electrode');
plot_tag(axFull, mesh, tags.top.left_lead, mm, [0.12, 0.45, 0.85], 3.0, '');
plot_tag(axFull, mesh, tags.top.right_lead, mm, [0.12, 0.67, 0.38], 3.0, '');
hJJ = plot_tag(axFull, mesh, tags.top.jj_sensitive, mm, ...
    [0.88, 0.12, 0.12], 5.0, 'JJ-sensitive segment');
hTrap = plot_tag(axFull, mesh, tags.top.normal_trap, mm, ...
    [0.95, 0.55, 0.08], 5.0, 'Normal trap overlay');
hBond = plot_tag(axFull, mesh, tags.top.left_bond_pad, mm, ...
    [0.47, 0.29, 0.70], 4.0, 'Bond pads');
plot_tag(axFull, mesh, tags.top.right_bond_pad, mm, [0.47, 0.29, 0.70], 4.0, '');
hSink = plot_tag(axFull, mesh, tags.bottom.backside_sink, mm, ...
    [0.00, 0.63, 0.68], 4.0, 'Backside sink');
axis(axFull, 'equal');
xlim(axFull, params.domain.xRange * mm);
ylim(axFull, params.domain.zRange * mm);
xlabel(axFull, 'x (mm)');
ylabel(axFull, 'z (mm)');
title(axFull, 'True-scale substrate mesh and boundary tags');
legend(axFull, [hLeftPad, hRightPad, hJJ, hTrap, hBond, hSink], ...
    'Location', 'eastoutside');

% Repeat the central device tags in a strong zoom that makes the 1 um JJ visible.
hold(axZoom, 'on');
plot_tag(axZoom, mesh, tags.top.left_pad, mm, [0.12, 0.45, 0.85], 4.0, '');
plot_tag(axZoom, mesh, tags.top.left_lead, mm, [0.12, 0.45, 0.85], 4.0, '');
plot_tag(axZoom, mesh, tags.top.right_pad, mm, [0.12, 0.67, 0.38], 4.0, '');
plot_tag(axZoom, mesh, tags.top.right_lead, mm, [0.12, 0.67, 0.38], 4.0, '');
plot_tag(axZoom, mesh, tags.top.jj_sensitive, mm, [0.88, 0.12, 0.12], 6.0, '');
plot_tag(axZoom, mesh, tags.top.normal_trap, mm, [0.95, 0.55, 0.08], 6.0, '');
axis(axZoom, 'equal');
xlim(axZoom, [-0.70, +0.70]);
ylim(axZoom, [-0.080, +0.008]);
xlabel(axZoom, 'x (mm)');
ylabel(axZoom, 'z (mm)');
title(axZoom, 'Central top-surface tag detail (all films remain zero-thickness mesh tags)');

% Add a figure-level title when supported by the installed MATLAB release.
if exist('sgtitle', 'file') == 2
    figure(fig);
    sgtitle('Module 9 FEM mesh and named surface segments');
end

% Export the diagnostic snapshot while leaving the interactive figure open.
if ~isempty(outputFile)
    export_module9_figure(fig, outputFile, params.visualization.imageResolution);
end
end

function draw_mesh(ax, mesh, mm)
% DRAW_MESH Plot all triangular edges in a low-contrast solver view.
meshHandle = triplot(ax, mesh.elems, mesh.nodes(:, 1) * mm, ...
    mesh.nodes(:, 2) * mm);
set(meshHandle, 'Color', [0.78, 0.80, 0.83], 'LineWidth', 0.35);
grid(ax, 'on');
box(ax, 'on');
end

function handle = plot_tag(ax, mesh, tag, mm, color, lineWidth, displayName)
% PLOT_TAG Draw a multi-edge tag as one NaN-separated MATLAB line object.
if isempty(tag.edges)
    handle = plot(ax, NaN, NaN, '-', 'Color', color, ...
        'LineWidth', lineWidth, 'DisplayName', displayName);
else
    p1 = mesh.nodes(tag.edges(:, 1), :) * mm;
    p2 = mesh.nodes(tag.edges(:, 2), :) * mm;
    xSegments = [p1(:, 1), p2(:, 1), nan(size(p1, 1), 1)].';
    zSegments = [p1(:, 2), p2(:, 2), nan(size(p1, 1), 1)].';
    handle = plot(ax, xSegments(:), zSegments(:), '-', ...
        'Color', color, 'LineWidth', lineWidth, 'DisplayName', displayName);
end
if isempty(displayName)
    handle.HandleVisibility = 'off';
end
end

function export_module9_figure(fig, outputFile, resolution)
% EXPORT_MODULE9_FIGURE Export using modern MATLAB or a compatible fallback.
[outputDir, ~, extension] = fileparts(outputFile);
if ~isempty(outputDir) && ~exist(outputDir, 'dir')
    mkdir(outputDir);
end
if exist('exportgraphics', 'file') == 2
    if strcmpi(extension, '.pdf')
        exportgraphics(fig, outputFile, 'ContentType', 'vector');
    else
        exportgraphics(fig, outputFile, 'Resolution', resolution);
    end
else
    if strcmpi(extension, '.pdf')
        print(fig, outputFile, '-dpdf', '-painters');
    else
        print(fig, outputFile, '-dpng', sprintf('-r%d', resolution));
    end
end
end
