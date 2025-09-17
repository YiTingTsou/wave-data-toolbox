function [location_info] = findNearestGridPoint(url, target_lon, target_lat, search_radius, verbose)
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
%                   .actual_lon - Actual longitude used
%                   .actual_lat - Actual latitude used
%                   .lon_start  - Starting longitude index for subsetting
%                   .lat_start  - Starting latitude index for subsetting
%                   .lon_count  - Number of longitude points in subset
%                   .lat_count  - Number of latitude points in subset
%                   .final_lon_idx - Final longitude index within subset
%                   .final_lat_idx - Final latitude index within subset

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

    % Use ocean point if target is NaN
    final_lon_idx = lon_idx;
    final_lat_idx = lat_idx;
    if isnan(hs_map(lon_idx, lat_idx))
        final_lon_idx = ocean_lon_idx;
        final_lat_idx = ocean_lat_idx;
    end

    % Store location info
    location_info.actual_lon = longitude(final_lon_idx);
    location_info.actual_lat = latitude(final_lat_idx);
    location_info.lon_start = lon_start;
    location_info.lat_start = lat_start;
    location_info.lon_count = lon_count;
    location_info.lat_count = lat_count;
    location_info.final_lon_idx = final_lon_idx;
    location_info.final_lat_idx = final_lat_idx;

catch ME
    error('Failed to find nearest grid point: %s', ME.message);
end

end