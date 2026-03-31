Geant4 notes for Radiation Effects Project 2
============================================

Module 1 uses Geant4 to generate radiation energy-deposition data or a damage-source map.

Files included here
-------------------
- `macros/run_dep_silicon.mac` : simple Geant4-style macro placeholder
- `output_example/sample_deposition_profile.csv` : simple legacy example
- `output_example/sample_damage_map_2d.csv` : example 2D map for MATLAB Module 3 import testing

Current intended MATLAB handoff format for 2D damage-map import
---------------------------------------------------------------
CSV with columns:
- `x`      : x coordinate in the normalized or physical coordinate system used by the case
- `y`      : y coordinate in the normalized or physical coordinate system used by the case
- `damage` : scalar damage metric or defect-generation proxy

Near-term plan
--------------
- define physical units explicitly for Geant4-to-MATLAB transfer
- decide whether Module 3 consumes:
  1) an initial defect concentration field, or
  2) a defect-generation source term over time
- add a stricter translator from deposited energy to defect-generation density
