Synthetic Module 1 output: three-strike radiation cascade in silicon

Geometry
--------
Lx = 20.0 um
Ly = 20.0 um
Lz = 50.0 um

Binning
-------
Nx = 100
Ny = 100
Nz = 250

Voxel size
----------
dx = 0.2 um
dy = 0.2 um
dz = 0.2 um

Deposited energies
------------------
High-energy strike:   1 MeV total deposited energy
Medium-energy strike: 100 keV = 0.1 MeV total deposited energy
Low-energy strike:    10 keV = 0.01 MeV total deposited energy

Normalization check
-------------------
high_MeV_sum   = 1
medium_MeV_sum = 0.1
low_MeV_sum    = 0.00999999999
total_MeV_sum  = 1.11

Main arrays
-----------
Edep_MeV[ix,iy,iz]     total deposited energy per voxel, in MeV
Edep_J[ix,iy,iz]       total deposited energy per voxel, in J
dose_Gy[ix,iy,iz]      absorbed dose per voxel, in Gy
E_high_MeV             high-event contribution only
E_medium_MeV           medium-event contribution only
E_low_MeV              low-event contribution only
event_id               dominant event label: 1=high, 2=medium, 3=low, 0=none

Coordinate arrays
-----------------
x_um, y_um, z_um are cell-centered coordinate arrays.
x_edges_um, y_edges_um, z_edges_um are bin-edge arrays.

Important modeling note
-----------------------
This is a synthetic Geant4-like source field. It is designed to provide a
downstream Module 1 interface for Modules 2-5 before the full Geant4 model
exists. It includes primary tracks and hand-constructed secondary branches,
but it is not a physics-list result from Geant4.
