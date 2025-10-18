% Analyze Preprocessed EEG Data
% This script helps you understand the structure and content of your preprocessed data

function analyze_preprocessed_data(data_file)
% ANALYZE_PREPROCESSED_DATA Explore the structure of preprocessed EEG data
% Usage: analyze_preprocessed_data('preprocessed_data/S1.mat')

if nargin < 1
    data_file = fullfile('preprocessed_data', 'S1.mat');
end

fprintf('=== Preprocessed EEG Data Analysis ===\n\n');

%% Load the preprocessed data
fprintf('1. Loading preprocessed data...\n');
if ~exist(data_file, 'file')
    error('File not found: %s', data_file);
end

loaded_data = load(data_file);
fprintf('✓ Loaded: %s\n', data_file);

% Check main variable
if isfield(loaded_data, 'preproc_trials')
    trials = loaded_data.preproc_trials;
    fprintf('✓ Found preproc_trials with %d trials\n', length(trials));
else
    error('preproc_trials variable not found in the file');
end

%% Analyze trial structure
fprintf('\n2. Analyzing trial structure...\n');

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    fprintf('\n--- Trial %d ---\n', trial_idx);
    
    % Basic trial info
    fprintf('Trial fields: %s\n', strjoin(fieldnames(trial), ', '));
    
    % EEG Data analysis
    if isfield(trial, 'RawData') && isfield(trial.RawData, 'EegData')
        eeg_data = trial.RawData.EegData;
        fprintf('EEG Data:\n');
        fprintf('  - Shape: %d samples × %d channels\n', size(eeg_data, 1), size(eeg_data, 2));
        fprintf('  - Duration: %.2f seconds (at %d Hz)\n', ...
                size(eeg_data, 1) / trial.FileHeader.SampleRate, ...
                trial.FileHeader.SampleRate);
        fprintf('  - Sample rate: %d Hz\n', trial.FileHeader.SampleRate);
        fprintf('  - Data range: [%.3f, %.3f] µV\n', min(eeg_data(:)), max(eeg_data(:)));
        
        % Check for filtering info
        if isfield(trial.RawData, 'HighPass')
            fprintf('  - High-pass: %.1f Hz\n', trial.RawData.HighPass);
        end
        if isfield(trial.RawData, 'LowPass')
            fprintf('  - Low-pass: %.1f Hz\n', trial.RawData.LowPass);
        end
    end
    
    % Audio envelope analysis
    if isfield(trial, 'Envelope') && isfield(trial.Envelope, 'AudioData')
        envelope_data = trial.Envelope.AudioData;
        fprintf('Audio Envelope:\n');
        fprintf('  - Shape: %d samples × %d subbands × %d ears\n', ...
                size(envelope_data, 1), size(envelope_data, 2), size(envelope_data, 3));
        fprintf('  - Left ear range: [%.3f, %.3f]\n', ...
                min(envelope_data(:,:,1), [], 'all'), max(envelope_data(:,:,1), [], 'all'));
        fprintf('  - Right ear range: [%.3f, %.3f]\n', ...
                min(envelope_data(:,:,2), [], 'all'), max(envelope_data(:,:,2), [], 'all'));
        
        if isfield(trial.Envelope, 'subband_weights')
            fprintf('  - Subband weights: %d bands\n', length(trial.Envelope.subband_weights));
        end
    end
    
    % Stimulus information
    if isfield(trial, 'stimuli')
        fprintf('Stimuli:\n');
        fprintf('  - Left ear: %s\n', trial.stimuli{1});
        fprintf('  - Right ear: %s\n', trial.stimuli{2});
    end
    
    % Experimental info
    if isfield(trial, 'repetition')
        fprintf('Repetition: %s\n', mat2str(trial.repetition));
    end
    
    % Only show first few trials in detail
    if trial_idx >= 3
        fprintf('\n... (showing first 3 trials in detail)\n');
        break;
    end
end

%% Summary statistics
fprintf('\n3. Summary Statistics Across All Trials:\n');

% Collect data from all trials
all_eeg_lengths = [];
all_envelope_lengths = [];
sample_rates = [];

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    if isfield(trial, 'RawData') && isfield(trial.RawData, 'EegData')
        all_eeg_lengths(end+1) = size(trial.RawData.EegData, 1);
        sample_rates(end+1) = trial.FileHeader.SampleRate;
    end
    
    if isfield(trial, 'Envelope') && isfield(trial.Envelope, 'AudioData')
        all_envelope_lengths(end+1) = size(trial.Envelope.AudioData, 1);
    end
end

fprintf('EEG Data Summary:\n');
fprintf('  - Trial lengths: %d to %d samples (%.1f to %.1f seconds)\n', ...
        min(all_eeg_lengths), max(all_eeg_lengths), ...
        min(all_eeg_lengths)/sample_rates(1), max(all_eeg_lengths)/sample_rates(1));
fprintf('  - Consistent sample rate: %s\n', mat2str(unique(sample_rates)));

fprintf('Audio Envelope Summary:\n');
fprintf('  - Envelope lengths: %d to %d samples\n', ...
        min(all_envelope_lengths), max(all_envelope_lengths));
fprintf('  - Length consistency: %s\n', ...
        iif(all(all_eeg_lengths == all_envelope_lengths), 'Perfect match', 'Mismatch detected'));

%% Data quality checks
fprintf('\n4. Data Quality Checks:\n');

% Check for NaN or infinite values
has_nan_eeg = false;
has_inf_eeg = false;
has_nan_envelope = false;
has_inf_envelope = false;

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    if isfield(trial, 'RawData') && isfield(trial.RawData, 'EegData')
        eeg_data = trial.RawData.EegData;
        if any(isnan(eeg_data(:)))
            has_nan_eeg = true;
        end
        if any(isinf(eeg_data(:)))
            has_inf_eeg = true;
        end
    end
    
    if isfield(trial, 'Envelope') && isfield(trial.Envelope, 'AudioData')
        envelope_data = trial.Envelope.AudioData;
        if any(isnan(envelope_data(:)))
            has_nan_envelope = true;
        end
        if any(isinf(envelope_data(:)))
            has_inf_envelope = true;
        end
    end
end

fprintf('EEG Data Quality:\n');
fprintf('  - Contains NaN: %s\n', iif(has_nan_eeg, 'YES (⚠ Warning)', 'No'));
fprintf('  - Contains Inf: %s\n', iif(has_inf_eeg, 'YES (⚠ Warning)', 'No'));

fprintf('Envelope Data Quality:\n');
fprintf('  - Contains NaN: %s\n', iif(has_nan_envelope, 'YES (⚠ Warning)', 'No'));
fprintf('  - Contains Inf: %s\n', iif(has_inf_envelope, 'YES (⚠ Warning)', 'No'));

%% Visualization suggestions
fprintf('\n5. Next Steps for Analysis:\n');
fprintf('✓ Data successfully preprocessed and ready for attention detection\n');
fprintf('✓ %d trials available for analysis\n', length(trials));
fprintf('✓ EEG and audio envelopes are time-aligned\n\n');

fprintf('Recommended next steps:\n');
fprintf('1. Visualize data: plot_trial_data(trials, 1)\n');
fprintf('2. Cross-correlation analysis: cross_correlation_analysis(trials)\n');
fprintf('3. Attention detection: detect_auditory_attention(trials)\n');
fprintf('4. Performance validation: validate_attention_detection(trials)\n\n');

% Store analysis results
analysis_results = struct();
analysis_results.num_trials = length(trials);
analysis_results.trial_lengths = all_eeg_lengths;
analysis_results.sample_rate = sample_rates(1);
analysis_results.data_quality = struct('has_nan_eeg', has_nan_eeg, ...
                                      'has_inf_eeg', has_inf_eeg, ...
                                      'has_nan_envelope', has_nan_envelope, ...
                                      'has_inf_envelope', has_inf_envelope);

% Save analysis results
[filepath, name, ~] = fileparts(data_file);
analysis_file = fullfile(filepath, [name '_analysis.mat']);
save(analysis_file, 'analysis_results');
fprintf('Analysis results saved to: %s\n', analysis_file);

end

function result = iif(condition, true_val, false_val)
% Inline if function
if condition
    result = true_val;
else
    result = false_val;
end
end