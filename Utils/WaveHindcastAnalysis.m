%WAVEHINDCASTANALYSIS Generate probability distribution heatmap for wave data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% This script generates a bi-variate probability distribution heatmap showing
% the relationship between wave period (T02) and significant wave height (Hs).
%
% REQUIREMENTS:
%   - wave_data: Table with t02 and hs columns
%   - n_bins: Number of bins for each dimension (set before calling)
%   - target_lon, target_lat: Location coordinates for plot title
%   - start_year_month, end_year_month: Time period for plot title
%
% OUTPUT:
%   Creates a figure with probability distribution heatmap
%

% Remove NaN values for probability calculation
valid_idx = ~isnan(wave_data.t02) & ~isnan(wave_data.hs);
t02_clean = wave_data.t02(valid_idx);
hs_clean = wave_data.hs(valid_idx);

% Define bin edges for 2D histogram
t0m1_edges = linspace(min(t02_clean), max(t02_clean), n_bins);
hs_edges = linspace(min(hs_clean), max(hs_clean), n_bins);

% Create 2D histogram
[N, ~, ~] = histcounts2(t02_clean, hs_clean, t0m1_edges, hs_edges);

% Convert counts to probabilities (normalize by total number of observations)
probability = N' / sum(N(:)); % Transpose for correct orientation

% Create bin centers for plotting
t0m1_centers = (t0m1_edges(1:end-1) + t0m1_edges(2:end)) / 2;
hs_centers = (hs_edges(1:end-1) + hs_edges(2:end)) / 2;

figure
% Create heatmap using imagesc for better control
imagesc(t0m1_centers, hs_centers, probability);
set(gca, 'YDir', 'normal') % Flip Y-axis to normal orientation

% Apply the same custom colormap
mycolormap = customcolormap([0 .25 .5 .75 1],{'#e81416','#EBE94E','#39D46B','#3282F6','#ffffff'});
colormap(mycolormap);

% Add colorbar
cbh = colorbar;
ylabel(cbh, 'Probability Density', 'FontSize', 12)

% Formatting
xlabel('Mean Period T_{0m1} [s]', 'FontSize', 12)
ylabel('Significant Wave Height H_s [m]', 'FontSize', 12)
title({'Bi-Variate Probability Distribution'; ...
       sprintf('%.4f°E, %.4f°N from %d to %d', target_lon, target_lat, start_year_month, end_year_month)}, ...
       'FontSize', 12);

% Add probability values as text on each cell
hold on
for i = 1:length(hs_centers)
    for j = 1:length(t0m1_centers)
        if probability(i,j) > 0.003 % Only show text the probabilities is greater then 0.3%
            % Choose text color based on background intensity
            if probability(i,j) > max(probability(:))/2
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

% Improve axis appearance
set(gca, 'FontSize', 11)
axis tight

%% Clean up temporary variables (keep required input parameters)
clear valid_idx t02_clean hs_clean t0m1_edges hs_edges N probability ...
      t0m1_centers hs_centers cbh i j text_color mycolormap