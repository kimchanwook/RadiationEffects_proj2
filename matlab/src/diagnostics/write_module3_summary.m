function write_module3_summary(params, metrics, tHistory, massHistory, cmaxHistory, l2ErrorHistory, outPath)
% WRITE_MODULE3_SUMMARY Write a plain-text verification summary.
[fid, msg] = fopen(outPath, 'w');
if fid < 0
    error('Could not open summary file for writing: %s (%s)', outPath, msg);
end
cleanupObj = onCleanup(@() fclose(fid)); %#ok<NASGU>

fprintf(fid, 'Module 3 2D verification / diagnostic summary\n');
fprintf(fid, '===========================================\n\n');
fprintf(fid, 'Case: %s\n', metrics.caseName);
fprintf(fid, 'Verification type: %s\n', metrics.verificationType);
fprintf(fid, 'Output directory: %s\n\n', metrics.outputDir);

fprintf(fid, 'Physics parameters\n');
fprintf(fid, '------------------\n');
fprintf(fid, 'D               = %.8e\n', params.physics.D);
fprintf(fid, 'kAnn            = %.8e\n', params.physics.kAnn);
fprintf(fid, 'dt              = %.8e\n', params.time.dt);
fprintf(fid, 'tEnd            = %.8e\n', params.time.tEnd);
fprintf(fid, 'Nx, Ny          = %d, %d\n', params.domain.Nx, params.domain.Ny);
fprintf(fid, 'dt stable est.  = %.8e\n', params.numerics.explicitDtStableEstimate);
fprintf(fid, 'stable?         = %d\n\n', params.numerics.isExplicitDiffusionStable);

fprintf(fid, 'Global metrics\n');
fprintf(fid, '--------------\n');
fprintf(fid, 'Initial mass          = %.12e\n', metrics.initialMass);
fprintf(fid, 'Final mass            = %.12e\n', metrics.finalMass);
fprintf(fid, 'Expected final mass   = %.12e\n', metrics.expectedFinalMass);
fprintf(fid, 'Final abs mass error  = %.12e\n', metrics.finalMassErrorAbs);
fprintf(fid, 'Final rel mass error  = %.12e\n', metrics.finalMassErrorRel);
fprintf(fid, 'Relative mass change  = %.12e\n', metrics.relativeMassChange);
fprintf(fid, 'Initial Cmax          = %.12e\n', metrics.cmaxInitial);
fprintf(fid, 'Final Cmax            = %.12e\n', metrics.cmaxFinal);
fprintf(fid, 'Final L2 error        = %.12e\n\n', metrics.finalL2Error);

fprintf(fid, 'Time-history endpoints\n');
fprintf(fid, '----------------------\n');
fprintf(fid, 'First time    = %.12e\n', tHistory(1));
fprintf(fid, 'Last time     = %.12e\n', tHistory(end));
fprintf(fid, 'First mass    = %.12e\n', massHistory(1));
fprintf(fid, 'Last mass     = %.12e\n', massHistory(end));
fprintf(fid, 'First Cmax    = %.12e\n', cmaxHistory(1));
fprintf(fid, 'Last Cmax     = %.12e\n', cmaxHistory(end));
if all(isnan(l2ErrorHistory))
    fprintf(fid, 'L2 history    = not applicable\n');
else
    fprintf(fid, 'First L2 err  = %.12e\n', l2ErrorHistory(find(~isnan(l2ErrorHistory), 1, 'first')));
    fprintf(fid, 'Last L2 err   = %.12e\n', l2ErrorHistory(find(~isnan(l2ErrorHistory), 1, 'last')));
end
end
