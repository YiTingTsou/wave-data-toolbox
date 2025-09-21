function saveMonthlyData(monthly_data, save_filename, additional_params, verbose)
%SAVEMONTHLYDATA Save monthly wind spectral data to file
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   saveMonthlyData(monthly_data, save_filename, additional_params, verbose)
%
% INPUTS:
%   monthly_data      - Structure containing monthly wind data
%   save_filename     - Full filename with path for saving
%   additional_params - Cell array of additional parameter names
%   verbose           - Display progress messages

try
    % Build table with standard columns
    table_data = {monthly_data.time, monthly_data.wnd, monthly_data.wnddir};
    var_names = {'time', 'wnd', 'wnddir'};
    
    % Add additional parameters to table
    if ~isempty(additional_params)
        for j = 1:length(additional_params)
            if isfield(monthly_data, additional_params{j})
                table_data{end+1} = monthly_data.(additional_params{j});
                var_names{end+1} = additional_params{j};
            end
        end
    end
    
    % Create table and save
    monthly_table = table(table_data{:}, 'VariableNames', var_names);
    
    % Ensure directory exists
    [save_dir, ~, ~] = fileparts(save_filename);
    if ~exist(save_dir, 'dir')
        mkdir(save_dir);
    end
    
    % Save the data
    save(save_filename, 'monthly_data');

catch ME
    if verbose
        fprintf('  Warning: Failed to save monthly data to %s - %s\n', save_filename, ME.message);
    end
end

end