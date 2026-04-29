MATLAB Implementation Notes for Radiation Effects Project 2
==========================================================

Tool split
----------
- Module 1 (radiation transport and deposited-energy generation): Geant4
- Modules 2-7 (device/material response and scalable prediction): MATLAB

Current implementation status
-----------------------------
This package now includes three working code paths:

1. Module 3: first 2D defect evolution implementation
2. Module 4: first executable 2D ballistic-diffusive thermal implementation
3. Legacy Module 4a: archived 2D Fourier thermal baseline for comparison

Module 4 ballistic-diffusive pieces now included:
- structured 2D Cartesian grid utilities shared with Module 3
- explicit transient stepping for the reduced ballistic-diffusive temperature PDE
- attenuated rectangular-domain ballistic-flux closure from boundary emission
- volumetric heat-source support including imported CSV maps
- save-history support for thermal snapshots and scalar metrics
- automated output plots and summary text files

Legacy Module 4a baseline pieces retained:
- explicit transient heat-equation stepping for a single temperature field
- zero-normal-gradient boundary handling for diffusion-type thermal tests
- uniform equilibrium, hotspot diffusion, and steady-source reference cases

Recommended run order
---------------------
1. `setup_project_paths`
2. `main_module3_2d_defect_evolution('gaussian_diffusion')`
3. `main_module3_2d_defect_evolution('pure_annealing')`
4. `main_module4_2d_ballistic_diffusive_thermal('uniform_equilibrium')`
5. `main_module4_2d_ballistic_diffusive_thermal('localized_pulse')`
6. `main_module4_2d_ballistic_diffusive_thermal('boundary_heating')`
7. `main_module4a_2d_continuum_thermal('uniform_equilibrium')`  % archived Fourier baseline
8. `test_module3_gaussian_diffusion_2d`
9. `test_module3_pure_annealing_2d`
10. `test_module4_bd_uniform_equilibrium_2d`
11. `test_module4_bd_localized_pulse_2d`
12. `test_module4_bd_boundary_heating_2d`
13. `test_module4a_uniform_equilibrium_2d`
14. `test_module4a_hotspot_diffusion_2d`
15. `test_module4a_steady_source_2d`

Outputs written automatically
-----------------------------
Module 3 outputs:
- `matlab/outputs/module3_2d/`

Module 4 ballistic-diffusive outputs:
- `matlab/outputs/module4_2d_ballistic_diffusive/`

Legacy Module 4a outputs:
- `matlab/outputs/module4a_2d/`

Generated files include:
- `*_results.mat`
- `*_final_temperature.png`
- `*_final_ballistic_divergence.png` (Module 4)
- `*_centerline_cuts.png`
- `*_history_metrics.png`
- `*_summary.txt`

Important numerical note
------------------------
The current Module 3, Module 4, and legacy Module 4a solvers all use explicit
time stepping. Module 4 adds a relaxation-time term and a ballistic front
resolution constraint, so the time step should satisfy the conservative
recommended dt reported in each summary file.

Near-term next steps
--------------------
- couple Module 4 temperature output into Module 3 coefficient updates
- compare Module 4 against the Fourier baseline in a formal diffusive-limit test
- add electrostatics (Module 2) on the same grid convention
- support stronger 2D ballistic closures beyond the current rectangular-domain model
- add implicit or semi-implicit stepping for longer transients and finer meshes
