% Simple AMToolbox Setup (bypasses amt_start issues)
% Generated automatically by fix_amtoolbox_config.m

fprintf('Setting up AMToolbox for EEG processing...\n');

% Add AMToolbox to path
current_dir = pwd;
local_amtoolbox = fullfile(current_dir, 'amtoolbox');
global_amtoolbox = 'C:/MATLAB/amtoolbox';

if exist(local_amtoolbox, 'dir')
    addpath(genpath(local_amtoolbox));
    fprintf('✓ Local AMToolbox added to path\n');
elseif exist(global_amtoolbox, 'dir')
    addpath(genpath(global_amtoolbox));
    fprintf('✓ Global AMToolbox added to path\n');
else
    error('AMToolbox not found');
end

% Skip amt_start due to configuration issues
fprintf('AMToolbox ready (amt_start skipped due to config issues)\n');

% Test key functions
try
    erbspacebw(100, 1000, 1.0);
    fprintf('✓ AMToolbox functions verified\n');
catch ME
    warning('AMToolbox functions may not work: %s', ME.message);
end
