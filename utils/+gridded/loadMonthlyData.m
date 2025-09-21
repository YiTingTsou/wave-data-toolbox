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
%   location_info   - Structure from findNearestGridPoint containing:
%                     .actual_lon - Actual longitude used
%                     .actual_lat - Actual latitude used  
%                     .lon_idx    - Longitude index for subsetting
%                     .lat_idx    - Latitude index for subsetting
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

    % Absolute indices for data extraction
    abs_lon_idx = location_info.lon_idx;
    abs_lat_idx = location_info.lat_idx;

    % List all required variable names
    var_names = {'t02', 'hs', 'dir'};
    if ~isempty(additional_params)
        var_names = [var_names, additional_params(:)'];
    end

    data_struct = struct();
    for k = 1:length(var_names)
        try
            vdata = squeeze(ncread(url, var_names{k}, [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
            data_struct.(var_names{k}) = vdata(:); % Ensure column vector
        catch ME_param
            if verbose
                fprintf('  Warning: Failed to load parameter %s - %s\n', var_names{k}, ME_param.message);
            end
            data_struct.(var_names{k}) = NaN(num_time_month, 1);
        end
    end

    % Store all arrays in output structure
    monthly_data = data_struct;
    monthly_data.time = time_month(:);

catch ME
    error('Failed to load monthly data: %s', ME.message);
end

end