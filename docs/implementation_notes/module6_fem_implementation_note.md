# Module 6 FEM implementation note

Module 6 is the coupled multiphysics integration layer. The first executable implementation is a reduced staggered finite-element driver rather than a fully monolithic semiconductor device simulator.

## Purpose

The Module 6 FEM path demonstrates how the individual FEM modules communicate on a common two-dimensional triangular mesh:

1. Module 3-style defect evolution updates the nodal defect concentration `C`.
2. Module 2-style Poisson assembly converts `C`, `n`, `p`, and dopants into the space-charge density `rho` and solves for `phi` and `E`.
3. Module 5-style carrier assembly advances `n` and `p` under the current electric field and defect-dependent coefficients.
4. Module 4-style thermal assembly advances `T` using radiation heat and optional Joule heating.
5. The cycle is repeated until the coupled maps are self-consistent for the time step.

## Main files

- `matlab/main_module6_multiphysics.m`
- `matlab/src/module6_coupling/default_module6_fem_params.m`
- `matlab/src/module6_coupling/initialize_module6_fem_state.m`
- `matlab/src/module6_coupling/solve_coupled_multiphysics_fem_2d.m`
- `matlab/src/module6_coupling/update_module6_electrostatics.m`
- `matlab/src/module6_coupling/compute_module6_metrics.m`
- `matlab/src/module6_coupling/write_module6_fem_summary.m`
- `matlab/src/module6_coupling/plot_module6_fem_result_2d.m`

## Current numerical model

All primary fields are represented as nodal values on one linear triangular mesh:

- defect concentration: `C`
- electrostatic potential: `phi`
- temperature: `T`
- electron concentration: `n`
- hole concentration: `p`

The first coupled driver uses a Picard-style staggered iteration. It is deliberately conservative: each subproblem is solved with matrices already developed for the Module 2, 3, 4, and 5 FEM paths.

## Current limitations

- The driver uses one effective defect species rather than a full defect reaction network.
- Poisson and drift-diffusion are coupled, but contacts are simplified.
- Thermal feedback is reduced to a Fourier-style thermal update inside Module 6, although the standalone Module 4 path contains the richer ballistic-diffusive thermal model.
- Carrier recombination is linearized through effective lifetimes and optional defect-dependent trap terms.
- The implementation is intended as a coupling scaffold and verification platform before a stronger monolithic solver is attempted.

## Verification tests

Two starter tests are included:

- `test_module6_fem_smoke_2d.m`: checks that the coupled fields remain finite and produce a nonzero electric field under contact bias.
- `test_module6_fem_charge_consistency_2d.m`: checks that the Poisson source term is consistent with the current defect, carrier, and dopant fields.

These tests should be run after executing `setup_project_paths` in MATLAB.
