function write_module3_fem_summary(out, outputDir)
% WRITE_MODULE3_FEM_SUMMARY Write a text summary of a Module 3 FEM run.

if nargin < 2 || isempty(outputDir)
    outputDir = fullfile('outputs', 'module3_fem_2d');
end
if ~exist(outputDir, 'dir')
    mkdir(outputDir);
end

p = out.params;
fname = fullfile(outputDir, [p.caseName '_fem_summary.txt']);
fid = fopen(fname, 'w');
if fid < 0
    error('Could not open summary file: %s', fname);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Module 3 defect diffusion-reaction FEM summary\n');
fprintf(fid, '================================================\n');
fprintf(fid, 'Case: %s\n', p.caseName);
fprintf(fid, 'Domain: Lx = %.6e m, Ly = %.6e m\n', p.domain.Lx, p.domain.Ly);
fprintf(fid, 'Mesh: nx = %d, ny = %d, nodes = %d, triangles = %d\n', ...
    p.domain.nx, p.domain.ny, size(out.mesh.nodes,1), size(out.mesh.elems,1));
fprintf(fid, 'D = %.6e m^2/s\n', p.physics.D);
fprintf(fid, 'kAnn = %.6e 1/s\n', p.physics.kAnn);
fprintf(fid, 'dt = %.6e s, tEnd = %.6e s\n', p.time.dt, p.time.tEnd);
fprintf(fid, 'Initial inventory = %.6e\n', out.metrics.initialInventory);
fprintf(fid, 'Final inventory = %.6e\n', out.metrics.finalInventory);
fprintf(fid, 'Expected final inventory = %.6e\n', out.metrics.expectedFinalInventory);
fprintf(fid, 'Relative inventory error/change = %.6e\n', out.metrics.finalInventoryErrorRel);
fprintf(fid, 'Initial max C = %.6e m^-3\n', out.metrics.cmaxInitial);
fprintf(fid, 'Final max C = %.6e m^-3\n', out.metrics.cmaxFinal);
fprintf(fid, 'Verification type = %s\n', out.metrics.verificationType);
fprintf(fid, 'Final relative L2 error = %.6e\n', out.metrics.finalL2Error);
fprintf(fid, 'Boundary model: homogeneous zero-flux natural unless Dirichlet nodes are supplied.\n');
end
