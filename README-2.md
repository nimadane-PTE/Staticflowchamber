# COMSOL-MATLAB Parametric Sweep Simulations for Methane Detection Canopy Optimization

This repository contains the COMSOL Multiphysics model and MATLAB LiveLink scripts used to optimize static flux chamber (canopy) geometry for methane emission detection from abandoned oil and gas wells. These simulations support the computational fluid dynamics (CFD) and machine learning optimization framework described in our study.

## Overview

The canopy is a cylindrical enclosure placed over an abandoned wellhead to concentrate methane emissions for sensor detection. Seven parameters govern the system's performance: well radius, well height, canopy radius, canopy height, punched hole radius, wind speed, and methane leak rate. To understand how these parameters affect methane-air mixing under the canopy, two phases of parametric simulations were conducted using COMSOL Multiphysics 6.4 with MATLAB LiveLink for automation.

## Repository Contents

| File | Description |
|------|-------------|
| `ComsolMatlab.m` | **Phase 1** — Single-parameter sweep script. Varies one parameter at a time across 5 levels while holding all others at baseline values |
| `LHSsweep.m` | **Phase 2** — Latin Hypercube Sampling (LHS) script. Simultaneously varies all parameters to capture cross-parameter interaction effects |

> **Note:** The COMSOL Multiphysics model file (`canopy_optimization.mph`) exceeds GitHub's file size limit and is not included in this repository. The model contains the 3D geometry, laminar flow physics, transport of concentrated species, and mesh configuration. To request the COMSOL model file, please contact: **nima.daneshvar.edu@gmail.com**

## Phase 1: Single-Parameter Sweeps (`ComsolMatlab.m`)

This script performs one-at-a-time parametric sweeps across seven design parameters to isolate the individual effect of each parameter on methane concentration distribution under the canopy.

**Parameters swept (5 levels each):**

| Parameter | Symbol | Range | Units |
|-----------|--------|-------|-------|
| Well height | Wheight | 0.150 – 0.350 | m |
| Canopy height | Cheight | 0.500 – 1.500 | m |
| Well radius | Wr | 0.05 – 0.25 | m |
| Canopy radius | Cr | 0.20 – 0.90 | m |
| Punched hole radius | PHr | 0.060 – 0.540 | m |
| Methane leak rate | Mq | 0.01 – 0.25 | kg/h |
| Wind speed | Aq | 0.05 – 1.25 | m/s |

**Baseline values:** Wheight = 0.15 m, Cheight = 1.0 m, Wr = 0.05 m, Cr = 0.6 m, PHr = 0.396 m, Mq = 0.05 kg/h, Aq = 0.95 m/s

**Total: 35 simulations, 35,000 observation points**

## Phase 2: Latin Hypercube Sampling (`LHSsweep.m`)

This script simultaneously varies all parameters using Latin Hypercube Sampling to explore cross-parameter effects across the design space.

**Sampling details:**
- 6 parameters sampled simultaneously (PHr is derived as a random fraction of Cr)
- Geometric validity constraints enforced: Cheight > Wheight + 0.01 m, Cr > Wr + 0.01 m
- Simulations that fail to converge are automatically skipped and replaced with new samples
- Runs are organized in batches for fault tolerance

**Total: ~1,000 successful simulations across multiple batches**

## How Each Simulation Works

For every parameter combination, the scripts:

1. Set the parameter values in the COMSOL model
2. Rebuild the geometry to reflect the new dimensions
3. Generate 1,000 uniformly distributed random observation points inside the annular canopy space (between the well wall and canopy wall), with a 1 cm safety margin from all boundaries
4. Run the time-dependent CFD simulation (0 to 1 minute, 0.1-minute intervals)
5. Interpolate methane concentration at all 1,000 points across all time steps
6. Export results to a CSV file with full parameter metadata in the header

## Output Format

Each simulation produces a CSV file containing:
- Header lines with all parameter values used
- 1,000 rows (one per observation point) with columns: point index, X, Y, Z coordinates, and methane concentration at each time step (t = 0.0 to 1.0 min)

## Requirements

- COMSOL Multiphysics 6.4 with CFD Module
- MATLAB with COMSOL LiveLink
- Statistics and Machine Learning Toolbox (for `lhsdesign` in Phase 2)

## Usage

1. Open MATLAB with COMSOL LiveLink enabled
2. Update the `modelPath` and `outputDir` variables in each script to match your local file paths
3. Run `ComsolMatlab.m` for Phase 1 single-parameter sweeps
4. Run `LHSsweep.m` for Phase 2 LHS sweeps (adjust `batch_number` and `start_from` as needed for batch execution)

## Citation

If you use this code, please cite the associated publication (forthcoming). In the meantime, related work can be found on the author's [Google Scholar profile](https://scholar.google.com/citations?user=mGlNNqAAAAAJ&hl=en&authuser=1).

## License

This project is provided for academic and research purposes.
