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
end_year_month = 201502; % YearMonth

%% Load wave data using function
wave_data = loadWaveData(target_lon, target_lat, start_year_month, end_year_month, 'save_loaded_data', false);
% Note: Complete dataset is always saved to outputData/ folder regardless of save_loaded_data setting

%% Basic Analysis and Visualization
if ~isempty(wave_data)
    % Figure 1 - Probability Distribution Heatmap
    n_bins = 10; % Number of bins for each dimension
    waveHindcastAnalysis
    
    % Figure 2 - Wave Direction Distribution
    waveRose  
else
    fprintf('No data loaded. Check your parameters.\n');
end
