%% LOAD WAVE DATA - MAIN SCRIPT
% 
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
% 
% For full documentation and usage instructions,
% see README.md in the project root directory.
%
% This script demonstrates wave hindcast data loading and basic analysis
% using the CSIRO/CAWCR Wave Hindcast Archive.
%
% ==================================================================

%% Load Wave Data Script
% Demonstrates loading and basic visualization of wave hindcast data
clc;clear;close all

addpath utils\

%% User Input
target_lon = 145.1768; % [degrees E]
target_lat = -40.026; % [degrees N]
start_year_month = 201501; % YearMonth
end_year_month = 201512; % YearMonth

%% Load wave data using function
[wave_data, dataset_metadata] = loadWaveData(target_lon, target_lat, start_year_month, end_year_month);

%% Basic Analysis and Visualization
if ~isempty(wave_data)
    % Figure 1 - Probability Distribution Heatmap
    waveHindcastAnalysis(wave_data.t02, wave_data.hs, dataset_metadata)
    
    % Figure 2 - Wave Direction Distribution
    mean_dir = waveRose(wave_data.dir, dataset_metadata);
else
    fprintf('No data loaded. Check your parameters.\n');
end
