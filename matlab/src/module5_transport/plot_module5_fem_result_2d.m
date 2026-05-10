function plot_module5_fem_result_2d(mesh, field, plotTitle, outputPath)
% PLOT_MODULE5_FEM_RESULT_2D Plot a nodal triangular FEM scalar field.

fig = figure('Visible','off');
trisurf(mesh.elems, mesh.nodes(:,1), mesh.nodes(:,2), field, 'EdgeColor', 'none');
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
