function test_module3_imported_map_2d()
setup_project_paths();
out = main_module3_2d_defect_evolution('imported_map');

assert(all(size(out.Cfinal) == [out.grid.Ny, out.grid.Nx]), ...
    'Imported-map case should return a field with the solver-grid shape.');
assert(all(isfinite(out.Cfinal), 'all'), ...
    'Imported-map case should produce finite concentrations.');

disp('Imported Geant4-map 2D diagnostic test passed.');
end
