function [mesh, geometry, params] = resolve_module2_mesh_2d(params)
% RESOLVE_MODULE2_MESH_2D Select the legacy rectangle or Module 9 mesh.
%
%   [mesh,geometry,params] = RESOLVE_MODULE2_MESH_2D(params) preserves the
%   original structured rectangular workflow by default.  When
%   params.geometryMode is 'module9_transmon', it either consumes the exact
%   prebuilt geometry in params.module9Geometry or builds the documented
%   Module 9 baseline.  The returned params are synchronized to the selected
%   substrate material and domain.

if ~isfield(params, 'geometryMode') || isempty(params.geometryMode)
    params.geometryMode = 'rectangle';
end

switch lower(char(params.geometryMode))
    case {'rectangle', 'legacy_rectangle'}
        mesh = make_rectangular_tri_mesh_2d( ...
            params.Lx, params.Ly, params.nx, params.ny);
        geometry = [];
        params.geometryMode = 'rectangle';
        params.coordinateNames = {'x', 'y'};

    case {'module9_transmon', 'transmon'}
        if isfield(params, 'module9Geometry') && ...
                ~isempty(params.module9Geometry)
            geometry = params.module9Geometry;
        else
            geometry = build_module9_transmon_geometry_2d();
        end

        % Reject incomplete or stale geometry objects before assembling any
        % physics.  The aggregate validator also checks tag lengths and mesh
        % orientation.
        requiredFields = {'mesh', 'tags', 'domain', 'materials', 'params'};
        for k = 1:numel(requiredFields)
            if ~isfield(geometry, requiredFields{k})
                error('Module2Electrostatics:InvalidModule9Geometry', ...
                    'Module 9 geometry is missing field "%s".', ...
                    requiredFields{k});
            end
        end
        geometry.validation = ...
            validate_module9_transmon_geometry_2d(geometry, true);

        mesh = geometry.mesh;
        params.geometryMode = 'module9_transmon';
        params.coordinateNames = {'x', 'z'};
        params.Lx = geometry.domain.width;
        params.Ly = geometry.domain.thickness;
        params.nx = mesh.nx;
        params.ny = mesh.ny;
        params.eps_rel_si = ...
            geometry.materials.substrate.relativePermittivity;
        params.eps_si = params.eps_rel_si * params.eps0;
        params.substrateMaterial = geometry.materials.substrate.key;

    otherwise
        error('Module2Electrostatics:UnknownGeometryMode', ...
            'Unknown Module 2 geometryMode: %s', params.geometryMode);
end
end
