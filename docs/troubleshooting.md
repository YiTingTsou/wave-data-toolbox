# Troubleshooting Guide

## Common issues and fixes

- **No grid points found**. Verify longitude/latitude and increase `search_radius`.
- **Network timeouts**. Remote server busy. Retry later or reduce concurrency.
- **Land point selected**. The tool automatically searches for the nearest valid ocean cell.
- **Parameter not found**. Inspect file variables with `ncdisp` or adjust `additional_params` names.
- **Large datasets**. Enable `save_loaded_data = true` for monthly caching to avoid memory pressure.
- **Permission errors**. Ensure write access to the working directory (for `output/`).
- **Interrupted downloads**. Re-run with the same inputs. Existing monthly files are skipped.

## Quick checks

```matlab
help loadWaveData
help waveHindcastAnalysis
help waveRose
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
