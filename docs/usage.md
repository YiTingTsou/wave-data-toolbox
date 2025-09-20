# Usage Guide

This guide shows typical workflows and runnable examples for the toolbox.

For complete argument definitions, defaults, and output fields, see **[parameters.md](parameters.md)**.

## Overview

**Typical workflow**

1. Choose a location and time range.
2. Load wave data with `loadWaveData`.
3. (Optional) Tune binning or use helper utilities for analysis and caching.
4. Use the downloaded `wave_data` or generated figures.

## 1. `loadWaveData` function

### 1.1 Basic loading

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512);
```

### 1.2 Advanced full options

```matlab
[wave_data, dataset_metadata] = loadWaveData(145.1768, -40.026, 201501, 201512, ...
    'region', 'aus', ...            % 'aus' | 'glob' | 'pac'
    'resolution', 4, ...            % arcminutes
    'radius', 0.5, ...              % degrees
    'params', {'t0m1','fp','dpm'}, ... % additional params to load
    'cache', false, ...             % monthly caching
    'verbose', false);              % display messages
```

#### 1.2.1 Exploring available parameters for `params`

Inspect available variables directly from the remote NetCDF catalogue:

```matlab
url = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/ww3.aus_4m.202508.nc';
ncdisp(url, '/', 'min');                 % quick overview
info = ncinfo(url); {info.Variables.Name}' % list parameter names
ncdisp(url, 'hs');                        % variable details
```

### 1.3 Outputs

- `wave_data`: table of time‑series variables suitable for plotting and statistics
- `dataset_metadata`: struct describing extraction and processing

## 2. Analysis functions

### 2.1 `waveHindcastAnalysis` function

Generate bi-variate probability distribution heatmaps

#### 2.1.1 Basic usage

```matlab
waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata);
```

#### 2.1.2 Advanced full options

```matlab
waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, ...
    'bins', 20, ...               % No. of bins
    'save_fig', false, ...
    'text', false, ...             % Display percentage values
    'xlabel', 'X-axis Label', ...
    'ylabel', 'Y-axis Label');
```

### 2.2 `waveRose` function

Generate polar histogram (rose plot) for wave directions

```matlab
mean_dir = waveRose(wave_data.dir, dataset_metadata);

% Display only
waveRose(wave_data.dir, dataset_metadata, 'save_fig', false);

% Wind rose
waveRose(wind_data, dataset_metadata, 'title', 'Wind Direction');
```

### 2.3 Example outputs

<table>
<tr>
<td width="50%">

**Bi-Variate Probability Distribution**
![Bi-Variate Probability Distribution](figures/biVariate_201501_201512_145.1668E_-40.0000N.png)

</td>
<td width="50%">

**Wave Rose**
![Wave Rose](figures/waveRose_201501_201512_145.1668E_-40.0000N.png)

</td>
</tr>
</table>

**See also**: [parameters.md](parameters.md), [troubleshooting.md](troubleshooting.md), [structure.md](structure.md)
