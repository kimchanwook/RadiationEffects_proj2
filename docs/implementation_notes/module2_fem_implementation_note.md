# Module 2 FEM implementation note

This note summarizes the implemented MATLAB path for Module 2.

## Governing equation

The solver computes the electrostatic potential `phi` from

```text
div(eps_si grad(phi)) = -rho
```

where `rho` is assembled from carriers, dopants, and effective charged-defect populations.

## Discretization

The current solver uses a Galerkin finite-element method with three-node linear triangular elements on a rectangular domain. The nodal unknown is electrostatic potential. For each element,

```text
K_e(a,b) = integral_e eps_si grad(N_a) dot grad(N_b) dA
b_e(a)   = integral_e N_a rho dA
```

For a linear triangle, the gradients of the shape functions are constant inside the element, so the element electric field is also constant.

## Boundary conditions

Dirichlet conditions are imposed strongly at selected boundary nodes. The default cases use left/right contacts as Dirichlet boundaries. Top/bottom boundaries are homogeneous natural Neumann boundaries unless otherwise specified.

## Main files

- `matlab/main_module2_electrostatics.m`
- `matlab/src/module2_electrostatics/default_module2_params.m`
- `matlab/src/module2_electrostatics/make_rectangular_tri_mesh_2d.m`
- `matlab/src/module2_electrostatics/build_space_charge_module2_2d.m`
- `matlab/src/module2_electrostatics/assemble_poisson_fem_2d.m`
- `matlab/src/module2_electrostatics/compute_element_stiffness_triangle.m`
- `matlab/src/module2_electrostatics/compute_element_source_triangle.m`
- `matlab/src/module2_electrostatics/apply_dirichlet_bc.m`
- `matlab/src/module2_electrostatics/solve_poisson_defect_space_charge_2d.m`
- `matlab/src/module2_electrostatics/compute_electric_field_from_potential_2d.m`

## Verification tests

- `test_module2_zero_charge_2d.m`
- `test_module2_linear_potential_2d.m`
- `test_module2_uniform_space_charge_2d.m`
- `test_module2_localized_defect_charge_2d.m`

## Next coupling step

The present implementation creates a local Gaussian charged-defect population internally. The next step is to replace that synthetic field with a defect concentration field exported from Module 3 and evaluate

```text
rho_def = q * sum_i z_i C_i(x,y,t)
```

on the Module 2 mesh.
