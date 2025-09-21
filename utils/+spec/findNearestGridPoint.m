function [location_info] = findNearestGridPoint(target_lon, target_lat)
%FINDNEARESTGRIDPOINT Find the nearest valid grid point in wind spectral data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   location_info = findNearestGridPoint(target_lon, target_lat)
%
% INPUTS:
%   target_lon    - Target longitude [degrees E]
%   target_lat    - Target latitude [degrees N]
%
% OUTPUT:
%   location_info - Structure containing:
%                   .target_lon - Target longitude used
%                   .target_lat - Target latitude used
%                   .actual_lon - Actual longitude used
%                   .actual_lat - Actual latitude used
%                   .station_idx - Station index for spectral data extraction

try
    % Get the path to this function's directory
    current_file_path = mfilename('fullpath');
    package_dir = fileparts(current_file_path);
    station_info_file = fullfile(package_dir, 'spac_station_info.mat');
    
    load(station_info_file, 'station_info');

    distances = sqrt((station_info.longitude - target_lon).^2 + (station_info.latitude - target_lat).^2);
    [~, station_idx] = min(distances);

    % Store location info (using absolute indices)
    location_info.target_lon = target_lon;
    location_info.target_lat = target_lat;
    location_info.actual_lon = station_info.longitude(station_idx);
    location_info.actual_lat = station_info.latitude(station_idx);
    location_info.station_idx = station_idx;

catch ME
    error('Failed to find nearest grid point: %s', ME.message);
end

end