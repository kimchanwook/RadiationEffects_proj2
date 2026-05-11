# Module 3 FEM implementation note

## Purpose

This note documents the first finite-element path for Module 3 defect diffusion-reaction evolution. The existing structured-grid Module 3 solver is retained, but this FEM path provides a clearer interview-facing numerical formulation parallel to the Module 2 linear-triangle electrostatic solver.

## Governing equation

The FEM path solves the scalar transient equation

```text
dC/dt = div(D grad C) - kAnn C + S
```

where `C` is defect concentration, `D` is defect diffusivity, `kAnn` is the first-order annealing coefficient, and `S` is an optional volumetric defect source term.

## Weak form

With test function `w`, the weak form is

```text
int_Omega w dC/dt dOmega
+ int_Omega D grad(w).grad(C) dOmega
+ int_Omega w kAnn C dOmega
= int_Omega w S dOmega.
```

Homogeneous zero-flux boundaries are natural in this weak form, so no explicit boundary matrix contribution is needed when `n dot D grad C = 0`.

## Discrete system

Linear triangular shape functions are used. Assembly gives

```text
M dC/dt + (Kdiff + Kreact) C = f
```

where:

- `M` is the consistent FEM mass matrix.
- `Kdiff` is the diffusion matrix from `int D grad(Na).grad(Nb) dOmega`.
- `Kreact` is the first-order annealing matrix from `int kAnn Na Nb dOmega`.
- `f` is the optional source vector.

The first time integrator is backward Euler:

```text
[M + dt*(Kdiff + Kreact)] C^{n+1} = M*C^n + dt*f.
```

## MATLAB file map

- `matlab/main_module3_fem_defect_evolution.m` - top-level FEM driver.
- `matlab/src/module3_defects/default_module3_fem_params.m` - default FEM case parameters.
- `matlab/src/module3_defects/initialize_defect_field_fem_2d.m` - nodal initial concentration fields.
- `matlab/src/module3_defects/compute_element_mass_triangle.m` - consistent T3 mass matrix.
- `matlab/src/module3_defects/compute_element_diffusion_triangle.m` - T3 diffusion matrix.
- `matlab/src/module3_defects/assemble_defect_fem_2d.m` - global mass, diffusion, reaction, and source assembly.
- `matlab/src/module3_defects/solve_defect_diffusion_reaction_fem_2d.m` - implicit time stepping and diagnostics.
- `matlab/src/module3_defects/plot_module3_fem_result_2d.m` - basic plots.
- `matlab/src/module3_defects/write_module3_fem_summary.m` - run summary output.

## Verification tests

- `test_module3_fem_uniform_state_2d.m`: verifies that diffusion preserves a uniform concentration under zero-flux boundaries.
- `test_module3_fem_pure_annealing_2d.m`: verifies uniform first-order decay against the analytic exponential solution.
- `test_module3_fem_gaussian_diffusion_2d.m`: verifies inventory conservation and peak reduction for pure diffusion.

## Relation to the legacy Module 3 grid solver

The structured-grid Module 3 solver remains useful for rapid experiments and conservative finite-volume intuition. The FEM path is useful for explaining the weak-form formulation, shape functions, element matrices, natural boundary conditions, and future extension to non-rectangular geometries.
