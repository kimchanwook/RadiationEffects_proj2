# RadiationEffects_proj2 Module 1: Geant4 Transmon Energy Deposition

This is a second, independent Geant4 application under `geant4/`. It does not modify or replace `module1_silicon_edep`.

The detector geometry is based on Figure 1 and the dimensions in:

```text
docs/physics_notes/module9_transmon_geometry_microwave_package_fem_domains.pdf
```

## Encoded 3D geometry

All named physical objects shown in the full microwave-aware Module 9 reference are represented:

- high-resistivity silicon substrate: `5 mm x 3 mm x 0.5 mm`
- patterned Al lambda/2 CPW resonator, approximately `7.6 mm` center-conductor length
- neighboring CPW ground traces with `10 um` strip width and `6 um` gap
- two-finger Al coupling capacitor and qubit-side route
- left and right Al transmon pads: `600 um x 300 um x 100 nm` each
- connected Al junction leads: `8 um` wide and `40 um` long
- one effective `1 um x 1 um` Al/AlOx/Al Josephson-junction region
- AlOx barrier thickness: `2 nm`
- Cu/Pd/Au quasiparticle trap: `100 um x 10 um x 80 nm`, located on the right pad
- Cu/Au backside heat-sink patch: `300 um x 300 um x 1 um`
- patterned perimeter/bias/control wiring
- ten on-chip Al bond pads
- ten external Au package pads
- ten semicircular Au wire bonds, `25 um` diameter

The chip top surface is `z = 0`; the substrate occupies `-0.5 mm <= z <= 0`.

## Modeling scope

This is a Geant4 radiation-transport geometry. It preserves the named components, baseline dimensions, material identities, topology, and major 3D package features needed for particle transport and energy-deposition scoring.

It is not a microwave eigenmode model. The meandered CPW uses square CSG turns, the package pads are simplified blocks, and the effective JJ uses a lateral `2 nm` AlOx slab so the left/right node separation remains explicit without overlapping Geant4 volumes. Use HFSS, COMSOL RF, Sonnet, or a comparable electromagnetic solver for resonant frequency, coupling rate, impedance, participation-ratio, and S-parameter predictions.

## Source control

The application uses `G4ParticleGun`. Launching without a macro opens an interactive Qt session. Standard Geant4 commands can then change the particle, energy, position, and direction:

```text
/gun/particle proton
/gun/energy 100 MeV
/gun/position 0 0 1 mm
/gun/direction 0 0 -1
/run/beamOn 1
```

The constructor default is a 10 MeV proton at `(0, 0, +1 mm)` directed along `-z`.

## Build

```bash
cd geant4/module1_transmon_edep
mkdir -p build
cd build
cmake ..
cmake --build . -j$(nproc)
```

Source the Geant4 environment first, for example:

```bash
source $HOME/opt/geant4/v11.4.1/bin/geant4.sh
```

## Run interactively

```bash
./module1_transmon_edep
```

The application automatically executes `init_vis.mac`, draws the geometry, and waits for commands.

A small trajectory demonstration is also available:

```bash
./module1_transmon_edep vis_run.mac
```

## Run in batch mode

```bash
./module1_transmon_edep run_batch.mac
```

## Check geometry overlaps

```bash
./module1_transmon_edep geometry_check.mac
```

The detector also enables overlap checking on every placement during construction.

## Output

The application deliberately uses the serial Geant4 run manager so HDF5 ntuples are written to one deterministic file. The Geant4 analysis manager writes:

```text
output/module1_transmon_edep.hdf5
output/component_map.csv
```

Three ntuples are created:

- `steps`: each nonzero energy-deposition step, including component ID, copy number, particle, position, and deposited energy
- `events`: total deposited energy and number of hit components per event
- `component_events`: sparse per-event deposited energy separated by geometry component

`component_map.csv` defines the stable integer component IDs. This allows later MATLAB or Python code to isolate deposition in the substrate, JJ, pads, trap, resonator, heat sink, or package wiring.

## Important transport note

The metal films and oxide are far thinner than the substrate. The code applies local `G4UserLimits` to the thin structures, but production thresholds and electromagnetic physics settings must still be chosen carefully for a particular particle/energy campaign. The default `FTFP_BERT` list is retained for consistency with the original Module 1 project; low-energy electron/photon studies may require a dedicated electromagnetic configuration and explicit verification against reference stopping-power data.
