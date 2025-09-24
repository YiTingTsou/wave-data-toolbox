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
    num_time_month = numel(time_month);

    % Absolute indices for data extraction
    abs_lon_idx = location_info.lon_idx;
    abs_lat_idx = location_info.lat_idx;

    % List all required variable names
    var_names = {'t02','hs','dir'};
    if ~isempty(additional_params)
        if isstring(additional_params) || ischar(additional_params)
            additional_params = cellstr(additional_params);
        end
        var_names = [var_names, additional_params(:)'];
    end

    fallbacks = struct('t0m1', {{'tm0m1'}}, ...
        't01',  {{'t'}}, ...
        'uwnd',  {{'U10'}}, ...
        'vwnd',  {{'V10'}});

    info = ncinfo(url);
    available = {info.Variables.Name};

    data_struct = struct();
    for k = 1:numel(var_names)
        req = var_names{k};
        resolved = pick_available(req, fallbacks, available);

        if isempty(resolved)
            if verbose
                fprintf('  Warning: Variable "%s" not found and no fallback available. Filling NaNs.\n', req);
            end
            data_struct.(req) = NaN(num_time_month, 1);
            continue
        end

        try
            vdata = squeeze(ncread(url, resolved, [abs_lon_idx, abs_lat_idx, 1], [1, 1, num_time_month]));
            data_struct.(req) = vdata(:);
            if verbose && ~strcmp(resolved, req)
                fprintf('  Info: Using fallback "%s" for requested "%s".\n', resolved, req);
            end
        catch ME_param
            if verbose
                fprintf('  Warning: Failed to load "%s" (resolved from "%s") - %s\n', resolved, req, ME_param.message);
            end
            data_struct.(req) = NaN(num_time_month, 1);
        end
    end

    % Store all arrays in output structure
    monthly_data = data_struct;
    monthly_data.time = time_month(:);

catch ME
    error('Failed to load monthly data: %s', ME.message);
end
end

%% Helper function to return first available variable among [requested, fallbacks{requested}...]
function resolved = pick_available(requested, fallbacks, available)

candidates = {requested};
if isfield(fallbacks, requested)
    fb = fallbacks.(requested);
    if isstring(fb) || ischar(fb), fb = cellstr(fb); end
    candidates = [candidates, fb(:)'];
end

resolved = '';
for i = 1:numel(candidates)
    if any(strcmp(available, candidates{i}))
        resolved = candidates{i};
        return;
    end
end
end