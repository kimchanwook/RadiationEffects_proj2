function test_module9_geometry_tags_2d()
% TEST_MODULE9_GEOMETRY_TAGS_2D Verify mesh anchors and boundary-tag lengths.
setup_project_paths;
geom = build_module9_transmon_geometry_2d();
mesh = geom.mesh;
tags = geom.tags;
regions = geom.regions;
tol = 1e-12;

% Confirm the full validator succeeds before inspecting individual tag values.
report = validate_module9_transmon_geometry_2d(geom, true);
assert(report.passed, 'Module 9 aggregate geometry validation did not pass.');

% Verify analytical lengths of the primary top and bottom surface tags.
assert(abs(tags.top.left_pad.length - regions.leftPad.length) <= tol, ...
    'Left-pad tag length is incorrect.');
assert(abs(tags.top.right_pad.length - regions.rightPad.length) <= tol, ...
    'Right-pad tag length is incorrect.');
assert(abs(tags.top.left_lead.length - regions.leftLead.length) <= tol, ...
    'Left-lead tag length is incorrect.');
assert(abs(tags.top.jj_sensitive.length - regions.jj.length) <= tol, ...
    'JJ tag length is incorrect.');
assert(abs(tags.top.right_lead.length - regions.rightLead.length) <= tol, ...
    'Right-lead tag length is incorrect.');
assert(abs(tags.top.normal_trap.length - regions.normalTrap.length) <= tol, ...
    'Normal-trap tag length is incorrect.');
assert(abs(tags.top.left_bond_pad.length - regions.leftBondPad.length) <= tol, ...
    'Left-bond-pad tag length is incorrect.');
assert(abs(tags.top.right_bond_pad.length - regions.rightBondPad.length) <= tol, ...
    'Right-bond-pad tag length is incorrect.');
assert(abs(tags.bottom.backside_sink.length - regions.backsideSink.length) <= tol, ...
    'Backside-sink tag length is incorrect.');

% Verify every top tag lies on z=0 and the sink lies on z=-0.5 mm.
topNames = fieldnames(tags.top);
for k = 1:numel(topNames)
    nodeIds = tags.top.(topNames{k}).nodeIds;
    assert(all(abs(mesh.nodes(nodeIds, 2)) <= tol), ...
        'A top-surface tag contains a node away from z=0.');
end
sinkNodes = tags.bottom.backside_sink.nodeIds;
assert(all(abs(mesh.nodes(sinkNodes, 2) - geom.domain.zRange(1)) <= tol), ...
    'Backside-sink tag contains a node away from the bottom surface.');

% Verify the central gap window is retained as a reference while its centerline
% is fully covered by the connected lead/JJ chain.
assert(abs(tags.reference.pad_gap_window.length - 60e-6) <= tol, ...
    'Pad-gap reference-window tag length is incorrect.');
assert(tags.reference.exposed_pad_gap.length == 0, ...
    'Centerline pad-gap window should be covered by lead/JJ metal.');

fprintf('test_module9_geometry_tags_2d passed: %d checks validated.\n', ...
    report.nChecks);
end
