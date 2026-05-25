# RadiationEffects_proj2 Module 1: Geant4 Silicon Energy Deposition

This is the first custom Geant4 application for `RadiationEffects_proj2` Module 1.

## Physics / geometry implemented

- Target material: silicon, `G4_Si`
- Target size: `20 um x 20 um x 50 um`
- Target placement: centered at the origin
  - x range: `[-10 um, +10 um]`
  - y range: `[-10 um, +10 um]`
  - z range: `[-25 um, +25 um]`
- Default source: `G4ParticleGun`
  - particle: proton
  - energy: `10 MeV`
  - position: `(0, 0, +30 um)`
  - direction: `(0, 0, -1)`
- Physics list: `FTFP_BERT`
- Output: HDF5 using Geant4 analysis manager

The default source starts just above the top silicon face and shoots downward along `-z`.
You can override particle type, energy, source position, and direction in the macro using `/gun/...` commands.

## Build

From this directory:

```bash
mkdir -p build
cd build
cmake ..
cmake --build . -j$(nproc)
```

This assumes you already sourced your Geant4 installation, for example:

```bash
source $HOME/opt/geant4/v11.4.1/bin/geant4.sh
```

## Run batch mode

```bash
./module1_silicon_edep run_batch.mac
```

Expected output file:

```text
output/module1_silicon_edep.hdf5
```

Inspect with:

```bash
h5dump -n output/module1_silicon_edep.hdf5
```

## Run interactive visualization

```bash
./module1_silicon_edep
```

or:

```bash
./module1_silicon_edep vis_run.mac
```

If Qt opens but OpenGL rendering fails under WSL, try:

```bash
export G4UI_USE_QT=1
export G4VIS_DEFAULT_DRIVER="OGLSQt 1000x1000-0+0"
export LIBGL_ALWAYS_SOFTWARE=1
./module1_silicon_edep
```

## HDF5 contents

The app writes two ntuples:

### `steps`

Per-step deposited-energy records inside the silicon target:

| Column | Meaning |
|---|---|
| `eventID` | Geant4 event ID |
| `trackID` | track ID |
| `parentID` | parent track ID; 0 means primary |
| `stepID` | current step number on the track |
| `pdgCode` | PDG code of particle causing the energy deposition |
| `x_um`, `y_um`, `z_um` | midpoint of the step, in micrometers |
| `edep_eV` | deposited energy during the step, in eV |
| `stepLength_um` | step length, in micrometers |

### `events`

Event-level deposited-energy summary:

| Column | Meaning |
|---|---|
| `eventID` | Geant4 event ID |
| `totalEdep_eV` | total energy deposited in silicon during the event, in eV |
| `nDepositingSteps` | number of steps with nonzero deposited energy in silicon |

## Next planned extensions

- Add a configurable output filename through a Geant4 messenger.
- Add voxel/bin scoring for direct 2D/3D energy-deposition maps.
- Add particle/energy sweep macros.
- Add MATLAB/Python reader to convert HDF5 event/step data into Module 2--6 source terms.
