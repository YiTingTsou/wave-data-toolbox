function mean_dir = waveRose(wave_directions, dataset_metadata, varargin)
%WAVEROSE Generate polar histogram (rose plot) # Configure figure window properties
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% Creates a polar histogram showing the probability distribution of wave 
% directions, commonly known as a wave rose plot. The plot uses oceanographic
% convention with North at the top and clockwise direction labeling.
%
% SYNTAX:
%   waveRose(wave_directions, dataset_metadata)
%   waveRose(wave_directions, dataset_metadata, 'save_fig', true)
%   waveRose(wave_directions, dataset_metadata, 'title', 'Wind Direction')
%   mean_dir = waveRose(wave_directions, dataset_metadata)
%   mean_dir = waveRose(wave_directions, dataset_metadata, 'save_fig', false, 'title', 'Current Direction')
%
% INPUTS:
%   wave_directions   - Numeric array of wave direction values in degrees (0-360°)
%                       NaN values are automatically removed
%   dataset_metadata  - Structure containing dataset information with fields:
%                       .actual_lon       - Extraction longitude [degrees E]
%                       .actual_lat       - Extraction latitude [degrees N] 
%                       .start_year_month - Start period (YYYYMM format)
%                       .end_year_month   - End period (YYYYMM format)
%
% OPTIONAL PARAMETERS (Name-Value Pairs):
%   'save_fig'        - Logical: Save figure to PNG file (default: true)
%   'title'           - String: Custom title prefix (default: 'Wave Direction')
%
% OUTPUT:
%   mean_dir          - Circular mean wave direction in degrees (0-360°)
%                       Calculated using vector averaging to handle directional wrap-around
%   
%   Figure output:
%   - Displays polar histogram figure with:
%     * 36 directional bins (10° each)
%     * Probability normalization
%     * Circular mean direction statistic
%     * Location and time period in title
%   - Optionally saves high-resolution PNG file to 'output' directory
%
% FEATURES:
%   - Oceanographic convention (North up, clockwise positive)
%   - Automatic handling of missing data (NaN removal)
%   - Statistical overlay showing mean wave direction
%   - Publication-quality figure output (300 DPI)
%   - Customizable for wind, current, or other directional data
%
% EXAMPLE:
%   % Basic usage with dataset from loadWaveData
%   waveRose(wave_data.dir, dataset_metadata);
%   
%   % Wind rose with custom title
%   waveRose(wind_direction_data, dataset_metadata, 'title', 'Wind Direction');
%   
%   % Current rose without saving
%   mean_dir = waveRose(current_dir, dataset_metadata, 'save_fig', false, 'title', 'Current Direction');
%   
%   % Get mean direction and display plot
%   mean_direction = waveRose(wave_data.dir, dataset_metadata);
%   fprintf('Mean wave direction: %.1f degrees\n', mean_direction);
%
% SEE ALSO: loadWaveData, polarhistogram
%

p = inputParser;
addRequired(p, 'wave_directions', @isnumeric);
addRequired(p, 'dataset_metadata', @isstruct);
addParameter(p, 'save_fig', true, @islogical);
addParameter(p, 'title', 'Wave', @ischar);

parse(p, wave_directions, dataset_metadata, varargin{:});

% Extract parsed values
save_figure = p.Results.save_fig;
title_prefix = p.Results.title;

actual_lon = dataset_metadata.actual_lon;
actual_lat = dataset_metadata.actual_lat;
start_year_month = dataset_metadata.start_year_month;
end_year_month = dataset_metadata.end_year_month;

figure
% Remove NaN values from wave direction data
dir_clean = wave_directions(~isnan(wave_directions));
% Convert degrees to radians for polar plot
dir_rad = deg2rad(dir_clean);
% Create polar histogram
polarhistogram(dir_rad, 36, 'Normalization', 'probability', 'FaceAlpha', 0.7);
% Formatting
title({sprintf('%s Direction Probability Distribution', title_prefix); ...
       sprintf('%.4f°E, %.4f°N from %d to %d', actual_lon, actual_lat, start_year_month, end_year_month)}, ...
       'FontSize', 20);
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
           'EdgeColor', 'black', 'FontSize', 12);

%% Figure visualization settings
% Set font size for axes elements (excluding title)
ax.FontSize = 12;
% Configure figure window properties
figure_name = sprintf('%s Rose', title_prefix);
set(gcf,'Name', figure_name,'units','normalized','outerposition',[1/2 1/4 1/3 1/2])

%% Save the figure
if save_figure
    if ~exist('output', 'dir')
            mkdir('output')
    end
    filename = sprintf('%sRose_%d_%d_%.4fE_%.4fN', strrep(title_prefix, ' ', ''), start_year_month, end_year_month, actual_lon, actual_lat);
    print(gcf, '-dpng', '-r300', fullfile('output', [filename '.png']))
end
end