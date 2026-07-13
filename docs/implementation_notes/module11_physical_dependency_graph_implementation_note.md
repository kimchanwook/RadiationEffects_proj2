# Module 11 implementation note: physical dependency graph discovery

## Status and scope

Module 11 is a proof-of-concept plan for learning the **directed physical dependency graph** among variables and parameters appearing in Modules 2--5. It is not an implemented GNN yet.

The learning target is limited to:

- directed edge existence;
- direct versus indirect dependence;
- physical relation type;
- state-dependent edge strength;
- monotonic sign when meaningful;
- zero-lag versus delayed influence;
- physical lag class or delay;
- strongly connected feedback groups;
- the topological order of the SCC condensation graph;
- calibrated uncertainty.

The following are explicitly outside Module 11: mesh-node adjacency, mesh-level graph simulation, numerical solver order, block partitioning, relaxation-factor selection, update frequency, runtime optimization, and fallback solver scheduling.

## First variable-node set

The first graph should contain a reduced set of approximately 18 nodes:

`C, T, D_C, rho, phi, E, n, p, mu_n, mu_p, D_n, D_p, tau_n, tau_p, J, G, Q_rad, Q_J`.

A later graph can separate defect species, electron/hole currents, reaction rates, and heat-source components.

## Candidate edge strategy

Use a physics-defined candidate superset rather than a fully connected graph. Every candidate ordered pair should store:

- source node;
- target node;
- prior relation type;
- trusted, candidate, or forbidden status;
- expected sign if known;
- allowed lag classes;
- mechanism-switch name;
- continuous edge multiplier name;
- intervention that isolates the mechanism.

The adjacency convention is source row, target column: `A(i,j)` means `i -> j`.

## Synthetic generator requirements

Each synthetic baseline case must include:

1. a sampled graph family;
2. active mechanism switches and edge multipliers;
3. independent physical parameters;
4. dependent coefficients generated through valid constitutive laws;
5. radiation, bias, and boundary forcing;
6. initial fields;
7. raw physical trajectories;
8. variable-node features or POD coefficients;
9. exact directed adjacency;
10. edge relation type, sign, and lag;
11. physics residuals and conservation diagnostics;
12. matched intervention identifiers;
13. random seed and generator version.

### Required graph switches

The first generator should expose at least:

- `C -> rho`: charged-defect space charge;
- `C -> mu_n, mu_p`: defect-induced mobility degradation;
- `C -> tau_n, tau_p`: defect-assisted trapping/recombination;
- `E -> C`: charged-defect drift;
- `(J,E) -> Q_J -> T`: Joule heating;
- `R -> T`: recombination heating;
- `T -> defect reactions`: thermally activated reaction pathway.

Each switch should support hard removal and, where meaningful, continuous scaling.

## Matched interventions

For each selected baseline case, create counterfactuals that preserve parameters, sources, initial conditions, and random seed while changing one mechanism. Required intervention classes are:

- hard edge removal;
- soft edge scaling;
- node clamping, which removes incoming influence while preserving outgoing effects;
- isolated source excitation;
- selected factorial combinations of edge switches.

Intervention pairs must remain in the same train/validation/test split.

## Feature extraction

The graph is variable based, even though raw quantities may be fields. Convert each physical field into a node feature vector containing a controlled subset of:

- mean, standard deviation, minimum, maximum;
- L2 norm;
- gradient norm;
- robust quantiles;
- temporal derivative descriptors;
- integral inventory or flux measures;
- optional POD coefficients;
- missing-data mask;
- variable type and unit metadata.

Do not create graph edges from spatial neighborhood information.

## Planned file map

- `matlab/main_module11_generate_dependency_dataset.m`
- `matlab/main_module11_train_dependency_gnn.m`
- `matlab/main_module11_evaluate_dependency_graph.m`
- `matlab/src/module11_gnn/build_candidate_variable_graph.m`
- `matlab/src/module11_gnn/sample_graph_family.m`
- `matlab/src/module11_gnn/sample_physical_parameters.m`
- `matlab/src/module11_gnn/sample_sources_initial_conditions.m`
- `matlab/src/module11_gnn/simulate_physical_graph_case.m`
- `matlab/src/module11_gnn/apply_physical_intervention.m`
- `matlab/src/module11_gnn/extract_variable_node_features.m`
- `matlab/src/module11_gnn/compute_physics_graph_labels.m`
- `matlab/src/module11_gnn/compute_graph_physics_residuals.m`
- `matlab/src/module11_gnn/train_graph_baselines.m`
- `matlab/src/module11_gnn/train_typed_dependency_mpnn.m`
- `matlab/src/module11_gnn/calibrate_edge_uncertainty.m`
- `matlab/src/module11_gnn/derive_physical_coupling_sequence.m`
- `matlab/tests/test_module11_direct_edge_recovery.m`
- `matlab/tests/test_module11_intervention_recovery.m`
- `matlab/tests/test_module11_lag_and_scc_recovery.m`
- `matlab/tests/test_module11_hidden_mechanism_uncertainty.m`

These files are planned; their presence is not claimed in the current package.

## Training ladder

1. Analytic chain, common-cause, and delayed-feedback systems.
2. Fixed graph with only trajectory prediction.
3. Fixed topology with learned continuous edge strengths.
4. Candidate topology with directed edge and relation-type prediction.
5. Lag prediction and SCC condensation.
6. Noise, missing variables, and hidden-mechanism discrepancy.
7. Reduced Module 2--5 field trajectories compressed to variable-node features.

## Baselines

The GNN must be compared against pairwise and lagged correlation, partial correlation, linear Granger-style tests, sparse nonlinear regression, an MLP pairwise edge classifier, fixed graph with learned strengths, and neural relational inference without physics constraints.

## Losses

The training objective should combine:

- next-state and rollout prediction;
- directed edge existence;
- edge relation type;
- lag classification or delay regression;
- physics equation residuals;
- charge, carrier, defect, and energy consistency;
- matched intervention response;
- graph sparsity;
- soft physical priors.

## Required evaluation

Report directed precision/recall/F1, structural Hamming distance, AUROC and AUPRC, direction accuracy, relation-type accuracy, lag error, edge-strength error, trajectory rollout error, intervention-effect error, SCC partition accuracy, condensation partial-order accuracy, physics residuals, and probability calibration.

## First executable milestone

Build a lumped eight-node generator for `C, T, rho, phi, E, n, p, J` with five switchable mechanisms. Generate 1,000--2,000 baseline cases plus matched interventions. Establish simple baselines before training a typed message-passing model.
