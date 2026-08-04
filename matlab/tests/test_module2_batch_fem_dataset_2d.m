function test_module2_batch_fem_dataset_2d()
% TEST_MODULE2_BATCH_FEM_DATASET_2D Run the complete pilot-dataset suite.
setup_project_paths;
options = default_module2_batch_fem_options_2d();
options.saveDataset = false;
options.makeRepresentativePlots = false;
dataset = generate_module2_batch_fem_dataset_2d(options);

test_module2_batch_dataset_contract_2d(dataset, options);
test_module2_batch_factorization_reuse_2d(dataset);
test_module2_batch_single_case_equivalence_2d(dataset);
test_module2_batch_split_integrity_2d(dataset);
test_module2_batch_reproducible_design_2d(dataset);

fprintf('All Module 2 batch FEM dataset tests passed.\n');
end
