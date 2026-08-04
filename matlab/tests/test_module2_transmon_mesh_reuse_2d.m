function test_module2_transmon_mesh_reuse_2d()
% TEST_MODULE2_TRANSMON_MESH_REUSE_2D Verify exact prebuilt-mesh injection.
setup_project_paths;
sharedGeometry = build_module9_transmon_geometry_2d();
params = default_module2_params('transmon_laplace');
params.module9Geometry = sharedGeometry;
params.makePlots = false;
params.saveMat = false;
result = solve_poisson_defect_space_charge_2d(params);

assert(isequal(result.mesh.nodes, sharedGeometry.mesh.nodes), ...
    'Module 2 changed the supplied Module 9 node coordinates.');
assert(isequal(result.mesh.elems, sharedGeometry.mesh.elems), ...
    'Module 2 changed the supplied Module 9 element connectivity.');
assert(isequal(result.geometry.tags.electrode.left_electrode.edgeIds, ...
    sharedGeometry.tags.electrode.left_electrode.edgeIds), ...
    'Module 2 changed the supplied left-electrode tag.');
assert(isequal(result.geometry.tags.electrode.right_electrode.edgeIds, ...
    sharedGeometry.tags.electrode.right_electrode.edgeIds), ...
    'Module 2 changed the supplied right-electrode tag.');

fprintf(['test_module2_transmon_mesh_reuse_2d passed: ', ...
    '%d nodes reused exactly.\n'], size(result.mesh.nodes, 1));
end
