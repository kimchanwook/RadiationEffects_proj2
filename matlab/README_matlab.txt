MATLAB Implementation Notes for Radiation Effects Project 2
==========================================================

Tool split
----------
- Module 1 (radiation transport and deposited-energy generation): Geant4
- Modules 2-7 (device/material response and scalable prediction): MATLAB

Current implementation status
-----------------------------
This package now includes ten working code paths:

1. Module 2: 2D finite-element electrostatic Poisson implementation on both
   the legacy rectangle and the shared Module 9 transmon substrate mesh
1a. Module 2 batch FEM: factorized multi-configuration dataset generation on
   the shared Module 9 mesh
1b. Module 2 PINN: standalone physics-inspired neural-network Poisson surrogate demo
2. Module 3: first 2D defect evolution implementation plus a linear-triangle FEM defect diffusion-reaction path
2b. Module 3 causal PINN: physical-time causal training for the same diffusion-reaction initial-value problem
3. Module 4: first executable 2D ballistic-diffusive thermal implementation plus a new linear-triangle FEM thermal path
4. Module 5: first linear-triangle FEM drift-diffusion carrier-transport path
5. Module 6: first staggered linear-triangle FEM coupling scaffold for Modules 2-5
6. Legacy Module 4a: archived 2D Fourier thermal baseline for comparison
7. Module 9: reduced transmon x-z geometry, substrate mesh, surface tags, validation, and visualization


Module 2 electrostatics pieces now included:
- structured rectangular triangular mesh generation
- validated Module 9 nonuniform substrate-mesh injection and exact mesh reuse
- linear triangular finite-element assembly for the 2D Poisson equation
- defect-dependent space-charge evaluation from effective charged defects
- strong Dirichlet boundary-condition insertion and natural zero-Neumann edges
- named left/right transmon-electrode conditions with the JJ kept separate
- electric-field postprocessing from the solved electrostatic potential
- free-node residual, fixed-voltage error, and global source/reaction balance
- verification cases for zero charge, linear Laplace solution, uniform space
  charge, localized defect charge, tagged transmon Laplace, and transmon
  trapped charge


Module 2 batch FEM pieces now included:
- deterministic 17-case pilot design for one elliptical Gaussian charge cloud
- public conditional parameters [C_peak, x_c, z_c, sigma_x, sigma_z]
- one validated Module 9 mesh reused for every complete configuration
- one stiffness assembly and one sparse Cholesky factorization per batch
- per-case source-vector assembly and factorized triangular solves
- compact MAT contract with mesh/tags stored once and rho/phi stored by case
- disjoint train, validation, and test indices assigned by whole configuration
- scalar residual, tagged-voltage, and global-balance diagnostics per case
- no routine plotting, with explicit opt-in representative audit plots
- regression against the existing single-case transmon trapped-charge solver


Module 2 PINN pieces now included:
- modular MATLAB entry point `main_module2_pinn_electrostatics.m`
- six commented functions in `matlab/pinn/` for network construction, loss
  evaluation, training, prediction, FEM-dataset generation, and verification
- physics residual for eps_si*(d2phi/dx2 + d2phi/dy2) + rho = 0
- Dirichlet and natural-Neumann boundary-condition loss terms
- optional sparse FEM anchor data for stabilization
- FEM-reference comparison plots, PDE-residual plots, field plots, and training-loss curves
- lightweight smoke/regression test `test_module2_pinn_electrostatics.m`

Module 3 FEM pieces now included:
- linear triangular finite-element weak-form implementation for diffusion-reaction evolution
- consistent mass matrix, diffusion matrix, and first-order annealing matrix assembly
- implicit backward-Euler time stepping
- natural homogeneous zero-flux boundary handling
- verification cases for pure annealing, uniform-state preservation, and Gaussian diffusion inventory conservation

Module 3 causal-PINN pieces now included:
- standalone MATLAB entry point `main_module3_CPINN_Defect_Evolution.m`
- normalized `(x/Lx,y/Ly,t/tEnd)` inputs and `C/Cscale` output
- automatic-differentiation residual for diffusion, first-order annealing, and source
- soft initial-condition and homogeneous zero-flux boundary losses
- residual-only causal prefix containing the initial condition and ordered physical-time residual slices
- exponential causal weights computed from detached prefix losses, implementing stop-gradient
- configurable epsilon schedule, optional sparse FEM anchors, analytic uniform-annealing reference, and FEM Gaussian-diffusion reference
- saved slice losses, activation-front weights, field/inventory errors, plots, and summary
- regression/physics test `test_module3_cpinn_pure_annealing.m`

Module 4 ballistic-diffusive pieces now included:
- structured 2D Cartesian grid utilities shared with Module 3
- explicit transient stepping for the reduced ballistic-diffusive temperature PDE
- attenuated rectangular-domain ballistic-flux closure from boundary emission
- volumetric heat-source support including imported CSV maps
- save-history support for thermal snapshots and scalar metrics
- automated output plots and summary text files

Module 4 FEM pieces now included:
- linear triangular finite-element weak-form implementation for the ballistic-diffusive temperature equation
- consistent heat-capacity matrix and thermal conductivity matrix assembly
- backward-Euler time stepping for the second-order-in-time relaxation equation
- natural homogeneous no-flux boundary handling and optional strong Dirichlet temperature support
- FEM verification cases for uniform equilibrium, Gaussian diffusion in the Fourier limit, and uniform volumetric heating

Module 5 FEM pieces now included:
- linear triangular finite-element weak-form implementation for electron and hole drift-diffusion transport
- consistent carrier mass matrix, diffusion matrix, electric-field drift matrix, and linear recombination matrix assembly
- backward-Euler time stepping for the reduced carrier equations
- natural zero-normal-flux boundary handling and optional strong Dirichlet carrier contacts
- elementwise current-density postprocessing for electron, hole, and total conventional current
- FEM verification cases for uniform no-field preservation, lifetime recombination, Gaussian diffusion inventory conservation, and current-sign sanity under a uniform electric field

Module 6 FEM pieces now included:
- shared linear triangular mesh for defect concentration, electrostatic potential, temperature, electrons, and holes
- staggered Picard-style coupling of Module 3 defect update, Module 2 Poisson update, Module 5 carrier update, and Module 4-style thermal update
- defect-to-space-charge mapping, field-to-carrier drift mapping, defect-to-mobility/recombination mapping, and current-to-Joule-heating mapping
- coupling convergence metrics and charge-consistency diagnostics
- smoke and charge-consistency verification tests

Module 9 reduced-geometry pieces now included:
- parameterized 3 mm by 0.5 mm high-resistivity-silicon substrate cross-section
- nonuniform linear-triangle substrate mesh with every feature endpoint inserted exactly
- named surface tags for Al pads, leads, effective JJ, normal trap, bond pads, and backside sink
- separate left/right electrode groups so the JJ-sensitive interface is not an electrical short
- explicit omission of curved wire-bond arcs, with bond pads retained for later boundary conditions
- presentation schematic with exaggerated film heights and true solver mesh/tag visualization
- dimension, connectivity, tag-length, no-wire-arc, and plotting smoke tests
- consumed by Module 2 FEM; no changes yet to Modules 3-6, Module 2 PINN, or
  the coupled solver

Legacy Module 4a baseline pieces retained:
- explicit transient heat-equation stepping for a single temperature field
- zero-normal-gradient boundary handling for diffusion-type thermal tests
- uniform equilibrium, hotspot diffusion, and steady-source reference cases

Recommended run order
---------------------
The setup script now also adds the `tests` folder to the MATLAB path, so test functions can be called by name from the MATLAB project root.

Start every session with `setup_project_paths`. For the newly integrated path,
run these commands first:

- `test_module9_transmon_geometry_2d`
- `test_module2_fem_all_2d`
- `main_module2_electrostatics('transmon_laplace')`
- `main_module2_electrostatics('transmon_trapped_charge')`
- `test_module2_batch_fem_dataset_2d`
- `[dataset, report] = main_module2_batch_fem_dataset()`

The legacy Module 2 cases remain available as `zero_charge`,
`linear_potential`, `uniform_space_charge`, and `localized_defect_charge`.
The PINN entry point remains `main_module2_pinn_electrostatics`; it has not yet
been adapted to Module 9. Module 3-6, Module 4a, and their existing tests keep
the same commands documented in their module-specific implementation notes.

Outputs written automatically
-----------------------------
Module 2 outputs:
- `matlab/outputs/module2_2d/`
- `matlab/outputs/module2_transmon_2d/`

Module 2 batch FEM outputs:
- `matlab/outputs/module2_batch_fem_2d/`

Module 2 PINN outputs:
- `matlab/outputs/module2_pinn_2d/`

Module 3 outputs:
- `matlab/outputs/module3_2d/`
- `matlab/outputs/module3_fem_2d/`
- `matlab/outputs/module3_cpinn_2d/`

Module 4 ballistic-diffusive outputs:
- `matlab/outputs/module4_2d_ballistic_diffusive/`

Module 4 FEM outputs:
- `matlab/outputs/module4_fem_2d/`

Module 5 FEM outputs:
- `matlab/outputs/module5_fem_2d/`

Module 6 FEM outputs:
- `matlab/outputs/module6_fem_2d/`

Module 9 geometry outputs:
- `matlab/outputs/module9_geometry/`

Legacy Module 4a outputs:
- `matlab/outputs/module4a_2d/`

Generated files include:
- `*_results.mat`
- `*_potential.png` (Module 2)
- `*_space_charge.png` (Module 2)
- `*_electric_field_magnitude.png` (Module 2)
- `module2_transmon_gaussian_batch_v1.mat` (Module 2 batch FEM)
- `module2_transmon_gaussian_batch_summary.txt` (Module 2 batch FEM)
- `*_pinn_potential.png` (Module 2 PINN)
- `*_pinn_abs_potential_error.png` (Module 2 PINN)
- `*_pinn_pde_residual.png` (Module 2 PINN)
- `*_pinn_training_loss.png` (Module 2 PINN)
- `*_cpinn_final_concentration.png` (Module 3 causal PINN)
- `*_cpinn_final_absolute_error.png` (Module 3 causal PINN)
- `*_cpinn_causal_weights.png` (Module 3 causal PINN)
- `*_cpinn_validation_history.png` (Module 3 causal PINN)
- `*_final_temperature.png`
- `*_final_ballistic_divergence.png` (Module 4)
- `*_fem_final_temperature.png` (Module 4 FEM)
- `*_fem_final_source.png` (Module 4 FEM)
- `*_fem_history_metrics.png` (Module 4 FEM)
- `*_fem_final_electrons.png` (Module 5 FEM)
- `*_fem_final_holes.png` (Module 5 FEM)
- `*_fem_total_current.png` (Module 5 FEM)
- `module6_fem_final_defects.png` (Module 6 FEM)
- `module6_fem_final_potential.png` (Module 6 FEM)
- `module6_fem_final_temperature.png` (Module 6 FEM)
- `module6_fem_coupling_convergence.png` (Module 6 FEM)
- `module9_transmon_geometry_2d.png` (Module 9 presentation schematic)
- `module9_transmon_mesh_tags_2d.png` (Module 9 solver mesh/tag view)
- `module9_transmon_geometry_2d.mat` (reusable geometry, mesh, and tag structure)
- `module9_transmon_geometry_summary.txt` (Module 9 dimensions and validation report)
- `*_centerline_cuts.png`
- `*_history_metrics.png`
- `*_summary.txt`

Important numerical note
------------------------
The current Module 2 solver is steady-state linear finite-element assembly. The Module 2 PINN entry point is a standalone Deep Learning Toolbox demonstration that trains a neural surrogate using the Poisson residual, boundary losses, and optional sparse FEM anchors. Module 3 now has an explicit structured-grid solver, an implicit linear-triangle FEM solver, and a Deep Learning Toolbox causal-PINN path whose causal coordinate is physical time. The first cPINN implementation supports scalar constant coefficients, analytic uniform cases, Gaussian FEM reference trajectories, homogeneous zero-flux boundaries, and optional sparse anchors; variable coefficients and imported maps remain extensions. Module 4 now has both the original explicit structured-grid ballistic-diffusive solver and a new implicit linear-triangle FEM solver. Module 5 now has a first implicit linear-triangle FEM drift-diffusion solver with known fields and linearized recombination. Module 6 now has a first staggered linear-triangle FEM coupling scaffold that passes fields between the Module 2, 3, 4, and 5 reduced FEM blocks. The legacy Module 4a Fourier baseline remains explicit. The structured-grid Module 4 path adds a relaxation-time term and a ballistic front resolution constraint, so the time step should satisfy the conservative recommended dt reported in each summary file.

Near-term next steps
--------------------
- run `test_module2_batch_fem_dataset_2d` and generate the 17-case pilot MAT
  file in MATLAB
- inspect the validation report and optionally export only the configured
  representative audit plots
- adapt the Module 2 PINN to named Module 9 boundary segments and consume the
  validated complete-case batch dataset
- scale to hundreds of FEM configurations only after the small conditional
  PINN path passes on the pilot dataset
- after Module 2 FEM validation, add the bond-pad heating to backside-sink thermal test in Module 4
- pass one shared Module 9 mesh/tags structure through Modules 3-6
- run the Module 3 causal-PINN regression test and the Module 3, Module 4, Module 5, and Module 6 FEM verification tests in MATLAB
- compare Module 4 FEM results against the structured-grid ballistic-diffusive path and archived Fourier baseline
- couple Module 4 FEM temperature output into Module 3 and Module 5 coefficient updates
- compare Module 4 against the Fourier baseline in a formal diffusive-limit test
- couple Module 3 defect fields into the Module 2 FEM space-charge source
- feed Module 2 electric fields into Module 5 FEM drift-diffusion cases
- replace the Module 5 linear lifetime sink with full nonlinear SRH recombination
- support stronger 2D ballistic closures beyond the current rectangular-domain model
- add implicit or semi-implicit stepping for longer transients and finer meshes
