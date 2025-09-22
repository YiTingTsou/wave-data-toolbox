function [monthly_data] = loadMonthlyData(url, location_info, additional_params, verbose)
%LOADMONTHLYDATA Load wind spectral data for a single month from OPeNDAP server
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   monthly_data = loadMonthlyData(url, location_info, additional_params, verbose)
%
% INPUTS:
%   url             - URL to the NetCDF file for wind spectral data
%   location_info   - Structure from findNearestGridPoint containing:
%                     .actual_lon - Actual longitude used
%                     .actual_lat - Actual latitude used
%                     .station_idx - Station index for spectral data extraction
%   additional_params - Cell array of additional parameter names to load
%   verbose         - Display progress messages
%
% OUTPUT:
%   monthly_data    - Structure containing:
%                     .time   - Time vector
%                     .wnd    - Wind speed (or 'u10m' if 'wnd' not found)
%                     .wnddir - Wind direction (or 'udir' if 'wnddir' not found)
%                     .(additional_params) - Any additional parameters
%
% NOTES:
%   If the primary variables 'wnd' or 'wnddir' are not found, the function will attempt to load
%   'u10m' for wind speed and 'udir' for wind direction as fallbacks. If neither is available,
%   the corresponding output field will be filled with NaN.

% Define fallback mappings
fallbacks = struct('wnd', 'u10m', 'wnddir', 'udir');

try
    % Read time data for current month
    time_month = ncread(url, 'time');
    num_time_month = length(time_month);
    % Read all variables for the selected station in one call
    start_pos = [location_info.station_idx, 1];
    count = [1, num_time_month];
catch ME
    error('Failed to initialise monthly data: %s', ME.message);
end

% List all required variable names
var_names = {'wnd', 'wnddir'};
if ~isempty(additional_params)
    var_names = [var_names, additional_params(:)'];
end

% Loop for variables with fallback
data_struct = struct();
for k = 1:length(var_names)
    var = var_names{k};
    alt = '';
    if isfield(fallbacks, var)
        alt = fallbacks.(var);
    end

    success = false;
    fallback_attempted = false;
    for idx = 1:2
        candidate = {var, alt};
        name = candidate{idx};
        if isempty(name), continue; end
        try
            vdata = squeeze(ncread(url, name, start_pos, count))';
            data_struct.(var) = vdata(:);
            success = true;
            break
        catch ME_param
            if idx == 1
                fallback_attempted = true;
                % Do not print warning yet, only if fallback also fails
            elseif idx == 2 && verbose
                % Only print warning if both fail
                fprintf('  Warning: Failed to load parameter %s for %s - %s\n', name, var, ME_param.message);
            end
        end
    end
    if ~success && fallback_attempted && verbose
        fprintf('  Warning: Failed to load parameter %s for %s - %s\n', var, var, 'Primary and fallback both failed');
    end
    if ~success
        data_struct.(var) = NaN(num_time_month, 1);
    end
end

% Store all arrays in output structure
monthly_data = data_struct;
monthly_data.time = time_month(:);
end