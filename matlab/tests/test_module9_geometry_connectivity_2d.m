function test_module9_geometry_connectivity_2d()
% TEST_MODULE9_GEOMETRY_CONNECTIVITY_2D Verify the central metal topology.
setup_project_paths;
geom = build_module9_transmon_geometry_2d();
regions = geom.regions;
tol = 1e-12;

% The code-ready convention requires this exact connected interval path.
assert(touch_or_overlap(regions.leftPad.xRange, regions.leftLead.xRange, tol), ...
    'Left pad does not touch/overlap the left lead.');
assert(touch_or_overlap(regions.leftLead.xRange, regions.jj.xRange, tol), ...
    'Left lead does not terminate at the JJ-sensitive segment.');
assert(touch_or_overlap(regions.jj.xRange, regions.rightLead.xRange, tol), ...
    'Right lead does not begin at the JJ-sensitive segment.');
assert(touch_or_overlap(regions.rightLead.xRange, regions.rightPad.xRange, tol), ...
    'Right lead does not touch/overlap the right pad.');

% The normal trap must remain a right-pad-only overlay.
assert(regions.normalTrap.xRange(1) >= regions.rightPad.xRange(1) - tol && ...
    regions.normalTrap.xRange(2) <= regions.rightPad.xRange(2) + tol, ...
    'Normal trap is not fully contained on the right pad.');
assert(~touch_or_overlap(regions.normalTrap.xRange, ...
    regions.leftPad.xRange, tol), 'Normal trap bridges or touches the left pad.');

% The JJ remains an interface/scoring region rather than an electrode union.
assert(~isempty(strfind(geom.modeling.junctionBehavior, 'never an imposed short')), ...
    'JJ modeling metadata no longer protects electrode separation.'); %#ok<STREMP>
assert(isempty(intersect(geom.tags.electrode.left_electrode.edgeIds, ...
    geom.tags.electrode.right_electrode.edgeIds)), ...
    'Left and right electrode tags overlap and would create a numerical short.');

fprintf('test_module9_geometry_connectivity_2d passed.\n');
end

function tf = touch_or_overlap(rangeA, rangeB, tol)
% TOUCH_OR_OVERLAP Test closed one-dimensional interval connectivity.
tf = max(rangeA(1), rangeB(1)) <= min(rangeA(2), rangeB(2)) + tol;
end
