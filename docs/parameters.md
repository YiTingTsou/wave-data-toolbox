# Function and Parameter Reference

This page documents function signatures, arguments, defaults, outputs, variables, and dataset coverage.

For step‑by‑step workflows and examples, see [Usage Guide](usage.md).

## 1. `loadWaveData`

### 1.1 Function signature

```matlab
[wave_data, dataset_metadata] = loadWaveData(target_lon,target_lat, start_year_month, end_year_month, ...
    'region', region, ...
    'resolution', resolution, ...
    'radius', radius, ...
    'verbose', verbose, ...
    'cache', cache, ...
    'params', params);
```

### 1.2 Description

Load CAWCR Wave Hindcast data for a target location and period, optionally including additional variables and caching.

### 1.3 Arguments

| Parameter          | Type       | Default | Description                                  |
| ------------------ | ---------- | ------- | -------------------------------------------- |
| `target_lon`       | numeric    | —       | Target longitude [degrees E]                 |
| `target_lat`       | numeric    | —       | Target latitude [degrees N]                  |
| `start_year_month` | numeric    | —       | Start date in `YYYYMM`                       |
| `end_year_month`   | numeric    | —       | End date in `YYYYMM`                         |
| `region`           | string     | `aus`   | Data region: `aus`, `glob`, `pac`            |
| `resolution`       | numeric    | `10`    | Grid resolution [arcminutes]                 |
| `radius`           | numeric    | `0.1`   | Search radius around target [degrees]        |
| `verbose`          | logical    | `true`  | Display progress messages                    |
| `cache`            | logical    | `true`  | Save monthly data during loading             |
| `params`           | cell array | `{}`    | Extra variables to load (e.g., `t0m1`, `fp`) |

### 1.4 Regions, resolutions, coverage

| Code   | Description       | Grid resolution (arcmin) | Temporal Coverage |
| ------ | ----------------- | ------------------------ | ----------------- |
| `glob` | Global domain     | 24                       | 197901–present    |
| `aus`  | Australian region | 10, 4                    | 197901–present    |
| `pac`  | Western Pacific   | 10, 4                    | 197901–present    |

> Check latest monthly availability at the [CSIRO THREDDS catalogue](https://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html).

![Data Coverage by Region and Resolution](figures/dataCoverage.png)

### 1.5 Outputs

_Note: `wave_data` is saved automatically to the `output/` folder as both .mat and .csv files; `dataset_metadata` is included only in the .mat file._

- **wave_data** - Table containing time series wave parameters with columns:
  - `time`: datetime vector of observation times
  - `t02`: mean zero-crossing period [s]
  - `hs`: significant wave height [m]
  - `dir`: mean wave direction [degrees]
  - Additional columns if specified in 'params' input (e.g., `t0m1`, `fp`, `dpm`)
- **dataset_metadata** - Structure with extraction location info and processing metadata:
  - `target_lon` - Target longitude requested [degrees E]
  - `target_lat` - Target latitude requested [degrees N]
  - `actual_lon` - Actual longitude of nearest grid point [degrees E]
  - `actual_lat` - Actual latitude of nearest grid point [degrees N]
  - `lon_idx` - Longitude index used for data extraction
  - `lat_idx` - Latitude index used for data extraction
  - `location_offset` - Distance between target and actual location [km]
  - `start_year_month` - Start date in YYYYMM format
  - `end_year_month` - End date in YYYYMM format
  - `region` - Dataset region ('aus', 'glob', or 'pac')
  - `grid_resolution` - Grid resolution [arcminutes]
  - `additional_params` - Cell array of additional parameters loaded

## 2. `waveHindcastAnalysis`

### 2.1 Function signature

```matlab
waveHindcastAnalysis(x_params, y_params, dataset_metadata, ...
    'bins', 15, ...
    'save_fig', true, ...
    'text', true, ...
    'xlabel', 'X-axis Label', ...
    'ylabel', 'Y-axis Label')
```

### 2.2 Description

Create a bi‑variate probability distribution heatmap from paired series, typically `t02` (x‑axis) and `hs` (y‑axis).

### 2.3 Arguments

| Parameter          | Type      | Default                             | Description                               |
| ------------------ | --------- | ----------------------------------- | ----------------------------------------- |
| `t02`              | numeric   | —                                   | First wave parameter (plotted on x-axis)  |
| `hs`               | numeric   | —                                   | Second wave parameter (plotted on y-axis) |
| `dataset_metadata` | structure | —                                   | Dataset information from `loadWaveData`   |
| `bins`             | numeric   | `15`                                | Number of bins for each dimension         |
| `save_fig`         | logical   | `true`                              | Save figure to PNG file                   |
| `text`             | logical   | `true`                              | Display percentage values on heatmap      |
| `xlabel`           | string    | `'Mean Period T_{02} [s]'`          | X-axis label                              |
| `ylabel`           | string    | `'Significant Wave Height H_s [m]'` | Y-axis label                              |
