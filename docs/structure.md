# Toolbox Structure

## For Users

### Main Script

- **`loadWaveDataMain.m`** - Example script showing how to use the toolbox

### Core Function

- **`loadWaveData.m`** - Main function for loading wave data

### Analysis Functions

- **`waveHindcastAnalysis.m`** - Generate probability distribution heatmap
- **`waveRose.m`** - Create directional wave rose plots

---

## For Contributors/Developers

### Internal Helper Functions for `loadWaveData`

The following helper functions support the main wave and wind data loading workflow:

- **`findNearestGridPoint.m`**: Identifies the nearest valid ocean grid point for a given location.
- **`loadMonthlyData.m`**: Loads wind or wave data for a single month, with built-in fallback logic for missing variables.
- **`saveMonthlyData.m`**: Saves individual monthly datasets to disk.
- **`storeMonthlyData.m`**: Collects and stores monthly wave data in cell arrays for further processing.
- **`saveCompleteDataset.m`**: Aggregates and saves complete datasets for both wave and wind data.

Folder structure:

- `+gridded/`: Contains functions for loading and processing wave data.
- `+spec/`: Contains functions for loading and processing wind data.
