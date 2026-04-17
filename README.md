# RadiationEffects_proj2

This repository builds a physics-based framework linking radiation energy deposition in silicon to long-term device degradation. The top-level `README.md`, `project_plan.tex`, and `project_plan.pdf` are the three maintained architecture documents and should be updated whenever the project architecture changes.

## High-level structure

- `project_plan.tex/.pdf` - single living roadmap document for the whole project
- `docs/physics_notes/` - textbook-style module notes with derivations and symbol definitions
- `docs/implementation_notes/` - implementation specifications and coding notes
- `geant4/` - Geant4-side radiation deposition setup and exported damage-source products
- `matlab/` - MATLAB codebase for Modules 2-7 and coupled studies

## Module architecture

- Module 1 - Geant4 radiation energy deposition in silicon
- Module 2 - 2D electrostatics with defect-dependent space charge
- Module 3 - 2D defect diffusion-reaction evolution and annealing
- Module 4a - 2D continuum thermal transport
- Module 4b - 2D phonon-aware thermal transport
- Module 5 - 2D drift-diffusion carrier transport with defect-assisted recombination
- Module 6 - coupled multiphysics integration of Modules 2, 3, 4a/4b, and 5
- Module 7 - multiscale extrapolation and scalable prediction methods

## Current coding status in this package

This package now includes:

- updated top-level `project_plan` and `README`
- Module 3 2D physics note and verified first MATLAB path
- first runnable Module 4a 2D continuum thermal solver path
- Module 4a verification cases for uniform equilibrium, hotspot diffusion, and a steady-source relaxation case
- automatic Module 4a output plots and summary files
- shared 2D grid/plotting conventions aligned with Module 3

## Run order workflow

1. Run Geant4 to generate deposited-energy or damage-source data.
2. Convert Geant4 output into a defect-generation map or initial defect field.
3. Evolve the defect field in MATLAB with Module 3.
4. Solve the baseline temperature field with Module 4a.
5. Compare against Module 4b when phonon-aware corrections are introduced.
6. Use the defect field in Module 2 to compute electrostatics.
7. Use electrostatics, thermal fields, and defect fields in Module 5 for carrier transport.
8. Couple Modules 2-5 in Module 6.
9. Use Module 7 for reduced-fidelity scaling, statistical extrapolation, or hybrid multiresolution prediction.

## Immediate next technical objective

The current baseline thermal step is Module 4a. The next major comparison task after baseline verification is to define what Module 4b must change in the predicted quantities of interest to justify the added complexity. Good comparison metrics include peak temperature, thermal gradients, annealing-rate changes, defect-history changes, and downstream electrical degradation metrics.

## Important note

This archive was prepared as a consolidated project package with the requested architecture updates implemented in the plan and in the first Module 4a MATLAB code path. I could not execute MATLAB itself in this environment, so the MATLAB code was prepared and organized here, but final runtime verification still needs to be done on your machine.
