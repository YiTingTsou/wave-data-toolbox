function [wave_data, dataset_metadata] = assembleAndSaveDataset(validFiles, wind, additional_params, target_lat, target_lon, location_info, folders, validMask, start_year_month, end_year_month, verbose, region, grid_resolution)
%ASSEMBLEANDSAVEDATASET  Assemble wave or wind data from monthly files and save complete dataset.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% INPUTS:
%   validFiles        - Cell array of valid monthly file paths
%   wind              - Boolean flag indicating if loading wind data (true) or wave data (false)
%   additional_params - Cell array of additional parameter names to include
%   target_lat       - Latitude of the target location
%   target_lon       - Longitude of the target location
%   location_info    - Structure with location information
%   folders          - Cell array of folder paths corresponding to validFiles
%   validMask        - Logical array indicating which files are valid
%   start_year_month - Start year-month (e.g., 202001 for Jan 2020)
%   end_year_month   - End year-month (e.g., 202012 for Dec 2020)
%   verbose          - Boolean flag for verbose output
%   region           - Region name for wave data (e.g., 'global', 'australia')
%   grid_resolution  - Grid resolution for wave data
%
% OUTPUTS:
%   wave_data        - Table containing the assembled wave or wind data
%   dataset_metadata - Structure containing metadata about the assembled dataset

%% Initialize outputs
nV = numel(validFiles); % Number of valid monthly files found
all_time = cell(nV,1);  % Cell array to collect time vectors from each file
if wind
    all_wnd    = cell(nV,1);    % Collect wind speed data
    all_wnddir = cell(nV,1);    % Collect wind direction data
else
    all_t02 = cell(nV,1);       % Collect mean wave period (t02)
    all_hs  = cell(nV,1);       % Collect significant wave height (hs)
    all_dir = cell(nV,1);       % Collect wave direction (dir)
end
% Preallocate for any additional parameters requested by user
all_additional = cell(numel(additional_params),1);
for a = 1:numel(additional_params)
    all_additional{a} = cell(nV,1); % Each additional param gets a cell array per file
end

% Loop through each valid monthly file and extract relevant data fields
for j = 1:nV
    L  = load(validFiles{j}, 'monthly_data'); % Load monthly_data struct from file
    md = L.monthly_data;
    all_time{j} = md.time; % Store time vector
    if wind
        % For wind mode, extract wind speed and direction if present
        if isfield(md,'wnd'),    all_wnd{j}    = md.wnd;    else, all_wnd{j}    = []; end
        if isfield(md,'wnddir'), all_wnddir{j} = md.wnddir; else, all_wnddir{j} = []; end
    else
        % For wave mode, extract t02, hs, dir if present
        if isfield(md,'t02'), all_t02{j} = md.t02; else, all_t02{j} = []; end
        if isfield(md,'hs'),  all_hs{j}  = md.hs;  else, all_hs{j}  = []; end
        if isfield(md,'dir'), all_dir{j} = md.dir; else, all_dir{j} = []; end
    end
    % Extract any additional parameters requested, or fill with NaNs if missing
    for a = 1:numel(additional_params)
        pname = additional_params{a};
        if isfield(md, pname)
            all_additional{a}{j} = md.(pname); % Store actual data
        else
            all_additional{a}{j} = nan(numel(md.time),1); % Fill with NaNs if missing
        end
    end
end

%% Build table and save complete dataset
if ~isempty(all_time) && any(~cellfun(@isempty, all_time))
    wave_data = table(); % Initialize output table
    wave_data.time = vertcat(all_time{:}); % Concatenate all time vectors into one column

    if wind
        wave_data.wnd    = vertcat(all_wnd{:});
        wave_data.wnddir = vertcat(all_wnddir{:});
    else
        wave_data.t02 = vertcat(all_t02{:});
        wave_data.hs  = vertcat(all_hs{:});
        wave_data.dir = vertcat(all_dir{:});
    end
    for a = 1:numel(additional_params)
        pname = additional_params{a};
        wave_data.(pname) = vertcat(all_additional{a}{:});
    end

    % Calculate distance (km) between requested and actual extraction location
    distance_km = waveDataToolbox.utils.calculateDistance(target_lat, target_lon, location_info);
    % Use the folder of the first valid file for saving outputs
    folder_name = folders{find(validMask,1,'first')};

    % Save wind dataset and metadata
    dataset_metadata = waveDataToolbox.utils.saveCompleteDataset( ...
        folder_name, wave_data, location_info, start_year_month, end_year_month, ...
        additional_params, distance_km, verbose);
else
    % If no data was loaded, warn and return empty outputs
    warning('No data was successfully loaded for assembly.');
    wave_data = table();
    dataset_metadata = struct();
end
end