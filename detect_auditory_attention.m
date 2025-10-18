% Auditory Attention Detection Algorithms
% This script implements several methods for detecting auditory attention from EEG

function attention_results = detect_auditory_attention(trials, method)
% DETECT_AUDITORY_ATTENTION Detect which audio stream the subject is attending to
% Usage: results = detect_auditory_attention(trials, 'correlation')
%        results = detect_auditory_attention(trials, 'trf')

if nargin < 2
    method = 'correlation'; % Default method
end

fprintf('=== Auditory Attention Detection ===\n');
fprintf('Method: %s\n', method);
fprintf('Analyzing %d trials...\n\n', length(trials));

attention_results = struct();
attention_results.method = method;
attention_results.num_trials = length(trials);
attention_results.predictions = [];
attention_results.confidence = [];
attention_results.details = {};

switch lower(method)
    case 'correlation'
        attention_results = detect_attention_correlation(trials, attention_results);
    case 'trf'
        attention_results = detect_attention_trf(trials, attention_results);
    case 'cca'
        attention_results = detect_attention_cca(trials, attention_results);
    case 'mutual_information'
        attention_results = detect_attention_mi(trials, attention_results);
    otherwise
        error('Unknown method: %s. Available: correlation, trf, cca, mutual_information', method);
end

% Summary
fprintf('\n=== Results Summary ===\n');
fprintf('Method: %s\n', method);
fprintf('Trials analyzed: %d\n', attention_results.num_trials);
fprintf('Left attention detected: %d trials\n', sum(attention_results.predictions == 1));
fprintf('Right attention detected: %d trials\n', sum(attention_results.predictions == 2));
fprintf('Mean confidence: %.3f\n', mean(attention_results.confidence));

% Save results
results_file = sprintf('attention_results_%s.mat', method);
save(results_file, 'attention_results');
fprintf('Results saved to: %s\n', results_file);

end

function results = detect_attention_correlation(trials, results)
% Cross-correlation method for attention detection

fprintf('1. Cross-correlation method:\n');
fprintf('   Computing correlations between EEG and audio envelopes...\n');

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    % Extract data
    eeg_data = trial.RawData.EegData; % samples × channels
    left_envelope = mean(trial.Envelope.AudioData(:, :, 1), 2); % broadband left
    right_envelope = mean(trial.Envelope.AudioData(:, :, 2), 2); % broadband right
    
    % Focus on central EEG channels (assuming standard 64-channel layout)
    central_channels = [1:64]; % Use all channels for now
    eeg_central = eeg_data(:, central_channels);
    
    % Compute correlations
    corr_left = zeros(1, length(central_channels));
    corr_right = zeros(1, length(central_channels));
    
    for ch = 1:length(central_channels)
        % Cross-correlation at zero lag
        corr_left(ch) = corr(eeg_central(:, ch), left_envelope);
        corr_right(ch) = corr(eeg_central(:, ch), right_envelope);
    end
    
    % Aggregate correlations (take maximum absolute correlation)
    max_corr_left = max(abs(corr_left));
    max_corr_right = max(abs(corr_right));
    
    % Decision: attend to the ear with higher correlation
    if max_corr_left > max_corr_right
        prediction = 1; % Left
        confidence = max_corr_left - max_corr_right;
    else
        prediction = 2; % Right
        confidence = max_corr_right - max_corr_left;
    end
    
    results.predictions(trial_idx) = prediction;
    results.confidence(trial_idx) = confidence;
    results.details{trial_idx} = struct('corr_left', corr_left, 'corr_right', corr_right);
    
    fprintf('   Trial %d: %s ear (confidence: %.3f)\n', ...
            trial_idx, iif(prediction == 1, 'Left', 'Right'), confidence);
end

end

function results = detect_attention_trf(trials, results)
% Temporal Response Function (TRF) method

fprintf('1. TRF method:\n');
fprintf('   Computing temporal response functions...\n');

% TRF parameters
trf_window = [-100, 400]; % ms
sample_rate = trials{1}.FileHeader.SampleRate;
trf_lags = round(trf_window(1)/1000*sample_rate):round(trf_window(2)/1000*sample_rate);

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    % Extract data
    eeg_data = trial.RawData.EegData;
    left_envelope = mean(trial.Envelope.AudioData(:, :, 1), 2);
    right_envelope = mean(trial.Envelope.AudioData(:, :, 2), 2);
    
    % Use central channels
    central_channels = 1:min(32, size(eeg_data, 2)); % First 32 channels
    eeg_central = eeg_data(:, central_channels);
    
    % Compute TRFs using ridge regression
    lambda = 1e-3; % Regularization parameter
    
    % Create design matrices with time lags
    [X_left, valid_indices] = create_design_matrix(left_envelope, trf_lags);
    [X_right, ~] = create_design_matrix(right_envelope, trf_lags);
    
    % Align EEG data
    Y = eeg_central(valid_indices, :);
    
    % Ridge regression for each envelope
    trf_left = ridge_regression(X_left, Y, lambda);
    trf_right = ridge_regression(X_right, Y, lambda);
    
    % Prediction accuracy
    pred_left = X_left * trf_left;
    pred_right = X_right * trf_right;
    
    % Compute correlation between predicted and actual EEG
    corr_left = mean(diag(corr(pred_left, Y)));
    corr_right = mean(diag(corr(pred_right, Y)));
    
    % Decision
    if corr_left > corr_right
        prediction = 1; % Left
        confidence = corr_left - corr_right;
    else
        prediction = 2; % Right
        confidence = corr_right - corr_left;
    end
    
    results.predictions(trial_idx) = prediction;
    results.confidence(trial_idx) = confidence;
    results.details{trial_idx} = struct('trf_left', trf_left, 'trf_right', trf_right, ...
                                       'corr_left', corr_left, 'corr_right', corr_right);
    
    fprintf('   Trial %d: %s ear (correlation: %.3f vs %.3f)\n', ...
            trial_idx, iif(prediction == 1, 'Left', 'Right'), ...
            max(corr_left, corr_right), min(corr_left, corr_right));
end

end

function results = detect_attention_cca(trials, results)
% Canonical Correlation Analysis method

fprintf('1. CCA method:\n');
fprintf('   Computing canonical correlations...\n');

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    % Extract data
    eeg_data = trial.RawData.EegData;
    left_envelope = trial.Envelope.AudioData(:, :, 1); % All subbands
    right_envelope = trial.Envelope.AudioData(:, :, 2);
    
    % Use subset of EEG channels
    eeg_subset = eeg_data(:, 1:min(16, size(eeg_data, 2)));
    
    % Canonical correlation analysis
    try
        [~, ~, corr_left] = canoncorr(eeg_subset, left_envelope);
        [~, ~, corr_right] = canoncorr(eeg_subset, right_envelope);
        
        max_corr_left = max(corr_left);
        max_corr_right = max(corr_right);
        
        % Decision
        if max_corr_left > max_corr_right
            prediction = 1; % Left
            confidence = max_corr_left - max_corr_right;
        else
            prediction = 2; % Right
            confidence = max_corr_right - max_corr_left;
        end
        
    catch ME
        fprintf('   Warning: CCA failed for trial %d: %s\n', trial_idx, ME.message);
        prediction = 1; % Default
        confidence = 0;
        max_corr_left = 0;
        max_corr_right = 0;
    end
    
    results.predictions(trial_idx) = prediction;
    results.confidence(trial_idx) = confidence;
    results.details{trial_idx} = struct('max_corr_left', max_corr_left, ...
                                       'max_corr_right', max_corr_right);
    
    fprintf('   Trial %d: %s ear (CCA: %.3f vs %.3f)\n', ...
            trial_idx, iif(prediction == 1, 'Left', 'Right'), ...
            max_corr_left, max_corr_right);
end

end

function results = detect_attention_mi(trials, results)
% Mutual Information method

fprintf('1. Mutual Information method:\n');
fprintf('   Computing mutual information between EEG and audio...\n');

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    % Extract data
    eeg_data = trial.RawData.EegData;
    left_envelope = mean(trial.Envelope.AudioData(:, :, 1), 2);
    right_envelope = mean(trial.Envelope.AudioData(:, :, 2), 2);
    
    % Use a few central EEG channels
    central_channels = [25:40]; % Central region
    central_channels = central_channels(central_channels <= size(eeg_data, 2));
    eeg_central = eeg_data(:, central_channels);
    
    % Compute mutual information
    mi_left = 0;
    mi_right = 0;
    
    for ch = 1:size(eeg_central, 2)
        mi_left = mi_left + mutual_information(eeg_central(:, ch), left_envelope);
        mi_right = mi_right + mutual_information(eeg_central(:, ch), right_envelope);
    end
    
    mi_left = mi_left / size(eeg_central, 2);
    mi_right = mi_right / size(eeg_central, 2);
    
    % Decision
    if mi_left > mi_right
        prediction = 1; % Left
        confidence = mi_left - mi_right;
    else
        prediction = 2; % Right
        confidence = mi_right - mi_left;
    end
    
    results.predictions(trial_idx) = prediction;
    results.confidence(trial_idx) = confidence;
    results.details{trial_idx} = struct('mi_left', mi_left, 'mi_right', mi_right);
    
    fprintf('   Trial %d: %s ear (MI: %.3f vs %.3f)\n', ...
            trial_idx, iif(prediction == 1, 'Left', 'Right'), ...
            max(mi_left, mi_right), min(mi_left, mi_right));
end

end

% Helper functions
function [X, valid_indices] = create_design_matrix(stimulus, lags)
% Create design matrix with time lags
n_samples = length(stimulus);
n_lags = length(lags);

X = zeros(n_samples, n_lags);
valid_indices = (max(lags) + 1):(n_samples + min(lags));

for i = 1:n_lags
    lag = lags(i);
    if lag >= 0
        X(valid_indices, i) = stimulus(valid_indices - lag);
    else
        X(valid_indices, i) = stimulus(valid_indices - lag);
    end
end

X = X(valid_indices, :);
end

function beta = ridge_regression(X, Y, lambda)
% Ridge regression
[n, p] = size(X);
beta = (X'*X + lambda*eye(p)) \ (X'*Y);
end

function mi = mutual_information(x, y)
% Simple mutual information estimate using histograms
n_bins = 20;

% Normalize data
x = (x - mean(x)) / std(x);
y = (y - mean(y)) / std(y);

% Create histograms
x_edges = linspace(min(x), max(x), n_bins+1);
y_edges = linspace(min(y), max(y), n_bins+1);

[~, x_idx] = histc(x, x_edges);
[~, y_idx] = histc(y, y_edges);

x_idx(x_idx == 0) = 1;
y_idx(y_idx == 0) = 1;
x_idx(x_idx > n_bins) = n_bins;
y_idx(y_idx > n_bins) = n_bins;

% Joint histogram
joint_hist = accumarray([x_idx, y_idx], 1, [n_bins, n_bins]);
joint_prob = joint_hist / sum(joint_hist(:));

% Marginal probabilities
px = sum(joint_prob, 2);
py = sum(joint_prob, 1);

% Mutual information
mi = 0;
for i = 1:n_bins
    for j = 1:n_bins
        if joint_prob(i,j) > 0
            mi = mi + joint_prob(i,j) * log2(joint_prob(i,j) / (px(i) * py(j)));
        end
    end
end

end

function result = iif(condition, true_val, false_val)
if condition
    result = true_val;
else
    result = false_val;
end
end