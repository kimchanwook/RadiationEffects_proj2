MATLAB Implementation Notes for Radiation Effects Project 2
==========================================================

Tool split
----------
- Module 1 (radiation transport and deposited-energy generation): Geant4
- Modules 2-7 (device/material response and scalable prediction): MATLAB

Current implementation status
-----------------------------
This package includes two working baseline code paths:

1. Module 3: first 2D defect evolution implementation
2. Module 4a: first 2D continuum thermal implementation

Included thermal baseline pieces:
- structured 2D Cartesian grid utilities shared with Module 3
- explicit transient heat-equation stepping for a single temperature field
- zero-normal-gradient boundary handling for diffusion-type thermal tests
- save-history support for thermal snapshots and scalar metrics
- automated output plots and summary text files
- three Module 4a tests:
  - uniform equilibrium preservation
  - hotspot diffusion / smoothing
  - steady-source relaxation with zero-flux boundaries

Recommended run order
---------------------
1. `setup_project_paths`
2. `main_module3_2d_defect_evolution('gaussian_diffusion')`
3. `main_module3_2d_defect_evolution('pure_annealing')`
4. `main_module4a_2d_continuum_thermal('uniform_equilibrium')`
5. `main_module4a_2d_continuum_thermal('hotspot_diffusion')`
6. `main_module4a_2d_continuum_thermal('steady_source')`
7. `test_module3_gaussian_diffusion_2d`
8. `test_module3_pure_annealing_2d`
9. `test_module4a_uniform_equilibrium_2d`
10. `test_module4a_hotspot_diffusion_2d`
11. `test_module4a_steady_source_2d`

Outputs written automatically
-----------------------------
Module 3 outputs:
- `matlab/outputs/module3_2d/`

Module 4a outputs:
- `matlab/outputs/module4a_2d/`

Generated files include:
- `*_results.mat`
- `*_final_field.png`
- `*_centerline_cuts.png`
- `*_history_metrics.png`
- `*_summary.txt`

Important numerical note
------------------------
The current Module 3 and Module 4a solvers use explicit time steps for diffusion-like operators. As the grid is refined, or as diffusion / thermal diffusivity grows, a later update should migrate these solvers to implicit or operator-split formulations.

Near-term next steps
--------------------
- couple Module 4a temperature output into Module 3 coefficient updates
- define the reduced phonon-aware closure path for Module 4b
- add 2D electrostatics (Module 2) on the same grid convention
- add implicit thermal stepping for stiff or fine-grid cases
