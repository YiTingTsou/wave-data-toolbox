%% Hindcast Wave–Wind Analysis and Visualisation
%
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% For full documentation and usage instructions,
% see README.md in the project root directory.
%
% Run the script and select `wave_wind_data.mat`.
% A heatmap, one wave rose and one wind rose are generated from the selected data,
% and the resulting figure is saved in the same folder as the data file.
%
% ==================================================================

%% Initialization
clc; clear; close all;
% Import functions from the waveDataToolbox package
import waveDataToolbox.*

%% User Input: Select `the wave_wind_data.mat`
[selected_file,location] = uigetfile('*.mat','Select a file');

%% Load Dataset and Initialise Variables
% Load the selected data
load(fullfile(location,selected_file))

% Assign parameters from the loaded dataset
wave_data = wave_wind_data.wave_data;
wave_metadata = wave_wind_data.wave_metadata;
wind_data = wave_wind_data.wind_data;
wind_metadata = wave_wind_data.wind_metadata;

% Update the metadata filename so the output is saved in the same folder as the selected file
wave_metadata.filename = location;
wind_metadata.filename = location;

%% Data Analysis and Visualization
% Probability Distribution Heatmap
waveHindcastAnalysis(wave_data.t02, wave_data.hs, wave_metadata);

% Wave Direction Distribution
wave_mean_dir = waveRose(wave_data.dir, wave_data.hs, wave_metadata);

% Wind Direction Distribution
wind_mean_dir = waveRose(wind_data.wnddir, wind_data.wnd, wind_metadata, "title", "Wind");

%% Verify loading location
% Confirm wave and wind data are loaded closely to the target location
locationComparison(wave_metadata, wind_metadata);
