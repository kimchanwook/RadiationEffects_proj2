function plot_module5_fem_current_2d(mesh, current, plotTitle, outputPath)
% PLOT_MODULE5_FEM_CURRENT_2D Plot total current vectors at element centers.

fig = figure('Visible','off');
mag = sqrt(sum(current.Jtotal.^2,2));
trisurf(mesh.elems, mesh.nodes(:,1), mesh.nodes(:,2), zeros(size(mesh.nodes,1),1), 'FaceAlpha', 0.05, 'EdgeColor', [0.8 0.8 0.8]);
hold on;
quiver(current.centers(:,1), current.centers(:,2), current.Jtotal(:,1), current.Jtotal(:,2));
scatter(current.centers(:,1), current.centers(:,2), 12, mag, 'filled');
view(2);
axis equal tight;
colorbar;
xlabel('x [m]');
ylabel('y [m]');
title(plotTitle, 'Interpreter', 'none');
set(gca, 'FontSize', 11);
if nargin >= 4 && ~isempty(outputPath)
    saveas(fig, outputPath);
end
close(fig);
end
