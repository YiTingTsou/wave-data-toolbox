function distance_km = calculateDistance(target_lat, target_lon, location_info)
%CALCULATEDISTANCE  Calculate distance (km) between target and actual extraction location.
% 
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% INPUTS:
%   target_lat     - Latitude of the target location
%   target_lon     - Longitude of the target location
%   location_info - Structure with actual_lat and actual_lon fields
% OUTPUTS:
%   distance_km   - Distance in kilometers between target and actual location
% 

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