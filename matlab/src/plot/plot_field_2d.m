function plot_field_2d(gridData, F, plotTitle, savePath)
figure('Visible', 'off');
imagesc(gridData.x, gridData.y, F);
axis image;
set(gca, 'YDir', 'normal');
xlabel('x');
ylabel('y');
title(plotTitle);
colorbar;
if nargin >= 4 && ~isempty(savePath)
    exportgraphics(gcf, savePath, 'Resolution', 150);
end
close(gcf);
end
