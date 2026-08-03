Restructured documentation set
==============================

This folder keeps one large physics note per module inside `docs/physics_notes/`, matching the textbook-style documentation approach requested for this project.

The top-level `project_plan.pdf` is the single living roadmap document for the full repository.

Current physics notes
---------------------
- module1_geant4_energy_deposition.tex/.pdf
- module2_2d_electrostatics_defect_space_charge.tex/.pdf
- module3_2d_defect_evolution.tex/.pdf
- module3_cPIN.tex/.pdf - self-contained causal-PIN tutorial, implemented MATLAB benchmark reference, and Module 3 extension design for temporally ordered defect diffusion-reaction training
- module4_2d_ballistic_diffusive_thermal_transport.tex/.pdf
- module5_2d_drift_diffusion_defect_recombination.tex/.pdf
- module6_2d_coupled_multiphysics_integration.tex/.pdf
- module8_reduced_fidelity_importance_scoring.tex/.pdf
- module9_transmon_geometry_microwave_package_fem_domains.tex/.pdf
- module10_bcs_gl_tdgl_superconductivity_theory.tex/.pdf
- module11_gnn_physical_dependency_graph.tex/.pdf

Current implementation notes
----------------------------
- implementation_notes/module2_fem_implementation_note.tex/.pdf - detailed
  run, dependency, parameter, test, output, probing, and troubleshooting guide
  for the Module 2 FEM electrostatics code path.

Module summary slides
---------------------
- summary_slides.tex/.pdf - expandable Beamer summary deck. The current version contains thirty-one slides: three Module 2 baseline electrostatics slides, three Module 3 defect-evolution slides, four Module 4 thermal-transport slides, four Module 5 carrier-transport slides, four Module 6 coupled-multiphysics slides, four Module 2 PINN slides, four Module 2 CPINN slides, and five Module 11 GNN physical-dependency-graph slides. It intentionally keeps the deck equations-and-bullets only, with no drawings, illustrations, diagrams, or plots.

Module 11 explanatory figures are stored in `docs/physics_notes/figures/module11/`. They illustrate physical-variable graph learning, synthetic sampling, edge strengths, and training behavior; they are conceptual teaching and design figures, not measured project results.
