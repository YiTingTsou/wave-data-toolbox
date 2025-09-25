function [wave_data, dataset_metadata] = loadWaveData_beta(target_lon, target_lat, start_year_month, end_year_month, options)
%LOADWAVEDATA  Load wave or wind hindcast data from OPeNDAP, with optional parallel fetch and caching.
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou, Australian Maritime College, University of Tasmania
%
% This version fixes a 'Workspace Transparency' violation by avoiding direct
% SAVE calls in a PARFOR body (use a local helper that calls SAVE with
% -fromstruct when available, or wraps SAVE outside the parfor body).
%
% SYNTAX (selected):
%   [wave_data, dataset_metadata] = loadWaveData_beta(lon, lat, YYYYMM, YYYYMM)
%   [wave_data, dataset_metadata] = loadWaveData_beta(..., options)
%
% OPTIONS fields (name–value via struct):
%   region        : 'aus'|'glob'|'pac' (default 'aus')
%   resolution    : 4|10 (arcmin) for 'aus'/'pac'; auto-sets to 24 for 'glob'
%   useParallel   : logical (default true)
%   verbose       : logical (default true)
%   params        : cellstr of extra variables to collect (default {})
%   wind          : logical, load wind instead of wave (default false)
%   cache         : logical, save per-month MAT files (default true)
%   maxWorkers    : scalar double, hard limit on pool size (default 6)
%   assembleMode  : 'inmemory'|'stream' (default 'inmemory')
%
% OUTPUTS
%   wave_data        : table with time series for wave (time,t02,hs,dir,...) or wind (time,wnd,wnddir,...)
%   dataset_metadata : struct with extraction location, distance, input span and provenance
%
% Notes on parallel transparency:
%   - Direct SAVE/LOAD in parfor bodies can cause transparency violations.
%     This implementation wraps SAVE in a local function (PARSAVE_STRUCT),
%     or uses '-fromstruct' on R2024a+.
%
% -------------------------------------------------------------------------

arguments
    % Required
    target_lon (1,1) double {mustBeGreaterThanOrEqual(target_lon,-180), mustBeLessThanOrEqual(target_lon,360)}
    target_lat (1,1) double {mustBeGreaterThanOrEqual(target_lat,-90),  mustBeLessThanOrEqual(target_lat,90)}
    start_year_month (1,1) double {mustBeValidYearMonth}
    end_year_month   (1,1) double {mustBeValidYearMonth}
    % Options
    options.region (1,:) string {mustBeMember(options.region,["aus","glob","pac"])} = "aus"
    options.resolution (1,1) double {mustBeMember(options.resolution,[4,10]), mustBePositive} = 10
    options.useParallel (1,1) logical = true
    options.verbose (1,1) logical = true
    options.params = {}
    options.wind (1,1) logical = false
end

% Extract options
region  = options.region;
grid_resolution = options.resolution;
verbose = options.verbose;
additional_params = options.params;
wind = options.wind;

% Convert single string to cell array
if ischar(additional_params)
    additional_params = {additional_params};
elseif isstring(additional_params)
    additional_params = cellstr(additional_params);
end

% Region-specific resolution override
if strcmpi(region,'glob')
    grid_resolution = 24; % dataset constraint
end

% Convert negative longitude to 0..360 (deg E)
if target_lon < 0
    target_lon = target_lon + 360;
end

% Parallel processing variables
maxWorkers = 6; % clamp 1..64
assembleMode = "inmemory";
% Check if parallel processing is available
[useParallel, ~] = localEnableParallel(options.useParallel, maxWorkers, verbose);

%% Build list of YYYYMM
year_months = [];
cy = floor(start_year_month/100); cm = mod(start_year_month,100);
ey = floor(end_year_month/100);   em = mod(end_year_month,100);
while (cy < ey) || (cy == ey && cm <= em)
    year_months = [year_months; cy*100 + cm]; %#ok<AGROW>
    cm = cm + 1;
    if cm > 12, cm = 1; cy = cy + 1; end
end
if verbose
    fprintf('Loading data from %d to %d (%d months)\n', start_year_month, end_year_month, numel(year_months));
end

%% Data sources
baseUrl_gridded = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/';
baseUrl_spec    = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/spec/';

%% 1) Find nearest grid point
if wind
    location_info = waveDataToolbox.utils.spec.findNearestGridPoint(target_lon, target_lat);
else
    lonlat = sprintf('%s_%dm.mat', region, grid_resolution);
    location_info = waveDataToolbox.utils.gridded.findNearestGridPoint(target_lon, target_lat, lonlat);
end
if isempty(location_info), error('Nearest grid lookup failed.'); end

%% 2) Plan requests and cache paths
nM = numel(year_months);
urls    = cell(nM,1);
pkgs    = cell(nM,1);
folders = cell(nM,1);
outFiles= cell(nM,1);
for k = 1:nM
    ym = year_months(k);
    if wind
        urls{k} = [baseUrl_spec, sprintf('ww3.%d_spec.nc', ym)];
        pkgs{k} = 'spec';
    else
        fn = sprintf('%s_%dm.%d', region, grid_resolution, ym);
        urls{k} = [baseUrl_gridded, 'ww3.', fn, '.nc'];
        pkgs{k} = 'gridded';
    end
    [folders{k}, outFiles{k}] = generateCacheFilename(wind, location_info, ym, region, grid_resolution);
    % Ensure both the base folder and the per-month subfolder exist
    if ~exist(folders{k},'dir'), mkdir(folders{k}); end
    [outDir,~,~] = fileparts(outFiles{k});
    if ~exist(outDir,'dir'), mkdir(outDir); end
end

%% 3) Fetch / cache (serial or parallel)
fetchAndCache(useParallel, urls, outFiles, pkgs, location_info, additional_params, verbose, year_months)

%% 4) Assemble from cache
validMask  = cellfun(@(f) exist(f,'file')==2, outFiles);
validFiles = outFiles(validMask);

switch lower(assembleMode)
    case 'inmemory'
        % Preallocate cell collectors
        nV = numel(validFiles);
        all_time = cell(nV,1);
        if wind
            all_wnd    = cell(nV,1);
            all_wnddir = cell(nV,1);
        else
            all_t02 = cell(nV,1);
            all_hs  = cell(nV,1);
            all_dir = cell(nV,1);
        end
        all_additional = cell(numel(additional_params),1);
        for a = 1:numel(additional_params)
            all_additional{a} = cell(nV,1);
        end

        for j = 1:nV
            L  = load(validFiles{j}, 'monthly_data');
            md = L.monthly_data;
            all_time{j} = md.time;
            if wind
                if isfield(md,'wnd'),    all_wnd{j}    = md.wnd;    else, all_wnd{j}    = []; end
                if isfield(md,'wnddir'), all_wnddir{j} = md.wnddir; else, all_wnddir{j} = []; end
            else
                if isfield(md,'t02'), all_t02{j} = md.t02; else, all_t02{j} = []; end
                if isfield(md,'hs'),  all_hs{j}  = md.hs;  else, all_hs{j}  = []; end
                if isfield(md,'dir'), all_dir{j} = md.dir; else, all_dir{j} = []; end
            end
            for a = 1:numel(additional_params)
                pname = additional_params{a};
                if isfield(md, pname)
                    all_additional{a}{j} = md.(pname);
                else
                    all_additional{a}{j} = nan(numel(md.time),1);
                end
            end
        end

        %% 5) Build table and save complete dataset
        if ~isempty(all_time) && any(~cellfun(@isempty, all_time))
            wave_data = table();
            wave_data.time = vertcat(all_time{:});
            if wind
                wave_data.wnd    = vertcat(all_wnd{:});
                wave_data.wnddir = vertcat(all_wnddir{:});
            else
                wave_data.t02 = vertcat(all_t02{:});
                wave_data.hs  = vertcat(all_hs{:});
                wave_data.dir = vertcat(all_dir{:});
            end
            for a = 1:numel(additional_params)
                pname = additional_params{a};
                wave_data.(pname) = vertcat(all_additional{a}{:});
            end
            distance_km = calculateDistance(target_lat, target_lon, location_info);
            folder_name = folders{find(validMask,1,'first')};
            if wind
                dataset_metadata = waveDataToolbox.utils.spec.saveCompleteDataset( ...
                    folder_name, wave_data, location_info, start_year_month, end_year_month, ...
                    additional_params, distance_km, verbose);
            else
                dataset_metadata = waveDataToolbox.utils.gridded.saveCompleteDataset( ...
                    folder_name, wave_data, location_info, start_year_month, end_year_month, ...
                    additional_params, distance_km, verbose, region, grid_resolution);
            end
        else
            warning('No data was successfully loaded for assembly.');
            wave_data = table();
            dataset_metadata = struct();
        end

    case 'stream'
        error('assembleMode="stream": implement streaming assembly using MATFILE as needed.');
    otherwise
        error('Unknown assembleMode: %s', assembleMode);
end

%% Report location info
if ~isempty(location_info) && isstruct(location_info)
    distance_km = calculateDistance(target_lat, target_lon, location_info);
    if verbose
        fprintf('Target location: %.4f°E, %.4f°N\n', target_lon, target_lat);
        fprintf('Extracting location: %.4f°E, %.4f°N\n', location_info.actual_lon, location_info.actual_lat);
        fprintf('Distance from target: %.2f km\n', distance_km);
    end
else
    if verbose, fprintf('\nWarning: No valid location info found\n'); end
end

end

%% ------------------------- Helpers -------------------------
function [folder_name, filename] = generateCacheFilename(wind, location_info, current_ym, region, grid_resolution)
% Use actual coordinates if available
current_lon = location_info.actual_lon;
current_lat = location_info.actual_lat;
if wind
    folder_name = sprintf('outputs/lon%.4fE_lat%.4fN_wind', current_lon, current_lat);
    filename    = sprintf('%s/monthly_files/wind_data_%d_%.4fE_%.4fN.mat', folder_name, current_ym, current_lon, current_lat);
else
    folder_name = sprintf('outputs/lon%.4fE_lat%.4fN', current_lon, current_lat);
    filename    = sprintf('%s/monthly_files/wave_data_%d_%s_%dm_%.4fE_%.4fN.mat', folder_name, current_ym, region, grid_resolution, current_lon, current_lat);
end
end

%% ---- %%
function distance_km = calculateDistance(target_lat, target_lon, location_info)
if isempty(location_info) || ~isstruct(location_info)
    error('location_info must be a non-empty structure');
end
if ~isfield(location_info,'actual_lat') || ~isfield(location_info,'actual_lon')
    error('location_info must contain actual_lat and actual_lon fields');
end
try
    % Prefer Mapping Toolbox great-circle distance (in meters)
    distance_km = distance(target_lat, target_lon, location_info.actual_lat, location_info.actual_lon, referenceEllipsoid('wgs84')) / 1000;
catch
    % Fallback: Haversine (km)
    R = 6371; % mean Earth radius [km]
    lat1 = deg2rad(target_lat);
    lat2 = deg2rad(location_info.actual_lat);
    dlat = deg2rad(location_info.actual_lat - target_lat);
    dlon = deg2rad(location_info.actual_lon - target_lon);
    a = sin(dlat/2)^2 + cos(lat1)*cos(lat2)*sin(dlon/2)^2;
    c = 2*atan2(sqrt(a), sqrt(1-a));
    distance_km = R*c;
end
end

%% -----
function mustBeValidYearMonth(value)
if ~isscalar(value) || ~isnumeric(value)
    error('Year-month must be a numeric scalar (YYYYMM).');
end
month = mod(value,100);
if month < 1 || month > 12
    error('Invalid month in year-month input: %d. Month must be 01..12.', value);
end
end

% ----
function parsave_struct(filename, S)
%PARSAVE_STRUCT Safe save for PARFOR bodies.
% Uses '-fromstruct' when available (R2024a+), else wraps a regular save.
try
    save(filename, '-fromstruct', S);
catch
    % Fallback for older MATLAB releases
    save(filename, '-struct', 'S');
end
end

%% function
function [useParallel, pool] = localEnableParallel(requested, maxWorkers, verbose)
%LOCALENABLEPARALLEL  Decide whether to use parallel and try to start a pool.
% Returns useParallel=false when Parallel is unavailable or fails to start.
useParallel = false;
pool = [];

% Respect the user's option first
if ~requested
    if verbose, fprintf('[parallel] requested=false -> using serial.\n'); end
    return
end

% 1) Fast capability check (does not open a pool)
%    R2020b+: canUseParallelPool reports whether a pool can be used.
%    Pre-R2020b: fall back to license/file checks.
ok = false;
if exist('canUseParallelPool','file') == 2
    ok = canUseParallelPool;   % true when PCT installed/licensed and pool can be created
else
    ok = license('test','Distrib_Computing_Toolbox') && exist('parpool','file')==2;
end

if ~ok
    if verbose, fprintf('[parallel] not available -> using serial.\n'); end
    return
end

% 2) Try to start or resize pool
try
    p = gcp('nocreate');          % does not create a pool
    if ~isempty(p) && p.NumWorkers ~= maxWorkers
        delete(p);
        p = [];
    end
    if isempty(p)
        pool = parpool('Processes', maxWorkers);
    else
        pool = p;
    end
    useParallel = true;
catch ME
    % Any error (license, config, filesystem, Java) -> fall back to serial
    warning('[parallel] disabled: %s\nUsing serial mode instead.', ME.message);
    useParallel = false;
    pool = [];
end
end

%%
function fetchAndCache(useParallel, urls, outFiles, pkgs, location_info, additional_params, verbose, year_months)
nM = numel(urls);
if useParallel

    parfor k = 1:nM
        locC = parallel.pool.Constant(location_info);
        addC = parallel.pool.Constant(additional_params);
        try
            if verbose && rem(k,12) == 1
                current_ym = year_months(k);
                year = floor(current_ym / 100);
                fprintf('  Starting year %d: Loading %d (%d of %d)\n', year, current_ym, k, nM);
            end
            if exist(outFiles{k},'file'), continue; end

            loader = ['waveDataToolbox.utils.' pkgs{k} '.loadMonthlyData'];
            md = feval(loader, urls{k}, locC.Value, addC.Value, false);
            S  = struct('monthly_data', md);
            parsave_struct(outFiles{k}, S);

            saver = ['waveDataToolbox.utils.' pkgs{k} '.saveMonthlyData'];
            feval(saver, md, outFiles{k}, addC.Value, false);

        catch ME
            warning('Month %d failed: %s', k, ME.message);
        end
    end
else
    for k = 1:nM
        if verbose && rem(k,12) == 1
            current_ym = year_months(k);
            year = floor(current_ym / 100);
            fprintf('  Starting year %d: Loading %d (%d of %d)\n', year, current_ym, k, nM);
        end
        try
            if exist(outFiles{k},'file'), continue; end
            loader = ['waveDataToolbox.utils.' pkgs{k} '.loadMonthlyData'];
            md = feval(loader, urls{k}, location_info, additional_params, verbose);
            S  = struct('monthly_data', md);
            save(outFiles{k}, '-struct', 'S');

            saver = ['waveDataToolbox.utils.' pkgs{k} '.saveMonthlyData'];
            feval(saver, md, outFiles{k}, additional_params, verbose);

        catch ME
            warning('Month %d failed: %s', k, ME.message);
        end
    end
end
end