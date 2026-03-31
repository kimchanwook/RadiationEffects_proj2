# RadiationEffects_proj2

This repository builds a physics-based framework linking radiation energy deposition in silicon to long-term device degradation.

## High-level structure

- `project_plan.tex/.pdf` — single living roadmap document for the whole project
- `docs/physics_notes/` — textbook-style module notes with derivations and symbol definitions
- `docs/implementation_notes/` — implementation specifications and coding notes
- `geant4/` — Geant4-side radiation deposition setup and exported damage-source products
- `matlab/` — MATLAB codebase for Modules 2–6 and coupled studies

## Module architecture

- **Module 1** — Geant4 radiation energy deposition in silicon
- **Module 2** — 2D electrostatics with defect-dependent space charge
- **Module 3** — 2D defect diffusion-reaction evolution and annealing
- **Module 4** — 2D thermal transport coupled to defect evolution
- **Module 5** — 2D drift-diffusion carrier transport with defect-assisted recombination
- **Module 6** — coupled multiphysics integration of Modules 2–5
- **Module 7** — multiscale extrapolation and scalable prediction methods

## Current coding status in this package

This package now includes a more complete first implementation pass for 2D Module 3:

- updated top-level `project_plan`
- Module 3 2D physics note
- first runnable 2D Module 3 MATLAB solver path
- quantitative verification scripts for Gaussian diffusion and pure annealing
- automatic output plots and summary files
- a first Geant4-to-Module-3 import stub for 2D damage maps

## Run order workflow

1. Run Geant4 to generate deposited-energy or damage-source data.
2. Convert Geant4 output into a defect-generation map or initial defect field.
3. Evolve the defect field in MATLAB with Module 3.
4. Use the defect field in Module 2 to compute electrostatics.
5. Use temperature coupling in Module 4 as needed.
6. Use electrostatics and defect fields in Module 5 for carrier transport.
7. Couple Modules 2–5 in Module 6.
8. Use Module 7 for reduced-fidelity scaling or statistical extrapolation.

## Important note

This archive was prepared as a consolidated project package with the requested 2D updates implemented in the plan and in the first verified MATLAB Module 3 code path. I could not execute MATLAB itself in this environment, so the MATLAB code was prepared and organized here, but final runtime verification still needs to be done on your machine.
