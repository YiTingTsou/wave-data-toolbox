# Usage Guide

This guide shows typical workflows and runnable examples for the toolbox.

For complete argument definitions, defaults, and output fields, see [Function and Parameter Reference](parameters.md).

## Overview

**Typical workflow**

1. Choose a location and time range
2. Load data with `loadWaveData`
3. (Optional) Tune binning or use helper utilities for analysis and caching
4. Use the downloaded data or generated figures

## 1. `loadWaveData` function

### 1.1 Basic loading for wave data

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512);
```

### 1.2 Advanced full options for loading wave data

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512, ...
    "region", "aus", ...            % "aus" | "glob" | "pac"
    "resolution", 4, ...            % arcminutes
    "params", {'t0m1','fp','dpm'}, ... % additional params to load
    "useParallel", false, ...             % sequential data loading
    "verbose", false);              % display messages
```

### 1.3 Basic loading for wind data

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512, 'wind', true);
```

### 1.4 Advanced full options for loading wind data

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512, ...
    "wind", true, ...
    "params", {'direction'}, ...    % additional params to load
    "useParallel", false, ...
    "verbose", false);              % display messages
```

### 1.5 Exploring available parameters for `params`

Inspect available variables directly from the remote NetCDF catalogue:

```matlab
% For gridded datasets (wave)
url = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/ww3.aus_4m.202508.nc';
info = ncinfo(url); {info.Variables.Name}' % list parameter names

% For spec datasets (wind)
url = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/spec/ww3.202508_spec.nc';
info = ncinfo(url); {info.Variables.Name}' % list parameter names
```

### 1.6 Outputs

- `wave_data` or `wind_data`: table of time‑series variables suitable for plotting and statistics
- `dataset_metadata`: struct describing extraction and processing
- Saved monthly data when `cache` is set to true

## 2. Analysis functions

### 2.1 `waveHindcastAnalysis`

Generate bi-variate probability distribution heatmaps.

#### 2.1.1 Basic usage

```matlab
waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata);
```

#### 2.1.2 Advanced full options

```matlab
waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, ...
    "bins", 20, ...               % No. of bins
    "save_fig", false, ...
    "text", false, ...            % Display percentage values
    "xlabel", "X-axis Label", ...
    "ylabel", "Y-axis Label", ...
    "rootName","bassStraight");   % Saved figure names will begin with 'bassStraight'
```

### 2.2 `waveRose`

Generate polar histogram (rose plot) showing the joint probability distribution of wave (or wind/current) directions and heights (or speeds).

```matlab
% Basic usage
mean_dir = waveRose(wave_data.dir, wave_data.hs, dataset_metadata);

% Advanced full options for using it as wave rose
waveRose(wave_data.dir, wave_data.hs, dataset_metadata, ...
    "save_fig", false, ...
    "rootName","bassStraight");

% Wind rose
waveRose(wind_data.wnddir, wind_data.wnd, dataset_metadata, "title", "Wind");
```

### 2.3 Example outputs

<table>
<tr>
<td width="50%">

`waveHindcastAnalysis`
![Bi-Variate Probability Distribution](figures/biVariate_201501_201612_145.1668E_-40.0000N.png)

</td>
<td width="50%">

`waveRose`
![Wind Rose](figures/waveRose_201501_201612_145.1668E_-40.0000N.png)

</td>
</tr>
</table>

### 2.4 **`locationComparison`**

A figure showing the target location, the data extraction location(s), and the locations of all available datasets in the [CAWCR Wave Hindcast](https://researchdata.edu.au/cawcr-wave-hindcast-aggregated-collection/1401722#:~:text=Organisation%26rft,4%20degree%20%2824%20arcminute).

```matlab
% With one extracted dataset_metadata (wave or wind)
locationComparison(dataset_metadata);

% With both wave and wind metadata
locationComparison(dataset_metadata);
```

#### 2.4.1 Double-check the extraction location

Check if you are happy with the location used for data extraction. If not, change the `region` or `resolution` to the closest available grid point by inspecting the locationComparison MATLAB .fig.

![Location Comparison](figures/locationComparison.png)

**See also**: [Function and Parameter Reference](parameters.md), [Troubleshooting Guide](troubleshooting.md), [Toolbox Structure](structure.md)
