function setup_aad_environment(basedir)
% SETUP_AAD_ENVIRONMENT Initialize environment for AAD analysis pipeline
% This function sets up the complete environment for running the AAD analysis
% pipeline, including path verification, AMToolbox initialization, and 
% data structure validation.
%
% Usage:
%   setup_aad_environment()           % Uses current directory
%   setup_aad_environment(basedir)    % Specify base directory
%
% This should be the FIRST script you run before any AAD analysis.

if nargin < 1
    basedir = pwd;
    % Try to find the AAD directory if we're in scripts subfolder
    if contains(basedir, 'scripts')
        basedir = fileparts(basedir);
    end
end

fprintf('=== AAD Environment Setup ===\n\n');

%% Step 1: Verify Directory Structure
fprintf('Step 1: Verifying directory structure...\n');

required_dirs = {'stimuli', 'scripts'};
missing_dirs = {};

for i = 1:length(required_dirs)
    dir_path = fullfile(basedir, required_dirs{i});
    if ~exist(dir_path, 'dir')
        missing_dirs{end+1} = required_dirs{i};
    else
        fprintf('  ✓ Found: %s\n', required_dirs{i});
    end
end

if ~isempty(missing_dirs)
    fprintf('  ✗ Missing directories: %s\n', strjoin(missing_dirs, ', '));
    error('Please ensure you have the correct directory structure.');
end

%% Step 2: Check for EEG Data Files
fprintf('\nStep 2: Checking for EEG data files...\n');

subject_files = dir(fullfile(basedir, 'S*.mat'));
num_subjects = length(subject_files);

if num_subjects == 0
    fprintf('  ✗ No subject files (S*.mat) found\n');
    fprintf('  Please download the KULeuven AAD dataset from:\n');
    fprintf('  https://zenodo.org/records/4004271\n');
    error('EEG data files not found.');
else
    fprintf('  ✓ Found %d subject files\n', num_subjects);
    fprintf('    First file: %s\n', subject_files(1).name);
    fprintf('    Last file: %s\n', subject_files(end).name);
end

%% Step 3: Check for Audio Stimuli
fprintf('\nStep 3: Checking for audio stimuli...\n');

stimuli_dir = fullfile(basedir, 'stimuli');
audio_files = dir(fullfile(stimuli_dir, '*.wav'));
num_audio = length(audio_files);

if num_audio == 0
    fprintf('  ✗ No audio files (*.wav) found in stimuli directory\n');
    error('Audio stimuli files not found.');
else
    fprintf('  ✓ Found %d audio files\n', num_audio);
    
    % Check for expected files
    expected_files = {'part1_track1_dry.wav', 'part1_track2_dry.wav'};
    for i = 1:length(expected_files)
        if exist(fullfile(stimuli_dir, expected_files{i}), 'file')
            fprintf('    ✓ %s\n', expected_files{i});
        else
            fprintf('    ✗ %s (missing)\n', expected_files{i});
        end
    end
end

%% Step 4: Initialize AMToolbox
fprintf('\nStep 4: Initializing AMToolbox...\n');

% Try to find AMToolbox
amtoolbox_paths = {
    fullfile(basedir, 'amtoolbox'),
    fullfile(fileparts(basedir), 'amtoolbox'),
    'amtoolbox'  % If already in path
};

amtoolbox_found = false;
for i = 1:length(amtoolbox_paths)
    if exist(amtoolbox_paths{i}, 'dir')
        fprintf('  Found AMToolbox at: %s\n', amtoolbox_paths{i});
        addpath(genpath(amtoolbox_paths{i}));
        amtoolbox_found = true;
        break;
    end
end

if amtoolbox_found
    try
        % Initialize AMToolbox
        amt_start;
        fprintf('  ✓ AMToolbox initialized successfully\n');
        
        % Test critical functions
        test_freq = erbspacebw(150, 4000, 1.5);
        fprintf('  ✓ ERB spacing function working (%d frequencies)\n', length(test_freq));
        
        % Test gammatone filters
        try
            g = gammatonefir(test_freq, 8000, [], 1.5*ones(size(test_freq)), 'real');
            fprintf('  ✓ Gammatone filters working (%d filters)\n', size(g, 2));
        catch
            fprintf('  ⚠ Gammatone filters not available - will use basic envelope\n');
        end
        
    catch ME
        fprintf('  ✗ AMToolbox initialization failed: %s\n', ME.message);
        fprintf('  ⚠ Continuing without AMToolbox (basic preprocessing only)\n');
    end
else
    fprintf('  ✗ AMToolbox not found in expected locations\n');
    fprintf('  Please download AMToolbox from: http://amtoolbox.org/\n');
    fprintf('  ⚠ Continuing without AMToolbox (basic preprocessing only)\n');
end

%% Step 5: Verify MATLAB Toolboxes
fprintf('\nStep 5: Checking MATLAB toolboxes...\n');

required_toolboxes = {
    'Signal Processing Toolbox', 'signal'
    'Statistics and Machine Learning Toolbox', 'stats'
};

for i = 1:size(required_toolboxes, 1)
    toolbox_name = required_toolboxes{i, 1};
    toolbox_dir = required_toolboxes{i, 2};
    
    if license('test', toolbox_dir)
        fprintf('  ✓ %s available\n', toolbox_name);
    else
        fprintf('  ✗ %s NOT available\n', toolbox_name);
    end
end

%% Step 6: Test Basic Functions
fprintf('\nStep 6: Testing basic functions...\n');

try
    % Test signal processing functions
    test_signal = randn(1000, 1);
    test_filtered = filtfilt([1, -0.9], 1, test_signal);
    fprintf('  ✓ filtfilt function working\n');
    
    % Test resampling
    test_resampled = resample(test_signal, 2, 3);
    fprintf('  ✓ resample function working\n');
    
    % Test correlation
    test_corr = corrcoef(test_signal(1:500), test_signal(501:1000));
    fprintf('  ✓ correlation functions working\n');
    
    % Test audio reading (if available)
    if num_audio > 0
        try
            [test_audio, fs] = audioread(fullfile(stimuli_dir, audio_files(1).name));
            fprintf('  ✓ audioread working (fs = %d Hz, %d samples)\n', fs, length(test_audio));
        catch
            fprintf('  ✗ audioread failed - check audio file format\n');
        end
    end
    
catch ME
    fprintf('  ✗ Basic function test failed: %s\n', ME.message);
end

%% Step 7: Create Output Directories
fprintf('\nStep 7: Creating output directories...\n');

output_dirs = {
    'preprocessed_data',
    'aad_comparison_results',
    fullfile('stimuli', 'envelopes'),
    'Plots'
};

for i = 1:length(output_dirs)
    output_path = fullfile(basedir, output_dirs{i});
    if ~exist(output_path, 'dir')
        mkdir(output_path);
        fprintf('  ✓ Created: %s\n', output_dirs{i});
    else
        fprintf('  ✓ Exists: %s\n', output_dirs{i});
    end
end

%% Step 8: Summary and Next Steps
fprintf('\n=== Setup Summary ===\n');
fprintf('Base directory: %s\n', basedir);
fprintf('Subject files: %d\n', num_subjects);
fprintf('Audio files: %d\n', num_audio);
if amtoolbox_found
    fprintf('AMToolbox: Available\n');
else
    fprintf('AMToolbox: Not found\n');
end

fprintf('\n=== Next Steps ===\n');
fprintf('Your environment is ready for AAD analysis!\n\n');
fprintf('Run the following scripts in order:\n');
fprintf('1. complete_aad_multichannel_example       %% Create multichannel stimuli\n');
fprintf('2. aad_algorithm_comparison_pipeline(''%s'', true)  %% Main analysis\n', basedir);
fprintf('3. test_aad_comparison                     %% View results\n\n');

fprintf('Or for quick start:\n');
fprintf('>> complete_aad_multichannel_example\n');
fprintf('>> aad_algorithm_comparison_pipeline(''%s'', true)\n\n', basedir);

% Save setup information
setup_info = struct();
setup_info.basedir = basedir;
setup_info.num_subjects = num_subjects;
setup_info.num_audio_files = num_audio;
setup_info.amtoolbox_available = amtoolbox_found;
setup_info.setup_date = datestr(now);

save(fullfile(basedir, 'aad_setup_info.mat'), 'setup_info');
fprintf('Setup information saved to: aad_setup_info.mat\n');

fprintf('\n=== Setup Complete! ===\n');

end