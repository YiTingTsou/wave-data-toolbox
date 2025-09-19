function [location_info] = findNearestGridPoint(url, target_lon, target_lat, search_radius)
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
%   verbose       - Display progress messages
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
    % Read coordinate arrays for this file
    longitude_full = ncread(url, 'longitude');
    latitude_full = ncread(url, 'latitude');

    % Find the subset indices around target location
    lon_mask = (longitude_full >= target_lon - search_radius) & ...
        (longitude_full <= target_lon + search_radius);
    lat_mask = (latitude_full >= target_lat - search_radius) & ...
        (latitude_full <= target_lat + search_radius);

    % Get the start and count indices for subsetting
    lon_indices = find(lon_mask);
    lat_indices = find(lat_mask);

    if isempty(lon_indices) || isempty(lat_indices)
        error('No grid points found within %.1f° of target location (%.4f°E, %.4f°N)', ...
            search_radius, target_lon, target_lat);
    end

    lon_start = min(lon_indices);
    lon_count = length(lon_indices);
    lat_start = min(lat_indices);
    lat_count = length(lat_indices);

    % Read only the subset of coordinates
    longitude = longitude_full(lon_indices);
    latitude = latitude_full(lat_indices);

    % Find nearest grid points
    [~, lon_idx] = min(abs(longitude - target_lon));
    [~, lat_idx] = min(abs(latitude - target_lat));

    % Get first time step for available point detection
    hs_map = squeeze(ncread(url, 'hs', [lon_start, lat_start, 1], [lon_count, lat_count, 1]));

    % Find nearest available point (ocean point)
    [ocean_lon_idx, ocean_lat_idx] = find(~isnan(hs_map));

    distances = sqrt((longitude(ocean_lon_idx) - target_lon).^2 + ...
        (latitude(ocean_lat_idx) - target_lat).^2);
    [~, min_idx] = min(distances);
    ocean_lon_idx = ocean_lon_idx(min_idx);
    ocean_lat_idx = ocean_lat_idx(min_idx);

    % Store location info (using absolute indices)
    location_info.target_lon = target_lon;
    location_info.target_lat = target_lat;
    location_info.actual_lon = longitude(ocean_lon_idx);
    location_info.actual_lat = latitude(ocean_lat_idx);
    location_info.lon_idx = lon_start + ocean_lon_idx - 1;
    location_info.lat_idx = lat_start + ocean_lat_idx - 1;

catch ME
    error('Failed to find nearest grid point: %s', ME.message);
end

end