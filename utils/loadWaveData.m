function [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, varargin)
%LOADWAVEDATA Load wave hindcast data from OPeNDAP server
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month)
%   [wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, 'Name', Value)
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
%   'radius'          - Search radius around target location in degrees (default: 0.1)
%   'verbose'         - Display progress messages (default: true)
%   'cache'           - Save monthly data during loading for resumable downloads (default: true)
%   'params'          - Cell array of additional parameter names to load (default: {})
%
% OUTPUT:
%   wave_data         - Table with time series wave data: time, t02 [s], hs [m], dir [deg]
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

%% Parse input arguments
p = inputParser;
addRequired(p, 'target_lon', @(x) isnumeric(x) && isscalar(x) && x >= -180 && x <= 360);
addRequired(p, 'target_lat', @(x) isnumeric(x) && isscalar(x) && x >= -90 && x <= 90);
addRequired(p, 'start_year_month', @(x) isnumeric(x) && isscalar(x));
addRequired(p, 'end_year_month', @(x) isnumeric(x) && isscalar(x));
addParameter(p, 'region', 'aus', @(x) ischar(x) && ismember(x, {'aus', 'glob', 'pac'}));
addParameter(p, 'resolution', 10, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'radius', 0.1, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'verbose', true, @islogical);
addParameter(p, 'cache', true, @islogical);
addParameter(p, 'params', {}, @(x) iscell(x) || ischar(x));

parse(p, target_lon, target_lat, start_year_month, end_year_month, varargin{:});

% Extract parsed values
region = p.Results.region;
grid_resolution = p.Results.resolution;
search_radius = p.Results.radius;
verbose = p.Results.verbose;
save_loaded_data = p.Results.cache;
additional_params = p.Results.params;

% Convert single string to cell array
if ischar(additional_params)
    additional_params = {additional_params};
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
    fprintf('Loading wave data from %d to %d (%d months)\n', start_year_month, end_year_month, length(year_months));
end

%% Initialize data collection
all_time = {};
all_t02 = {};
all_hs = {};
all_dir = {};

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
baseUrl = 'https://data-cbr.csiro.au/thredds/dodsC/catch_all/CMAR_CAWCR-Wave_archive/CAWCR_Wave_Hindcast_aggregate/gridded/';
location_info = [];  % Will be set in first iteration

for i = 1:length(year_months)
    current_ym = year_months(i);
    if verbose
        fprintf('Loading %d (%d/%d)\n', current_ym, i, length(year_months));
    end

    % Construct filename for current month
    fileName = sprintf('%s_%dm.%d', region, grid_resolution, current_ym);
    url = [baseUrl 'ww3.' fileName '.nc'];

    try
        % Only for first iteration
        if i == 1
            % Find the extraction location
            location_info = findNearestGridPoint(url, target_lon, target_lat, search_radius);
        end

        % Check if file already exists
        if save_loaded_data
            % Use actual coordinates if available, otherwise use target coordinates
            if isempty(location_info)
                current_lon = target_lon;
                current_lat = target_lat;
            else
                current_lon = location_info.actual_lon;
                current_lat = location_info.actual_lat;
            end

            [~, save_filename] = generateFilePaths(current_lon, current_lat, current_ym, region, grid_resolution);

            if exist(save_filename, 'file')
                loaded_data = load(save_filename);
                monthly_data = loaded_data.monthly_data;
                % Store data in cell arrays
                storeMonthlyData
                continue;
            end
        end

        % Validate location info exists for data extraction
        if isempty(location_info)
            error('Location parameters not set. First iteration may have failed.');
        end

        % Load monthly data
        monthly_data = loadMonthlyData(url, location_info, additional_params, verbose);

        % Store data in cell arrays
        storeMonthlyData

        % Save individual monthly data if requested
        if save_loaded_data
            saveMonthlyData(monthly_data, save_filename, additional_params, verbose);
        end

    catch ME
        if verbose
            fprintf('  Warning: Failed to load %d - %s\n', current_ym, ME.message);
        end
        continue;
    end
end

% Calculate distance between target and actual extraction point
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

% Display location info
if verbose && ~isempty(location_info)
    fprintf('\nTarget location:     %.4f°E, %.4f°N\n', target_lon, target_lat);
    fprintf('Extracting location: %.4f°E, %.4f°N\n', location_info.actual_lon, location_info.actual_lat);
    fprintf('Distance from target: %.2f km\n', distance_km);
end

%% Combine all data into table
if ~isempty(all_time)
    wave_data = table();
    wave_data.time = vertcat(all_time{:});
    wave_data.t02 = vertcat(all_t02{:});
    wave_data.hs = vertcat(all_hs{:});
    wave_data.dir = vertcat(all_dir{:});

    % Add additional parameter columns if they were loaded
    if ~isempty(additional_params)
        for j = 1:length(additional_params)
            param_name = additional_params{j};
            wave_data.(param_name) = vertcat(all_additional{j}{:});
        end
    end

    % Save complete dataset (always saved by default)
    if ~isempty(location_info)
        if ~exist('output', 'dir')
            mkdir('output')
        end
        % Save `wave_data`
        base_complete_filename = sprintf('%s/wave_data_%d_%d_%s_%dm_%.4fE_%.4fN', ...
            'output', start_year_month, end_year_month, region, grid_resolution, location_info.actual_lon, location_info.actual_lat);
        mat_complete_filename =  [base_complete_filename '.mat'];
        save(mat_complete_filename, 'wave_data');
        csv_complete_filename = [base_complete_filename '.csv'];
        writetable(wave_data, csv_complete_filename);

        % Save extraction and processing metadata
        dataset_metadata = location_info;
        dataset_metadata.start_year_month = start_year_month;
        dataset_metadata.end_year_month = end_year_month;
        dataset_metadata.region = region;
        dataset_metadata.grid_resolution = grid_resolution;
        dataset_metadata.location_offset = distance_km;
        dataset_metadata.additional_params = additional_params;

        save(sprintf('output/lon%.4fE_lat%.4fN.mat', location_info.actual_lon, location_info.actual_lat), 'dataset_metadata');
        if verbose
            fprintf('\nComplete dataset saved\n');
        end
    end

else
    warning('No data was successfully loaded');
    wave_data = table();
end

end