%% LOAD WAVE DATA - MAIN SCRIPT
%
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% For full documentation and usage instructions,
% see README.md in the project root directory.
%
% This script demonstrates wave hindcast data loading and basic analysis
% using the CAWCR Wave Hindcast – Aggregated Collection.
%
% ==================================================================

%% Initialization
clc; clear; close all;
% Import functions from the waveDataToolbox package
import waveDataToolbox.*

%% User Input: Set target location and time range
target_lon = 145.1768; % Longitude [degrees E]
target_lat = -40.026;  % Latitude [degrees N]
start_year_month = 201501; % Start YearMonth (YYYYMM)
end_year_month = 201503;   % End YearMonth (YYYYMM)

%% Load Wave Data

[wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month);

% Wave Data Analysis and Visualization
% Probability Distribution Heatmap
waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata);

% Wave Direction Distribution
wave_mean_dir = waveRose(wave_data.dir, wave_data.hs, dataset_metadata);

%% Load Wind Data

[wind_data, dataset_metadata_wind] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, "wind", true);

% Wind Direction Distribution
wind_mean_dir = waveRose(wind_data.wnddir, wind_data.wnd, dataset_metadata_wind, "title", "Wind");

%% Verify loading location
% Confirm wave and wind data are loaded closely to the target location
locationComparison(dataset_metadata, dataset_metadata_wind);