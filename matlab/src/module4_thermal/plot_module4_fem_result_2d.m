function plot_module4_fem_result_2d(mesh, field, titleText, outPath)
% PLOT_MODULE4_FEM_RESULT_2D Plot nodal FEM field using trisurf.

figure('Visible','off');
trisurf(mesh.elems, mesh.nodes(:,1), mesh.nodes(:,2), field(:), 'EdgeColor', 'none');
view(2);
axis equal tight;
colorbar;
xlabel('x [m]');
ylabel('y [m]');
title(titleText, 'Interpreter', 'none');
set(gca, 'YDir', 'normal');
saveas(gcf, outPath);
close(gcf);
end
