function [folder_name, save_filename] = generateFilePaths(lon, lat, current_ym, region, grid_resolution)
%GENERATEFILEPATHS Generate consistent file and folder paths for wave data
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   [folder_name, save_filename] = generateFilePaths(lon, lat, current_ym, region, grid_resolution)
%
% INPUTS:
%   lon             - Longitude [degrees E]
%   lat             - Latitude [degrees N]
%   current_ym      - Current year-month (YYYYMM format)
%   region          - Data region ('aus', 'glob', 'pac')
%   grid_resolution - Grid resolution in arcminutes
%
% OUTPUTS:
%   folder_name     - Folder name based on coordinates
%   save_filename   - Full filename with path for saving

% Generate folder name based on coordinates
folder_name = sprintf('lon%.4fE_lat%.4fN', lon, lat);

% Generate save filename
save_filename = sprintf('%s/wave_data_%d_%s_%dm_%.4fE_%.4fN.mat', ...
    folder_name, current_ym, region, grid_resolution, lon, lat);

end