%WAVEROSE Generate polar histogram (rose plot) for wave direction data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% This script creates a polar histogram showing the probability distribution
% of wave directions, commonly known as a wave rose plot.
%
% REQUIREMENTS:
%   - wave_data: Table with dir column (wave direction in degrees)
%   - target_lon, target_lat: Location coordinates for plot title
%   - start_year_month, end_year_month: Time period for plot title
%
% OUTPUT:
%   Creates a polar figure showing wave direction probability distribution
%

figure
% Remove NaN values from wave direction data
dir_clean = wave_data.dir(~isnan(wave_data.dir));
% Convert degrees to radians for polar plot
dir_rad = deg2rad(dir_clean);
% Create polar histogram
polarhistogram(dir_rad, 36, 'Normalization', 'probability', 'FaceAlpha', 0.7);
% Formatting
title({'Wave Direction Probability Distribution'; ...
       sprintf('%.4f°E, %.4f°N from %d to %d', target_lon, target_lat, start_year_month, end_year_month)}, ...
       'FontSize', 12);
thetaticks(0:45:330);
thetaticklabels({'N', 'N-E', 'E', 'S-E', 'S', 'S-W', 'W', '270°', 'N-W', 'N'});

% Add grid and improve readability
grid on;
ax = gca;
ax.ThetaZeroLocation = 'top';     % Set North (0°) at the top
ax.ThetaDir = 'clockwise';        % Clockwise direction (oceanographic convention)

% Add statistics text
% Calculate circular mean direction (handles wrap-around at 0°/360°)
x_comp = mean(cosd(dir_clean));
y_comp = mean(sind(dir_clean));
mean_dir = atan2d(y_comp, x_comp);
if mean_dir < 0
    mean_dir = mean_dir + 360;
end

% Add text box with statistics
str = sprintf('Mean Direction: %.1f°', mean_dir);
annotation('textbox', [0.02, 0.78, 0.2, 0.1], 'String', str, ...
           'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
           'EdgeColor', 'black', 'FontSize', 10);

%% Clean up temporary variables (keep required input parameters)
clear dir_clean dir_rad ax x_comp y_comp str