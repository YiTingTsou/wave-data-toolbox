function [all_time, all_t02, all_hs, all_dir, all_additional] = storeMonthlyData(monthly_data, all_time, all_t02, all_hs, all_dir, all_additional, additional_params)
%STOREMONTHLYDATA Store monthly wave data in cell arrays
% 
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   [all_time, all_t02, all_hs, all_dir, all_additional] = storeMonthlyData(monthly_data, all_time, all_t02, all_hs, all_dir, all_additional, additional_params)
%
% INPUTS:
%   monthly_data     - Structure with monthly wave data fields
%   all_time         - Cell array to store time data
%   all_t02          - Cell array to store wave period data
%   all_hs           - Cell array to store wave height data  
%   all_dir          - Cell array to store wave direction data
%   all_additional   - Cell array to store additional parameter data
%   additional_params - Cell array of additional parameter names
%
% OUTPUTS:
%   all_time         - Updated cell array with new time data
%   all_t02          - Updated cell array with new wave period data
%   all_hs           - Updated cell array with new wave height data
%   all_dir          - Updated cell array with new wave direction data
%   all_additional   - Updated cell array with new additional parameter data

% Store core data in cell arrays
all_time{end+1} = monthly_data.time;
all_t02{end+1} = monthly_data.t02;
all_hs{end+1} = monthly_data.hs;
all_dir{end+1} = monthly_data.dir;

% Store additional parameters
if ~isempty(additional_params)
    for j = 1:length(additional_params)
        if isfield(monthly_data, additional_params{j})
            all_additional{j}{end+1} = monthly_data.(additional_params{j});
        else
            all_additional{j}{end+1} = NaN(length(monthly_data.time), 1);
        end
    end
end

end