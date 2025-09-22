function [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, options)
%LOADWAVEDATA Load wave hindcast data from OPeNDAP server
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
%   'cache'           - Save monthly data during loading for resumable downloads (default: true)
%   'params'          - Cell array of additional parameter names to load (default: {})
%   'wind'            - Load wind data instead of wave data (default: false)
%
% OUTPUT:
%   wave_data         - Table with time series wave data: time, t02 [s], hs [m], dir [deg]
%                       OR wind data: time, wnd [m/s], wnddir [deg]
%                       and any additional parameters specified in 'params'. Always saved to output/ folder as .mat and .csv files
%   dataset_metadata  - Structure with extraction location info and processing metadata. Always saved to output/ folder as .mat file
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
% p = inputParser;
% addRequired(p, 'target_lon', @(x) isnumeric(x) && isscalar(x) && x >= -180 && x <= 360);
% addRequired(p, 'target_lat', @(x) isnumeric(x) && isscalar(x) && x >= -90 && x <= 90);
% addRequired(p, 'start_year_month', @(x) isnumeric(x) && isscalar(x));
% addRequired(p, 'end_year_month', @(x) isnumeric(x) && isscalar(x));
% addParameter(p, 'region', 'aus', @(x) ischar(x) && ismember(x, {'aus', 'glob', 'pac'}));
% addParameter(p, 'resolution', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
% addParameter(p, 'verbose', true, @islogical);
% addParameter(p, 'cache', true, @islogical);
% addParameter(p, 'params', {}, @(x) iscell(x) || ischar(x));
% addParameter(p, 'wind', false, @islogical);
% 
% parse(p, target_lon, target_lat, start_year_month, end_year_month, varargin{:});
% 
% % Extract parsed values
% region = p.Results.region;
% grid_resolution = p.Results.resolution;
% verbose = p.Results.verbose;
% save_loaded_data = p.Results.cache;
% additional_params = p.Results.params;
% wind = p.Results.wind;

arguments
    % Required inputs
    target_lon (1,1) double {mustBeGreaterThanOrEqual(target_lon,-180), mustBeLessThanOrEqual(target_lon,360)}
    target_lat (1,1) double {mustBeGreaterThanOrEqual(target_lat,-90), mustBeLessThanOrEqual(target_lat,90)}
    start_year_month (1,1) double
    end_year_month (1,1) double

    % Optional parameters
    options.region (1,:) char {mustBeMember(options.region,{'aus','glob','pac'})} = 'aus'
    options.resolution (1,1) double {mustBeMember(options.resolution, [4, 10]), mustBePositive} = 10
    options.verbose (1,1) logical = true
    options.cache (1,1) logical = true
    options.params = {}
    options.wind (1,1) logical = false
end

% Extract parsed values
region = options.region;
grid_resolution = options.resolution;
verbose = options.verbose;
save_loaded_data = options.cache;
additional_params = options.params;
wind = options.wind;

% Convert single string to cell array
if ischar(additional_params)
    additional_params = {additional_params};
end

% Provided incorrect resolution input
if strcmpi(region, 'glob')
    grid_resolution = 24;
end

% Convert negative longitude to 0-360° range (degrees East)
if target_lon < 0
    target_lon = target_lon + 360;
end

%% Generate list of year-month combinations
year_months = [];
current_year = floor(start_year_month / 100);
current_month = mod(start_year_month, 100);
end_year = floor(end_year_month / 100);
end_month = mod(end_year_month, 100);

while (current_year < end_year) || (current_year == end_year && current_month <= end_month)
    year_months = [year_months; current_year * 100 + current_month];
    current_month = current_month + 1;
    if current_month > 12
        current_month = 1;
        current_year = current_year + 1;
    end
end

if verbose
    fprintf('Loading data from %d to %d (%d months)\n', start_year_month, end_year_month, length(year_months));
end

%% Initialize data collection
if wind
    all_time = {};
    all_wnd = {};
    all_wnddir = {};
else
    all_time = {};
    all_t02 = {};
    all_hs = {};
    all_dir = {};
end

% Initialize storage for additional parameters
all_additional = {};
if ~isempty(additional_params)
    for i = 1:length(additional_params)
        all_additional{i} = {};
    end
    if verbose
        fprintf('Additional parameters to load: %s\n', strjoin(additional_params, ', '));
    end
end

%% Load data for each month
% Base URLs for different data sources
baseUrl_gridded = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/';
baseUrl_spec = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/spec/';
location_info = [];  % Will be set in first iteration

for i = 1:length(year_months)
    current_ym = year_months(i);

    % Print message only once per year
    if verbose && rem(i,12) == 1
        year = floor(current_ym / 100);
        fprintf('  Starting year %d: Loading %d (%d of %d)\n', year, current_ym, i, length(year_months));
    end

    % Generate URL and package name based on data type
    if wind
        fileName = sprintf('ww3.%d_spec.nc', current_ym);
        url = [baseUrl_spec fileName];
        package_name = 'spec';
    else
        lonlat = sprintf('%s_%dm.mat', region, grid_resolution);
        fileName = sprintf('%s_%dm.%d', region, grid_resolution, current_ym);
        url = [baseUrl_gridded 'ww3.' fileName '.nc'];
        package_name = 'gridded';
    end

    try
        % Find extraction location (first iteration only)
        if i == 1
            if wind
                location_info = spec.findNearestGridPoint(target_lon, target_lat);
            else
                location_info = gridded.findNearestGridPoint(target_lon, target_lat, lonlat);
            end
        end

        % Validate location info exists for data extraction
        if isempty(location_info)
            error('Location parameters not set. First iteration may have failed.');
        end

        % Generate save filename for caching
        save_filename = generateCacheFilename(wind, location_info, current_ym, region, grid_resolution);

        % Try to load cached data first
        if save_loaded_data && exist(save_filename, 'file')
            loaded_data = load(save_filename);
            monthly_data = loaded_data.monthly_data;
            % Store data using package function
            if wind
                [all_time, all_wnd, all_wnddir, all_additional] = spec.storeMonthlyData(...
                    monthly_data, all_time, all_wnd, all_wnddir, all_additional, additional_params);
            else
                [all_time, all_t02, all_hs, all_dir, all_additional] = gridded.storeMonthlyData(...
                    monthly_data, all_time, all_t02, all_hs, all_dir, all_additional, additional_params);
            end
            continue;
        end

        % Load monthly data from server
        monthly_data = feval([package_name '.loadMonthlyData'], url, location_info, additional_params, verbose);

        % Store data using package function
        if wind
            [all_time, all_wnd, all_wnddir, all_additional] = spec.storeMonthlyData(...
                monthly_data, all_time, all_wnd, all_wnddir, all_additional, additional_params);
        else
            [all_time, all_t02, all_hs, all_dir, all_additional] = gridded.storeMonthlyData(...
                monthly_data, all_time, all_t02, all_hs, all_dir, all_additional, additional_params);
        end

        % Save monthly data to cache
        if save_loaded_data
            feval([package_name '.saveMonthlyData'], monthly_data, save_filename, additional_params, verbose);
        end

    catch ME
        if verbose
            fprintf('  Warning: Failed to load %d - %s\n', current_ym, ME.message);
        end
        continue;
    end
end

%% Calculate distance and display location info
if ~isempty(location_info) && isstruct(location_info)
    distance_km = calculateDistance(target_lat, target_lon, location_info);

    if verbose
        fprintf('\nTarget location:     %.4f°E, %.4f°N\n', target_lon, target_lat);
        fprintf('Extracting location: %.4f°E, %.4f°N\n', location_info.actual_lon, location_info.actual_lat);
        fprintf('Distance from target: %.2f km\n', distance_km);
    end
else
    distance_km = NaN;
    if verbose
        fprintf('\nWarning: No valid location info found\n');
    end
end

%% Combine all data into table
if ~isempty(all_time)
    % Create data table
    wave_data = table();
    wave_data.time = vertcat(all_time{:});

    % Add data columns based on data type
    if wind
        wave_data.wnd = vertcat(all_wnd{:});
        wave_data.wnddir = vertcat(all_wnddir{:});
    else
        wave_data.t02 = vertcat(all_t02{:});
        wave_data.hs = vertcat(all_hs{:});
        wave_data.dir = vertcat(all_dir{:});
    end

    % Add additional parameter columns if they were loaded
    for j = 1:length(additional_params)
        param_name = additional_params{j};
        wave_data.(param_name) = vertcat(all_additional{j}{:});
    end

    % Save complete dataset using appropriate package function
    if wind
        [dataset_metadata] = spec.saveCompleteDataset(wave_data, location_info, ...
            start_year_month, end_year_month, additional_params, distance_km, verbose);
    else
        [dataset_metadata] = gridded.saveCompleteDataset(wave_data, location_info, ...
            start_year_month, end_year_month, additional_params, distance_km, verbose, region, grid_resolution);
    end

else
    warning('No data was successfully loaded');
end

end

%% Helper function for generating cache filenames
function filename = generateCacheFilename(wind, location_info, current_ym, region, grid_resolution)
% Use actual coordinates if available, otherwise use target coordinates

current_lon = location_info.actual_lon;
current_lat = location_info.actual_lat;

if wind
    folder_name = sprintf('outputs/lon%.4fE_lat%.4fN_wind', current_lon, current_lat);
    filename = sprintf('%s/wind_data_%d_%.4fE_%.4fN.mat', ...
        folder_name, current_ym, current_lon, current_lat);
else
    folder_name = sprintf('outputs/lon%.4fE_lat%.4fN', current_lon, current_lat);
    filename = sprintf('%s/wave_data_%d_%s_%dm_%.4fE_%.4fN.mat', ...
        folder_name, current_ym, region, grid_resolution, current_lon, current_lat);
end
end

%% Helper function for calculating distance between coordinates
function distance_km = calculateDistance(target_lat, target_lon, location_info)
% Validate inputs
if isempty(location_info) || ~isstruct(location_info)
    error('location_info must be a non-empty structure');
end

if ~isfield(location_info, 'actual_lat') || ~isfield(location_info, 'actual_lon')
    error('location_info must contain actual_lat and actual_lon fields');
end

try
    % Use MATLAB Mapping Toolbox function if available (more accurate)
    distance_km = distance(target_lat, target_lon, ...
        location_info.actual_lat, location_info.actual_lon, ...
        referenceEllipsoid('wgs84')) / 1000; % Convert meters to kilometers
catch
    % Fallback to Haversine formula (spherical Earth approximation)
    R = 6371; % Earth's radius in km (Mean earth radius)
    lat1_rad = deg2rad(target_lat);
    lat2_rad = deg2rad(location_info.actual_lat);
    delta_lat = deg2rad(location_info.actual_lat - target_lat);
    delta_lon = deg2rad(location_info.actual_lon - target_lon);
    a = sin(delta_lat/2)^2 + cos(lat1_rad) * cos(lat2_rad) * sin(delta_lon/2)^2;
    c = 2 * atan2(sqrt(a), sqrt(1-a));
    distance_km = R * c;
end
end