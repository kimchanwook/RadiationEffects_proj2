# RadiationEffects_proj2

This repository builds a physics-based framework linking radiation energy deposition in silicon to long-term device degradation. The top-level `README.md`, `project_plan.tex`, and `project_plan.pdf` are the three maintained architecture documents and should be updated whenever the project architecture changes. `This work was conducted with the assistance of a large language model (LLM), specifically ChatGPT`.


## High-level structure

- `project_plan.tex/.pdf` - single living roadmap document for the whole project
- `docs/physics_notes/` - textbook-style module notes with derivations and symbol definitions
- `docs/implementation_notes/` - implementation specifications and coding notes
- `geant4/` - Geant4-side radiation deposition setup and exported damage-source products
- `matlab/` - MATLAB codebase for Modules 2-7 and coupled studies

## Module architecture

- Module 1 - interaction-resolved Geant4 radiation deposition campaign in silicon
- Module 2 - 2D electrostatics with defect-dependent space charge
- Module 3 - 2D defect diffusion-reaction evolution and annealing with material-aware kinetic coefficients with material-aware kinetic coefficients
- Module 4 - 2D ballistic-diffusive thermal transport in silicon
- Module 5 - 2D drift-diffusion carrier transport with defect-assisted recombination
- Module 6 - coupled multiphysics integration of Modules 2, 3, 4, and 5
- Module 7 - multiscale extrapolation and scalable prediction methods


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
- Module 3 2D physics note, verified first MATLAB path, and first material-aware kinetic-coefficient framework
- archived legacy Module 4a/4b thermal notes and baseline MATLAB path for reference
- new Module 4 architecture centered on 2D ballistic-diffusive thermal transport
- new Module 4 documentation path plus first executable MATLAB implementation
- shared 2D grid/plotting conventions aligned with Module 3

## Run order workflow

1. Run the interaction-resolved Geant4 campaign to generate deposited-energy, secondary-particle, and interaction-summary data.
2. Convert Geant4 output into a defect-generation map or initial defect field.
3. Evolve the defect field in MATLAB with Module 3.
4. Solve the thermal field with Module 4 using the reduced ballistic-diffusive model.
5. Use the defect field in Module 2 to compute electrostatics.
6. Use electrostatics, thermal fields, and defect fields in Module 5 for carrier transport.
7. Couple Modules 2-5 in Module 6.
8. Use Module 7 for reduced-fidelity scaling, statistical extrapolation, or hybrid multiresolution prediction.

## Immediate next technical objective

The revised thermal step is now an executable Module 4 path, so the next technical objective is to verify it on the user's MATLAB environment, compare it against the legacy Fourier baseline in the diffusive limit, and then couple its temperature output back into Module 3 coefficient updates.

## Important note

This archive was updated to reflect the replacement of the old Module 4a/4b split with a single Module 4 ballistic-diffusive thermal architecture. Documentation and project-plan updates were prioritized first, and the repository now also includes the first executable MATLAB path for the revised Module 4 architecture.


