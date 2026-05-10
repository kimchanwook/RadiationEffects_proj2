function write_module2_summary(result, outputDir)
% WRITE_MODULE2_SUMMARY Write a text summary of a Module 2 run.

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile('outputs', 'module2_2d');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

p = result.params;
fname = fullfile(outputDir, [p.caseName, '_summary.txt']);
fid = fopen(fname, 'w');
if fid < 0
    error('Could not open summary file: %s', fname);
end
cleanupObj = onCleanup(@() fclose(fid));

fprintf(fid, 'Module 2 electrostatics FEM summary\n');
fprintf(fid, '===================================\n');
fprintf(fid, 'Case: %s\n', p.caseName);
fprintf(fid, 'Domain: Lx = %.6e m, Ly = %.6e m\n', p.Lx, p.Ly);
fprintf(fid, 'Mesh: nx = %d, ny = %d, nodes = %d, triangles = %d\n', ...
    p.nx, p.ny, size(result.mesh.nodes,1), size(result.mesh.elems,1));
fprintf(fid, 'eps_si = %.6e F/m\n', p.eps_si);
fprintf(fid, 'rho min/max = %.6e / %.6e C/m^3\n', min(result.rho), max(result.rho));
fprintf(fid, 'phi min/max = %.6e / %.6e V\n', min(result.phi), max(result.phi));
fprintf(fid, '|E| max = %.6e V/m\n', result.maxAbsE);
fprintf(fid, 'Dirichlet nodes: %d\n', numel(result.fixedNodes));
end
