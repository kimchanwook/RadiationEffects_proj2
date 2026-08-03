function geom = build_module9_transmon_geometry_2d(params)
% BUILD_MODULE9_TRANSMON_GEOMETRY_2D Assemble geometry, mesh, tags, and checks.
%
%   geom = BUILD_MODULE9_TRANSMON_GEOMETRY_2D() uses the baseline Module 9
%   specification.  Passing an edited params structure permits controlled
%   geometry studies without changing this function.

% Construct the documented baseline when no explicit parameter set is supplied.
if nargin < 1 || isempty(params)
    params = default_module9_transmon_geometry_2d();
end

% Build the substrate bulk mesh independently of every current physics solver.
mesh = make_module9_transmon_mesh_2d(params);

% Convert the physical thin-film and package features to named boundary tags.
tags = tag_module9_transmon_mesh_2d(mesh, params);

% Expose the requested reusable geometry fields at the top level.
geom.schema = params.schema;
geom.domain = params.domain;
geom.thickness = params.thickness;
geom.materials = params.materials;
geom.regions = params.regions;
geom.boundaries = params.boundaries;
geom.modeling = params.modeling;
geom.reference = params.reference;
geom.mesh = mesh;
geom.tags = tags;
geom.params = params;

% Run all non-destructive checks and attach their results for inspection.
geom.validation = validate_module9_transmon_geometry_2d(geom, false);
end
