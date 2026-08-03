Implementation notes
====================

This folder contains module-specific numerical specifications, solver interfaces,
verification requirements, data schemas, and staged implementation plans.

Current notes
-------------
- module2_pinn_implementation_note.tex/.pdf: detailed how-to guide for running,
  testing, probing, tuning, and diagnosing the single-case Module 2 PINN with
  optional FEM anchors.
- module2_fem_implementation_note.tex/.pdf: detailed how-to guide for running,
  testing, probing, modifying, and diagnosing the Module 2 finite-element
  electrostatics implementation.
- module2_fem_implementation_note.md: earlier concise Module 2 FEM overview;
  the LaTeX/PDF note above is now the authoritative operational guide.
- module3_fem_implementation_note.md: finite-element defect diffusion-reaction implementation.
- module4_fem_implementation_note.md: finite-element ballistic-diffusive thermal implementation.
- module5_fem_implementation_note.md: finite-element drift-diffusion carrier implementation.
- module6_fem_implementation_note.md: staggered shared-mesh multiphysics coupling implementation.
- module11_physical_dependency_graph_implementation_note.md: planned graph-family generation, intervention-supervised directed edge discovery, lag/SCC inference, validation, and uncertainty workflow for the Module 2--5 physical-variable graph.
