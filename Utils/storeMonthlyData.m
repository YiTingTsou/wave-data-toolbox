% STOREMONTHLYDATA - Script to store monthly wave data in cell arrays
% 
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% Requires these variables to exist in calling workspace:
%   monthly_data, all_time, all_t02, all_hs, all_dir, all_additional, additional_params

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