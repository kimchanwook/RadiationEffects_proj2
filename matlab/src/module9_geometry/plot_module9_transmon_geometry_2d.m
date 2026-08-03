function fig = plot_module9_transmon_geometry_2d(geom, outputFile)
% PLOT_MODULE9_TRANSMON_GEOMETRY_2D Draw a presentation-scale cross-section.
%
%   fig = PLOT_MODULE9_TRANSMON_GEOMETRY_2D(geom) opens an interactive MATLAB
%   figure.  Supplying outputFile also exports the figure as a PNG or PDF.
%   Film heights are exaggerated only in this view because the real 100 nm Al
%   layer is invisible next to the 0.5 mm substrate at a common scale.

if nargin < 2
    outputFile = '';
end

params = geom.params;
mm = 1e3;

% Create the requested interactive MATLAB figure.
fig = figure('Color', 'w', 'Visible', params.visualization.figureVisible, ...
    'Name', 'Module 9 reduced transmon geometry');
ax = axes(fig);
hold(ax, 'on');

% Draw the high-resistivity-silicon substrate at true x-z scale.
xDomain = params.domain.xRange * mm;
zDomain = params.domain.zRange * mm;
substrateHandle = patch(ax, ...
    [xDomain(1), xDomain(2), xDomain(2), xDomain(1)], ...
    [zDomain(1), zDomain(1), zDomain(2), zDomain(2)], ...
    [0.82, 0.86, 0.90], 'EdgeColor', [0.25, 0.28, 0.32], ...
    'LineWidth', 1.1, 'DisplayName', 'High-resistivity Si substrate');

% Convert visual-only display heights to millimetres.
alHeight = params.visualization.aluminumDisplayHeight * mm;
trapHeight = params.visualization.trapDisplayHeight * mm;
sinkHeight = params.visualization.sinkDisplayHeight * mm;

% Draw aluminum pad and lead tags with an exaggerated common display height.
alColor = [0.20, 0.55, 0.88];
padHandle = draw_top_rectangle(ax, params.regions.leftPad.xRange * mm, ...
    0, alHeight, alColor, 'Al pads and leads');
draw_top_rectangle(ax, params.regions.rightPad.xRange * mm, ...
    0, alHeight, alColor, '');
draw_top_rectangle(ax, params.regions.leftLead.xRange * mm, ...
    0, alHeight, alColor, '');
draw_top_rectangle(ax, params.regions.rightLead.xRange * mm, ...
    0, alHeight, alColor, '');

% Draw the two package-interface bond pads as separate aluminum features.
bondColor = [0.35, 0.36, 0.68];
bondHandle = draw_top_rectangle(ax, params.regions.leftBondPad.xRange * mm, ...
    0, alHeight, bondColor, 'Bond pads; wire arcs omitted');
draw_top_rectangle(ax, params.regions.rightBondPad.xRange * mm, ...
    0, alHeight, bondColor, '');

% Emphasize the effective JJ scoring/interface segment in red.
jjHandle = draw_top_rectangle(ax, params.regions.jj.xRange * mm, ...
    0, 1.25 * alHeight, [0.86, 0.18, 0.18], 'Effective JJ-sensitive region');

% Place the normal trap visually above its parent right-pad aluminum film.
trapHandle = draw_top_rectangle(ax, params.regions.normalTrap.xRange * mm, ...
    alHeight, trapHeight, [0.94, 0.57, 0.13], 'Normal-metal trap');

% Draw the bottom sink just below the substrate to keep it visually distinct.
sinkHandle = draw_bottom_rectangle(ax, params.regions.backsideSink.xRange * mm, ...
    zDomain(1), sinkHeight, [0.25, 0.72, 0.53], 'Backside thermal sink');

% Add labels only when requested by the geometry parameter structure.
if params.visualization.showLabels
    text(ax, -0.33, alHeight + 0.015, 'Left Al pad', ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
    text(ax, +0.33, alHeight + trapHeight + 0.015, 'Right Al pad + trap', ...
        'HorizontalAlignment', 'center', 'FontSize', 9);
    text(ax, 0, 1.25 * alHeight + 0.018, 'JJ', ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 9);
    text(ax, -1.44, alHeight + 0.012, 'Bond pad', ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
    text(ax, +1.44, alHeight + 0.012, 'Bond pad', ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
    text(ax, 0, zDomain(1) - sinkHeight - 0.014, 'Backside sink', ...
        'HorizontalAlignment', 'center', 'FontSize', 8);
end

% Use equal x-z scaling while leaving enough vertical room for schematic films.
axis(ax, 'equal');
xlim(ax, xDomain + [-0.05, +0.05]);
ylim(ax, [zDomain(1) - sinkHeight - 0.055, ...
    max(0.13, alHeight + trapHeight + 0.075)]);
grid(ax, 'on');
box(ax, 'on');
xlabel(ax, 'x (mm)');
ylabel(ax, 'z (mm)');
title(ax, {'Module 9 reduced 2D transmon cross-section', ...
    'Film thicknesses exaggerated for visibility; curved wire arcs not meshed'});
legend(ax, [substrateHandle, padHandle, jjHandle, trapHandle, ...
    sinkHandle, bondHandle], 'Location', 'southoutside', 'NumColumns', 3);

% Export without closing the figure so the user can still zoom and pan in MATLAB.
if ~isempty(outputFile)
    export_module9_figure(fig, outputFile, params.visualization.imageResolution);
end
end

function handle = draw_top_rectangle(ax, xRange, zBase, height, color, displayName)
% DRAW_TOP_RECTANGLE Draw one exaggerated top-surface thin-film rectangle.
handle = patch(ax, [xRange(1), xRange(2), xRange(2), xRange(1)], ...
    [zBase, zBase, zBase + height, zBase + height], color, ...
    'EdgeColor', 0.55 * color, 'LineWidth', 0.8, 'DisplayName', displayName);
if isempty(displayName)
    handle.HandleVisibility = 'off';
end
end

function handle = draw_bottom_rectangle(ax, xRange, zTop, height, color, displayName)
% DRAW_BOTTOM_RECTANGLE Draw one exaggerated bottom-surface sink rectangle.
handle = patch(ax, [xRange(1), xRange(2), xRange(2), xRange(1)], ...
    [zTop - height, zTop - height, zTop, zTop], color, ...
    'EdgeColor', 0.55 * color, 'LineWidth', 0.8, 'DisplayName', displayName);
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
