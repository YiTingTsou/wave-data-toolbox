function [wave_data, dataset_metadata] = assembleStreamedDataset(validFiles, wind, additional_params, target_lat, target_lon, location_info, folders, validMask, start_year_month, end_year_month, verbose, region, grid_resolution)
%ASSEMBLESTREAMEDDATASET Assemble wave or wind data using streamed access via MATFILE.
%   This function replicates the 'inmemory' logic from loadWaveData but uses
%   matfile to stream data from disk, reducing memory usage.
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


nV = numel(validFiles);
all_time = cell(nV,1);
if wind
    all_wnd = cell(nV,1);
    all_wnddir = cell(nV,1);
else
    all_t02 = cell(nV,1);
    all_hs  = cell(nV,1);
    all_dir = cell(nV,1);
end
all_additional = cell(numel(additional_params),1);
for a = 1:numel(additional_params)
    all_additional{a} = cell(nV,1);
end

for j = 1:nV
    mf = matfile(validFiles{j});
    try
        all_time{j} = mf.monthly_data.time;
    catch
        all_time{j} = [];
    end

    if wind
        try, all_wnd{j} = mf.monthly_data.wnd; catch, all_wnd{j} = []; end
        try, all_wnddir{j} = mf.monthly_data.wnddir; catch, all_wnddir{j} = []; end
    else
        try, all_t02{j} = mf.monthly_data.t02; catch, all_t02{j} = []; end
        try, all_hs{j}  = mf.monthly_data.hs;  catch, all_hs{j}  = []; end
        try, all_dir{j} = mf.monthly_data.dir; catch, all_dir{j} = []; end
    end

    for a = 1:numel(additional_params)
        pname = additional_params{a};
        try
            all_additional{a}{j} = mf.monthly_data.(pname);
        catch
            if ~isempty(all_time{j})
                all_additional{a}{j} = nan(numel(all_time{j}),1);
            else
                all_additional{a}{j} = [];
            end
        end
    end
end

if ~isempty(all_time) && any(~cellfun(@isempty, all_time))
    wave_data = table();
    wave_data.time = vertcat(all_time{:});

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

    distance_km = waveDataToolbox.utils.calculateDistance(target_lat, target_lon, location_info);
    folder_name = folders{find(validMask,1,'first')};

    % Save wind dataset and metadata
    dataset_metadata = waveDataToolbox.utils.saveCompleteDataset( ...
        folder_name, wave_data, location_info, start_year_month, end_year_month, ...
        additional_params, distance_km, verbose);
else
    warning('No data was successfully loaded for streaming assembly.');
    wave_data = table();
    dataset_metadata = struct();
end
end