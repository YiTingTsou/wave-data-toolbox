# Usage Guide

This page explains common workflows and advanced options for the coding toolbox to access the CAWCR Wave Hindcast data and related utilities.

## Overview

**Typical workflow**

1. Choose a location and time range.
2. Load wave data with `loadWaveData`.
3. (Optional) Tune binning or use helper utilities for analysis and caching.
4. Use the downloaded `wave_data` or generated visualisation figures.

## 1.`loadWaveData` function

### 1.1 Basic loading

```matlab
% Most common use
wave_data = loadWaveData(145.1768, -40.026, 201501, 201512);
```

### 1.2 Advanced options

```matlab
wave_data = loadWaveData(145.1768, -40.026, 201501, 201512, ...
    'region', 'aus', ...            % 'aus' | 'glob' | 'pac'
    'resolution', 10, ...           % arcminutes
    'radius', 0.1, ...              % degrees
    'params', {'t0m1','fp','dpm'}, ...
    'cache', true, ...              % monthly caching
    'verbose', true);
```

For a full list of available parameters, their types, allowed values, and defaults, see: [parameters.md](parameters.md)

## 2. Exploring available parameters from CAWCR Wave Hindcast

You can quickly inspect variables and metadata from the remote dataset in the MATLAB Workspace.

```matlab
url = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/ww3.aus_4m.202508.nc';
ncdisp(url, '/', 'min');                 % quick overview
info = ncinfo(url); {info.Variables.Name}' % list parameter names
ncdisp(url, 'hs');                        % variable details
```

## 3. Adjusting the heatmap binning (probability distributions)

In `LoadWaveData_Main.m`, set the number of bins for each dimension of the probability distribution heatmap.

```matlab
n_bins = 10; % Number of bins for each dimension
```

## 4. Using helper utilities directly

```matlab
% Find nearest grid point
location_info = findNearestGridPoint(url, lon, lat, 0.1, true);

% Generate file paths
[folder_name, filename] = generateFilePaths(lon, lat, 201508, 'aus', 10);

% Load a single month
monthly_data = loadMonthlyData(url, location_info, {'hs','t02'}, true);

% Save a monthly file
saveMonthlyData(monthly_data, filename, {'hs','t02'}, true);
```

## 5. Related analysis scripts

- **`waveHindcastAnalysis.m`** - Generate bi-variate probability distribution heatmaps

  ```matlab
  waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata);
  waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, 'bins', 20, 'text', false);
  ```

For detailed parameter options and descriptions, see: [parameters.md](parameters.md)

- **`waveRose.m`** - Generate polar histogram (rose plot) for wave directions

  ```matlab
  mean_dir = waveRose(wave_data.dir, dataset_metadata);
  waveRose(wave_data.dir, dataset_metadata, false);  % Display only
  ```

  **See also**: [parameters.md](parameters.md), [troubleshooting.md](troubleshooting.md), [structure.md](structure.md)
