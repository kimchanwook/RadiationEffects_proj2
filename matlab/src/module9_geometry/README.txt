Module 9 reduced transmon geometry layer
=========================================

Current scope
-------------
This directory remains the geometry owner. The Module 2 FEM solver now consumes
this geometry through `resolve_module2_mesh_2d.m`, while the Module 2 PINN,
Modules 3-6, and the multiphysics driver remain on their earlier geometries.

The substrate is the sole two-dimensional bulk mesh. Aluminum films, the
effective JJ, normal trap, bond pads, and backside sink are retained as named
surface segments with their physical z ranges and thicknesses stored as
metadata. Curved wire-bond arcs are intentionally omitted; later wiring effects
must be applied at the bond-pad tags.

Run and verify
--------------
From the matlab directory:

1. setup_project_paths
2. out = main_module9_transmon_geometry_2d();
3. test_module9_transmon_geometry_2d

Inspect both generated images:

- outputs/module9_geometry/module9_transmon_geometry_2d.png
- outputs/module9_geometry/module9_transmon_mesh_tags_2d.png

The first is a presentation schematic with exaggerated film heights. The
second is the true substrate FEM mesh with zero-thickness boundary tags. The
schematic exaggeration must never be passed into a physics solver.

The master test includes a headless plotting smoke test for both figure paths.
It checks that the figures can be constructed without a graphics API error,
but it does not compare image appearance; both PNGs still require inspection.

Strict gated follow-on sequence
-------------------------------
Do not skip the geometry tests or change all solvers at once.

Gate 1: Module 9 geometry acceptance
- Run all Module 9 tests in MATLAB.
- Inspect both images for correct feature placement and readable labels.
- Confirm the MAT file contains mesh, tags, regions, materials, and validation.

Gate 2: Connect Module 2 FEM while preserving legacy rectangle cases [IMPLEMENTED]
- Geometry selection and exact prebuilt-geometry reuse are implemented.
- Named left_electrode/right_electrode Dirichlet conditions are implemented.
- The JJ remains a scoring/interface tag and is not an imposed short.
- Transmon Laplace and trapped-charge cases are implemented.
- Tagged plot overlays, residual/balance diagnostics, exact mesh-reuse tests,
  and named-boundary guard tests are implemented.
- Run `test_module2_fem_all_2d` in MATLAB before accepting this gate locally.
- The follow-on batch dataset path now reuses this same accepted mesh and
  named-boundary operator for a deterministic 17-case pilot design.
- Run `test_module2_batch_fem_dataset_2d`, then generate and inspect the batch
  validation summary before treating the dataset contract as accepted.
- Scalar substrate permittivity remains intentional; elementwise/nodal
  permittivity should be added only when a multi-material bulk mesh requires it.

Gate 3: Adapt Module 2 PINN after local FEM acceptance
- Sample the Module 9 substrate interior and named electrode segments.
- Preserve the JJ as an interface rather than a short.
- Load the validated complete-case batch FEM dataset for reference/anchor data.
- Keep train, validation, and test splits separated by charge configuration.
- Preserve the existing rectangular PINN regression.

Gate 4: First tagged thermal validation
- Apply heat at one bond pad and a sink condition at backside_sink.
- Verify heat spreads through the substrate and relaxes toward the sink.

Gate 5: Rest of the coupled FEM chain
- Make Module 3 accept the externally supplied Module 9 mesh.
- Make Module 4 consume bond-pad and backside-sink boundary tags.
- Add a genuine quasiparticle diffusion-reaction path to Module 5; do not
  relabel the existing electron-hole transport solver as quasiparticle physics.
- Build the shared Module 9 mesh once in Module 6 and pass it to all modules.

These gates are intentionally recorded here so future changes can be traced to
one integration stage if a regression appears.
