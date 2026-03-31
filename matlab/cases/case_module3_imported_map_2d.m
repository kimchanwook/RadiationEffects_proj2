function params = case_module3_imported_map_2d()
params.domain.xmin = 0.0;
params.domain.xmax = 1.0;
params.domain.ymin = 0.0;
params.domain.ymax = 1.0;
params.domain.Nx   = 101;
params.domain.Ny   = 101;

params.physics.D = 5e-4;
params.physics.kAnn = 1.0;

params.time.dt   = 1e-4;
params.time.tEnd = 1e-2;

params.init.sourceType = 'geant4_csv';
params.init.csvPath = fullfile('geant4', 'output_example', 'sample_damage_map_2d.csv');
params.init.xColumn = 'x';
params.init.yColumn = 'y';
params.init.valueColumn = 'damage';
params.init.scaleFactor = 1.0;
params.init.fillValue = 0.0;

params.io.saveEvery     = 20;
params.io.writeMatFile  = true;
params.io.outputDir     = fullfile('matlab', 'outputs', 'module3_2d', 'imported_map');

params.verification.type = 'diagnostic_only';
end
