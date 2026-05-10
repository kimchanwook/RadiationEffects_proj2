function plot_module6_fem_result_2d(out)
% PLOT_MODULE6_FEM_RESULT_2D Save basic Module 6 coupled field plots.

outDir = out.params.io.outputDir;
if ~exist(outDir, 'dir')
    mkdir(outDir);
end
mesh = out.mesh;
s = out.stateFinal;

plot_one(mesh, s.C, 'Final defect concentration C [m^{-3}]', fullfile(outDir, 'module6_fem_final_defects.png'));
plot_one(mesh, s.phi, 'Final electrostatic potential \phi [V]', fullfile(outDir, 'module6_fem_final_potential.png'));
plot_one(mesh, sqrt(sum(s.E.^2,2)), 'Final electric-field magnitude |E| [V/m]', fullfile(outDir, 'module6_fem_final_electric_field.png'));
plot_one(mesh, s.T, 'Final temperature T [K]', fullfile(outDir, 'module6_fem_final_temperature.png'));
plot_one(mesh, s.n, 'Final electron concentration n [m^{-3}]', fullfile(outDir, 'module6_fem_final_electrons.png'));
plot_one(mesh, s.p, 'Final hole concentration p [m^{-3}]', fullfile(outDir, 'module6_fem_final_holes.png'));

fig = figure('Visible','off');
semilogy(out.convergenceHistory.', 'LineWidth', 1.2);
grid on;
xlabel('Coupling iteration');
ylabel('Relative field-change metric');
title('Module 6 FEM coupling convergence by time step');
exportgraphics(fig, fullfile(outDir, 'module6_fem_coupling_convergence.png'));
close(fig);
end

function plot_one(mesh, field, titleText, filename)
fig = figure('Visible','off');
trisurf(mesh.elems, mesh.nodes(:,1), mesh.nodes(:,2), field, 'EdgeColor', 'none');
view(2);
axis equal tight;
colorbar;
xlabel('x [m]');
ylabel('y [m]');
title(titleText);
exportgraphics(fig, filename);
close(fig);
end
