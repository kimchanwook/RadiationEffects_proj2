function plot_module3_fem_result_2d(out, outputDir)
% PLOT_MODULE3_FEM_RESULT_2D Save basic FEM concentration plots.

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile('outputs', 'module3_fem_2d');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

mesh = out.mesh;
nodes = mesh.nodes;
elems = mesh.elems;
caseName = out.params.caseName;

fig = figure('Visible','off');
trisurf(elems, nodes(:,1), nodes(:,2), out.Cinitial, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 3 FEM initial C: ', strrep(caseName, '_', '\_')]);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fullfile(outputDir, [caseName '_fem_initial_concentration.png']));
close(fig);

fig = figure('Visible','off');
trisurf(elems, nodes(:,1), nodes(:,2), out.Cfinal, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 3 FEM final C: ', strrep(caseName, '_', '\_')]);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fullfile(outputDir, [caseName '_fem_final_concentration.png']));
close(fig);

fig = figure('Visible','off');
plot(out.tHistory, out.inventoryHistory, 'LineWidth', 1.5);
grid on;
xlabel('time [s]'); ylabel('FEM inventory integral');
title(['Module 3 FEM inventory: ', strrep(caseName, '_', '\_')]);
saveas(fig, fullfile(outputDir, [caseName '_fem_inventory_history.png']));
close(fig);
end
