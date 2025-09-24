function [all_time, all_wnd, all_wnddir, all_additional] = storeMonthlyData(monthly_data, all_time, all_wnd, all_wnddir, all_additional, additional_params)
%STOREMONTHLYDATA Store monthly wind spectral data in cell arrays
% 
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% SYNTAX:
%   [all_time, all_wnd, all_wnddir, all_additional] = storeMonthlyData(monthly_data, all_time, all_wnd, all_wnddir, all_additional, additional_params)
%
% INPUTS:
%   monthly_data     - Structure with monthly wind data fields
%   all_time         - Cell array to store time data
%   all_wnd          - Cell array to store wind speed data
%   all_wnddir       - Cell array to store wind direction data  
%   all_additional   - Cell array to store additional parameter data
%   additional_params - Cell array of additional parameter names
%
% OUTPUTS:
%   all_time         - Updated cell array with new time data
%   all_wnd          - Updated cell array with new wind speed data
%   all_wnddir       - Updated cell array with new wind direction data
%   all_additional   - Updated cell array with new additional parameter data

% Store core data in cell arrays
all_time{end+1} = monthly_data.time;
all_wnd{end+1} = monthly_data.wnd;
all_wnddir{end+1} = monthly_data.wnddir;

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