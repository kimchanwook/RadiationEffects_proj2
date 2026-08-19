Module 2 batch-output version note
==================================

The files named module2_transmon_gaussian_batch_v1.* in this directory were
generated before the Module 2 input contract was changed to field-to-field.
They are retained for reproducibility only and should be treated as legacy
artifacts.

Current code writes v2 outputs named:
  module2_transmon_field_to_field_gaussian_pilot_v2.mat
  module2_transmon_field_to_field_gaussian_pilot_v2_summary.txt

In v2, the neural-surrogate input is the full nodal rho field. Gaussian
parameters are only synthetic-generator provenance.
