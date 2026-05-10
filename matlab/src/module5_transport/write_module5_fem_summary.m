function write_module5_fem_summary(params, metrics, outputPath)
% WRITE_MODULE5_FEM_SUMMARY Write a text summary of a Module 5 FEM run.

fid = fopen(outputPath, 'w');
if fid < 0
    error('Could not open summary file: %s', outputPath);
end
cleanup = onCleanup(@() fclose(fid));

fprintf(fid, 'Module 5 FEM drift-diffusion summary\n');
fprintf(fid, '====================================\n\n');
fprintf(fid, 'Case: %s\n', params.caseName);
fprintf(fid, 'Domain: Lx = %.6e m, Ly = %.6e m\n', params.domain.Lx, params.domain.Ly);
fprintf(fid, 'Mesh: nx = %d, ny = %d\n', params.domain.nx, params.domain.ny);
fprintf(fid, 'Time step: dt = %.6e s, steps = %d\n', params.time.dt, params.time.numSteps);
fprintf(fid, 'Electric field: type = %s, Ex = %.6e V/m, Ey = %.6e V/m\n', params.field.type, params.field.Ex, params.field.Ey);
fprintf(fid, 'Recombination: %s\n', params.recombination.type);
fprintf(fid, 'Source: %s\n\n', params.source.type);

fprintf(fid, 'Initial electron inventory = %.12e m^-1\n', metrics.initialElectronInventory);
fprintf(fid, 'Final electron inventory   = %.12e m^-1\n', metrics.finalElectronInventory);
fprintf(fid, 'Electron inventory change  = %.12e m^-1\n', metrics.electronInventoryChange);
fprintf(fid, 'Initial hole inventory     = %.12e m^-1\n', metrics.initialHoleInventory);
fprintf(fid, 'Final hole inventory       = %.12e m^-1\n', metrics.finalHoleInventory);
fprintf(fid, 'Hole inventory change      = %.12e m^-1\n\n', metrics.holeInventoryChange);

fprintf(fid, 'Initial max n = %.12e m^-3\n', metrics.nMaxInitial);
fprintf(fid, 'Final max n   = %.12e m^-3\n', metrics.nMaxFinal);
fprintf(fid, 'Initial max p = %.12e m^-3\n', metrics.pMaxInitial);
fprintf(fid, 'Final max p   = %.12e m^-3\n\n', metrics.pMaxFinal);

fprintf(fid, 'Max |Jn|      = %.12e A/m^2\n', metrics.maxAbsJn);
fprintf(fid, 'Max |Jp|      = %.12e A/m^2\n', metrics.maxAbsJp);
fprintf(fid, 'Max |Jtotal|  = %.12e A/m^2\n\n', metrics.maxAbsJtotal);

fprintf(fid, 'Verification type = %s\n', metrics.verificationType);
fprintf(fid, 'Final L2 error    = %.12e\n', metrics.finalL2Error);
end
