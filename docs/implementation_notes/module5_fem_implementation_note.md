# Module 5 FEM implementation note

## Purpose

Module 5 solves the reduced 2D electron-hole drift-diffusion carrier transport problem using the electrostatic field from Module 2, defect fields from Module 3, and temperature-dependent transport coefficients from Module 4.

The first FEM implementation is intentionally a reduced but executable solver. It is meant to make the carrier-transport part of the project numerically explicit and interview-defensible before a fully self-consistent semiconductor device simulator is built.

## Governing equations

The carrier equations are written in conservative drift-diffusion-reaction form:

```text
n_t - div(D_n grad n + mu_n n E) = G - R_n
p_t - div(D_p grad p - mu_p p E) = G - R_p
```

The opposite sign in the field-driven term is essential: electrons and holes drift in opposite particle directions under the same electric field.

## FEM discretization

The solver uses the same rectangular triangular mesh utility already used by Modules 2-4:

```text
make_rectangular_tri_mesh_2d.m
```

The carrier fields are approximated with linear triangular shape functions:

```text
n_h = sum_a N_a n_a
p_h = sum_a N_a p_a
```

The assembled semidiscrete carrier equation is

```text
M dc/dt + (K_D + K_E + K_R)c = f_G + f_R
```

where `c` is either the electron density vector or the hole density vector.

## Matrix meanings

- `M`: consistent carrier mass matrix from the time-derivative term
- `K_D`: diffusion matrix from `D grad c`
- `K_E`: drift/advection matrix from the electric-field term
- `K_R`: linearized recombination matrix
- `f_G`: volumetric generation vector
- `f_R`: equilibrium restoring source from the linear lifetime recombination model

The drift matrix is generally nonsymmetric.

## Time stepping

The first time integrator is backward Euler:

```text
(M/dt + K_D + K_E + K_R)c^{k+1} = (M/dt)c^k + f_G + f_R
```

This is robust for the reduced diffusion-reaction tests and provides a stable starting point for later nonlinear SRH and self-consistent Poisson coupling.

## Boundary conditions

The first implementation supports:

1. Strong Dirichlet carrier concentrations at selected contact boundaries.
2. Natural zero-normal-flux conditions on insulating or symmetry boundaries.

Surface recombination is documented in the physics note as a Robin-type extension but is not required for the first verification path.

## Main files

- `main_module5_drift_diffusion.m`: primary Module 5 FEM driver
- `main_module5_fem_drift_diffusion.m`: compatibility wrapper
- `default_module5_fem_params.m`: default parameter structure
- `assemble_carrier_fem_2d.m`: mass, diffusion, drift, recombination, and source assembly
- `solve_drift_diffusion_carrier_fem_2d.m`: backward-Euler carrier solver
- `evaluate_module5_fem_coefficients_2d.m`: electric field, mobility, diffusivity, defects, source, and recombination coefficients
- `compute_current_density_fem_2d.m`: elementwise current-density postprocessing
- `plot_module5_fem_result_2d.m`: nodal carrier and scalar-field plotting
- `plot_module5_fem_current_2d.m`: elementwise total-current plotting
- `write_module5_fem_summary.m`: summary writer

## Verification cases

The first FEM tests are:

1. `test_module5_fem_uniform_no_field_2d.m`: uniform no-field preservation.
2. `test_module5_fem_lifetime_recombination_2d.m`: uniform lifetime recombination against the backward-Euler analytic recurrence.
3. `test_module5_fem_gaussian_diffusion_2d.m`: inventory conservation and smoothing of a Gaussian carrier packet with zero-flux boundaries.
4. `test_module5_fem_field_drift_sign_2d.m`: conventional electron and hole current signs under a uniform electric field.

## Near-term extensions

- Replace the linear lifetime recombination closure with nonlinear SRH recombination.
- Add Robin boundary terms for surface recombination.
- Couple Module 5 carrier densities back into Module 2 Poisson solves.
- Add stabilization, such as upwind/SUPG, for high-drift Péclet-number cases.
- Add terminal-current integration along explicit contact boundaries.
