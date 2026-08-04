function figureHandle = plot_module2_batch_fem_case_2d( ...
    dataset, caseIndex, outputDir)
% PLOT_MODULE2_BATCH_FEM_CASE_2D Save one explicitly selected audit figure.
%
%   This function is never called by the numerical generator. The top-level
%   driver calls it only when options.makeRepresentativePlots is true.

if caseIndex < 1 || caseIndex > dataset.nCases || caseIndex ~= round(caseIndex)
    error('Module2BatchFEM:InvalidPlotCase', ...
        'caseIndex must select one complete dataset configuration.');
end
if isempty(dataset.rho)
    error('Module2BatchFEM:RhoNotStored', ...
        'Representative charge plots require options.storeRho=true.');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

mesh = dataset.mesh;
mm = 1e3;
figureHandle = figure('Visible', 'off', 'Color', 'w', ...
    'Name', ['Batch FEM ', dataset.caseNames{caseIndex}]);

axRho = subplot(2, 1, 1, 'Parent', figureHandle);
draw_field(axRho, mesh, dataset.rho(:, caseIndex), mm);
title(axRho, ['Space charge: ', strrep(dataset.caseNames{caseIndex}, '_', '\_')]);
ylabel(axRho, 'z [mm]');
colorbar(axRho);

axPhi = subplot(2, 1, 2, 'Parent', figureHandle);
draw_field(axPhi, mesh, dataset.phi(:, caseIndex), mm);
overlay_solver_tags(axPhi, dataset, mm);
title(axPhi, 'FEM potential with solver-facing surface tags');
xlabel(axPhi, 'x [mm]');
ylabel(axPhi, 'z [mm]');
colorbar(axPhi);

fileName = [dataset.caseNames{caseIndex}, '_batch_fem_audit.png'];
saveas(figureHandle, fullfile(outputDir, fileName));
close(figureHandle);
figureHandle = [];
end

function draw_field(ax, mesh, values, mm)
patch('Parent', ax, 'Faces', double(mesh.elems), ...
    'Vertices', mesh.nodes * mm, 'FaceVertexCData', values, ...
    'FaceColor', 'interp', 'EdgeColor', 'none');
axis(ax, 'equal');
axis(ax, 'tight');
set(ax, 'YDir', 'normal');
box(ax, 'on');
end

function overlay_solver_tags(ax, dataset, mm)
hold(ax, 'on');
draw_tag(ax, dataset.mesh, ...
    dataset.tags.electrode.left_electrode, mm, [0.10, 0.35, 0.95], 2.0);
draw_tag(ax, dataset.mesh, ...
    dataset.tags.electrode.right_electrode, mm, [0.95, 0.25, 0.15], 2.0);
draw_tag(ax, dataset.mesh, ...
    dataset.tags.top.jj_sensitive, mm, [0.65, 0.10, 0.75], 3.0);
hold(ax, 'off');
end

function draw_tag(ax, mesh, tag, mm, colorValue, lineWidth)
edges = tag.edges;
for k = 1:size(edges, 1)
    points = mesh.nodes(edges(k, :), :) * mm;
    plot(ax, points(:, 1), points(:, 2), '-', ...
        'Color', colorValue, 'LineWidth', lineWidth);
end
end
