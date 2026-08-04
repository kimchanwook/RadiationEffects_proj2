function test_module2_transmon_boundary_guards_2d()
% TEST_MODULE2_TRANSMON_BOUNDARY_GUARDS_2D Verify tag/voltage failures stop.
setup_project_paths;
geometry = build_module9_transmon_geometry_2d();
params = default_module2_params('transmon_laplace');
[mesh, geometry, params] = resolve_module2_mesh_2d(params);

% A misspelled or absent tag must not silently fall back to a chip side.
badTagParams = params;
badTagParams.bc.named.right_electrode.tagName = 'missing_electrode';
caughtUnknownTag = false;
try
    get_module2_dirichlet_nodes(mesh, badTagParams, geometry);
catch ME
    caughtUnknownTag = strcmp(ME.identifier, ...
        'Module2Electrostatics:UnknownBoundaryTag');
end
assert(caughtUnknownTag, ...
    'An unknown named boundary tag did not raise the expected error.');

% Applying a second, different voltage to the left electrode must be rejected.
conflictParams = params;
conflictParams.bc.named.left_duplicate.type = 'dirichlet';
conflictParams.bc.named.left_duplicate.value = 2.0e-3;
conflictParams.bc.named.left_duplicate.tagGroup = 'electrode';
conflictParams.bc.named.left_duplicate.tagName = 'left_electrode';
caughtConflict = false;
try
    get_module2_dirichlet_nodes(mesh, conflictParams, geometry);
catch ME
    caughtConflict = strcmp(ME.identifier, ...
        'Module2Electrostatics:ConflictingDirichletValues');
end
assert(caughtConflict, ...
    'Conflicting voltages on one electrode did not raise the expected error.');

fprintf(['test_module2_transmon_boundary_guards_2d passed: ', ...
    'unknown and conflicting tags rejected.\n']);
end
