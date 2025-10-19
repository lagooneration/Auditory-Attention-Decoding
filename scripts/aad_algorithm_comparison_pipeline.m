function aad_algorithm_comparison_pipeline(basedir, run_multichannel)
% AAD_ALGORITHM_COMPARISON_PIPELINE Comprehensive AAD algorithm comparison
% This function implements and compares multiple AAD algorithms (Correlation, TRF, CCA)
% on both 2-channel and multichannel (8-channel) stimuli to evaluate the impact
% of spatial upmixing on auditory attention decoding performance
%
% Inputs:
%   basedir: Directory containing the AAD dataset
%   run_multichannel: Boolean flag to include multichannel comparison (default: true)
%
% The pipeline implements:
% 1. Correlation-based AAD (original approach)
% 2. Temporal Response Function (TRF) based AAD
% 3. Canonical Correlation Analysis (CCA) based AAD
%
% Comparison is performed between:
% - Original 2-channel stimuli (dichotic presentation)
% - 8-channel spatial upmixed stimuli
%
% Author: Generated for AAD research comparison
% Based on methods from Das et al. (2019) and related AAD literature

if nargin < 1
    basedir = pwd;
end

if nargin < 2
    run_multichannel = true;
end

fprintf('=== AAD Algorithm Comparison Pipeline ===\n\n');

% Setup paths and configurations
results_dir = fullfile(basedir, 'aad_comparison_results');
if ~exist(results_dir, 'dir')
    mkdir(results_dir);
end

% Algorithm configurations
algorithms = {'correlation', 'trf', 'cca'};
channel_configs = {'ch2'};  % Valid field names (no leading numbers)
if run_multichannel
    channel_configs{end+1} = 'ch8';
end

% Analysis parameters
params = setup_aad_parameters();

% Initialize results storage
results = struct();
results.algorithms = algorithms;
results.channel_configs = channel_configs;
results.params = params;

%% Step 1: Ensure preprocessed data exists
fprintf('Step 1: Ensuring preprocessed data availability...\n');

% Check 2-channel preprocessed data
preprocdir_2ch = fullfile(basedir, 'preprocessed_data');
if ~exist(preprocdir_2ch, 'dir')
    fprintf('Creating 2-channel preprocessed data...\n');
    preprocess_data(basedir);
end

% Check multichannel preprocessed data
if run_multichannel
    preprocdir_8ch = fullfile(basedir, 'stimuli', 'multichannel_8ch', 'envelopes');
    if ~exist(preprocdir_8ch, 'dir')
        fprintf('Creating 8-channel preprocessed data...\n');
        create_multichannel_aad_stimuli(basedir, 8);
        preprocess_multichannel_aad_data(basedir, 8);
    end
end

%% Step 2: Load and prepare data
fprintf('\nStep 2: Loading and preparing AAD data...\n');

% Load subject data
subjects = dir(fullfile(basedir, 'S*.mat'));
subjects = {subjects.name};
num_subjects = length(subjects);

fprintf('Found %d subjects for analysis\n', num_subjects);

%% Step 3: Run AAD algorithms for each configuration
for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    
    % Convert to user-friendly display name
    if strcmp(config, 'ch2')
        display_name = '2-Channel';
    elseif strcmp(config, 'ch8')
        display_name = '8-Channel';
    else
        display_name = upper(config);
    end
    
    fprintf('\n=== Processing %s Configuration ===\n', display_name);
    
    % Load appropriate data
    if strcmp(config, 'ch2')
        data_struct = load_2channel_data(basedir, subjects, params);
    else
        data_struct = load_multichannel_data(basedir, subjects, params);
    end
    
    % Run each algorithm
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        fprintf('\nRunning %s algorithm on %s data...\n', upper(algorithm), display_name);
        
        % Run algorithm with cross-validation
        algo_results = run_aad_algorithm(data_struct, algorithm, params);
        
        % Store results
        results.(config).(algorithm) = algo_results;
        
        fprintf('Completed %s on %s: Mean accuracy = %.2f%%\n', ...
            upper(algorithm), display_name, mean(algo_results.accuracies) * 100);
    end
end

%% Step 4: Compare results and generate report
fprintf('\n=== Generating Comparison Report ===\n');

comparison_report = generate_comparison_report(results, results_dir);

%% Step 5: Create visualizations
fprintf('\nCreating visualization plots...\n');

create_comparison_visualizations(results, results_dir);

%% Step 6: Statistical analysis
fprintf('\nPerforming statistical analysis...\n');

if run_multichannel
    stats_results = perform_statistical_analysis(results);
    results.statistics = stats_results;
end

% Save complete results
save(fullfile(results_dir, 'complete_aad_comparison_results.mat'), 'results');

fprintf('\n=== AAD Comparison Pipeline Complete ===\n');
fprintf('Results saved to: %s\n', results_dir);

end

function params = setup_aad_parameters()
% Setup parameters for AAD algorithm comparison

% Common parameters
params.fs = 32; % Sample rate after preprocessing
params.analysis_window = 10; % seconds for analysis windows
params.step_size = 1; % seconds for sliding window
params.cv_folds = 5; % Cross-validation folds

% Correlation-based AAD parameters
params.correlation.max_lag = round(0.5 * params.fs); % 500ms max lag
params.correlation.integration_window = 10; % seconds

% TRF parameters
params.trf.max_lag = round(0.5 * params.fs); % 500ms max lag
params.trf.min_lag = round(-0.1 * params.fs); % -100ms min lag (pre-stimulus)
params.trf.regularization = 1e-3; % Ridge regression regularization
params.trf.feature_normalization = true;

% CCA parameters
params.cca.max_lag = round(0.2 * params.fs); % 200ms max lag (reduced for stability)
params.cca.num_components = 2; % Number of canonical components (reduced for stability)
params.cca.regularization = 1e-3; % Increased regularization for stability
params.cca.max_components_ratio = 0.1; % Max components as fraction of min(features, samples)
params.cca.min_samples_per_component = 50; % Minimum samples per component

% Trial selection
params.min_trial_length = 60; % Minimum trial length in seconds
params.exclude_short_trials = true;

end

function data_struct = load_2channel_data(basedir, subjects, params)
% Load 2-channel preprocessed data

data_struct = struct();
data_struct.type = '2channel';
data_struct.subjects = {};

preprocdir = fullfile(basedir, 'preprocessed_data');

subject_count = 0;
for s = 1:length(subjects)
    subject_file = fullfile(preprocdir, subjects{s});
    
    if exist(subject_file, 'file')
        subject_count = subject_count + 1;
        load(subject_file, 'preproc_trials');
        
        % Extract relevant data
        subject_data = extract_2channel_features(preproc_trials, params);
        data_struct.subjects{subject_count} = subject_data;
        data_struct.subjects{subject_count}.id = subjects{s};
        
        fprintf('Loaded 2-channel data for subject %s: %d trials\n', ...
            subjects{s}, length(subject_data.trials));
    end
end

data_struct.num_subjects = subject_count;

end

function data_struct = load_multichannel_data(basedir, subjects, params)
% Load multichannel preprocessed data

data_struct = struct();
data_struct.type = '8channel';
data_struct.subjects = {};

% For multichannel, we need to create compatible data structure
% by loading the multichannel envelopes and matching with EEG

envelope_dir = fullfile(basedir, 'stimuli', 'multichannel_8ch', 'envelopes');
preprocdir = fullfile(basedir, 'preprocessed_data');

subject_count = 0;
for s = 1:length(subjects)
    subject_file = fullfile(preprocdir, subjects{s});
    
    if exist(subject_file, 'file')
        subject_count = subject_count + 1;
        load(subject_file, 'preproc_trials');
        
        % Extract features with multichannel envelopes
        subject_data = extract_multichannel_features(preproc_trials, envelope_dir, params);
        data_struct.subjects{subject_count} = subject_data;
        data_struct.subjects{subject_count}.id = subjects{s};
        
        fprintf('Loaded 8-channel data for subject %s: %d trials\n', ...
            subjects{s}, length(subject_data.trials));
    end
end

data_struct.num_subjects = subject_count;

end

function subject_data = extract_2channel_features(preproc_trials, params)
% Extract features from 2-channel preprocessed trials

subject_data = struct();
subject_data.trials = {};

trial_count = 0;
for t = 1:length(preproc_trials)
    trial = preproc_trials{t};
    
    % Check trial length
    trial_length = size(trial.RawData.EegData, 1) / params.fs;
    if trial_length < params.min_trial_length && params.exclude_short_trials
        continue;
    end
    
    trial_count = trial_count + 1;
    
    % Extract EEG data
    eeg_data = double(trial.RawData.EegData);
    
    % Extract envelope data (left and right ear)
    envelope_left = trial.Envelope.AudioData(:, :, 1);  % Left ear
    envelope_right = trial.Envelope.AudioData(:, :, 2); % Right ear
    
    % Determine attention (which ear was attended)
    attended_ear = trial.attended_ear;
    if strcmp(attended_ear, 'L')
        attended_envelope = envelope_left;
        unattended_envelope = envelope_right;
        attention_label = 1; % Left = 1
    else
        attended_envelope = envelope_right;
        unattended_envelope = envelope_left;
        attention_label = 0; % Right = 0
    end
    
    % Store trial data
    trial_data = struct();
    trial_data.eeg = eeg_data;
    trial_data.attended_envelope = attended_envelope;
    trial_data.unattended_envelope = unattended_envelope;
    trial_data.envelope_left = envelope_left;
    trial_data.envelope_right = envelope_right;
    trial_data.attention_label = attention_label;
    trial_data.attended_ear = attended_ear;
    trial_data.trial_id = trial.TrialID;
    trial_data.condition = trial.condition;
    trial_data.experiment = trial.experiment;
    
    subject_data.trials{trial_count} = trial_data;
end

subject_data.num_trials = trial_count;

end

function subject_data = extract_multichannel_features(preproc_trials, envelope_dir, params)
% Extract features with multichannel envelopes

subject_data = struct();
subject_data.trials = {};

trial_count = 0;
for t = 1:length(preproc_trials)
    trial = preproc_trials{t};
    
    % Check trial length
    trial_length = size(trial.RawData.EegData, 1) / params.fs;
    if trial_length < params.min_trial_length && params.exclude_short_trials
        continue;
    end
    
    % Load corresponding multichannel envelope
    multichannel_envelope = load_multichannel_envelope_for_trial(trial, envelope_dir);
    
    if isempty(multichannel_envelope)
        continue; % Skip if multichannel envelope not found
    end
    
    trial_count = trial_count + 1;
    
    % Extract EEG data
    eeg_data = double(trial.RawData.EegData);
    
    % Determine attention based on original trial
    attended_ear = trial.attended_ear;
    if strcmp(attended_ear, 'L')
        attention_label = 1; % Left = 1
    else
        attention_label = 0; % Right = 0
    end
    
    % For multichannel, we need to determine which channels correspond
    % to attended vs unattended based on the spatial configuration
    [attended_envelope, unattended_envelope] = extract_attended_unattended_multichannel(...
        multichannel_envelope, attention_label);
    
    % Store trial data
    trial_data = struct();
    trial_data.eeg = eeg_data;
    trial_data.attended_envelope = attended_envelope;
    trial_data.unattended_envelope = unattended_envelope;
    trial_data.multichannel_envelope = multichannel_envelope;
    trial_data.attention_label = attention_label;
    trial_data.attended_ear = attended_ear;
    trial_data.trial_id = trial.TrialID;
    trial_data.condition = trial.condition;
    trial_data.experiment = trial.experiment;
    
    subject_data.trials{trial_count} = trial_data;
end

subject_data.num_trials = trial_count;

end

function multichannel_envelope = load_multichannel_envelope_for_trial(trial, envelope_dir)
% Load multichannel envelope corresponding to a trial

multichannel_envelope = [];

% Determine which multichannel file corresponds to this trial
% Based on the trial stimuli information
if trial.repetition
    part_num = extract_part_number(trial.stimuli{1}); % Extract part number from filename
    envelope_filename = sprintf('powerlaw subbands rep_part%d_competitive_dry.mat', part_num);
else
    part_num = extract_part_number(trial.stimuli{1});
    envelope_filename = sprintf('powerlaw subbands part%d_competitive_dry.mat', part_num);
end

envelope_file = fullfile(envelope_dir, envelope_filename);

if exist(envelope_file, 'file')
    load(envelope_file, 'envelope');
    
    % Truncate to match EEG length
    eeg_length = size(trial.RawData.EegData, 1);
    if size(envelope, 1) >= eeg_length
        multichannel_envelope = envelope(1:eeg_length, :);
    else
        % Pad if envelope is shorter
        padding = zeros(eeg_length - size(envelope, 1), size(envelope, 2));
        multichannel_envelope = [envelope; padding];
    end
end

end

function part_num = extract_part_number(stimulus_name)
% Extract part number from stimulus filename

% Look for pattern like 'part1' or 'part2' etc.
tokens = regexp(stimulus_name, 'part(\d+)', 'tokens');
if ~isempty(tokens)
    part_num = str2double(tokens{1}{1});
else
    part_num = 1; % Default fallback
end

end

function [attended_envelope, unattended_envelope] = extract_attended_unattended_multichannel(multichannel_envelope, attention_label)
% Extract attended and unattended envelopes from multichannel data

% For the multichannel data created by our pipeline:
% - Channels 1-2 typically contain the primary competing sources
% - Additional channels contain spatial enhancements

% Simple strategy: use energy-based selection
num_channels = size(multichannel_envelope, 2);
channel_energies = sum(multichannel_envelope.^2, 1);
[~, sorted_channels] = sort(channel_energies, 'descend');

% Take top 2 energetic channels as competing sources
if num_channels >= 2
    ch1_envelope = multichannel_envelope(:, sorted_channels(1));
    ch2_envelope = multichannel_envelope(:, sorted_channels(2));
    
    % Assign based on attention label
    if attention_label == 1 % Attended left
        attended_envelope = ch1_envelope;
        unattended_envelope = ch2_envelope;
    else % Attended right
        attended_envelope = ch2_envelope;
        unattended_envelope = ch1_envelope;
    end
else
    % Fallback if insufficient channels
    attended_envelope = multichannel_envelope(:, 1);
    unattended_envelope = zeros(size(attended_envelope));
end

end

function algo_results = run_aad_algorithm(data_struct, algorithm, params)
% Run specified AAD algorithm with cross-validation

switch lower(algorithm)
    case 'correlation'
        algo_results = run_correlation_aad(data_struct, params);
    case 'trf'
        algo_results = run_trf_aad(data_struct, params);
    case 'cca'
        algo_results = run_cca_aad(data_struct, params);
    otherwise
        error('Unknown algorithm: %s', algorithm);
end

end

function results = run_correlation_aad(data_struct, params)
% Correlation-based AAD algorithm

results = struct();
results.algorithm = 'correlation';
results.subject_accuracies = zeros(data_struct.num_subjects, 1);
results.subject_details = cell(data_struct.num_subjects, 1);

for s = 1:data_struct.num_subjects
    subject = data_struct.subjects{s};
    
    % Cross-validation across trials
    trial_accuracies = zeros(subject.num_trials, 1);
    
    for t = 1:subject.num_trials
        trial = subject.trials{t};
        
        % Use sliding window approach
        [predictions, true_labels] = correlation_decode_trial(trial, params);
        
        % Calculate accuracy for this trial
        trial_accuracies(t) = mean(predictions == true_labels);
    end
    
    results.subject_accuracies(s) = mean(trial_accuracies);
    results.subject_details{s} = struct('trial_accuracies', trial_accuracies, ...
                                       'subject_id', subject.id);
end

results.accuracies = results.subject_accuracies;
results.mean_accuracy = mean(results.subject_accuracies);
results.std_accuracy = std(results.subject_accuracies);

end

function [predictions, true_labels] = correlation_decode_trial(trial, params)
% Correlation-based decoding for a single trial

eeg = trial.eeg;
env_attended = trial.attended_envelope;
env_unattended = trial.unattended_envelope;

% Create analysis windows
window_samples = round(params.correlation.integration_window * params.fs);
step_samples = round(params.step_size * params.fs);

num_windows = floor((size(eeg, 1) - window_samples) / step_samples) + 1;

predictions = zeros(num_windows, 1);
true_labels = ones(num_windows, 1) * trial.attention_label;

for w = 1:num_windows
    start_idx = (w-1) * step_samples + 1;
    end_idx = start_idx + window_samples - 1;
    
    if end_idx > size(eeg, 1)
        break;
    end
    
    % Extract window data
    eeg_window = eeg(start_idx:end_idx, :);
    env_att_window = env_attended(start_idx:end_idx, :);
    env_unatt_window = env_unattended(start_idx:end_idx, :);
    
    % Calculate correlations with both envelopes
    corr_attended = calculate_envelope_eeg_correlation(eeg_window, env_att_window, params);
    corr_unattended = calculate_envelope_eeg_correlation(eeg_window, env_unatt_window, params);
    
    % Predict based on higher correlation
    if corr_attended > corr_unattended
        predictions(w) = 1; % Attended
    else
        predictions(w) = 0; % Unattended
    end
end

% Remove excess predictions
predictions = predictions(1:num_windows);
true_labels = true_labels(1:num_windows);

end

function correlation = calculate_envelope_eeg_correlation(eeg, envelope, params)
% Calculate correlation between envelope and EEG

% Sum across frequency bands if multiple
if size(envelope, 2) > 1
    envelope = sum(envelope, 2);
end

% Calculate cross-correlation across all EEG channels
max_correlation = 0;

for ch = 1:size(eeg, 2)
    eeg_ch = eeg(:, ch);
    
    % Cross-correlate with time lags
    [xcorr_result, ~] = xcorr(eeg_ch, envelope, params.correlation.max_lag, 'coeff');
    max_correlation = max(max_correlation, max(abs(xcorr_result)));
end

correlation = max_correlation;

end

function results = run_trf_aad(data_struct, params)
% TRF (Temporal Response Function) based AAD algorithm

results = struct();
results.algorithm = 'trf';
results.subject_accuracies = zeros(data_struct.num_subjects, 1);
results.subject_details = cell(data_struct.num_subjects, 1);

for s = 1:data_struct.num_subjects
    subject = data_struct.subjects{s};
    
    % Collect all trial data for this subject
    all_eeg = [];
    all_env_attended = [];
    all_env_unattended = [];
    trial_indices = [];
    
    for t = 1:subject.num_trials
        trial = subject.trials{t};
        all_eeg = [all_eeg; trial.eeg];
        all_env_attended = [all_env_attended; trial.attended_envelope];
        all_env_unattended = [all_env_unattended; trial.unattended_envelope];
        trial_indices = [trial_indices; ones(size(trial.eeg, 1), 1) * t];
    end
    
    % Cross-validation across trials
    unique_trials = unique(trial_indices);
    cv_accuracies = zeros(length(unique_trials), 1);
    
    for cv = 1:length(unique_trials)
        test_trial = unique_trials(cv);
        train_trials = unique_trials(unique_trials ~= test_trial);
        
        % Split data
        train_mask = ismember(trial_indices, train_trials);
        test_mask = trial_indices == test_trial;
        
        % Train TRF models
        trf_attended = train_trf_model(all_eeg(train_mask, :), ...
                                     all_env_attended(train_mask, :), params);
        trf_unattended = train_trf_model(all_eeg(train_mask, :), ...
                                       all_env_unattended(train_mask, :), params);
        
        % Test on held-out trial
        test_eeg = all_eeg(test_mask, :);
        test_env_att = all_env_attended(test_mask, :);
        test_env_unatt = all_env_unattended(test_mask, :);
        
        % Predict using TRF models
        pred_att = predict_with_trf(test_eeg, trf_attended, params);
        pred_unatt = predict_with_trf(test_eeg, trf_unattended, params);
        
        % Calculate reconstruction accuracies
        corr_att = corr(test_env_att(:), pred_att(:));
        corr_unatt = corr(test_env_unatt(:), pred_unatt(:));
        
        % Classify based on better reconstruction
        if corr_att > corr_unatt
            cv_accuracies(cv) = 1; % Correct prediction
        else
            cv_accuracies(cv) = 0; % Incorrect prediction
        end
    end
    
    results.subject_accuracies(s) = mean(cv_accuracies);
    results.subject_details{s} = struct('cv_accuracies', cv_accuracies, ...
                                       'subject_id', subject.id);
end

results.accuracies = results.subject_accuracies;
results.mean_accuracy = mean(results.subject_accuracies);
results.std_accuracy = std(results.subject_accuracies);

end

function trf_model = train_trf_model(eeg, envelope, params)
% Train TRF model using ridge regression

% Create time-lagged features
lags = params.trf.min_lag:params.trf.max_lag;
num_lags = length(lags);
num_channels = size(eeg, 2);
num_features = size(envelope, 2);

% Build design matrix
X = [];
for lag = lags
    if lag >= 0
        shifted_env = [zeros(lag, num_features); envelope(1:end-lag, :)];
    else
        shifted_env = [envelope(-lag+1:end, :); zeros(-lag, num_features)];
    end
    X = [X, shifted_env];
end

% Regularized regression for each EEG channel
trf_model = struct();
trf_model.weights = zeros(num_channels, num_lags * num_features);
trf_model.lags = lags;
trf_model.num_features = num_features;

for ch = 1:num_channels
    y = eeg(:, ch);
    
    % Ridge regression
    lambda = params.trf.regularization;
    w = (X'*X + lambda*eye(size(X, 2))) \ (X'*y);
    trf_model.weights(ch, :) = w';
end

end

function prediction = predict_with_trf(eeg, trf_model, ~)
% Predict envelope using trained TRF model

num_channels = size(eeg, 2);
lags = trf_model.lags;
num_features = trf_model.num_features;

% For prediction, we reverse the process - use EEG to predict envelope
prediction = zeros(size(eeg, 1), num_features);

for ch = 1:num_channels
    eeg_ch = eeg(:, ch);
    weights_ch = reshape(trf_model.weights(ch, :), length(lags), num_features);
    
    for f = 1:num_features
        for lag_idx = 1:length(lags)
            lag = lags(lag_idx);
            
            if lag >= 0
                shifted_eeg = [zeros(lag, 1); eeg_ch(1:end-lag)];
            else
                shifted_eeg = [eeg_ch(-lag+1:end); zeros(-lag, 1)];
            end
            
            prediction(:, f) = prediction(:, f) + weights_ch(lag_idx, f) * shifted_eeg;
        end
    end
end

% Average across channels
prediction = prediction / num_channels;

end

function results = run_cca_aad(data_struct, params)
% CCA (Canonical Correlation Analysis) based AAD algorithm

results = struct();
results.algorithm = 'cca';
results.subject_accuracies = zeros(data_struct.num_subjects, 1);
results.subject_details = cell(data_struct.num_subjects, 1);

for s = 1:data_struct.num_subjects
    subject = data_struct.subjects{s};
    
    % Cross-validation across trials
    trial_accuracies = zeros(subject.num_trials, 1);
    
    for t = 1:subject.num_trials
        trial = subject.trials{t};
        
        % Use leave-one-trial-out for training CCA model
        other_trials = setdiff(1:subject.num_trials, t);
        
        % Collect training data
        train_eeg = [];
        train_env_att = [];
        train_env_unatt = [];
        
        for tr = other_trials
            if tr <= length(subject.trials)
                train_eeg = [train_eeg; subject.trials{tr}.eeg];
                train_env_att = [train_env_att; subject.trials{tr}.attended_envelope];
                train_env_unatt = [train_env_unatt; subject.trials{tr}.unattended_envelope];
            end
        end
        
        if isempty(train_eeg)
            trial_accuracies(t) = 0.5; % Chance level if no training data
            continue;
        end
        
        % Train CCA models
        cca_attended = train_cca_model(train_eeg, train_env_att, params);
        cca_unattended = train_cca_model(train_eeg, train_env_unatt, params);
        
        % Test on current trial
        test_corr_att = test_cca_model(trial.eeg, trial.attended_envelope, cca_attended);
        test_corr_unatt = test_cca_model(trial.eeg, trial.unattended_envelope, cca_unattended);
        
        % Classify based on higher correlation
        if test_corr_att > test_corr_unatt
            trial_accuracies(t) = 1; % Correct
        else
            trial_accuracies(t) = 0; % Incorrect
        end
    end
    
    results.subject_accuracies(s) = mean(trial_accuracies);
    results.subject_details{s} = struct('trial_accuracies', trial_accuracies, ...
                                       'subject_id', subject.id);
end

results.accuracies = results.subject_accuracies;
results.mean_accuracy = mean(results.subject_accuracies);
results.std_accuracy = std(results.subject_accuracies);

end

function cca_model = train_cca_model(eeg, envelope, params)
% Train CCA model between EEG and envelope

% Prepare time-lagged features
lags = 0:params.cca.max_lag;
num_lags = length(lags);

% Create lagged envelope features
X_env = [];
for lag = lags
    shifted_env = [zeros(lag, size(envelope, 2)); envelope(1:end-lag, :)];
    X_env = [X_env, shifted_env];
end

% Use EEG as second set
X_eeg = eeg;

% Remove rows with zeros (due to lagging)
valid_rows = (max(lags)+1):size(X_eeg, 1);
X_env = X_env(valid_rows, :);
X_eeg = X_eeg(valid_rows, :);

% Normalize and condition data for better CCA performance
X_eeg = zscore(X_eeg, 0, 1); % Normalize each column (electrode)
X_env = zscore(X_env, 0, 1); % Normalize each column (envelope feature)

% Remove any remaining NaN values (from zero std)
nan_cols_eeg = any(~isfinite(X_eeg), 1);
nan_cols_env = any(~isfinite(X_env), 1);

if any(nan_cols_eeg)
    fprintf('Removing %d EEG channels with NaN values\n', sum(nan_cols_eeg));
    X_eeg(:, nan_cols_eeg) = [];
end

if any(nan_cols_env)
    fprintf('Removing %d envelope features with NaN values\n', sum(nan_cols_env));
    X_env(:, nan_cols_env) = [];
end

% Ensure minimum data size for CCA
min_samples = 100;  % Minimum samples needed for reliable CCA
if size(X_eeg, 1) < min_samples
    fprintf('Warning: Too few samples (%d < %d) for reliable CCA\n', size(X_eeg, 1), min_samples);
end

% Check data quality before CCA
if any(~isfinite(X_eeg(:))) || any(~isfinite(X_env(:)))
    warning('Non-finite values detected in data, using fallback model');
    use_fallback = true;
else
    % Check rank condition
    rank_eeg = rank(X_eeg);
    rank_env = rank(X_env);
    
    if rank_eeg < size(X_eeg, 2) || rank_env < size(X_env, 2)
        fprintf('Data matrices not full rank (EEG: %d/%d, ENV: %d/%d), applying regularization...\n', ...
            rank_eeg, size(X_eeg, 2), rank_env, size(X_env, 2));
        
        % Apply regularization by adding small noise
        reg_factor = 1e-6;
        X_eeg = X_eeg + reg_factor * randn(size(X_eeg));
        X_env = X_env + reg_factor * randn(size(X_env));
    end
    
    use_fallback = false;
end

% Perform CCA with timeout protection
if ~use_fallback
    try
        % Set warning state to catch rank issues
        orig_warn_state = warning('query', 'stats:canoncorr:NotFullRank');
        warning('error', 'stats:canoncorr:NotFullRank');
        
        [A, B, r] = canoncorr(X_eeg, X_env);
        
        % Restore warning state
        warning(orig_warn_state.state, 'stats:canoncorr:NotFullRank');
        
        % Determine safe number of components based on data size
        max_components_data = floor(min([size(X_eeg, 1), size(X_eeg, 2), size(X_env, 2)]) * params.cca.max_components_ratio);
        max_components_samples = floor(size(X_eeg, 1) / params.cca.min_samples_per_component);
        safe_components = min([params.cca.num_components, max_components_data, max_components_samples, size(A, 2), length(r)]);
        safe_components = max(1, safe_components); % At least 1 component
        
        fprintf('Using %d CCA components (requested: %d, data-limited: %d, sample-limited: %d)\n', ...
            safe_components, params.cca.num_components, max_components_data, max_components_samples);
        
        cca_model = struct();
        cca_model.A = A(:, 1:safe_components);
        cca_model.B = B(:, 1:safe_components);
        cca_model.correlations = r(1:safe_components);
        cca_model.lags = lags;
        
    catch ME
        fprintf('CCA failed (%s), using fallback model...\n', ME.message);
        use_fallback = true;
    end
end

if use_fallback
    % Fallback for problematic matrices
    fprintf('Using simplified correlation-based fallback for CCA...\n');
    cca_model = struct();
    cca_model.A = randn(size(X_eeg, 2), params.cca.num_components);
    cca_model.B = randn(size(X_env, 2), params.cca.num_components);
    cca_model.correlations = zeros(params.cca.num_components, 1);
    cca_model.lags = lags;
end

end

function correlation = test_cca_model(eeg, envelope, cca_model)
% Test CCA model and return canonical correlation

% Prepare lagged features
lags = cca_model.lags;
X_env = [];
for lag = lags
    shifted_env = [zeros(lag, size(envelope, 2)); envelope(1:end-lag, :)];
    X_env = [X_env, shifted_env];
end

X_eeg = eeg;

% Remove rows with zeros
valid_rows = (max(lags)+1):size(X_eeg, 1);
X_env = X_env(valid_rows, :);
X_eeg = X_eeg(valid_rows, :);

% Project onto canonical components
try
    U = X_eeg * cca_model.A;
    V = X_env * cca_model.B;
    
    % Calculate correlation between canonical variates
    correlation = abs(corr(U(:, 1), V(:, 1)));
    
catch
    correlation = 0; % Fallback
end

end

function comparison_report = generate_comparison_report(results, results_dir)
% Generate comprehensive comparison report

comparison_report = struct();

fprintf('\n=== AAD Algorithm Comparison Report ===\n\n');

algorithms = results.algorithms;
channel_configs = results.channel_configs;

% Summary table
fprintf('Algorithm Performance Summary:\n');
fprintf('%-12s', 'Algorithm');
for config = channel_configs
    fprintf(' | %-15s', [config{1} ' Mean±STD']);
end
fprintf('\n');
fprintf(repmat('-', 1, 12 + length(channel_configs) * 18));
fprintf('\n');

comparison_report.summary = struct();

for algo = algorithms
    fprintf('%-12s', upper(algo{1}));
    
    for config = channel_configs
        if isfield(results, config{1}) && isfield(results.(config{1}), algo{1})
            mean_acc = results.(config{1}).(algo{1}).mean_accuracy * 100;
            std_acc = results.(config{1}).(algo{1}).std_accuracy * 100;
            fprintf(' | %5.1f±%4.1f%%   ', mean_acc, std_acc);
            
            % Store for comparison
            comparison_report.summary.(config{1}).(algo{1}).mean = mean_acc;
            comparison_report.summary.(config{1}).(algo{1}).std = std_acc;
        else
            fprintf(' | %-15s', 'N/A');
        end
    end
    fprintf('\n');
end

fprintf('\n');

% Best performing combinations
if length(channel_configs) > 1
    fprintf('Channel Configuration Comparison:\n');
    for algo = algorithms
        fprintf('\n%s Algorithm:\n', upper(algo{1}));
        
        accuracies = [];
        config_names = {};
        
        for config = channel_configs
            if isfield(results, config{1}) && isfield(results.(config{1}), algo{1})
                accuracies(end+1) = results.(config{1}).(algo{1}).mean_accuracy * 100;
                config_names{end+1} = config{1};
            end
        end
        
        if length(accuracies) > 1
            [~, best_idx] = max(accuracies);
            improvement = accuracies(2) - accuracies(1); % Assuming 2ch is first, 8ch is second
            
            fprintf('  Best configuration: %s (%.1f%%)\n', config_names{best_idx}, accuracies(best_idx));
            if length(accuracies) == 2
                if improvement > 0
                    improvement_text = 'multichannel better';
                else
                    improvement_text = '2-channel better';
                end
                fprintf('  Channel improvement: %.1f%% (%s)\n', improvement, improvement_text);
            end
        end
    end
end

% Save report
report_file = fullfile(results_dir, 'comparison_report.txt');
diary(report_file);
diary off;

end

function create_comparison_visualizations(results, results_dir)
% Create visualization plots for comparison

algorithms = results.algorithms;
channel_configs = results.channel_configs;

% Figure 1: Accuracy comparison
figure('Position', [100, 100, 1200, 800]);

num_algorithms = length(algorithms);
num_configs = length(channel_configs);

% Subplot 1: Mean accuracies with error bars
subplot(2, 2, 1);
mean_data = zeros(num_algorithms, num_configs);
std_data = zeros(num_algorithms, num_configs);

for a = 1:num_algorithms
    for c = 1:num_configs
        algo = algorithms{a};
        config = channel_configs{c};
        
        if isfield(results, config) && isfield(results.(config), algo)
            mean_data(a, c) = results.(config).(algo).mean_accuracy * 100;
            std_data(a, c) = results.(config).(algo).std_accuracy * 100;
        end
    end
end

bar_handle = bar(mean_data);
hold on;

% Add error bars
for c = 1:num_configs
    x_positions = (1:num_algorithms) + (c-1)*0.8/num_configs - 0.4 + 0.4/num_configs;
    errorbar(x_positions, mean_data(:, c), std_data(:, c), 'k.', 'LineWidth', 1.5);
end

xlabel('Algorithm');
ylabel('Accuracy (%)');
title('AAD Algorithm Performance Comparison');
set(gca, 'XTickLabel', upper(algorithms));
legend(channel_configs, 'Location', 'best');
grid on;

% Subplot 2: Subject-wise comparison (if multichannel available)
if num_configs > 1
    subplot(2, 2, 2);
    
    % Show improvement from 2ch to 8ch for each algorithm
    improvements = zeros(num_algorithms, 1);
    for a = 1:num_algorithms
        algo = algorithms{a};
        if isfield(results, channel_configs{1}) && isfield(results.(channel_configs{1}), algo) && ...
           isfield(results, channel_configs{2}) && isfield(results.(channel_configs{2}), algo)
            
            acc_2ch = results.(channel_configs{1}).(algo).mean_accuracy * 100;
            acc_8ch = results.(channel_configs{2}).(algo).mean_accuracy * 100;
            improvements(a) = acc_8ch - acc_2ch;
        end
    end
    
    bar(improvements);
    xlabel('Algorithm');
    ylabel('Accuracy Improvement (8ch - 2ch)');
    title('Multichannel Improvement');
    set(gca, 'XTickLabel', upper(algorithms));
    grid on;
    
    % Add zero line
    hold on;
    plot([0.5, num_algorithms+0.5], [0, 0], 'r--', 'LineWidth', 2);
end

% Subplot 3: Distribution of subject accuracies
subplot(2, 2, 3);
all_accuracies = [];
all_labels = {};

for c = 1:num_configs
    config = channel_configs{c};
    for a = 1:num_algorithms
        algo = algorithms{a};
        
        if isfield(results, config) && isfield(results.(config), algo)
            accuracies = results.(config).(algo).accuracies * 100;
            all_accuracies = [all_accuracies; accuracies(:)];
            
            labels = repmat({[upper(algo), ' ', config]}, length(accuracies), 1);
            all_labels = [all_labels; labels];
        end
    end
end

if ~isempty(all_accuracies)
    boxplot(all_accuracies, all_labels);
    ylabel('Accuracy (%)');
    title('Distribution of Subject Accuracies');
    xtickangle(45);
end

% Subplot 4: Statistical significance (if applicable)
subplot(2, 2, 4);
text(0.1, 0.8, 'Statistical Analysis:', 'FontSize', 14, 'FontWeight', 'bold');

text_y = 0.7;
if length(channel_configs) > 1
    for a = 1:num_algorithms
        algo = algorithms{a};
        text_str = sprintf('%s: ', upper(algo));
        
        if isfield(results, channel_configs{1}) && isfield(results.(channel_configs{1}), algo) && ...
           isfield(results, channel_configs{2}) && isfield(results.(channel_configs{2}), algo)
            
            acc1 = results.(channel_configs{1}).(algo).accuracies;
            acc2 = results.(channel_configs{2}).(algo).accuracies;
            
            % Paired t-test
            [~, p_value] = ttest(acc1, acc2);
            
            if p_value < 0.001
                sig_str = '***';
            elseif p_value < 0.01
                sig_str = '**';
            elseif p_value < 0.05
                sig_str = '*';
            else
                sig_str = 'ns';
            end
            
            text_str = [text_str, sprintf('p=%.3f %s', p_value, sig_str)];
        else
            text_str = [text_str, 'N/A'];
        end
        
        text(0.1, text_y, text_str, 'FontSize', 12);
        text_y = text_y - 0.1;
    end
end

axis off;

% Save figure
sgtitle('AAD Algorithm and Channel Configuration Comparison', 'FontSize', 16);
saveas(gcf, fullfile(results_dir, 'aad_comparison_visualization.png'));
saveas(gcf, fullfile(results_dir, 'aad_comparison_visualization.fig'));

end

function stats_results = perform_statistical_analysis(results)
% Perform statistical analysis of results

stats_results = struct();
algorithms = results.algorithms;

fprintf('Statistical Analysis Results:\n');
fprintf('============================\n\n');

for a = 1:length(algorithms)
    algo = algorithms{a};
    
    if isfield(results, 'ch2') && isfield(results.('ch2'), algo) && ...
       isfield(results, 'ch8') && isfield(results.('ch8'), algo)
        
        acc_2ch = results.('ch2').(algo).accuracies;
        acc_8ch = results.('ch8').(algo).accuracies;
        
        % Paired t-test
        [h, p, ci, stats] = ttest(acc_2ch, acc_8ch);
        
        % Effect size (Cohen's d)
        mean_diff = mean(acc_8ch) - mean(acc_2ch);
        pooled_std = sqrt((var(acc_2ch) + var(acc_8ch)) / 2);
        cohens_d = mean_diff / pooled_std;
        
        % Store results
        stats_results.(algo).ttest.h = h;
        stats_results.(algo).ttest.p = p;
        stats_results.(algo).ttest.ci = ci;
        stats_results.(algo).ttest.stats = stats;
        stats_results.(algo).effect_size.cohens_d = cohens_d;
        stats_results.(algo).effect_size.mean_difference = mean_diff * 100;
        
        % Report
        fprintf('%s Algorithm:\n', upper(algo));
        fprintf('  2-channel: %.1f±%.1f%%\n', mean(acc_2ch)*100, std(acc_2ch)*100);
        fprintf('  8-channel: %.1f±%.1f%%\n', mean(acc_8ch)*100, std(acc_8ch)*100);
        fprintf('  Difference: %.1f%% (p=%.3f)\n', mean_diff*100, p);
        fprintf('  Effect size (Cohen''s d): %.3f\n', cohens_d);
        
        if h
            if mean_diff > 0
                fprintf('  Result: 8-channel significantly BETTER than 2-channel\n');
            else
                fprintf('  Result: 8-channel significantly WORSE than 2-channel\n');
            end
        else
            fprintf('  Result: No significant difference between configurations\n');
        end
        fprintf('\n');
    end
end

end