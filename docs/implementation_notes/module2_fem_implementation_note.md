# Module 2 FEM implementation note

> The detailed, authoritative operational guide is
> `module2_fem_implementation_note.tex/.pdf`. This Markdown file is a concise
> compatibility overview.

## Current input contract

Module 2 now accepts an **arbitrary nodal total-charge-density field** as its
canonical physics input:

```text
rho(nodes) -> FEM Poisson solve -> phi(nodes)
```

`rho` contains one value in C/m^3 for every active FEM node. The solver does
not require Gaussian center/width/amplitude parameters.

Physical component maps can be combined first:

```text
rho = q * (p - n + ND_plus - NA_minus + zdef .* Cdef)
```

where each component may be a scalar or a nodal field. The helper
`compose_module2_charge_field_2d.m` performs this composition.

## Gaussian source role

The previous Gaussian source model is retained only as a **synthetic field
generator** for controlled tests and pilot training data. Its parameters are
provenance metadata, not the final field-surrogate inputs.

## Governing equation

```text
div(eps_si grad(phi)) = -rho
```

## Discretization

The current solver uses a Galerkin FEM with three-node linear triangular
elements. For each element,

```text
K_e(a,b) = integral_e eps_si grad(N_a) dot grad(N_b) dA
b_e(a)   = integral_e N_a rho dA
```

## Main field-contract files

- `matlab/src/module2_electrostatics/make_module2_charge_field_2d.m`
- `matlab/src/module2_electrostatics/validate_module2_charge_field_2d.m`
- `matlab/src/module2_electrostatics/compose_module2_charge_field_2d.m`
- `matlab/src/module2_electrostatics/generate_module2_gaussian_charge_field_2d.m`
- `matlab/src/module2_electrostatics/solve_poisson_defect_space_charge_2d.m`
- `matlab/src/module2_electrostatics/solve_module2_nodal_charge_batch_2d.m`
- `matlab/src/module2_electrostatics/generate_module2_batch_fem_dataset_2d.m`

`build_space_charge_module2_2d.m` remains as a compatibility wrapper for the
older pointwise PINN code and legacy scripts.

## Field-to-field batch dataset

The current dataset schema is:

```text
module2_field_to_field_fem_dataset_v2
```

with mandatory matrices

```text
rho : nNodes x nCases
phi : nNodes x nCases
```

Train/validation/test splits are made by complete field cases. The default
17-field pilot uses Gaussian-generated charge maps, but those Gaussian
parameters are stored only under `syntheticGenerator`.

## Verification tests added for the new contract

- `test_module2_explicit_charge_field_2d.m`
- `test_module2_charge_component_fields_2d.m`
- existing analytical, Module 9, and batch tests remain in the suite

## Coupling implication

Module 3 and Module 5 can eventually provide their spatial defect/carrier maps
directly. No Gaussian fit is required between modules. If meshes differ, the
remaining coupling work is to define and validate interpolation or conservative
projection before forming the Module 2 total-charge field.
