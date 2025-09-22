function [location_info] = findNearestGridPoint(target_lon, target_lat, lonlat)
%FINDNEARESTGRIDPOINT Find the nearest valid grid point in wave data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   location_info = findNearestGridPoint(url, target_lon, target_lat, search_radius, verbose)
%
% INPUTS:
%   url           - URL to the NetCDF file
%   target_lon    - Target longitude [degrees E]
%   target_lat    - Target latitude [degrees N]
%   search_radius - Search radius around target location [degrees]
%   lonlat        - Pre-download longitude and latitude file name
%
% OUTPUT:
%   location_info - Structure containing:
%                   .target_lon - Target longitude used
%                   .target_lat - Target latitude used
%                   .actual_lon - Actual longitude used
%                   .actual_lat - Actual latitude used
%                   .lon_idx    - Longitude index for subsetting
%                   .lat_idx    - Latitude index for subsetting

try
    % Get the path to this function's directory
    current_file_path = mfilename('fullpath');
    package_dir = fileparts(current_file_path);
    lonlat_info_file = fullfile(package_dir, lonlat);
    % load station info
    load(lonlat_info_file, 'geo_coord');

    longitude = geo_coord.longitude;
    latitude = geo_coord.latitude;
    valid_lon_idx = geo_coord.valid_lon_idx;
    valid_lat_idx = geo_coord.valid_lat_idx;

    distances = sqrt((longitude(valid_lon_idx) - target_lon).^2 + (latitude(valid_lat_idx) - target_lat).^2);
    [~, min_idx] = min(distances);
    ocean_lon_idx = valid_lon_idx(min_idx);
    ocean_lat_idx = valid_lat_idx(min_idx);

    % Store location info (using absolute indices)
    location_info.target_lon = target_lon;
    location_info.target_lat = target_lat;
    location_info.actual_lon = longitude(ocean_lon_idx);
    location_info.actual_lat = latitude(ocean_lat_idx);
    location_info.lon_idx = ocean_lon_idx;
    location_info.lat_idx = ocean_lat_idx;

catch ME
    error('Failed to find nearest grid point: %s', ME.message);
end

end