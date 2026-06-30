# RadiationEffects_proj2

This repository builds a physics-based framework linking radiation energy deposition in silicon to long-term device degradation. The top-level `README.md`, `project_plan.tex`, and `project_plan.pdf` are the three maintained architecture documents and should be updated whenever the project architecture changes. `This work was conducted with the assistance of a large language model (LLM)`.

## High-level structure

- `project_plan.tex/.pdf` - single living roadmap document for the whole project
- `docs/physics_notes/` - textbook-style module notes with derivations and symbol definitions
- `docs/implementation_notes/` - implementation specifications and coding notes
- `geant4/` - Geant4-side radiation deposition setup and exported damage-source products
- `matlab/` - MATLAB codebase for Modules 2-7 and coupled studies; Module 9 geometry is documented for the next MATLAB FEM extension

## Module architecture

- Module 1 - interaction-resolved Geant4 radiation deposition campaign in silicon
- Module 2 - 2D electrostatics with defect-dependent space charge using a first linear-triangle FEM Poisson solver
- Module 3 - 2D defect diffusion-reaction evolution and annealing with material-aware kinetic coefficients; includes both the original structured-grid path and a new linear-triangle FEM path
- Module 4 - 2D ballistic-diffusive thermal transport in silicon; includes the original structured-grid path and a new linear-triangle FEM path
- Module 5 - 2D drift-diffusion carrier transport with defect-assisted recombination using a first linear-triangle FEM path
- Module 6 - coupled multiphysics integration of Modules 2, 3, 4, and 5 using a first staggered linear-triangle FEM coupling scaffold
- Module 7 - multiscale extrapolation and scalable prediction methods
- Module 8 - reduced-fidelity and importance-based physics selection
- Module 9 - transmon geometry, microwave-package context, and 2D MATLAB FEM target domains


## Module 1 interaction-resolved campaign update

Module 1 is now planned as a family of Geant4 runs rather than one broad deposition run. The idea is to separate photon and neutron simulations into targeted energy bands so that different interaction mechanisms can be emphasized and interpreted more cleanly.

## Module 3 material-aware kinetics update

Module 3 now distinguishes between the microscopic origin of defect kinetics and the subset of dependencies that are implemented in the first reduced simulation model.

Microscopic quantities that contribute to the effective defect diffusivity $D$ and annealing coefficient $k_{\mathrm{ann}}$ include:
- interatomic bonding and migration saddle-point energetics
- local lattice geometry and jump distance
- electronic structure and defect-level energetics
- defect charge state
- strain field
- nearby impurities or dopants
- nearby interfaces or sinks
- local electric field
- local temperature

In the current reduced simulation path, the first implemented dependencies are:
- temperature
- defect charge state
- dopant environment
- electric-field magnitude

Strain and interface proximity are documented in the physics note as the next refinement layer, while bonding, local geometry, and electronic structure are treated as the microscopic origin of the fitted or imported kinetic parameters rather than as direct continuum fields solved in MATLAB.

For photons, the current planning bands are intended to emphasize:
- Rayleigh scattering (about eV to 100 keV)
- photoelectric effect (about eV to 500 keV)
- Compton scattering (about 10 keV to 10 MeV)
- pair production (above 1.022 MeV)
- photonuclear interactions in the resonance region (about 5 MeV to 3 GeV)
- deep-inelastic or very-high-energy behavior (GeV scale and above)

These are campaign ranges, not sharp exclusive boundaries. Multiple processes can still contribute in overlapping ranges.

For neutrons, the same interaction-resolved philosophy will be used, with exact energy partitions to be finalized around the reaction classes that matter most for silicon damage and secondary production.

## Current coding status in this package

This package now includes:

- updated top-level `project_plan` and `README`
- Module 1 physics note defining the Geant4 energy-deposition source term and its reduced 2D mapping
- Module 2 expanded physics note, superconductivity electrostatics extension note, first MATLAB FEM Poisson path, triangular mesh generation, electrostatic verification tests, PINN electrostatics demo, and causal-PINN electrostatics continuation demo
- Module 3 expanded physics note, superconductivity defect-evolution extension note, FEM weak form, mass/diffusion/reaction matrices, backward-Euler time stepping, verified structured-grid path, material-aware kinetic-coefficient framework, and first linear-triangle FEM path
- archived legacy Module 4a/4b thermal notes and baseline MATLAB path for reference
- new Module 4 architecture centered on 2D ballistic-diffusive thermal transport
- new Module 4 documentation path plus first executable MATLAB implementation
- Module 4 expanded FEM documentation, superconductivity thermal-transport extension note, linear-triangle thermal matrix assembly, and first implicit FEM ballistic-diffusive thermal path
- Module 5 expanded physics note, superconductivity carrier-response extension note, FEM weak form, mass/diffusion/drift/recombination matrices, backward-Euler time stepping, first executable linear-triangle carrier-transport path, and carrier-transport verification tests
- Module 6 expanded physics note defining the coupled multiphysics integration of defect, electrostatic, thermal, and carrier maps, superconductivity coupling-architecture extension note, including shared-mesh FEM discretization, block residual structure, and a first staggered MATLAB FEM coupling path
- Module 8 reduced-fidelity and importance-scoring physics note
- Module 9 transmon-geometry physics note defining the microwave-aware full model and the reduced 2D FEM target with substrate, Al pads/leads/JJ, normal trap, backside heat sink, bond pads, and wire-bond boundary treatment
- shared 2D grid/plotting conventions aligned with Module 3
- Module 2 FEM implementation note in `docs/implementation_notes/module2_fem_implementation_note.md`
- Module 3 FEM implementation note in `docs/implementation_notes/module3_fem_implementation_note.md`
- Module 4 FEM implementation note in `docs/implementation_notes/module4_fem_implementation_note.md`
- Module 5 FEM implementation note in `docs/implementation_notes/module5_fem_implementation_note.md`
- Module 6 FEM implementation note in `docs/implementation_notes/module6_fem_implementation_note.md`

## Run order workflow

1. Run the interaction-resolved Geant4 campaign to generate deposited-energy, secondary-particle, and interaction-summary data.
2. Convert Geant4 output into a defect-generation map or initial defect field.
3. Evolve the defect field in MATLAB with Module 3.
4. Solve the thermal field with Module 4 using the reduced ballistic-diffusive model.
5. Use the defect field in Module 2 to compute electrostatics.
6. Use electrostatics, thermal fields, and defect fields in Module 5 for carrier transport.
7. Couple Modules 2-5 in Module 6.
8. Use Module 7/8 for reduced-fidelity scaling, statistical extrapolation, importance scoring, or hybrid multiresolution prediction.
9. Use Module 9 as the superconducting transmon geometry baseline when moving from rectangular silicon cross sections to qubit-relevant FEM domains.

## Immediate next technical objective

The next technical objective is to convert the Module 9 2D transmon geometry into a MATLAB FEM geometry/tagging function and then decide the first executable superconducting-region implementation path. The physics-note sequence for superconducting Modules 2-6 is now in place, so the natural next implementation target is a reduced superconducting Module 6 scaffold that couples offset charge, trapped charge, pair-breaking phonon population, quasiparticle density, and superconducting device metrics. In parallel, run the new Module 2 FEM/PINN/causal-PINN verification tests plus the Module 3, Module 4, Module 5, and Module 6 FEM verification tests in MATLAB. After that, refine the Module 6 staggered coupling path by replacing the reduced thermal update with the full Module 4 ballistic-diffusive FEM update, adding stronger defect-field drift coupling, and tightening the Poisson/drift-diffusion fixed-point loop.

## Important note

This archive now includes the earlier Module 4 ballistic-diffusive thermal architecture update, the Module 2 finite-element electrostatics update, the Module 3 finite-element defect-evolution update, the Module 4 finite-element thermal-transport update, the Module 5 finite-element drift-diffusion carrier-transport update, the Module 6 staggered finite-element coupling update, and the Module 2-6 superconducting-region physics-note sequence, and the Module 9 transmon-geometry note. The Module 2, Module 3, Module 4, Module 5, and Module 6 FEM paths are first reduced solvers and coupling scaffolds, not yet a full production semiconductor TCAD simulator.
