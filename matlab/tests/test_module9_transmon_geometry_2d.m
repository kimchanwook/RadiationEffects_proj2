function test_module9_transmon_geometry_2d()
% TEST_MODULE9_TRANSMON_GEOMETRY_2D Run the complete Module 9 geometry suite.
setup_project_paths;
test_module9_geometry_dimensions_2d;
test_module9_geometry_connectivity_2d;
test_module9_geometry_tags_2d;
test_module9_geometry_no_wire_arc_2d;
test_module9_geometry_plotting_2d;
fprintf('All Module 9 reduced-geometry tests passed.\n');
end
