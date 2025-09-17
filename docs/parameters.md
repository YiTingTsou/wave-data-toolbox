# Parameters and data options

## Function signature
```matlab
wave_data = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, ...
    'region', region, 'grid_resolution', grid_resolution, 'search_radius', search_radius, ...
    'verbose', verbose, 'save_loaded_data', save_loaded_data, 'additional_params', additional_params);
```
## Arguments
| Parameter           | Type       | Default | Description                                  |
| ------------------- | ---------- | ------- | -------------------------------------------- |
| `target_lon`        | numeric    | —       | Target longitude [degrees E]                 |
| `target_lat`        | numeric    | —       | Target latitude [degrees N]                  |
| `start_year_month`  | numeric    | —       | Start date in `YYYYMM`                       |
| `end_year_month`    | numeric    | —       | End date in `YYYYMM`                         |
| `region`            | string     | `aus`   | Data region: `aus`, `glob`, `pac`            |
| `grid_resolution`   | numeric    | `10`    | Grid resolution [arcminutes]                 |
| `search_radius`     | numeric    | `0.1`   | Search radius around target [degrees]        |
| `verbose`           | logical    | `true`  | Display progress messages                    |
| `save_loaded_data`  | logical    | `true`  | Save monthly data during loading             |
| `additional_params` | cell array | `{}`    | Extra variables to load (e.g., `t0m1`, `fp`) |

## Variables
**Standard (always loaded)**
- `time`: time vector
- `t02`: mean period from second frequency moment
- `hs`: significant wave height
- `dir`: wave direction

**Optional (`additional_params`)**
- `t0m1`: mean period from inverse frequency moment
- Others as available in NetCDF files
## Regions, resolutions, coverage
| Code   | Description       | Grid resolution (arcmin) | Coverage       |
| ------ | ----------------- | ------------------------ | -------------- |
| `pac`  | Western Pacific   | 4, 10                    | 197901–present |
| `glob` | Global domain     | 24                       | 197901–present |
| `aus`  | Australian region | 4, 10                    | 197901–present |

> Check latest monthly availability at the CSIRO THREDDS catalogue.

**Links**
- Collection page: <https://data.csiro.au/collection/csiro:39819>
- THREDDS (gridded): <http://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html>
- DAP guide to THREDDS and OPeNDAP access: <https://research.csiro.au/dap/download/accessing-data-via-a-thredds-catalogue/>
