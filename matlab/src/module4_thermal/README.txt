Module 4 thermal implementation for the revised project architecture.

This directory now contains the first executable 2D ballistic-diffusive
thermal solver path for RadiationEffects_proj2.

Included pieces:
- temperature-field initialization
- volumetric source initialization and time evaluation
- reduced rectangular-domain ballistic flux closure
- explicit stepping for the reduced ballistic-diffusive PDE
- boundary-emission helper functions
- history output support and summary writing

Current model choices:
- 2D Cartesian silicon domain
- equivalent-temperature formulation for the medium/scattered energy
- explicit boundary-originated ballistic flux approximation using retarded
  emission times and exponential attenuation over an effective mean free path
- volumetric heat-source support for zero, Gaussian, Gaussian-pulse, and
  imported CSV-map source patterns

Legacy continuum thermal files remain in matlab/src/module4a_thermal/ as a
Fourier-baseline reference for comparison tests.
