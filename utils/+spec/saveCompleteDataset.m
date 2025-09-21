function [dataset_metadata] = saveCompleteDataset(wind_data, location_info, start_year_month, end_year_month, additional_params, distance_km, verbose)
% SAVECOMPLETEDATASET Save complete wind dataset to files
%
% Syntax:
%   [dataset_metadata] = saveCompleteDataset(wind_data, location_info, start_year_month, end_year_month, additional_params, distance_km, verbose)
%
% Description:
%   This function saves wind data table to both .mat and .csv files and generates metadata.
%
% Input Arguments:
%   wind_data - Table containing the complete wind dataset
%   location_info - Structure containing location information
%   start_year_month - Start date in YYYYMM format
%   end_year_month - End date in YYYYMM format
%   additional_params - Cell array of additional parameter names
%   distance_km - Distance from target location in km
%   verbose - Logical flag for verbose output
%
% Output Arguments:
%   dataset_metadata - Structure containing extraction and processing metadata

% Save complete dataset (always saved by default)
if ~isempty(location_info)
    if ~exist('output', 'dir')
        mkdir('output')
    end
    
    % Save wind_data
    base_complete_filename = sprintf('%s/wind_data_%d_%d_%.4fE_%.4fN', ...
        'output', start_year_month, end_year_month, location_info.actual_lon, location_info.actual_lat);
    mat_complete_filename = [base_complete_filename '.mat'];
    save(mat_complete_filename, 'wind_data');
    csv_complete_filename = [base_complete_filename '.csv'];
    writetable(wind_data, csv_complete_filename);

    % Save extraction and processing metadata
    dataset_metadata = location_info;
    dataset_metadata.start_year_month = start_year_month;
    dataset_metadata.end_year_month = end_year_month;
    dataset_metadata.location_offset = distance_km;
    dataset_metadata.additional_params = additional_params;

    save(sprintf('output/lon%.4fE_lat%.4fN_wind.mat', location_info.actual_lon, location_info.actual_lat), 'dataset_metadata');
    
    if verbose
        fprintf('\nComplete wind dataset saved\n------\n\n');
    end
end

end