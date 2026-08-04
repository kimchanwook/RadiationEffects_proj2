Module 2 batch FEM dataset pipeline
===================================

Purpose
-------
This path generates a compact multi-configuration reference dataset on the
validated Module 9 transmon substrate. It is the required input contract for
the future conditional Module 2 PINN. The PINN source itself is not changed by
this implementation.

Run
---
From the matlab directory:

  setup_project_paths
  test_module2_batch_fem_dataset_2d
  [dataset, report] = main_module2_batch_fem_dataset();

The default run saves:

  outputs/module2_batch_fem_2d/module2_transmon_gaussian_batch_v1.mat
  outputs/module2_batch_fem_2d/module2_transmon_gaussian_batch_summary.txt

No plot is created by default. To export only the four configured audit cases:

  options = default_module2_batch_fem_options_2d();
  options.makeRepresentativePlots = true;
  [dataset, report] = main_module2_batch_fem_dataset(options);

Dataset contract
----------------
- mesh and tags are stored once
- parameters is nCases-by-5 in the order
  [C_peak, x_c, z_c, sigma_x, sigma_z]
- rho and phi are nNodes-by-nCases
- trainCases, validationCases, and testCases contain complete case indices
- diagnostics contains compact scalar FEM checks for each case
- jj_sensitive remains a scoring interface and is never a voltage boundary
- the stiffness matrix and Cholesky factors are intentionally not stored

Efficiency contract
-------------------
The mesh, stiffness matrix, tagged Dirichlet matrix, and sparse Cholesky factor
are each constructed once. Only charge evaluation, source-vector assembly, and
two triangular substitutions are repeated per configuration.

Scaling rule
------------
Do not expand to hundreds of cases until the 17-case pilot test and validation
report pass locally. When expanding the design, preserve complete-case splits;
never scatter nodes from one configuration across training and test subsets.
