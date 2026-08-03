Module 9 reduced transmon geometry layer
=========================================

Current scope
-------------
This directory implements geometry only. It does not modify the Module 2 FEM
solver, Module 2 PINN, Modules 3-6, or the multiphysics driver.

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

Strict gated follow-on sequence
-------------------------------
Do not skip the geometry tests or change all solvers at once.

Gate 1: Module 9 geometry acceptance
- Run all Module 9 tests in MATLAB.
- Inspect both images for correct feature placement and readable labels.
- Confirm the MAT file contains mesh, tags, regions, materials, and validation.

Gate 2: Connect Module 2 FEM while preserving legacy rectangle cases
- Extend default_module2_params.m with rectangular/module9 geometry selection.
- Extend solve_poisson_defect_space_charge_2d.m to accept a supplied mesh.
- Extend get_module2_dirichlet_nodes.m to consume left_electrode and
  right_electrode tags instead of applying voltage to whole chip sides.
- Extend plot_module2_result_2d.m to overlay Module 9 tags and label x-z axes.
- Add a transmon case to main_module2_electrostatics.m and matlab/cases/.
- Extend assemble_poisson_fem_2d.m only when scalar versus elementwise/nodal
  permittivity is actually required.
- Add dedicated Module 2-on-Module-9 verification tests.

Gate 3: First tagged-physics validation
- Apply heat at one bond pad and a sink condition at backside_sink.
- Verify heat spreads through the substrate and relaxes toward the sink.

Gate 4: Rest of the coupled FEM chain
- Make Module 3 accept the externally supplied Module 9 mesh.
- Make Module 4 consume bond-pad and backside-sink boundary tags.
- Add a genuine quasiparticle diffusion-reaction path to Module 5; do not
  relabel the existing electron-hole transport solver as quasiparticle physics.
- Build the shared Module 9 mesh once in Module 6 and pass it to all modules.

Gate 5: PINN adaptation last
- Update the Module 2 PINN only after the tagged Module 2 FEM implementation is
  validated. The current PINN assumes a simple rectangle, scalar permittivity,
  and boundary samples on whole sides.

These gates are intentionally recorded here so future changes can be traced to
one integration stage if a regression appears.
