function plot_centerline_cuts_2d(gridData, Finitial, Ffinal, plotTitle, savePath)
ix = round((gridData.Nx + 1) / 2);
iy = round((gridData.Ny + 1) / 2);

figure('Visible', 'off');
plot(gridData.x, Finitial(iy, :), 'LineWidth', 1.5); hold on;
plot(gridData.x, Ffinal(iy, :), 'LineWidth', 1.5);
plot(gridData.y, Finitial(:, ix), '--', 'LineWidth', 1.5);
plot(gridData.y, Ffinal(:, ix), '--', 'LineWidth', 1.5);
grid on;
xlabel('Coordinate');
ylabel('Defect concentration');
title(plotTitle);
legend({'Initial y-centerline', 'Final y-centerline', 'Initial x-centerline', 'Final x-centerline'}, ...
    'Location', 'best');
if nargin >= 5 && ~isempty(savePath)
    exportgraphics(gcf, savePath, 'Resolution', 150);
end
close(gcf);
end
