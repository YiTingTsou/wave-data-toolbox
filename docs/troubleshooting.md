# Troubleshooting Guide

## Common issues and fixes

- **Network timeouts** - Remote server busy. Retry later or reduce the number of `params`
- **Land point selection** - Try alternative regions or resolutions for a closer available point
- **Parameter not found** - Check file variables using `ncdisp` or adjust `additional_params` names
  > If the issue is due to the parameter name differing in the early release dataset, please open an issue to request an update.
- **Permission errors** - Ensure write access to the working directory (for `outputs/`)
- **Interrupted downloads** - Re-run with the same inputs. Existing monthly files will be skipped

### Parallel pool

#### Why is my parallel job queued?

- MATLAB is waiting to allocate workers (local cores or cluster nodes).
- If resources are busy, your job stays in the queue until workers are free.

#### Why does it take so long to start?

- Licensing delay: Waiting for available Parallel Computing Toolbox licenses.
- Startup overhead: Even on a local machine, MATLAB must launch multiple worker processes.

#### How can I reduce waiting time?

1. **Check resources**: Ensure enough cores or cluster nodes are available
2. **Check licenses**: Confirm Parallel Computing Toolbox licenses are free
3. **Reuse pools**: Once a pool is open, it stays active until idle timeout or manual deletion. Subsequent tasks will run immediately
4. **Fallback option**: If delays persist, set `useParallel = false` to use sequential data loading

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
