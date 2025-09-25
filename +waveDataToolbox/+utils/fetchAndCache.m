function fetchAndCache(useParallel, urls, outFiles, pkgs, location_info, additional_params, verbose, year_months)
%FETCHANDCACHE Fetch and cache monthly data files, optionally in parallel.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% INPUTS:
%   useParallel       - Boolean flag to use parallel processing
%   urls              - Cell array of URLs to fetch
%   outFiles          - Cell array of output file paths
%   pkgs              - Cell array of package names for loading data
%   location_info     - Structure with location information
%   additional_params - Cell array of additional parameters for loading data
%   verbose           - Boolean flag for verbose output
%   year_months       - Array of year-month values
%
% This function downloads and caches monthly data files, using parallel processing if requested.
% It dynamically loads and saves data using package-specific functions, and skips files that already exist.

nM = numel(urls);
if useParallel

    % Use parallel processing to fetch and cache data
    parfor k = 1:nM
        % Use parallel.pool.Constant to safely share data across workers
        locC = parallel.pool.Constant(location_info);
        addC = parallel.pool.Constant(additional_params);
        try
            % Print progress at the start of each year if verbose is enabled
            if verbose && rem(k,12) == 1
                current_ym = year_months(k);
                year = floor(current_ym / 100);
                fprintf('  Starting year %d: Loading %d (%d of %d)\n', year, current_ym, k, nM);
            end
            % Skip if output file already exists
            if exist(outFiles{k},'file'), continue; end

            % Dynamically construct loader function name and load data
            loader = ['waveDataToolbox.utils.' pkgs{k} '.loadMonthlyData'];
            md = feval(loader, urls{k}, locC.Value, addC.Value, false);
            % Store loaded data in a struct
            S  = struct('monthly_data', md);
            % Save struct using helper for parallel compatibility
            parsave_struct(outFiles{k}, S);

            % Dynamically construct saver function name and save data
            saver = ['waveDataToolbox.utils.' pkgs{k} '.saveMonthlyData'];
            feval(saver, md, outFiles{k}, addC.Value, false);

        catch ME
            % Warn if any error occurs during processing
            warning('Month %d failed: %s', k, ME.message);
        end
    end
else
    % Use regular for loop to fetch and cache data
    for k = 1:nM
        % Print progress at the start of each year if verbose is enabled
        if verbose && rem(k,12) == 1
            current_ym = year_months(k);
            year = floor(current_ym / 100);
            fprintf('  Starting year %d: Loading %d (%d of %d)\n', year, current_ym, k, nM);
        end
        try
            % Skip if output file already exists
            if exist(outFiles{k},'file'), continue; end
            % Dynamically construct loader function name and load data
            loader = ['waveDataToolbox.utils.' pkgs{k} '.loadMonthlyData'];
            md = feval(loader, urls{k}, location_info, additional_params, verbose);
            % Store loaded data in a struct
            S  = struct('monthly_data', md);
            % Save struct to file
            save(outFiles{k}, '-struct', 'S');

            % Dynamically construct saver function name and save data
            saver = ['waveDataToolbox.utils.' pkgs{k} '.saveMonthlyData'];
            feval(saver, md, outFiles{k}, additional_params, verbose);

        catch ME
            % Warn if any error occurs during processing
            warning('Month %d failed: %s', k, ME.message);
        end
    end
end
end
%% Helper function
function parsave_struct(filename, S)
%PARSAVE_STRUCT Safe save for PARFOR bodies.
% This helper function saves a struct to file, using '-fromstruct' if available (MATLAB R2024a+),
% otherwise falls back to '-struct' for compatibility with older MATLAB versions.
try
    save(filename, '-fromstruct', S);
catch
    % Fallback for older MATLAB releases
    save(filename, '-struct', 'S');
end
end