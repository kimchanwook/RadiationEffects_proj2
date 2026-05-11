# Module 4 FEM Implementation Note

## Purpose

This note documents the first finite-element implementation path for Module 4: two-dimensional ballistic-diffusive thermal transport in silicon. The purpose is to make the thermal solver explainable from the FEM standpoint, not only from the physics standpoint.

The implemented FEM equation is the temperature form of the reduced ballistic-diffusive model:

```text
tau*C*T_tt + C*T_t - div(k grad T) = Q + tau*Q_t - div(q_b)
```

where `T` is the medium-equivalent temperature, `C = rho*cp` is volumetric heat capacity, `k` is thermal conductivity, `Q` is volumetric heat generation, and `q_b` is the reduced ballistic heat-flux contribution.

## Discretization

The solver uses a rectangular two-dimensional domain split into linear three-node triangular elements. Each rectangular cell is divided into two counter-clockwise triangles. The primary unknown is the nodal temperature vector `T`.

The local approximation on one element is

```text
T_h(x,y,t) = N1(x,y)*T1(t) + N2(x,y)*T2(t) + N3(x,y)*T3(t)
```

where the `N_i` are linear triangular shape functions.

## Element matrices

For each triangular element of area `A_e`, the consistent heat-capacity matrix is

```text
M_e = C*A_e/12 * [2 1 1; 1 2 1; 1 1 2]
```

The thermal conductivity matrix is

```text
K_e = k*A_e*(gradN*gradN')
```

where `gradN` contains the constant shape-function gradients inside the element.

## Global equation

After assembly, the semi-discrete equation is

```text
tau*M*Tddot + M*Tdot + K*T = F(t)
```

where `F(t)` is the assembled source vector for

```text
S = Q + tau*dQdt - div(q_b)
```

## Time stepping

The first FEM implementation uses backward Euler in the first-order variables

```text
V = T_t
```

Eliminating `V^{n+1}` gives the linear system

```text
(tau/dt^2*M + 1/dt*M + K)*T_new
  = F_new + (tau/dt^2 + 1/dt)*M*T_old + (tau/dt)*M*V_old
```

Then

```text
V_new = (T_new - T_old)/dt
```

If `tau = 0`, the update reduces to the standard implicit heat equation step:

```text
(1/dt*M + K)*T_new = F_new + 1/dt*M*T_old
```

## Boundary conditions

The default boundary condition is natural homogeneous conductive flux:

```text
k grad(T).n = 0
```

This enters naturally through the weak form and does not require extra matrix terms. Optional fixed-temperature Dirichlet boundaries are supported by strongly replacing matrix rows with prescribed nodal values.

## Ballistic source closure

The first FEM path does not perform full angular Boltzmann quadrature. It reuses the reduced rectangular-domain boundary-emission closure from the structured-grid Module 4 path. Boundary-emitted ballistic fluxes are evaluated at mesh nodes, and a nodal approximation to `-div(q_b)` is included in the FEM source vector.

This is a reduced first implementation. The purpose is to provide a clean FEM location for ballistic source physics while preserving a simple verification path.

## MATLAB file map

- `main_module4_fem_ballistic_diffusive_thermal.m`: top-level FEM driver
- `default_module4_fem_params.m`: default FEM parameters
- `finalize_module4_fem_params.m`: derived parameters and output setup
- `compute_element_heat_capacity_triangle.m`: element heat-capacity matrix
- `compute_element_conductivity_triangle.m`: element conductivity matrix
- `assemble_thermal_fem_2d.m`: global thermal matrix assembly
- `assemble_thermal_source_fem_2d.m`: global source-vector assembly
- `evaluate_module4_fem_source_2d.m`: volumetric and ballistic source evaluation
- `solve_ballistic_diffusive_thermal_fem_2d.m`: backward-Euler FEM time stepping
- `get_module4_fem_dirichlet_nodes.m`: fixed-temperature node selection
- `apply_module4_dirichlet_bc.m`: strong Dirichlet boundary insertion
- `plot_module4_fem_result_2d.m`: triangular FEM field plotting
- `write_module4_fem_summary.m`: scalar diagnostic output

## Verification cases

The first FEM tests are:

1. `test_module4_fem_uniform_equilibrium_2d.m`: checks that a uniform no-source field remains uniform.
2. `test_module4_fem_gaussian_diffusion_2d.m`: checks the Fourier limit with `tau = 0`, no ballistic term, and insulated-boundary energy conservation.
3. `test_module4_fem_uniform_source_2d.m`: checks a spatially uniform source against the analytic uniform ballistic-diffusive temporal response.

These tests should be run in MATLAB after `setup_project_paths`.
