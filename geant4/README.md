# Geant4 applications

- `module1_silicon_edep/` - original `20 um x 20 um x 50 um` silicon target with optional tungsten cap.
- `module1_transmon_edep/` - full 3D transmon-chip/package geometry derived from Module 9 Figure 1, with interactive particle-gun control and per-component energy-deposition scoring.

Each directory is a standalone CMake project and should be built in its own `build/` directory.
