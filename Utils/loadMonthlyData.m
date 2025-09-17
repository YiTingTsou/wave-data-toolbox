function [monthly_data] = loadMonthlyData(url, location_info, additional_params, verbose)
%LOADMONTHLYDATA Load wave data for a single month from OPeNDAP server
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   monthly_data = loadMonthlyData(url, location_info, additional_params, verbose)
%
% INPUTS:
%   url             - URL to the NetCDF file
%   location_info   - Structure from findNearestGridPoint containing grid indices
%   additional_params - Cell array of additional parameter names to load
%   verbose         - Display progress messages
%
% OUTPUT:
%   monthly_data    - Structure containing:
%                     .time - Time vector
%                     .t02  - Zero-crossing period
%                     .hs   - Significant wave height
%                     .dir  - Wave direction
%                     .(additional_params) - Any additional parameters

try
    % Read time data for current month
    time_month = ncread(url, 'time');
    num_time_month = length(time_month);

    % Calculate absolute indices for data extraction
    abs_lon_idx = location_info.lon_start + location_info.final_lon_idx - 1;
    abs_lat_idx = location_info.lat_start + location_info.final_lat_idx - 1;

    % Read standard wave data for current month at the specific location
    t02_month = squeeze(ncread(url, 't02', [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
    hs_month = squeeze(ncread(url, 'hs', [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
    dir_month = squeeze(ncread(url, 'dir', [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
    
    % Read additional parameters if requested
    additional_data = struct();
    if ~isempty(additional_params)
        for j = 1:length(additional_params)
            param_name = additional_params{j};
            try
                param_data = squeeze(ncread(url, param_name, [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
                additional_data.(param_name) = param_data(:);  % Ensure column vector
            catch ME_param
                if verbose
                    fprintf('  Warning: Failed to load parameter %s - %s\n', param_name, ME_param.message);
                end
                additional_data.(param_name) = NaN(num_time_month, 1);  % Fill with NaN if parameter not available
            end
        end
    end

    % Ensure all arrays are column vectors and store in output structure
    monthly_data.time = time_month(:);
    monthly_data.t02 = t02_month(:);
    monthly_data.hs = hs_month(:);
    monthly_data.dir = dir_month(:);
    
    % Add additional parameters to the structure
    param_names = fieldnames(additional_data);
    for i = 1:length(param_names)
        monthly_data.(param_names{i}) = additional_data.(param_names{i});
    end

catch ME
    error('Failed to load monthly data: %s', ME.message);
end

end