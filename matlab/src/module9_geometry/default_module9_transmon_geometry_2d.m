function params = default_module9_transmon_geometry_2d()
% DEFAULT_MODULE9_TRANSMON_GEOMETRY_2D Define the reduced 2D transmon geometry.
%
%   params = DEFAULT_MODULE9_TRANSMON_GEOMETRY_2D() returns the complete,
%   code-ready Module 9 geometry specification in SI units.  The substrate is
%   the only two-dimensional bulk domain in the first implementation.  The
%   nanometre-scale metal stacks are retained as named top- or bottom-surface
%   regions with their physical thicknesses stored as metadata.
%
%   The coordinates follow Section 7 of the Module 9 physics note.  In
%   particular, the lead coordinates intentionally overlap the large pads by
%   10.5 micrometres so the pad-lead-JJ chain is topologically connected.

% Record a schema label so future geometry revisions can be distinguished.
params.schema = 'module9_transmon_geometry_2d_v1';

% Store every numerical geometry value in metres (SI), even though the plots
% display millimetres and micrometres for readability.
params.units.length = 'm';
params.units.plotLength = 'mm';

% Define the substrate cross-section: 3 mm wide and 0.5 mm thick.
params.domain.xRange = [-1.5e-3, +1.5e-3];
params.domain.zRange = [-0.5e-3, 0.0];
params.domain.width = diff(params.domain.xRange);
params.domain.thickness = diff(params.domain.zRange);
params.domain.area = params.domain.width * params.domain.thickness;
params.domain.coordinateNames = {'x', 'z'};

% Name the four outer substrate boundaries independently of any physics BC.
params.boundaries.left.coordinate = params.domain.xRange(1);
params.boundaries.right.coordinate = params.domain.xRange(2);
params.boundaries.bottom.coordinate = params.domain.zRange(1);
params.boundaries.top.coordinate = params.domain.zRange(2);

% Retain the physical thin-film thicknesses without resolving them in the
% substrate mesh.  Later solvers can convert volume coefficients to sheet
% coefficients by multiplying by these thicknesses.
params.thickness.aluminum = 100e-9;
params.thickness.normalTrap = 80e-9;
params.thickness.backsideSink = 1e-6;

% Record the collapsed out-of-plane lead width from the physical layout.
% This width is metadata in the present x-z cross-section, not a mesh length.
params.outOfPlane.leftLeadWidth = 8e-6;
params.outOfPlane.rightLeadWidth = 8e-6;

% Select high-resistivity silicon as the default substrate because it connects
% directly to the existing defect, electrostatic, carrier, and thermal modules.
params.materials.substrate.key = 'high_resistivity_silicon';
params.materials.substrate.label = 'High-resistivity silicon';
params.materials.substrate.relativePermittivity = 11.7;
params.materials.substrate.modelRole = 'bulk_domain';
params.materials.substrateOptions.highResistivitySilicon = params.materials.substrate;
params.materials.substrateOptions.sapphire.key = 'sapphire';
params.materials.substrateOptions.sapphire.label = 'Sapphire (Al2O3)';
params.materials.substrateOptions.sapphire.relativePermittivity = 9.4;
params.materials.substrateOptions.sapphire.modelRole = 'bulk_domain_alternative';

% Store the other material identities separately from their future,
% temperature-dependent transport coefficients.
params.materials.aluminum.key = 'aluminum';
params.materials.aluminum.label = 'Superconducting aluminum';
params.materials.aluminum.modelRole = 'top_surface_film';
params.materials.junction.key = 'effective_josephson_junction';
params.materials.junction.label = 'Effective JJ scoring/interface region';
params.materials.junction.modelRole = 'surface_interface';
params.materials.normalTrap.key = 'normal_metal_trap';
params.materials.normalTrap.label = 'Cu/Au/Pd normal-metal trap';
params.materials.normalTrap.modelRole = 'top_surface_sink';
params.materials.backsideSink.key = 'backside_cu_au_sink';
params.materials.backsideSink.label = 'Cu/Au backside thermalization patch';
params.materials.backsideSink.modelRole = 'bottom_boundary';

% Define the large aluminum shunt-capacitance pads.
params.regions.leftPad = surface_region( ...
    'left_pad', 'Left Al capacitor pad', [-0.630e-3, -0.030e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.rightPad = surface_region( ...
    'right_pad', 'Right Al capacitor pad', [+0.030e-3, +0.630e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.leftPad.zRange = [0, params.thickness.aluminum];
params.regions.rightPad.zRange = [0, params.thickness.aluminum];

% Define the connected junction leads.  Each lead overlaps its large pad over
% 10.5 micrometres and terminates exactly at an edge of the effective JJ.
params.regions.leftLead = surface_region( ...
    'left_lead', 'Left Al junction lead', [-0.0405e-3, -0.0005e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.rightLead = surface_region( ...
    'right_lead', 'Right Al junction lead', [+0.0005e-3, +0.0405e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.leftLead.zRange = [0, params.thickness.aluminum];
params.regions.rightLead.zRange = [0, params.thickness.aluminum];

% Treat the 1-micrometre-wide JJ as a scoring/interface segment.  The oxide
% barrier is not resolved at this geometry stage and this tag must not be used
% later as an electrical short between the two electrodes.
params.regions.jj = surface_region( ...
    'jj_sensitive', 'Effective JJ-sensitive region', ...
    [-0.0005e-3, +0.0005e-3], 'effective_josephson_junction', ...
    'top', params.thickness.aluminum);
params.regions.jj.zRange = [0, params.thickness.aluminum];

% Keep the nominal 60-micrometre pad gap as a geometric reference window.
% Along the selected centerline, the leads and JJ occupy this window; therefore
% it is not an independent bulk material region.
params.reference.padGap.xRange = [-0.030e-3, +0.030e-3];
params.reference.padGap.width = diff(params.reference.padGap.xRange);
params.reference.padGap.description = ...
    'Nominal separation of the large-pad inner edges; central lead/JJ metal is superposed.';

% Place a 100-micrometre normal-metal trap on the right pad, away from the JJ.
params.regions.normalTrap = surface_region( ...
    'normal_trap', 'Right-pad normal-metal trap', ...
    [+0.450e-3, +0.550e-3], 'normal_metal_trap', ...
    'top', params.thickness.normalTrap);
params.regions.normalTrap.parent = 'right_pad';
params.regions.normalTrap.zRange = [params.thickness.aluminum, ...
    params.thickness.aluminum + params.thickness.normalTrap];

% Define the two on-chip package-interface pads.  The curved bond-wire arcs
% above these pads are intentionally excluded from the first 2D mesh.
params.regions.leftBondPad = surface_region( ...
    'left_bond_pad', 'Left package bond pad', [-1.48e-3, -1.40e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.rightBondPad = surface_region( ...
    'right_bond_pad', 'Right package bond pad', [+1.40e-3, +1.48e-3], ...
    'aluminum', 'top', params.thickness.aluminum);
params.regions.leftBondPad.zRange = [0, params.thickness.aluminum];
params.regions.rightBondPad.zRange = [0, params.thickness.aluminum];

% Define the 300-micrometre backside sink as a bottom boundary patch.  Its
% effective 1-micrometre thickness remains available for later sheet models.
params.regions.backsideSink = surface_region( ...
    'backside_sink', 'Centered backside thermal sink', ...
    [-0.150e-3, +0.150e-3], 'backside_cu_au_sink', ...
    'bottom', params.thickness.backsideSink);
params.regions.backsideSink.zRange = [params.domain.zRange(1), ...
    params.domain.zRange(1) + params.thickness.backsideSink];

% Make the wire-bond omission explicit and machine-testable.
params.modeling.includeCurvedWireArcs = false;
params.modeling.wireRepresentation = ...
    'Boundary flux, source, or lumped thermal/electrical link at bond-pad tags.';
params.modeling.resolveThinFilmsInBulkMesh = false;
params.modeling.substrateOnlyBulkMesh = true;
params.modeling.junctionBehavior = ...
    'Sensitive interface separating left and right electrodes; never an imposed short.';

% Configure nonuniform mesh spacing.  All region endpoints are inserted exactly
% even when the requested local spacing is coarser than a short feature.
params.mesh.bulkDx = 25e-6;
params.mesh.featureDx = 10e-6;
params.mesh.centralDx = 5e-6;
params.mesh.bulkDz = 25e-6;
params.mesh.surfaceDz = 5e-6;
params.mesh.surfaceRefinementDepth = 50e-6;
params.mesh.alternateCellDiagonals = true;

% Configure the two diagnostic views.  The display heights are deliberately
% exaggerated; they never alter the physical thickness metadata or FEM mesh.
params.visualization.figureVisible = 'on';
params.visualization.aluminumDisplayHeight = 0.035e-3;
params.visualization.trapDisplayHeight = 0.025e-3;
params.visualization.sinkDisplayHeight = 0.025e-3;
params.visualization.imageResolution = 220;
params.visualization.showLabels = true;

% Configure the stand-alone driver outputs relative to the MATLAB directory.
params.outputDir = fullfile('outputs', 'module9_geometry');
params.saveMat = true;
params.saveSummary = true;
params.makePlots = true;
params.saveFigures = true;
end

function region = surface_region(key, label, xRange, material, side, thickness)
% SURFACE_REGION Create a consistent named thin-film or boundary definition.
region.key = key;
region.label = label;
region.xRange = xRange;
region.length = diff(xRange);
region.material = material;
region.side = side;
region.physicalThickness = thickness;
region.representation = 'tagged_surface_segment';
end
