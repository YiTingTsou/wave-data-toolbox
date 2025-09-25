function [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, options)
%LOADWAVEDATA Load wave hindcast data from OPeNDAP server, with optional parallel fetch and caching.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month)
%   [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, 'Name', Value)
%   [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, 'wind', true)  % For wind data
%
% INPUTS:
%   target_lon        - Target longitude [degrees E]
%   target_lat        - Target latitude [degrees N]
%   start_year_month  - Start year-month (YYYYMM format, e.g., 201501)
%   end_year_month    - End year-month (YYYYMM format, e.g., 201601)
%
% OPTIONAL PARAMETERS:
%   'region'          - Data region: 'aus', 'glob', 'pac' (default: 'aus')
%   'resolution'      - Grid resolution in arcminutes (default: 10)
%   'verbose'         - Display progress messages (default: true)
%   'useParallel'     - Use parallel processing (default: true)
%   'params'          - Cell array of additional parameter names to load (default: {})
%   'wind'            - Load wind data instead of wave data (default: false)
%
% OUTPUT:
%   wave_data         - Table with time series wave data: time, t02 [s], hs [m], dir [deg]
%                       OR wind data: time, wnd [m/s], wnddir [deg]
%                       and any additional parameters specified in 'params'. Always saved to output/ folder as .mat and .csv files
%   dataset_metadata  - Structure with extraction location info and processing metadata. Always saved to outputs/ folder as .mat file
%
% EXAMPLE:
%   % Load 1 year of data for Bass Strait (with monthly file saving enabled by default)
%   wave_data = loadWaveData(145.1768, -40.026, 201501, 201512);
%
%   % Load with monthly file saving disabled (faster, but no resume capability)
%   wave_data = loadWaveData(145.1768, -40.026, 201501, 201502, ...
%                           'cache', false);
%
%   % Load with custom parameters
%   wave_data = loadWaveData(145.1768, -40.026, 201501, 201502, ...
%                           'region', 'aus', 'resolution', 10, 'verbose', false);
%
%   % Load with additional parameters
%   wave_data = loadWaveData(145.1768, -40.026, 201501, 201502, ...
%                           'params', {'t0m1', 'fp', 'dpm'});
%
%   % Load with both additional parameters and custom saving options
%   wave_data = loadWaveData(145.1768, -40.026, 201501, 201502, ...
%                           'params', {'t0m1', 'fp', 'dpm'}, ...
%                           'cache', false, 'verbose', true);
%
%   % Load wind data for a location
%   wind_data = loadWaveData(145.1768, -40.026, 201501, 201512, 'wind', true);
%

%% Parse input arguments
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

% Convert single string or string array to cell array
if ischar(additional_params) || isstring(additional_params)
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
maxWorkers = 6; 
% Check if parallel processing is available
[useParallel, ~] = waveDataToolbox.utils.localEnableParallel(options.useParallel, maxWorkers, verbose);

%% Build list of YYYYMM
% Build a list of year-months (YYYYMM) between start and end dates

year_months = [];
cy = floor(start_year_month/100); % current year
cm = mod(start_year_month,100);   % current month
ey = floor(end_year_month/100);   % end year
em = mod(end_year_month,100);     % end month
while (cy < ey) || (cy == ey && cm <= em)
    year_months = [year_months; cy*100 + cm]; %#ok<AGROW> % Append current YYYYMM
    cm = cm + 1; % Move to next month
    if cm > 12
        cm = 1; cy = cy + 1; % If month > 12, increment year and reset month
    end
end
% Display loading info if verbose mode is enabled
if verbose
    fprintf('Loading data from %d to %d (%d months)\n', start_year_month, end_year_month, numel(year_months));
end

%% Data sources
baseUrl_gridded = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/';
baseUrl_spec    = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/spec/';

%% Find nearest grid point
if wind
    location_info = waveDataToolbox.utils.spec.findNearestGridPoint(target_lon, target_lat);
else
    lonlat = sprintf('%s_%dm.mat', region, grid_resolution);
    location_info = waveDataToolbox.utils.gridded.findNearestGridPoint(target_lon, target_lat, lonlat);
end
if isempty(location_info), error('Nearest grid lookup failed.'); end

%% Plan requests and cache paths
% For each month, plan the data request and cache file/folder paths
nM = numel(year_months); % Number of months to process
urls    = cell(nM,1);    % URLs to fetch data from
pkgs    = cell(nM,1);    % Package type ('spec' for wind, 'gridded' for wave)
folders = cell(nM,1);    % Output folders for each location/month
outFiles= cell(nM,1);    % Output file paths for each month
for k = 1:nM
    ym = year_months(k); % Current year-month
    if wind
        % Wind data: use spec dataset URL and package type
        urls{k} = [baseUrl_spec, sprintf('ww3.%d_spec.nc', ym)];
        pkgs{k} = 'spec';
    else
        % Wave data: use gridded dataset URL and package type
        fn = sprintf('%s_%dm.%d', region, grid_resolution, ym);
        urls{k} = [baseUrl_gridded, 'ww3.', fn, '.nc'];
        pkgs{k} = 'gridded';
    end
    % Generate output folder and file name for cache
    [folders{k}, outFiles{k}] = generateCacheFilename(wind, location_info, ym, region, grid_resolution);
    % Ensure both the base folder and the per-month subfolder exist
    if ~exist(folders{k},'dir')
        mkdir(folders{k});
    end
    [outDir,~,~] = fileparts(outFiles{k});
    if ~exist(outDir,'dir')
        mkdir(outDir);
    end
end

%% Fetch / cache (serial or parallel)
% Fetch and cache monthly data files, optionally in parallel.
waveDataToolbox.utils.fetchAndCache(useParallel, urls, outFiles, pkgs, location_info, additional_params, verbose, year_months)

%% Assemble from cache
validMask  = cellfun(@(f) exist(f,'file')==2, outFiles);
validFiles = outFiles(validMask);

% assembleMode='inmemory' loads all monthly files into RAM; fallback to 'stream' uses matfile for low-memory access.
try
    [wave_data, dataset_metadata] = waveDataToolbox.utils.assembleAndSaveDataset( ...
        validFiles, wind, additional_params, target_lat, target_lon, ...
        location_info, folders, validMask, start_year_month, ...
        end_year_month, verbose, region, grid_resolution);
catch ME
    if strcmp(ME.identifier, 'MATLAB:nomem') % or other memory-related error
        warning('Memory error in inmemory mode; switching to stream mode.');
        [wave_data, dataset_metadata] = waveDataToolbox.utils.assembleStreamedDataset( ...
            validFiles, wind, additional_params, target_lat, target_lon, ...
            location_info, folders, validMask, start_year_month, ...
            end_year_month, verbose, region, grid_resolution);
    else
        rethrow(ME);
    end
end

%% Report location info
if verbose
    fprintf('\nTarget location: %.4f°E, %.4f°N\n', target_lon, target_lat);
    fprintf('Extracting location: %.4f°E, %.4f°N\n', location_info.actual_lon, location_info.actual_lat);
    fprintf('Distance from target: %.2f km\n------\n\n', dataset_metadata.location_offset);
end
end

%% Helper function for generating cache filenames
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

%% Helper function to check input is valid YYYYMM
function mustBeValidYearMonth(value)

% Validate that VALUE is a numeric scalar in the form YYYYMM.
if ~(isscalar(value) && isnumeric(value) && isfinite(value))
    error('Year-month must be a numeric scalar (YYYYMM).');
end

% Split into year and month
year  = floor(value / 100);
month = mod(value, 100);

if year < 1000 || year > 9999
    error('Invalid year: %d. Year must be 4 digits (YYYY).', year);
end

if month < 1 || month > 12
    error('Invalid month: %d. Month must be 01..12.', month);
end
end