Module 2 field-to-field FEM dataset pipeline
============================================

Purpose
-------
The canonical Module 2 learning contract is now a complete spatial field map:

  rho(nodes, case)  ->  phi(nodes, case)

on one fixed FEM mesh. The input is total charge density [C/m^3] at every mesh
node. The output is electrostatic potential [V] at those same nodes.

Gaussian parameters are NOT surrogate inputs. The default 17-case pilot still
uses one elliptical Gaussian defect population only as a deterministic
synthetic FIELD GENERATOR so that the field-to-field data path can be tested
before Modules 3 and 5 provide arbitrary physical fields.

Run
---
From the matlab directory:

  setup_project_paths
  test_module2_fem_all_2d
  [dataset, report] = main_module2_batch_fem_dataset();

The default v2 run saves:

  outputs/module2_batch_fem_2d/module2_transmon_field_to_field_gaussian_pilot_v2.mat
  outputs/module2_batch_fem_2d/module2_transmon_field_to_field_gaussian_pilot_v2_summary.txt

The older module2_transmon_gaussian_batch_v1 files, if present, are retained
only as historical outputs from the previous parameterized-source contract.

Canonical single-case input contract
------------------------------------
Create or receive an arbitrary nodal field and pass it explicitly:

  [mesh,~,~] = resolve_module2_mesh_2d(params);
  chargeField = make_module2_charge_field_2d(mesh, rho);
  result = solve_poisson_defect_space_charge_2d(params, chargeField);

A raw numeric rho vector is also accepted as the second solver argument.

Physical component-field composition
------------------------------------
Future coupled modules can provide scalar or nodal fields for

  p, n, ND_plus, NA_minus, Cdef, zdef

and combine them through

  chargeField = compose_module2_charge_field_2d(mesh, components, q);

which implements

  rho = q*(p - n + ND_plus - NA_minus + zdef.*Cdef).

Gaussian synthetic generator
----------------------------
The legacy Gaussian model now lives behind

  generate_module2_gaussian_charge_field_2d

and exists only to create controlled rho fields for verification and training
set generation. build_space_charge_module2_2d remains as a compatibility
wrapper for the current pointwise PINN prototype and older scripts.

Dataset contract
----------------
- schema: module2_field_to_field_fem_dataset_v2
- rho is mandatory nNodes-by-nCases input data
- phi is nNodes-by-nCases output/reference data
- mesh and tags are stored once
- trainCases, validationCases, and testCases refer to complete field cases
- syntheticGenerator contains Gaussian provenance for the default pilot only
- Gaussian generator parameters must not be fed to the final field surrogate
- diagnostics contains compact scalar FEM checks for each complete field case
- jj_sensitive remains a scoring interface and is never a voltage boundary

Efficiency contract
-------------------
For a fixed geometry/material/boundary configuration, the mesh, stiffness
matrix, Dirichlet-constrained matrix, and sparse Cholesky factor are reused.
Only the source-vector assembly and triangular substitutions change for each
new rho field.

Scaling rule
------------
Do not expand to hundreds of fields until the 17-case pilot tests and
validation report pass locally. Split by complete rho/phi field pairs; never
scatter nodes from one field configuration across training and test subsets.
