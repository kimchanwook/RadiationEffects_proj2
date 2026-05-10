function write_module6_fem_summary(out, filename)
% WRITE_MODULE6_FEM_SUMMARY Write scalar diagnostics for Module 6.

fid = fopen(filename, 'w');
if fid < 0
    error('Could not open summary file: %s', filename);
end
c = onCleanup(@() fclose(fid));

m = out.metrics;
fprintf(fid, 'Module 6 coupled FEM summary\n');
fprintf(fid, '============================\n\n');
fprintf(fid, 'Case name: %s\n', m.caseName);
fprintf(fid, 'Final time [s]: %.6e\n', m.finalTime);
fprintf(fid, 'Final coupling metric: %.6e\n', m.finalCouplingMetric);
fprintf(fid, 'Final iteration count: %d\n', m.finalIterationCount);
fprintf(fid, 'Final charge mismatch diagnostic: %.6e\n', m.finalChargeMismatch);
fprintf(fid, 'Max defect concentration [m^-3]: %.6e\n', m.maxDefect);
fprintf(fid, 'Max temperature [K]: %.6e\n', m.maxTemperature);
fprintf(fid, 'Min temperature [K]: %.6e\n', m.minTemperature);
fprintf(fid, 'Potential range [V]: %.6e to %.6e\n', m.minPotential, m.maxPotential);
fprintf(fid, 'Max electric field [V/m]: %.6e\n', m.maxElectricField);
fprintf(fid, 'Max electron density [m^-3]: %.6e\n', m.maxElectronDensity);
fprintf(fid, 'Max hole density [m^-3]: %.6e\n', m.maxHoleDensity);
fprintf(fid, 'Max total current density [A/m^2]: %.6e\n', m.maxTotalCurrentDensity);
fprintf(fid, 'Final defect inventory [m^-1 for 2D unit-depth model]: %.6e\n', m.finalDefectInventory);
fprintf(fid, 'Final electron inventory [m^-1 for 2D unit-depth model]: %.6e\n', m.finalElectronInventory);
fprintf(fid, 'Final hole inventory [m^-1 for 2D unit-depth model]: %.6e\n', m.finalHoleInventory);
end
