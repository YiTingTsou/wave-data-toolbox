function waveHindcastAnalysis(t02, hs, dataset_metadata, varargin)
%WAVEHINDCASTANALYSIS Generate probability distribution heatmap for wave data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% Creates a bi-variate probability distribution heatmap showing the joint
% relationship between any two wave parameters (commonly wave period and 
% significant wave height, but can be any pair of wave variables).
% The visualization helps identify dominant wave conditions and their
% frequency of occurrence at the specified location and time period.
%
% SYNTAX:
%   waveHindcastAnalysis(t02, hs, dataset_metadata)
%   waveHindcastAnalysis(t02, hs, dataset_metadata, 'bins', 20)
%   waveHindcastAnalysis(t02, hs, dataset_metadata, 'save_fig', false)
%   waveHindcastAnalysis(t02, hs, dataset_metadata, 'text', false)
%   waveHindcastAnalysis(t02, hs, dataset_metadata, 'bins', 25, 'save_fig', true)
%
% INPUTS:
%   t02               - Numeric array of first wave parameter (e.g., wave periods) [units depend on data]
%                       This parameter will be plotted on the x-axis
%   hs                - Numeric array of second wave parameter (e.g., wave heights) [units depend on data]
%                       This parameter will be plotted on the y-axis
%   dataset_metadata  - Structure containing dataset information with fields:
%                       .actual_lon       - Extraction longitude [degrees E]
%                       .actual_lat       - Extraction latitude [degrees N]
%                       .start_year_month - Start period (YYYYMM format)
%                       .end_year_month   - End period (YYYYMM format)
%
% OPTIONAL PARAMETERS (Name-Value Pairs):
%   'bins'            - Number of bins for each dimension (default: 15)
%   'save_fig'        - Logical: Save figure to PNG file (default: true)
%   'text'            - Logical: Display percentage values on heatmap (default: true)
%   'xlabel'          - String: X-axis label (default: 'Mean Period T_{02} [s]')
%   'ylabel'          - String: Y-axis label (default: 'Significant Wave Height H_s [m]')
%
% OUTPUT:
%   - Displays bi-variate probability heatmap with:
%     * Probability values as percentage text overlay (>1% only)
%     * Location and time period in title
%     * Probability density colorbar
%   - Optionally saves high-resolution PNG file to 'output' directory
%
% FEATURES:
%   - Automatic handling of missing data (NaN removal)
%   - Adaptive text color for readability (white on dark, black on light)
%   - Custom colormap for enhanced visualization
%   - Publication-quality figure output (300 DPI)
%   - Probability normalization for statistical interpretation
%
% EXAMPLE:
%   % Basic usage with default settings (15 bins, save figure, show text)
%   waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata);
%   
%   % Custom number of bins
%   waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, 'bins', 20);
%   
%   % Clean heatmap without percentage text
%   waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, 'text', false);
%   
%   % Display only (no file saving)
%   waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, 'save_fig', false);
%   
%   % Multiple options combined
%   waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata, ...
%                       'bins', 25, 'save_fig', true, 'text', false);
%   
%   % Custom axis labels for different wave parameters
%   waveHindcastAnalysis(wave_data.dir, wave_data.hs, dataset_metadata, ...
%                       'xlabel', 'Wave Direction [degrees]', 'ylabel', 'Significant Wave Height H_s [m]');
%
% NOTES:
%   - Both input arrays must have the same length
%   - Parameter names (t02, hs) are for convenience - any two wave parameters can be used
%   - Higher n_bins values provide more detail but may reduce statistical significance
%   - Probability text is only shown for bins with >0.3% probability
%
% SEE ALSO: loadWaveData, waveRose, customcolormap
%

p = inputParser;
addRequired(p, 't02', @isnumeric);
addRequired(p, 'hs', @isnumeric);
addRequired(p, 'dataset_metadata', @isstruct);
addParameter(p, 'bins', 15, @(x) isnumeric(x) && isscalar(x) && x > 0);
addParameter(p, 'save_fig', true, @islogical);
addParameter(p, 'text', true, @islogical);
addParameter(p, 'xlabel', 'Mean Period T_{02} [s]', @ischar);
addParameter(p, 'ylabel', 'Significant Wave Height H_s [m]', @ischar);

parse(p, t02, hs, dataset_metadata, varargin{:});

% Extract parsed values
n_bins = p.Results.bins;
save_figure = p.Results.save_fig;
show_percentages = p.Results.text;
x_label = p.Results.xlabel;
y_label = p.Results.ylabel;

actual_lon = dataset_metadata.actual_lon;
actual_lat = dataset_metadata.actual_lat;
start_year_month = dataset_metadata.start_year_month;
end_year_month = dataset_metadata.end_year_month;

% Remove NaN values for probability calculation
valid_idx = ~isnan(t02) & ~isnan(hs);
t02_clean = t02(valid_idx);
hs_clean = hs(valid_idx);

% Define bin edges for 2D histogram
t02_edges = linspace(min(t02_clean), max(t02_clean), n_bins);
hs_edges = linspace(min(hs_clean), max(hs_clean), n_bins);

% Create 2D histogram
[N, ~, ~] = histcounts2(t02_clean, hs_clean, t02_edges, hs_edges);

% Convert counts to probabilities (normalize by total number of observations)
probability = N' / sum(N(:)); % Transpose for correct orientation

% Create bin centers for plotting
t0m1_centers = (t02_edges(1:end-1) + t02_edges(2:end)) / 2;
hs_centers = (hs_edges(1:end-1) + hs_edges(2:end)) / 2;

figure
% Create heatmap using imagesc for better control
imagesc(t0m1_centers, hs_centers, probability);
set(gca, 'YDir', 'normal') % Flip Y-axis to normal orientation

% Apply the custom colormap
mycolormap = customcolormap([0 .25 .5 .75 1],{'#e81416','#EBE94E','#39D46B','#3282F6','#ffffff'});
colormap(mycolormap);

% Add colorbar
cbh = colorbar;
ylabel(cbh, 'Probability Density', 'FontSize', 14)

% Formatting
xlabel(x_label)
ylabel(y_label)
title({'Bi-Variate Probability Distribution'; ...
       sprintf('%.4f°E, %.4f°N from %d to %d', actual_lon, actual_lat, start_year_month, end_year_month)}, ...
       'FontSize', 20);

% Add probability values as text on each cell
if show_percentages
hold on
for i = 1:length(hs_centers)
    for j = 1:length(t0m1_centers)
        if probability(i,j) > 0.003 % Only show text the probabilities is greater then 0.3%
            % Choose text color based on background intensity
            if probability(i,j) > max(probability(:))*6/7
                text_color = 'white';
            else
                text_color = 'black';
            end
            
            % Display probability as percentage
            text(t0m1_centers(j), hs_centers(i), sprintf('%.1f%%', probability(i,j)*100), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
                'FontSize', 8, 'Color', text_color, 'FontWeight', 'bold');
        end
    end
end
end

% Improve axis appearance
set(gca, 'FontSize', 12)
axis tight

% Configure figure window properties
set(gcf,'Name','Bi-Variate Probability Distribution','units','normalized','outerposition',[1/8 1/4 1/3 1/2])

%% Save the figure
if save_figure
    if ~exist('output', 'dir')
            mkdir('output')
    end
    filename = sprintf('biVariate_%d_%d_%.4fE_%.4fN', start_year_month, end_year_month, actual_lon, actual_lat);
    print(gcf, '-dpng', '-r300', fullfile('output', [filename '.png']))
end
end