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
fprintf(fid, 'Geometry mode: %s\n', p.geometryMode);
xRange = [min(result.mesh.nodes(:,1)), max(result.mesh.nodes(:,1))];
yRange = [min(result.mesh.nodes(:,2)), max(result.mesh.nodes(:,2))];
fprintf(fid, 'Domain coordinate 1: [%.6e, %.6e] m\n', xRange);
fprintf(fid, 'Domain coordinate 2: [%.6e, %.6e] m\n', yRange);
fprintf(fid, 'Mesh: nx = %d, ny/nz = %d, nodes = %d, triangles = %d\n', ...
    result.mesh.nx, result.mesh.ny, ...
    size(result.mesh.nodes,1), size(result.mesh.elems,1));
fprintf(fid, 'eps_si = %.6e F/m\n', p.eps_si);
fprintf(fid, 'rho min/max = %.6e / %.6e C/m^3\n', min(result.rho), max(result.rho));
fprintf(fid, 'phi min/max = %.6e / %.6e V\n', min(result.phi), max(result.phi));
fprintf(fid, '|E| max = %.6e V/m\n', result.maxAbsE);
fprintf(fid, 'Dirichlet nodes: %d\n', numel(result.fixedNodes));
fprintf(fid, 'Free-node residual (relative): %.6e\n', ...
    result.diagnostics.freeResidualRelative);
fprintf(fid, 'Dirichlet error (infinity norm): %.6e V\n', ...
    result.diagnostics.dirichletErrorInf);
fprintf(fid, 'Global source/reaction balance (relative): %.6e\n', ...
    result.diagnostics.globalBalanceRelative);

if ~isempty(result.geometry)
    fprintf(fid, 'Module 9 schema: %s\n', result.geometry.schema);
    fprintf(fid, 'Substrate material: %s\n', ...
        result.geometry.materials.substrate.key);
    fprintf(fid, 'Named Dirichlet entries:\n');
    for k = 1:numel(result.bcInfo.entries)
        entry = result.bcInfo.entries(k);
        if strncmp(entry.source, 'tag.', 4)
            fprintf(fid, '  - %s: %.6e V on %d nodes\n', ...
                entry.source, entry.value, numel(entry.nodeIds));
        end
    end
    fprintf(fid, 'JJ treatment: scoring/interface tag; not a Dirichlet short.\n');
end
end
