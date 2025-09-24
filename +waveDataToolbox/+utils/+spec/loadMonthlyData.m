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


% Predefined fallbacks
fallbacks = struct('wnd',   {{'u10m'}}, ...
    'wnddir',{{'udir'}}, ...
    'dpt',   {{'depth'}}, ...
    'cur',   {{'curr'}}, ...
    'curdir',   {{'currdir'}});

try
    % Read time data
    time_month = ncread(url, 'time');
    num_time_month = numel(time_month);

    % Assume dimensions [station, time]
    start_pos = [location_info.station_idx, 1];
    count     = [1, num_time_month];

    % Build variable list
    var_names = {'wnd','wnddir'};
    if ~isempty(additional_params)
        if isstring(additional_params) || ischar(additional_params)
            additional_params = cellstr(additional_params);
        end
        var_names = [var_names, additional_params(:)'];
    end

    data_struct = struct();

    for k = 1:numel(var_names)
        req = var_names{k};

        % Build candidate list: primary + fallbacks
        candidates = {req};
        if isfield(fallbacks, req)
            fb = fallbacks.(req);
            if isstring(fb) || ischar(fb), fb = cellstr(fb); end
            candidates = [candidates, fb(:)'];
        end

        loaded = false;
        last_err = '';

        for c = 1:numel(candidates)
            name = candidates{c};
            try
                vdata = squeeze(ncread(url, name, start_pos, count));
                data_struct.(req) = vdata(:); % store under requested name
                loaded = true;
                if verbose && c > 1
                    fprintf('  Info: Using fallback "%s" for "%s".\n', name, req);
                end
                break
            catch ME_param
                last_err = ME_param.message;
            end
        end

        if ~loaded
            if verbose
                fprintf('  Warning: Failed to load "%s" (and fallbacks). Last error: %s\n', req, last_err);
            end
            data_struct.(req) = NaN(num_time_month, 1);
        end
    end

    monthly_data = data_struct;
    monthly_data.time = time_month(:);

catch ME
    error('Failed to load monthly data: %s', ME.message);
end
end
