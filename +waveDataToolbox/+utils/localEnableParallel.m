function [requested, pool] = localEnableParallel(requested, maxWorkers, verbose)
%LOCALENABLEPARALLEL  Decide whether to use parallel and try to start a pool.
%
% Part of Load Wave Data Toolbox
% Author: Yi-Ting Tsou
% Australian Maritime College | University of Tasmania
%
% INPUTS:
%   requested  - Boolean flag indicating if parallel processing is requested
%   maxWorkers - Maximum number of workers to use if parallel processing is enabled
%   verbose    - Boolean flag for log output
%
% OUTPUTS:
%   requested  - Boolean flag indicating if parallel processing is enabled
%   pool       - Parallel pool object if created, empty otherwise
%
% Returns requested=false when Parallel is unavailable or fails to start.

pool = [];

% Early exit if parallel not requested
if ~requested
    requested = false;   % ensure output is false
    return
end

% 1) Fast capability check (does not open a pool)
if exist('canUseParallelPool','file') == 2
    ok = canUseParallelPool();  % true when PCT installed/licensed and pool can be created
else
    ok = license('test','Distrib_Computing_Toolbox') && ~isempty(which('parpool'));
end

if ~ok
    if verbose, fprintf('[parallel] not available : using serial.\n'); end
    requested = false;
    pool = [];
    return
end

% 2) Try to start or resize pool
try
    % Use default cluster, respect its maximum workers
    c = parcluster();                 % default profile
    maxAllowed = c.NumWorkers;        % cluster limit
    n = min(maxWorkers, maxAllowed);

    p = gcp('nocreate');              % do not create a pool yet
    if ~isempty(p) && p.NumWorkers ~= n
        delete(p);
        p = [];
    end
    if isempty(p)
        pool = parpool(c, n);
    else
        pool = p;
    end
    requested = true;

    if verbose
        fprintf('[parallel] Using %d workers.\n', p.NumWorkers);
    end
catch ME
    warning(ME.identifier, '[parallel] disabled: %s\nUsing serial mode instead.', ME.message);
    requested = false;
    pool = [];
end
end
