function mean_dir = waveRose(wave_directions, hs, dataset_metadata, options)
%WAVEROSE Generate a polar histogram (rose plot) of wave or wind directions and heights/speeds.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% This function creates a polar histogram (rose plot) showing the joint probability distribution of wave (or wind/current) directions and heights (or speeds).
% The plot uses oceanographic convention (North at the top, clockwise direction labeling).
%
% SYNTAX:
%   waveRose(wave_directions, hs, dataset_metadata)
%   waveRose(wave_directions, hs, dataset_metadata, 'save_fig', true)
%   waveRose(wave_directions, hs, dataset_metadata, 'title', 'Wind Direction')
%   mean_dir = waveRose(wave_directions, hs, dataset_metadata)
%   mean_dir = waveRose(wave_directions, hs, dataset_metadata, 'save_fig', false, 'title', 'Current Direction')
%
% INPUTS:
%   wave_directions   - Numeric array of direction values in degrees (0-360°)
%   hs                - Numeric array of wave heights (or wind speeds)
%   dataset_metadata  - Structure with fields:
%                       .actual_lon       - Extraction longitude [degrees E]
%                       .actual_lat       - Extraction latitude [degrees N]
%                       .start_year_month - Start period (YYYYMM format)
%                       .end_year_month   - End period (YYYYMM format)
%
% OPTIONAL PARAMETERS (Name-Value Pairs):
%   'save_fig'        - Logical: Save figure to PNG file (default: true)
%   'title'           - String: Custom title prefix (default: 'Wave')
%
% OUTPUT:
%   mean_dir          - Circular mean direction in degrees (0-360°)
%                       Calculated using vector averaging to handle wrap-around
%
%   Figure output:
%   - Displays polar histogram with:
%     * 24 directional bins (15° each)
%     * 6 wave height bins (or wind speed bins)
%     * Probability normalization (percent)
%     * Circular mean direction statistic
%     * Location and time period in title
%   - Optionally saves high-resolution PNG file to 'output' directory
%
% FEATURES:
%   - Oceanographic convention (North up, clockwise positive)
%   - Automatic handling of missing data (NaN removal)
%   - Statistical overlay showing mean direction
%   - Publication-quality figure output (300 DPI)
%   - Customizable for wind, current, or other directional data
%
% EXAMPLE:
%   % Basic usage with dataset from loadWaveData
%   waveRose(wave_data.dir, wave_data.hs, dataset_metadata);
%
%   % Wind rose with custom title
%   waveRose(wind_direction_data, wind_speed_data, dataset_metadata, 'title', 'Wind Direction');
%
%   % Current rose without saving
%   mean_dir = waveRose(current_dir, current_speed, dataset_metadata, 'save_fig', false, 'title', 'Current Direction');
%

arguments
    wave_directions (:,1) double          % Array of directions (degrees)
    hs (:,1) double                       % Array of directions (degrees)
    dataset_metadata struct               % Metadata structure
    options.save_fig (1,1) logical = true % Save figure to PNG
    options.title (1,:) char = 'Wave'     % Custom title prefix
end

% Extract parsed values
save_figure = options.save_fig;
title_prefix = options.title;

actual_lon = dataset_metadata.actual_lon;
actual_lat = dataset_metadata.actual_lat;
start_year_month = dataset_metadata.start_year_month;
end_year_month = dataset_metadata.end_year_month;

% Remove NaNs from both direction and height arrays
mask = ~isnan(wave_directions) & ~isnan(hs);
dir_deg   = mod(wave_directions(mask), 360); % Ensure directions are 0-360
dir_rad   = deg2rad(dir_deg);                % Convert to radians for binning
hs_clean  = hs(mask);                        % Cleaned wave heights

%% Set up bin edges
numDirBins = 24; % Number of directional bins (15° each)
directedges = linspace(0, 2*pi, numDirBins+1);   % Direction bin edges (radians)

% Wave height bin edges
if strcmpi(title_prefix, 'wave')
    hightedges = [0 0.5 1 2 3 4 Inf];  % or based on quantiles
elseif strcmpi(title_prefix, 'wind')
    hightedges = [0 1.6 5.5 10.8 17.2 24.5 Inf];
else
    hightedges = round(linspace(0, max(hs_clean), 7),1); 
end

% 2D histogram: direction vs. height
waveRose = histcounts2(dir_rad, hs_clean, directedges, hightedges);

% Fix circularity (combine first and last bins), normalize to percent, stack for plotting
waveRose = [waveRose(1,:)+waveRose(end,:); waveRose(2:end-1,:)];
waveRose = waveRose / sum(waveRose, 'all') * 100; % Normalize to percent
waveRoseStack = cumsum(waveRose, 2);             % Stack for cumulative plotting

% Edges for polarhistogram (radians)
cardinals = linspace(0, 2*pi, size(waveRoseStack,1)+1);

%% Plot the figure
figure
tiledlayout(1,1,'TileSpacing','compact','Padding','compact');
nexttile

% Define FaceColor cell array for each wave height bin
FaceColors = {'#4cc9f0','#3282F6','#39D46B','#EBE94E','#F8961E','#e81416'};
numSpeedBins = size(waveRoseStack, 2);
for k = numSpeedBins:-1:1
    colorIdx = min(k, numel(FaceColors));
    polarhistogram('BinEdges', cardinals, 'BinCounts', waveRoseStack(:, k), 'FaceColor', FaceColors{colorIdx});
    hold on
end

% Title with location and time duration
title({sprintf('%s Direction Probability Distribution', title_prefix); ...
    sprintf('%.4f°E, %.4f°N from %d to %d', actual_lon, actual_lat, start_year_month, end_year_month)}, ...
    'FontSize', 20);

% Set cardinal direction labels
thetaticks([0 45 90 135 180 225 270 315])
thetaticklabels({'N','NE','E','SE','S','SW','W','NW'})

%% Dynamically generate legend labels for wave height bins
labels = cell(1, numel(hightedges)-1);
hightedges_lab = flip(hightedges); % Highest bin first
for i = 1:numel(hightedges_lab)-1
    if i == 1
        labels{i} = sprintf('%.1f+', hightedges_lab(i+1)); % Highest bin
    else
        labels{i} = sprintf('%.1f ~ %.1f', hightedges_lab(i+1), hightedges_lab(i));
    end
end

% Legend
leg = legend(labels, 'Location', 'southeastoutside');
if strcmpi(title_prefix, 'wave')
    leg.Title.String = 'H_s [m]'; % Significant wave height
elseif strcmpi(title_prefix, 'wind')
    leg.Title.String = 'Wind Speed [m/s]';
else
    leg.Title.String = 'Bin'; % Generic label for other types
end
leg.Title.FontWeight = 'bold'; % Make the legend title bold

set(allchild(gca), 'FaceAlpha', 0.8) % Set transparency for all histogram faces

%% Add statistics text box
% Calculate circular mean direction (handles wrap-around at 0°/360°)
x_comp = mean(cosd(dir_deg));
y_comp = mean(sind(dir_deg));
mean_dir = atan2d(y_comp, x_comp);
if mean_dir < 0
    mean_dir = mean_dir + 360;
end

% Add text box with mean direction statistic
str = sprintf('Mean Direction: %.1f°', mean_dir);
annotation('textbox', [0.65, 0.75, 0.2, 0.1], 'String', str, ...
    'FitBoxToText', 'on', 'BackgroundColor', 'white', ...
    'EdgeColor', 'black', 'FontSize', 12);

%% Figure visualization settings
grid on; % Add grid for readability
ax = gca;
ax.ThetaZeroLocation = 'top';     % Set North (0°) at the top
ax.ThetaDir = 'clockwise';        % Clockwise direction (oceanographic convention)
ax.RAxis.TickLabelFormat = '%g%%'; % Show percent on radial axis
ax.FontSize = 12; % Set font size for axes elements

% Configure figure window properties
figure_name = sprintf('%s Rose', title_prefix);
set(gcf,'Name', figure_name,'units','normalized','outerposition',[1/2 1/4 1/3 1/2])

%% Save the figure if requested
if save_figure
    if ~exist('outputs', 'dir')
        mkdir('outputs')
    end
    title_prefix = lower(title_prefix);
    filename = sprintf('%sRose_%d_%d_%.4fE_%.4fN', strrep(title_prefix, ' ', ''), start_year_month, end_year_month, actual_lon, actual_lat);
    print(gcf, '-dpng', '-r300', fullfile('outputs', [filename '.png']))
end
end