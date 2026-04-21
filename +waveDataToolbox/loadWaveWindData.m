function [wave_wind_data] = loadWaveWindData(target_lon, target_lat, start_year_month, end_year_month, options)
%LOADWAVEWINDDATA Load both wave and wind hindcast data in a single call.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   wave_wind_data = loadWaveWindData(target_lon, target_lat, start_year_month, end_year_month)
%   wave_wind_data = loadWaveWindData(target_lon, target_lat, start_year_month, end_year_month, ...
%       region="aus", resolution=10, useParallel=true, verbose=true, rootName="")
%
% INPUTS:
%   target_lon        - Target longitude [degrees E]
%   target_lat        - Target latitude [degrees N]
%   start_year_month  - Start year-month (YYYYMM format, e.g., 201501)
%   end_year_month    - End year-month (YYYYMM format, e.g., 201601)
%
% OPTIONAL PARAMETERS:
%   'region'          - Data region passed to loadWaveData (default: "aus")
%   'resolution'      - Grid resolution [arcminutes] passed to loadWaveData (default: 10)
%   'useParallel'     - Use parallel processing (default: true)
%   'verbose'         - Display progress messages (default: true)
%   'rootName'        - Name of the root folder used to save outputs (default: "")
%
% OUTPUT:
%   wave_wind_data    - Structure containing:
%                       .wave_data      - Wave time series table
%                       .wind_data      - Wind time series table
%                       .wave_metadata  - Metadata for wave extraction
%                       .wind_metadata  - Metadata for wind extraction
%                       Also saved as outputs/<rootName>/wave_wind_data.mat
%
% EXAMPLE:
%   wave_wind_data = loadWaveWindData(145.1768, -40.026, 201501, 201512, ...
%       useParallel=false, verbose=true, rootName="bassStraight");

%% Parse input arguments
arguments
    % Required
    target_lon (1,1) double {mustBeGreaterThanOrEqual(target_lon,-180), mustBeLessThanOrEqual(target_lon,360)}
    target_lat (1,1) double {mustBeGreaterThanOrEqual(target_lat,-90),  mustBeLessThanOrEqual(target_lat,90)}
    start_year_month (1,1) double
    end_year_month   (1,1) double
    % Shared options forwarded to loadWaveData
    options.region (1,:) string = "aus"
    options.resolution (1,1) double = 10
    options.useParallel (1,1) logical = true
    options.verbose (1,1) logical = true
    options.rootName (1,:) string = ""
end

if strlength(options.rootName) == 0
    options.rootName = sprintf('lon%.4fE_lat%.4fN', target_lon, target_lat);
end

if options.verbose
    fprintf('=== Load Wave Data ===\n');
end
[wave_data, dataset_metadata_wave] = waveDataToolbox.loadWaveData( ...
    target_lon, target_lat, start_year_month, end_year_month, ...
    region=options.region, ...
    resolution=options.resolution, ...
    useParallel=options.useParallel, ...
    verbose=options.verbose, ...
    rootName=options.rootName);

if options.verbose
    fprintf('=== Load Wind Data ===\n');
end
[wind_data, dataset_metadata_wind] = waveDataToolbox.loadWaveData( ...
    target_lon, target_lat, start_year_month, end_year_month, ...
    region=options.region, ...
    resolution=options.resolution, ...
    useParallel=options.useParallel, ...
    verbose=options.verbose, ...
    rootName=options.rootName, ...
    wind=true);

wave_wind_data = struct();
wave_wind_data.wave_metadata = dataset_metadata_wave;
wave_wind_data.wind_metadata = dataset_metadata_wind;
wave_wind_data.wave_data = wave_data;
wave_wind_data.wind_data = wind_data;

save_folder = fullfile('outputs', options.rootName);
if ~exist(save_folder, 'dir')
    mkdir(save_folder);
end

save(fullfile(save_folder, 'wave_wind_data.mat'), 'wave_wind_data');

end