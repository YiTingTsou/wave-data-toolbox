function [dataset_metadata] = saveCompleteDataset( ...
    foldername, data_tbl, location_info, start_year_month, end_year_month, ...
    additional_params, distance_km, verbose, varargin)
%SAVECOMPLETEDATASET Save complete wind or wave dataset to files and produce metadata.
%
% USAGE (wind):
%   m = saveCompleteDataset(folder, data_tbl, loc, sYM, eYM, extra, dist_km, verbose, ...
%                           'type','wind');
%
% USAGE (wave):
%   m = saveCompleteDataset(folder, data_tbl, loc, sYM, eYM, extra, dist_km, verbose, ...
%                           'type','wave', 'region','australia', 'grid_resolution', 10000);
%
% Optional name-value pairs:
%   'type'              : "wind" | "wave" | "auto" (default "auto")
%   'region'            : region string (wave only)
%   'grid_resolution'   : grid resolution in metres (wave only)
%   'metadataNameMode'  : "legacy" | "deterministic" (default "legacy")
%
% Backward compatibility:
% - Saves the table variable as 'wind_data' in wind mode, or 'wave_data' in wave mode,
%   matching the previous two implementations.
% - In "legacy" metadata mode, saves dataset_metadata as <afterOutputs(foldername)>.mat,
%   matching previous behaviour.

%% ---- Parse inputs ----
p = inputParser;
p.FunctionName = 'saveCompleteDataset';
addRequired(p, 'foldername', @(x)ischar(x) || (isstring(x)&&isscalar(x)));
addRequired(p, 'data_tbl', @(x) istable(x));
addRequired(p, 'location_info', @isstruct);
addRequired(p, 'start_year_month', @(x)isnumeric(x)&&isscalar(x));
addRequired(p, 'end_year_month',   @(x)isnumeric(x)&&isscalar(x));
addRequired(p, 'additional_params', @(x)iscell(x) || isempty(x));
addRequired(p, 'distance_km', @(x)isnumeric(x)&&isscalar(x));
addRequired(p, 'verbose', @(x)islogical(x)||ismember(x,[0 1]));

addParameter(p, 'type', "auto");
addParameter(p, 'region', "");
addParameter(p, 'grid_resolution', NaN);
addParameter(p, 'metadataNameMode', "legacy");

parse(p, foldername, data_tbl, location_info, start_year_month, end_year_month, ...
      additional_params, distance_km, verbose, varargin{:});

opts = p.Results;
foldername = string(opts.foldername);

%% ---- Determine dataset type ----
type = string(opts.type);
if type == "auto"
    vars = string(data_tbl.Properties.VariableNames);
    if any(ismember(["wnd","wnddir"], vars))
        type = "wind";
    elseif any(ismember(["hs","t02","dir"], vars))
        type = "wave";
    else
        % Default to wind if ambiguous
        type = "wind";
    end
end

%% ---- Build base filename ----
switch type
    case "wind"
        base = sprintf("wind_data_%d_%d_%.4fE_%.4fN", ...
            opts.start_year_month, opts.end_year_month, ...
            location_info.actual_lon, location_info.actual_lat);
    case "wave"
        region = string(opts.region);
        if strlength(region) == 0
            region = "unknown";
        end
        gr = opts.grid_resolution;
        if isnan(gr), gr = 0; end
        base = sprintf("wave_data_%d_%d_%s_%dm_%.4fE_%.4fN", ...
            opts.start_year_month, opts.end_year_month, region, round(gr), ...
            location_info.actual_lon, location_info.actual_lat);
    otherwise
        error('Unsupported type: %s', type);
end

mat_file = fullfile(foldername, base + ".mat");
csv_file = fullfile(foldername, base + ".csv");

%% ---- Save data table ----
switch type
    case "wind"
        wind_data = data_tbl; %#ok<NASGU>
        save(mat_file, 'wind_data');
    case "wave"
        wave_data = data_tbl; %#ok<NASGU>
        save(mat_file, 'wave_data');
end
writetable(data_tbl, csv_file);

%% ---- Build and save metadata ----
dataset_metadata = location_info;
dataset_metadata.start_year_month = start_year_month;
dataset_metadata.end_year_month   = end_year_month;

% Keep legacy field names
dataset_metadata.location_offset  = distance_km;
dataset_metadata.additional_params = additional_params;

if type == "wave"
    dataset_metadata.region = char(opts.region);
    dataset_metadata.grid_resolution = opts.grid_resolution;
end

% Metadata filename policy
if opts.metadataNameMode == "legacy"
    dataset_metadata.filename = afterOutputs(foldername); % legacy behaviour
    meta_file = fullfile(foldername, dataset_metadata.filename + ".mat");
else
    dataset_metadata.filename = base;
    meta_file = fullfile(foldername, "metadata_" + base + ".mat");
end
save(meta_file, 'dataset_metadata');

if verbose
    fprintf('\nComplete %s dataset saved\n', type);
end

end

%% ---- Helper: path segment after "outputs" with either separator ----
function tail = afterOutputs(folder_name)
    folder_name = string(folder_name);
    % Find 'outputs' followed by / or \ and extract after the last one
    ends = regexp(folder_name, 'outputs[\\/]', 'end');
    if isempty(ends)
        tail = "";
        return
    end
    tail = extractAfter(folder_name, ends(end));
end