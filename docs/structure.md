# Toolbox Structure

This page covers the structure of the toolbox.

## Main Functions

- **`loadWaveDataMain.m`** - Example script demonstrating usage and analysis
- **`loadWaveData.m`** - Main orchestrator function for loading wave data (in Utils/)

## Helper Functions (Utils/)

- **`findNearestGridPoint.m`** - Finds nearest valid ocean grid point
- **`generateFilePaths.m`** - Creates consistent file and folder naming
- **`loadMonthlyData.m`** - Loads wave data for a single month
- **`saveMonthlyData.m`** - Saves individual monthly datasets
- **`storeMonthlyData.m`** - Script to store monthly wave data in cell arrays

## Analysis Functions (Utils/)

- **`waveHindcastAnalysis.m`** - Generate probability distribution heatmap
- **`waveRose.m`** - Create directional wave rose plots
