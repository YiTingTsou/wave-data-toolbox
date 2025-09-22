function locationComparison(dataset_metadata, dataset_metadata_wind)
% LOCATIONCOMPARISON Visualizes and compares target, wave, and wind locations on a map.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% This function creates a figure showing the specified locations and relevant datasets
% for visual comparison. No outputs are returned; the result is a plotted figure.
%
% SYNTAX:
%   locationComparison(dataset_metadata, dataset_metadata_wind);
%
% Inputs:
%   dataset_metadata        - Struct with fields:
%                            .target_lon, .target_lat: Target location coordinates
%                            .actual_lon, .actual_lat: Wave data location coordinates
%   dataset_metadata_wind   - (Optional) Struct with fields:
%                            .actual_lon, .actual_lat: Wind data location coordinates
%
% EXAMPLE:
%   % Having one extract dataset_metadata (wave or wind)
%   locationComparison(dataset_metadata);
%
%   % Having both wave and wind metadata for validation
%   locationComparison(dataset_metadata);

% Extract coordinates
target_lon = dataset_metadata.target_lon;
target_lat = dataset_metadata.target_lat;
wave_lon = dataset_metadata.actual_lon;
wave_lat = dataset_metadata.actual_lat;

% Prepare figure
figure;
hold on;
set(gcf, 'Name', 'Location Comparison', 'units', 'normalized', 'outerposition', [0 0 1 1]);
dataColor = {'#ef476f';'#762a83';'#f9c74f';'#fc8d59';'#8cb369';'#3288bd'};

% Grid datasets to plot
gridArray = {'glob_24m.mat', 'aus_10m.mat', 'aus_4m.mat', 'pac_10m.mat', 'pac_4m.mat'};
gridArrayName = {'glob\_24m', 'aus\_10m', 'aus\_4m', 'pac\_10m', 'pac\_4m'};

% Get the path to this function's directory
current_file_path = mfilename('fullpath');
package_dir = fileparts(current_file_path);

% Plot gridded locations
for i = 1:length(gridArray)
    lonlat_info_file = fullfile(package_dir, '+gridded', gridArray{i});
    load(lonlat_info_file, 'geo_coord'); % geo_coord.grid_lon, geo_coord.grid_lat
    scatter(geo_coord.grid_lon, geo_coord.grid_lat, 20, 'filled', ...
        MarkerFaceAlpha = 0.7, ...
        MarkerFaceColor = dataColor{i},...
        DisplayName = gridArrayName{i});
end

% Plot wind locations if provided
if nargin == 2 && ~isempty(dataset_metadata_wind)
    wind_lon = dataset_metadata_wind.actual_lon;
    wind_lat = dataset_metadata_wind.actual_lat;
    lonlat_info_file = fullfile(package_dir, '+spec', 'spac_station_info.mat');
    load(lonlat_info_file, 'station_info'); % station_info.longitude, station_info.latitude
    scatter(station_info.longitude, station_info.latitude, 100, 'x', ...
        LineWidth = 2, MarkerFaceAlpha = 0.7, MarkerFaceColor = dataColor{end}, DisplayName = 'spec');
    plot(wind_lon, wind_lat, 'rx', MarkerSize = 15, LineWidth = 2, DisplayName = 'Wind Data Location');
end

% Plot selected wave and target locations
plot(wave_lon, wave_lat, 'r+', MarkerSize = 15, LineWidth = 2, DisplayName = 'Wave Data Location');
plot(target_lon, target_lat, 'ro', MarkerSize = 15, LineWidth = 2, DisplayName = 'Target Location');

% Add labels and legend
title('Location Comparison', FontSize = 24);
set(gca, 'FontSize', 16)
xlabel('Longitude [°E]');
ylabel('Latitude [°N]');
legend;

% Set axis limits for better focus
xlim([target_lon - 5, target_lon + 5]);
ylim([target_lat - 3, target_lat + 3]);

hold off;
end