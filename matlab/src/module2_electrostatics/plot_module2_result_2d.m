function plot_module2_result_2d(result, outputDir)
% PLOT_MODULE2_RESULT_2D Save basic Module 2 potential and field plots.

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

fig = figure('Visible','off');
trisurf(elems, nodes(:,1), nodes(:,2), phi, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 potential: ', strrep(caseName, '_', '\_')]);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fullfile(outputDir, [caseName, '_potential.png']));
close(fig);

fig = figure('Visible','off');
trisurf(elems, nodes(:,1), nodes(:,2), rho, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 space charge: ', strrep(caseName, '_', '\_')]);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fullfile(outputDir, [caseName, '_space_charge.png']));
close(fig);

fig = figure('Visible','off');
trisurf(elems, nodes(:,1), nodes(:,2), Emag, 'EdgeColor', 'none');
view(2); axis equal tight; colorbar;
title(['Module 2 electric-field magnitude: ', strrep(caseName, '_', '\_')]);
xlabel('x [m]'); ylabel('y [m]');
saveas(fig, fullfile(outputDir, [caseName, '_electric_field_magnitude.png']));
close(fig);
end
