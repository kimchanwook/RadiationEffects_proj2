MATLAB Implementation Notes for Radiation Effects Project 2
==========================================================

Tool split
----------
- Module 1 (radiation transport and deposited-energy generation): Geant4
- Modules 2-7 (device/material response and scalable prediction): MATLAB

Current implementation status
-----------------------------
This package now includes seven working code paths:

1. Module 2: first 2D finite-element electrostatic Poisson implementation
1b. Module 2 PINN: standalone physics-inspired neural-network Poisson surrogate demo
2. Module 3: first 2D defect evolution implementation plus a new linear-triangle FEM defect diffusion-reaction path
3. Module 4: first executable 2D ballistic-diffusive thermal implementation plus a new linear-triangle FEM thermal path
4. Module 5: first linear-triangle FEM drift-diffusion carrier-transport path
5. Module 6: first staggered linear-triangle FEM coupling scaffold for Modules 2-5
6. Legacy Module 4a: archived 2D Fourier thermal baseline for comparison


Module 2 electrostatics pieces now included:
- structured rectangular triangular mesh generation
- linear triangular finite-element assembly for the 2D Poisson equation
- defect-dependent space-charge evaluation from effective charged defects
- strong Dirichlet boundary-condition insertion and natural zero-Neumann edges
- electric-field postprocessing from the solved electrostatic potential
- verification cases for zero charge, linear Laplace solution, uniform space charge, and localized defect charge


Module 2 PINN pieces now included:
- standalone MATLAB entry point `main_module2_pinn_electrostatics.m`
- physics residual for eps_si*(d2phi/dx2 + d2phi/dy2) + rho = 0
- Dirichlet and natural-Neumann boundary-condition loss terms
- optional sparse FEM anchor data for stabilization
- FEM-reference comparison plots, PDE-residual plots, field plots, and training-loss curves

Module 3 FEM pieces now included:
- linear triangular finite-element weak-form implementation for diffusion-reaction evolution
- consistent mass matrix, diffusion matrix, and first-order annealing matrix assembly
- implicit backward-Euler time stepping
- natural homogeneous zero-flux boundary handling
- verification cases for pure annealing, uniform-state preservation, and Gaussian diffusion inventory conservation

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

Legacy Module 4a baseline pieces retained:
- explicit transient heat-equation stepping for a single temperature field
- zero-normal-gradient boundary handling for diffusion-type thermal tests
- uniform equilibrium, hotspot diffusion, and steady-source reference cases

Recommended run order
---------------------
1. `setup_project_paths`
2. `main_module2_electrostatics('localized_defect_charge')`
3. `main_module2_electrostatics('linear_potential')`
4. `main_module2_electrostatics('uniform_space_charge')`
4b. `main_module2_pinn_electrostatics('localized_defect_charge')`
5. `main_module3_2d_defect_evolution('gaussian_diffusion')`
6. `main_module3_2d_defect_evolution('pure_annealing')`
7. `main_module3_fem_defect_evolution('gaussian_diffusion')`
8. `main_module3_fem_defect_evolution('pure_annealing')`
9. `main_module4_2d_ballistic_diffusive_thermal('uniform_equilibrium')`
10. `main_module4_2d_ballistic_diffusive_thermal('localized_pulse')`
11. `main_module4_2d_ballistic_diffusive_thermal('boundary_heating')`
12. `main_module4_fem_ballistic_diffusive_thermal('uniform_equilibrium')`
13. `main_module4_fem_ballistic_diffusive_thermal('gaussian_diffusion')`
14. `main_module4_fem_ballistic_diffusive_thermal('uniform_source')`
15. `main_module5_drift_diffusion('uniform_no_field')`
16. `main_module5_drift_diffusion('lifetime_recombination')`
17. `main_module5_drift_diffusion('gaussian_diffusion')`
18. `main_module5_drift_diffusion('field_drift')`
19. `main_module6_multiphysics('smoke')`
20. `main_module6_multiphysics('defect_field_coupling')`
21. `main_module6_multiphysics('thermal_feedback')`
22. `main_module4a_2d_continuum_thermal('uniform_equilibrium')`  % archived Fourier baseline
20. `test_module2_zero_charge_2d`
21. `test_module2_linear_potential_2d`
22. `test_module2_uniform_space_charge_2d`
23. `test_module2_localized_defect_charge_2d`
24. `test_module3_gaussian_diffusion_2d`
25. `test_module3_pure_annealing_2d`
26. `test_module3_fem_gaussian_diffusion_2d`
27. `test_module3_fem_pure_annealing_2d`
28. `test_module3_fem_uniform_state_2d`
29. `test_module4_bd_uniform_equilibrium_2d`
30. `test_module4_bd_localized_pulse_2d`
31. `test_module4_bd_boundary_heating_2d`
32. `test_module4_fem_uniform_equilibrium_2d`
33. `test_module4_fem_gaussian_diffusion_2d`
34. `test_module4_fem_uniform_source_2d`
35. `test_module5_fem_uniform_no_field_2d`
36. `test_module5_fem_lifetime_recombination_2d`
37. `test_module5_fem_gaussian_diffusion_2d`
38. `test_module5_fem_field_drift_sign_2d`
39. `test_module6_fem_smoke_2d`
40. `test_module6_fem_charge_consistency_2d`
41. `test_module4a_uniform_equilibrium_2d`
40. `test_module4a_hotspot_diffusion_2d`
41. `test_module4a_steady_source_2d`

Outputs written automatically
-----------------------------
Module 2 outputs:
- `matlab/outputs/module2_2d/`

Module 2 PINN outputs:
- `matlab/outputs/module2_pinn_2d/`

Module 3 outputs:
- `matlab/outputs/module3_2d/`
- `matlab/outputs/module3_fem_2d/`

Module 4 ballistic-diffusive outputs:
- `matlab/outputs/module4_2d_ballistic_diffusive/`

Module 4 FEM outputs:
- `matlab/outputs/module4_fem_2d/`

Module 5 FEM outputs:
- `matlab/outputs/module5_fem_2d/`

Module 6 FEM outputs:
- `matlab/outputs/module6_fem_2d/`

Legacy Module 4a outputs:
- `matlab/outputs/module4a_2d/`

Generated files include:
- `*_results.mat`
- `*_potential.png` (Module 2)
- `*_space_charge.png` (Module 2)
- `*_electric_field_magnitude.png` (Module 2)
- `*_pinn_potential.png` (Module 2 PINN)
- `*_pinn_abs_potential_error.png` (Module 2 PINN)
- `*_pinn_pde_residual.png` (Module 2 PINN)
- `*_pinn_training_loss.png` (Module 2 PINN)
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
- `*_centerline_cuts.png`
- `*_history_metrics.png`
- `*_summary.txt`

Important numerical note
------------------------
The current Module 2 solver is steady-state linear finite-element assembly. The Module 2 PINN entry point is a standalone Deep Learning Toolbox demonstration that trains a neural surrogate using the Poisson residual, boundary losses, and optional sparse FEM anchors. Module 3 now has both an explicit structured-grid solver and an implicit linear-triangle FEM solver. Module 4 now has both the original explicit structured-grid ballistic-diffusive solver and a new implicit linear-triangle FEM solver. Module 5 now has a first implicit linear-triangle FEM drift-diffusion solver with known fields and linearized recombination. Module 6 now has a first staggered linear-triangle FEM coupling scaffold that passes fields between the Module 2, 3, 4, and 5 reduced FEM blocks. The legacy Module 4a Fourier baseline remains explicit. The structured-grid Module 4 path adds a relaxation-time term and a ballistic front resolution constraint, so the time step should satisfy the conservative recommended dt reported in each summary file.

Near-term next steps
--------------------
- run the new Module 3, Module 4, Module 5, and Module 6 FEM verification tests in MATLAB
- compare Module 4 FEM results against the structured-grid ballistic-diffusive path and archived Fourier baseline
- couple Module 4 FEM temperature output into Module 3 and Module 5 coefficient updates
- compare Module 4 against the Fourier baseline in a formal diffusive-limit test
- couple Module 3 defect fields into the Module 2 FEM space-charge source
- feed Module 2 electric fields into Module 5 FEM drift-diffusion cases
- replace the Module 5 linear lifetime sink with full nonlinear SRH recombination
- support stronger 2D ballistic closures beyond the current rectangular-domain model
- add implicit or semi-implicit stepping for longer transients and finer meshes
