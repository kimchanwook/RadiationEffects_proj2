MATLAB Implementation Notes for Radiation Effects Project 2
==========================================================

Tool split
----------
- Module 1 (radiation transport and deposited-energy generation): Geant4
- Modules 2-6 (device/material response): MATLAB

Current implementation status
-----------------------------
This package advances the first 2D Module 3 implementation beyond a bare skeleton.

Included in this package:
- first runnable 2D Module 3 solver path
- structured 2D Cartesian grid utilities
- diffusion-reaction stepping for a single defect species
- zero-normal-gradient boundary handling for diffusion
- save-history support
- automated output plots and summary text files
- quantitative diagnostics for mass conservation and annealing error
- simple Geant4 2D damage-map import stub
- three tests:
  - 2D Gaussian diffusion
  - pure annealing
  - imported damage-map diagnostic case

Recommended run order
---------------------
1. `setup_project_paths`
2. `main_module3_2d_defect_evolution('gaussian_diffusion')`
3. `main_module3_2d_defect_evolution('pure_annealing')`
4. `main_module3_2d_defect_evolution('imported_map')`
5. `test_module3_gaussian_diffusion_2d`
6. `test_module3_pure_annealing_2d`
7. `test_module3_imported_map_2d`

Outputs written automatically
-----------------------------
Each case writes into its own subdirectory under:
- `matlab/outputs/module3_2d/`

Generated files include:
- `*_results.mat`
- `*_final_field.png`
- `*_centerline_cuts.png`
- `*_history_metrics.png`
- `*_summary.txt`

Important numerical note
------------------------
The current solver uses an explicit time step for diffusion. The code now reports an
estimated explicit diffusion stability limit. As the grid is refined or the diffusion
coefficient grows, a later update should migrate the diffusion solve to an implicit or
operator-split formulation.

Near-term next steps
--------------------
- replace the simple CSV import stub with a stricter Geant4-to-defect translator
- add multi-species defect evolution scaffolding
- add 2D electrostatics (Module 2) on the same grid convention
- add implicit time stepping for stiff or fine-grid cases
