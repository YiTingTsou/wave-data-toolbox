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
addParameter(p, 'type', "wind", @(x) any(strcmp(x, ["wind","wave"])));

addParameter(p, 'region', "", @(x) any(strcmp(x, ["aus","glob","pac",""])));
addParameter(p, 'grid_resolution', NaN);

parse(p, foldername, data_tbl, location_info, start_year_month, end_year_month, ...
    additional_params, distance_km, verbose, varargin{:});

opts = p.Results;
foldername = string(opts.foldername);

%% Wind and wave data table
% Build base filename
base = opts.type + "_data";
mat_file = fullfile(foldername, base + ".mat");
csv_file = fullfile(foldername, base + ".csv");

% Save data table
data_struct = struct(base, data_tbl);
save(mat_file, '-struct', 'data_struct');
writetable(data_tbl, csv_file);

%% Build and save metadata
dataset_metadata = location_info;
dataset_metadata.start_year_month = start_year_month;
dataset_metadata.end_year_month   = end_year_month;

% Keep legacy field names
dataset_metadata.location_offset  = distance_km;
dataset_metadata.additional_params = additional_params;

if opts.type == "wave"
    dataset_metadata.region = char(opts.region);
    dataset_metadata.grid_resolution = opts.grid_resolution;
end

% Save Metadata
dataset_metadata.filename = afterOutputs(foldername);
meta_file = fullfile(foldername, "metadata.mat");

save(meta_file, 'dataset_metadata');

if verbose
    fprintf('Complete %s dataset saved\n', opts.type);
end
end

%% Helper: path segment after "outputs" with either separator
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