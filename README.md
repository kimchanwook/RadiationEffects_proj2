# RadiationEffects_proj2

This README mirrors the current top-level `project_plan.txt` and should be updated whenever the project architecture changes.

Project Plan - Radiation Effects Project 2

Purpose
This file is the plain-text companion to the top-level project_plan.pdf. It is the single living roadmap summary for Radiation Effects Project 2.

Core architecture decision
- Module 1 remains the Geant4 radiation-deposition module.
- Modules 2 through 6 are 2D-first.
- Module 4 is now split into two thermal branches:
  - Module 4a: continuum heat-equation thermal model
  - Module 4b: phonon-aware thermal model
- Module 7 remains the scaling / multiscale prediction module.

Module roadmap
1. Geant4 radiation energy deposition in silicon
   Compute where, when, and how much energy is deposited in silicon by the incident radiation field. Export a deposition map that seeds later damage or defect-generation models.

2. Two-dimensional electrostatics with defect-dependent space charge
   Solve the 2D electrostatic problem for a damaged silicon structure. Convert dopants and charged defects into electric potential, electric field, and depletion-structure changes.

3. Two-dimensional defect evolution: diffusion, reaction, migration, and annealing
   Evolve vacancies, interstitials, complexes, and effective defect species in 2D as functions of time and temperature.

4a. Two-dimensional thermal transport from the continuum heat equation
   Solve the macroscopic temperature field with the continuum heat equation and use it to update diffusion coefficients, reaction rates, annealing rates, and other temperature-dependent physics.

4b. Two-dimensional phonon-aware thermal transport
   Extend the thermal model beyond a plain continuum conductivity by incorporating phonon-mediated heat-flow physics, especially defect-dependent thermal transport and possible nonequilibrium or size-effect corrections.

5. Two-dimensional drift-diffusion carrier transport with defect-assisted recombination
   Predict how the damaged device transports electrons and holes under the altered field and trap landscape.

6. Coupled two-dimensional multiphysics degradation model
   Couple Modules 2, 3, 4a/4b, and 5 into a self-consistent simulator for defect evolution, field evolution, thermal evolution, and carrier-transport degradation.

7. Multiscale extrapolation and scalable prediction
   Develop methods for making predictions on much larger spatial, temporal, or statistical scales than the direct high-fidelity simulation can afford. This module covers controlled approximations, quantified error bars, and statistical upscaling.

Project narrative summary
This project builds a physics-based framework for connecting a radiation event in silicon to the eventual degradation of device performance. The framework tracks deposited energy, defect generation, defect evolution, electrostatics, thermal response, carrier transport, and their coupled influence on measurable device behavior.

Thermal split rationale
- Module 4a is the baseline production thermal model because it is simpler, cheaper, and easier to validate.
- Module 4b is the richer physics branch because it can represent how defects modify heat flow more directly through phonon-mediated transport effects.
- The project should compare 4a and 4b using quantities of interest such as peak temperature, spatial temperature gradients, defect-annealing histories, effective diffusion-rate changes, and final electrical degradation metrics.

Recommended comparison logic for 4a vs 4b
1. When does Module 4a already reproduce device-level behavior to acceptable accuracy?
2. Under what regimes does Module 4b change the predicted outcome enough to justify its extra complexity?

Recommended development order
1. Module 1: Geant4 geometry, scoring, and export format.
2. Module 3: 2D defect evolution on a structured grid.
3. Module 2: 2D electrostatics with prescribed charged defects.
4. Module 4a: 2D continuum thermal solver plus temperature-dependent coefficients.
5. Module 4b: phonon-aware thermal extension after the continuum baseline is working.
6. Module 5: 2D drift-diffusion with prescribed electrostatic field and defect/trap fields.
7. Module 6: weak coupling, then stronger feedback and iterative convergence.
8. Module 7: scalable-prediction methods after at least one credible high-fidelity coupled workflow exists.

Run-order workflow summary
1. Module 1: Geant4 radiation transport
2. Geant4-to-MATLAB handoff
3. Module 3: defect evolution
4. Module 4a: continuum thermal field
5. Module 4b: phonon-aware comparison branch
6. Module 2: electrostatics
7. Module 5: carrier transport
8. Module 6: coupled iteration
9. Module 7: scalable prediction

Near-term next steps
- Keep project_plan.pdf and this text companion updated whenever architecture changes.
- Continue 2D Module 3 implementation and verification.
- Define the first Geant4-to-MATLAB 2D handoff file and its units.
- Update implementation notes for Modules 2, 4a, 4b, and 5 so their first solver architecture is 2D rather than 1D.
- Define a comparison workflow between Module 4a and Module 4b with explicit metrics.
- Decide a first benchmark quantity of interest for Module 7.

