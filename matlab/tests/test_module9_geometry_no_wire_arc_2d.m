function test_module9_geometry_no_wire_arc_2d()
% TEST_MODULE9_GEOMETRY_NO_WIRE_ARC_2D Enforce the reduced wiring decision.
setup_project_paths;
params = default_module9_transmon_geometry_2d();
geom = build_module9_transmon_geometry_2d(params);

% Curved bond wires must not exist as a bulk region, edge tag, or mesh object.
assert(~params.modeling.includeCurvedWireArcs, ...
    'Curved wire arcs were unexpectedly enabled in Module 9 parameters.');
assert(~geom.tags.omissions.curved_wire_arcs.present, ...
    'A curved-wire tag was unexpectedly added to the geometry.');
assert(~isfield(geom.regions, 'wireArc') && ~isfield(geom.regions, 'wireArcs'), ...
    'A curved wire-arc region exists in the reduced 2D geometry.');

% The on-chip bond pads must remain available as replacement BC locations.
assert(~isempty(geom.tags.top.left_bond_pad.edges), ...
    'Left bond-pad boundary tag is missing.');
assert(~isempty(geom.tags.top.right_bond_pad.edges), ...
    'Right bond-pad boundary tag is missing.');
assert(~isempty(strfind(params.modeling.wireRepresentation, 'Boundary')), ...
    'Wire replacement must be documented as a boundary/lumped effect.'); %#ok<STREMP>

fprintf('test_module9_geometry_no_wire_arc_2d passed.\n');
end
