# Troubleshooting Guide

## Common issues and fixes

- **Network timeouts** - Remote server busy. Retry later or reduce the number of `params`
- **Land point selection** - Consider using other regions or resolutions for a closer available point
- **Parameter not found** - Inspect file variables with `ncdisp` or adjust `additional_params` names
  > If the issue is due to the parameter name differing in the early release dataset, please open an issue to request an update.
- **Parallel pool issues** - Set `useParallel = false` to use sequential data loading
- **Permission errors** - Ensure write access to the working directory (for `outputs/`)
- **Interrupted downloads** - Re-run with the same inputs. Existing monthly files are skipped

## Quick checks

```matlab
help loadWaveData
help waveHindcastAnalysis
help waveRose
help locationComparison
```

## Minimal reproducible example

```matlab
% Coordinates near Tasmania
lon = 145.1768; lat = -40.026;
[wave_data, dataset_metadata] = loadWaveData(lon, lat, 201501, 201502);
summary(wave_data);
```

## Diagnostics

```matlab
% Check remote file availability
url = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/ww3.aus_4m.202508.nc';
try
    ncdisp(url, '/', 'min');
catch ME
    fprintf('OPeNDAP/THREDDS access error: %s\n', ME.message);
end
```

**Further help**: See the [CSIRO THREDDS catalogue](https://data-cbr.csiro.au/thredds/catalog/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/catalog.html) to confirm the latest month available.
