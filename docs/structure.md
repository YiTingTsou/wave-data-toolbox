# Toolbox Structure

## For Users

### Main Script

- **`loadWaveDataMain.m`** - Example script demonstrating the use of all toolbox functions

### Toolbox Functions

#### Core Function

- **`loadWaveData.m`** - Function for loading wave data

#### Analysis Functions

- **`waveHindcastAnalysis.m`** - Generates probability distribution heatmaps
- **`waveRose.m`** - Creates directional wave rose plots
- **`locationComparison.m`** - Generates a figure showing the target location and the data extraction location(s)

---

## For Contributors/Developers `+utils`

### Internal Helper Functions for `loadWaveData`

- **localEnableParallel.m**: Decide whether to use parallel and try to start a pool
- **fetchAndCache.m**: Fetch and cache monthly data files, optionally in parallel
- **assembleAndSaveDataset**: Assemble wave or wind data from monthly files and save complete dataset.
- **assembleStreamedDataset.m**: Assemble wave or wind data using streamed access via MATFILE if assembleAndSaveDataset fails due to memory limits

The following helper functions support the main wave and wind data loading workflow, `+gridded/` and `+spec/`:

- **`findNearestGridPoint.m`**: Identifies the nearest valid ocean grid point for a given location
- **`loadMonthlyData.m`**: Loads wind or wave data for a single month, with built-in fallback logic for missing variables
- **`saveMonthlyData.m`**: Saves individual monthly datasets to disk
- **`storeMonthlyData.m`**: Collects and stores monthly wave data in cell arrays for further processing
- **`saveCompleteDataset.m`**: Aggregates and saves complete datasets for both wave and wind data

### Internal Helper Functions for `waveHindcastAnalysis`

- **`customcolormap.m`** - Defines a customized colormap (Third-Party Component)

```
 +waveDataToolbox/
   ├── loadWaveData.m
   ├── locationComparison.m
   ├── waveHindcastAnalysis.m
   ├── waveRose.m
   │
   └── +utils/         % Internal Helper Functions
       ├── +gridded/   % Functions for wave data
       │   └── lonlat/ % Pre-loaded grid points
       └── +spec/      % Functions for wind data
```
