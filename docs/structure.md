# Toolbox Structure

## For Users

### Main Script (example script)

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

The following helper functions support the main wave and wind data loading workflow:

- **`findNearestGridPoint.m`**: Identifies the nearest valid ocean grid point for a given location
- **`loadMonthlyData.m`**: Loads wind or wave data for a single month, with built-in fallback logic for missing variables
- **`saveMonthlyData.m`**: Saves individual monthly datasets to disk
- **`storeMonthlyData.m`**: Collects and stores monthly wave data in cell arrays for further processing
- **`saveCompleteDataset.m`**: Aggregates and saves complete datasets for both wave and wind data

Folder structure:

- `+gridded/`: Contains functions for loading and processing wave data
  - `lonlat/`: Pre-loaded longitude, latitude and available wave data locations
- `+spec/`: Contains functions for loading and processing wind data

### Internal Helper Functions for `waveHindcastAnalysis`

- **`customcolormap.m`** - Defines a customized colormap (Third-Party Component)

```
 +waveDataToolbox/
   ├── loadWaveData.m
   ├── locationComparison.m
   ├── waveHindcastAnalysis.m
   ├── waveRose.m
   │
   └── +utils/
       ├── customcolormap.m
       ├── +gridded/
       │   └── lonlat/
       └── +spec/
```
