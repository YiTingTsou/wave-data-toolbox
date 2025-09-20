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

### Internal Helper Functions (Utils/)

- **`findNearestGridPoint.m`** - Finds nearest valid ocean grid point
- **`generateFilePaths.m`** - Creates consistent file and folder naming
- **`loadMonthlyData.m`** - Loads wave data for a single month
- **`saveMonthlyData.m`** - Saves individual monthly datasets
- **`storeMonthlyData.m`** - Script to store monthly wave data in cell arrays
