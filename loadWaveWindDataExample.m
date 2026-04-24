%% Load Wave Data: Main Script Example Using the `loadWaveWindData` Function 
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
target_lon = 146.5615; % Longitude [degrees E]
target_lat = -40.477;  % Latitude [degrees N]
start_year_month = 201501; % Start YearMonth (YYYYMM)
end_year_month = 201502;   % End YearMonth (YYYYMM)

%% Load Wave and Wind Data
[wave_wind_data] = loadWaveWindData(target_lon, target_lat, start_year_month, end_year_month);

%% Data Analysis and Visualization
% Assign parameters
wave_data = wave_wind_data.wave_data;
wave_metadata = wave_wind_data.wave_metadata;
wind_data = wave_wind_data.wind_data;
wind_metadata = wave_wind_data.wind_metadata;

% Probability Distribution Heatmap
waveHindcastAnalysis(wave_data.t02, wave_data.hs, wave_metadata);

% Wave Direction Distribution
wave_mean_dir = waveRose(wave_data.dir, wave_data.hs, wave_metadata);

% Wind Direction Distribution
wind_mean_dir = waveRose(wind_data.wnddir, wind_data.wnd, wind_metadata, "title", "Wind");

%% Verify loading location
% Confirm wave and wind data are loaded closely to the target location
locationComparison(wave_metadata, wind_metadata);