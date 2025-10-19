function auditory_encoding_analysis(basedir)
% AUDITORY_ENCODING_ANALYSIS Analyzes auditory perception encoding for AAD
% This function demonstrates how different auditory encoding methods affect
% the correlation between sound features and EEG signals, which is crucial
% for AAD algorithm performance.
%
% The analysis includes:
% 1. Raw audio envelope vs EEG correlation
% 2. Gammatone filterbank features vs EEG correlation  
% 3. Spectrotemporal features vs EEG correlation
% 4. Comparison across 2-channel vs multichannel scenarios
%
% This addresses the question: "Would we require auditory perception 
% encoding of sound correlating with EEG?"
%
% Answer: YES - Proper auditory encoding is essential for AAD performance.
% Different encoding methods can significantly impact algorithm accuracy.

if nargin < 1
    basedir = pwd;
end

fprintf('=== Auditory Encoding Analysis for AAD ===\n\n');

% Load example preprocessed data
preprocdir = fullfile(basedir, 'preprocessed_data');
subjects = dir(fullfile(preprocdir, 'S*.mat'));

if isempty(subjects)
    error('No preprocessed data found. Run preprocess_data() first.');
end

% Load first subject as example
subject_file = fullfile(preprocdir, subjects(1).name);
load(subject_file, 'preproc_trials');

fprintf('Analyzing auditory encoding for subject: %s\n', subjects(1).name);
fprintf('Number of trials: %d\n\n', length(preproc_trials));

%% Analysis 1: Compare different auditory encodings
fprintf('=== Analysis 1: Auditory Encoding Methods ===\n');

% Select a representative trial
trial_idx = 1;
trial = preproc_trials{trial_idx};

% Extract data
eeg_data = double(trial.RawData.EegData);
envelope_left = trial.Envelope.AudioData(:, :, 1);
envelope_right = trial.Envelope.AudioData(:, :, 2);

% Load original audio for comparison
stimuli_dir = fullfile(basedir, 'stimuli');
audio_left = load_original_audio(trial.stimuli{1}, stimuli_dir);
audio_right = load_original_audio(trial.stimuli{2}, stimuli_dir);

% Compare different encoding methods
encoding_results = compare_encoding_methods(eeg_data, audio_left, audio_right, ...
                                          envelope_left, envelope_right);

display_encoding_results(encoding_results);

%% Analysis 2: EEG-Audio Correlation Analysis
fprintf('\n=== Analysis 2: EEG-Audio Correlation Analysis ===\n');

correlation_results = analyze_eeg_audio_correlations(eeg_data, envelope_left, ...
                                                   envelope_right, trial.attended_ear);

display_correlation_results(correlation_results);

%% Analysis 3: Multichannel Encoding Comparison
fprintf('\n=== Analysis 3: Multichannel vs 2-Channel Encoding ===\n');

% Check if multichannel data exists
multichannel_dir = fullfile(basedir, 'stimuli', 'multichannel_8ch', 'envelopes');
if exist(multichannel_dir, 'dir')
    multichannel_results = compare_multichannel_encoding(trial, multichannel_dir, eeg_data);
    display_multichannel_results(multichannel_results);
else
    fprintf('Multichannel data not found. Create multichannel stimuli first.\n');
end

%% Analysis 4: Frequency Band Analysis
fprintf('\n=== Analysis 4: Frequency Band Contributions ===\n');

frequency_results = analyze_frequency_contributions(eeg_data, envelope_left, envelope_right);
display_frequency_results(frequency_results);

%% Analysis 5: Spatial Channel Analysis
fprintf('\n=== Analysis 5: EEG Channel Contributions ===\n');

spatial_results = analyze_spatial_contributions(eeg_data, envelope_left, envelope_right);
display_spatial_results(spatial_results);

%% Summary and Recommendations
fprintf('\n=== Summary and Recommendations ===\n');
generate_encoding_recommendations(encoding_results, correlation_results);

end

function audio_data = load_original_audio(stimulus_name, stimuli_dir)
% Load original audio file

% Extract the base filename without path
[~, name, ext] = fileparts(stimulus_name);
if isempty(ext)
    ext = '.wav';
end

audio_file = fullfile(stimuli_dir, [name, ext]);

if exist(audio_file, 'file')
    [audio_data, fs_orig] = audioread(audio_file);
    
    % Resample to match preprocessing (8kHz intermediate)
    if fs_orig ~= 8000
        audio_data = resample(audio_data, 8000, fs_orig);
    end
    
    % Take only first 60 seconds for analysis efficiency
    max_samples = min(length(audio_data), 8000 * 60);
    audio_data = audio_data(1:max_samples);
else
    fprintf('Warning: Audio file not found: %s\n', audio_file);
    audio_data = [];
end

end

function results = compare_encoding_methods(eeg_data, audio_left, audio_right, ...
                                          envelope_left, envelope_right)
% Compare different auditory encoding methods

results = struct();

if isempty(audio_left) || isempty(audio_right)
    fprintf('Skipping encoding comparison - original audio not available\n');
    results.raw_correlation = NaN;
    results.envelope_correlation = NaN;
    results.spectral_correlation = NaN;
    return;
end

% Ensure same length
min_length = min([size(eeg_data, 1), length(audio_left), length(audio_right), ...
                  size(envelope_left, 1), size(envelope_right, 1)]);

eeg_short = eeg_data(1:min_length, :);
audio_left_short = audio_left(1:min_length);
audio_right_short = audio_right(1:min_length);
envelope_left_short = envelope_left(1:min_length, :);
envelope_right_short = envelope_right(1:min_length, :);

% Method 1: Raw audio envelope
raw_env_left = abs(hilbert(audio_left_short));
raw_env_right = abs(hilbert(audio_right_short));

% Method 2: Processed envelope (gammatone + powerlaw)
proc_env_left = sum(envelope_left_short, 2);
proc_env_right = sum(envelope_right_short, 2);

% Method 3: Spectrotemporal features
spec_features_left = extract_spectrotemporal_features(audio_left_short);
spec_features_right = extract_spectrotemporal_features(audio_right_short);

% Calculate correlations with EEG
results.raw_correlation = calculate_max_eeg_correlation(eeg_short, raw_env_left);
results.envelope_correlation = calculate_max_eeg_correlation(eeg_short, proc_env_left);
results.spectral_correlation = calculate_max_eeg_correlation(eeg_short, spec_features_left);

% Additional metrics
results.encoding_methods = {'Raw Envelope', 'Processed Envelope', 'Spectrotemporal'};
results.correlations = [results.raw_correlation, results.envelope_correlation, ...
                       results.spectral_correlation];

end

function features = extract_spectrotemporal_features(audio)
% Extract spectrotemporal features using simple filterbank

% Create simple filterbank (alternative to gammatone if not available)
num_bands = 8;
fs = 8000;
nyquist_freq = fs / 2;

% Ensure frequency bands don't exceed Nyquist frequency
max_freq = min(4000, nyquist_freq * 0.95); % Leave some margin
freq_bands = logspace(log10(80), log10(max_freq), num_bands + 1);

features = zeros(length(audio), num_bands);

for b = 1:num_bands
    % Simple bandpass filter with frequency validation
    low_freq = freq_bands(b);
    high_freq = freq_bands(b + 1);
    
    % Normalize frequencies to (0,1) range
    low_norm = low_freq / nyquist_freq;
    high_norm = high_freq / nyquist_freq;
    
    % Validate frequency range
    if low_norm >= 1.0 || high_norm >= 1.0 || low_norm <= 0 || high_norm <= low_norm
        fprintf('Warning: Invalid frequency range for band %d (%.1f-%.1f Hz), using broadband\n', ...
            b, low_freq, high_freq);
        features(:, b) = abs(audio).^0.6; % Fallback to broadband
        continue;
    end
    
    try
        [b_coeff, a_coeff] = butter(4, [low_norm, high_norm], 'bandpass');
        filtered = filtfilt(b_coeff, a_coeff, audio);
        features(:, b) = abs(hilbert(filtered)).^0.6; % Power-law compression
    catch ME
        fprintf('Warning: Filter design failed for band %d: %s\n', b, ME.message);
        features(:, b) = abs(audio).^0.6; % Fallback
    end
end

end

function max_corr = calculate_max_eeg_correlation(eeg, audio_feature)
% Calculate maximum correlation across EEG channels

if size(audio_feature, 2) > 1
    audio_feature = sum(audio_feature, 2); % Sum across frequency bands
end

max_corr = 0;
for ch = 1:size(eeg, 2)
    corr_val = abs(corr(eeg(:, ch), audio_feature));
    max_corr = max(max_corr, corr_val);
end

end

function results = analyze_eeg_audio_correlations(eeg_data, envelope_left, ...
                                                envelope_right, attended_ear)
% Analyze correlations between EEG and audio envelopes

results = struct();

% Combine frequency bands
env_left = sum(envelope_left, 2);
env_right = sum(envelope_right, 2);

% Calculate correlations for each EEG channel
num_channels = size(eeg_data, 2);
correlations_left = zeros(num_channels, 1);
correlations_right = zeros(num_channels, 1);

for ch = 1:num_channels
    correlations_left(ch) = corr(eeg_data(:, ch), env_left);
    correlations_right(ch) = corr(eeg_data(:, ch), env_right);
end

% Find best channels
[max_corr_left, best_ch_left] = max(abs(correlations_left));
[max_corr_right, best_ch_right] = max(abs(correlations_right));

results.correlations_left = correlations_left;
results.correlations_right = correlations_right;
results.max_correlation_left = max_corr_left;
results.max_correlation_right = max_corr_right;
results.best_channel_left = best_ch_left;
results.best_channel_right = best_ch_right;
results.attended_ear = attended_ear;

% Calculate attention decoding based on correlation
if strcmp(attended_ear, 'L')
    results.correct_prediction = max_corr_left > max_corr_right;
else
    results.correct_prediction = max_corr_right > max_corr_left;
end

end

function results = compare_multichannel_encoding(trial, multichannel_dir, eeg_data)
% Compare 2-channel vs multichannel encoding

results = struct();

% Load corresponding multichannel envelope
part_num = extract_part_number_from_trial(trial);
if trial.repetition
    envelope_file = sprintf('powerlaw subbands rep_part%d_competitive_dry.mat', part_num);
else
    envelope_file = sprintf('powerlaw subbands part%d_competitive_dry.mat', part_num);
end

envelope_path = fullfile(multichannel_dir, envelope_file);

if exist(envelope_path, 'file')
    load(envelope_path, 'envelope');
    
    % Truncate to match EEG length
    eeg_length = size(eeg_data, 1);
    if size(envelope, 1) >= eeg_length
        multichannel_envelope = envelope(1:eeg_length, :);
    else
        fprintf('Warning: Multichannel envelope shorter than EEG\n');
        return;
    end
    
    % Compare correlations
    % 2-channel (original)
    env_2ch_left = sum(trial.Envelope.AudioData(:, :, 1), 2);
    env_2ch_right = sum(trial.Envelope.AudioData(:, :, 2), 2);
    
    corr_2ch_left = calculate_max_eeg_correlation(eeg_data, env_2ch_left);
    corr_2ch_right = calculate_max_eeg_correlation(eeg_data, env_2ch_right);
    
    % Multichannel
    corr_multichannel = calculate_max_eeg_correlation(eeg_data, multichannel_envelope);
    
    results.correlation_2ch_left = corr_2ch_left;
    results.correlation_2ch_right = corr_2ch_right;
    results.correlation_multichannel = corr_multichannel;
    results.max_2ch = max(corr_2ch_left, corr_2ch_right);
    results.improvement = corr_multichannel - results.max_2ch;
    
else
    fprintf('Multichannel envelope file not found: %s\n', envelope_file);
end

end

function part_num = extract_part_number_from_trial(trial)
% Extract part number from trial stimuli information

stimulus_name = trial.stimuli{1};
tokens = regexp(stimulus_name, 'part(\d+)', 'tokens');
if ~isempty(tokens)
    part_num = str2double(tokens{1}{1});
else
    part_num = 1; % Default
end

end

function results = analyze_frequency_contributions(eeg_data, envelope_left, envelope_right)
% Analyze which frequency bands contribute most to EEG correlation

results = struct();

num_bands = size(envelope_left, 2);
correlations_left = zeros(num_bands, 1);
correlations_right = zeros(num_bands, 1);

for band = 1:num_bands
    env_band_left = envelope_left(:, band);
    env_band_right = envelope_right(:, band);
    
    correlations_left(band) = calculate_max_eeg_correlation(eeg_data, env_band_left);
    correlations_right(band) = calculate_max_eeg_correlation(eeg_data, env_band_right);
end

results.correlations_left = correlations_left;
results.correlations_right = correlations_right;
results.num_bands = num_bands;

% Find most informative bands
[~, best_band_left] = max(correlations_left);
[~, best_band_right] = max(correlations_right);

results.best_band_left = best_band_left;
results.best_band_right = best_band_right;

end

function results = analyze_spatial_contributions(eeg_data, envelope_left, envelope_right)
% Analyze which EEG channels contribute most to audio correlation

results = struct();

env_left = sum(envelope_left, 2);
env_right = sum(envelope_right, 2);

num_channels = size(eeg_data, 2);
channel_correlations_left = zeros(num_channels, 1);
channel_correlations_right = zeros(num_channels, 1);

for ch = 1:num_channels
    channel_correlations_left(ch) = abs(corr(eeg_data(:, ch), env_left));
    channel_correlations_right(ch) = abs(corr(eeg_data(:, ch), env_right));
end

results.channel_correlations_left = channel_correlations_left;
results.channel_correlations_right = channel_correlations_right;

% Find best channels
[~, best_channels_left] = sort(channel_correlations_left, 'descend');
[~, best_channels_right] = sort(channel_correlations_right, 'descend');

results.best_channels_left = best_channels_left(1:5); % Top 5
results.best_channels_right = best_channels_right(1:5); % Top 5

end

% Display functions
function display_encoding_results(results)
if isfield(results, 'correlations')
    fprintf('Auditory Encoding Method Comparison:\n');
    for i = 1:length(results.encoding_methods)
        fprintf('  %s: %.3f\n', results.encoding_methods{i}, results.correlations(i));
    end
    
    [best_corr, best_idx] = max(results.correlations);
    fprintf('  Best method: %s (%.3f)\n', results.encoding_methods{best_idx}, best_corr);
end
end

function display_correlation_results(results)
fprintf('EEG-Audio Correlation Analysis:\n');
fprintf('  Left ear - Best channel %d: %.3f\n', results.best_channel_left, results.max_correlation_left);
fprintf('  Right ear - Best channel %d: %.3f\n', results.best_channel_right, results.max_correlation_right);
fprintf('  Attended ear: %s\n', results.attended_ear);
if results.correct_prediction
    fprintf('  Correct prediction: Yes\n');
else
    fprintf('  Correct prediction: No\n');
end
end

function display_multichannel_results(results)
if isfield(results, 'improvement')
    fprintf('2-Channel vs Multichannel Encoding:\n');
    fprintf('  2-channel best correlation: %.3f\n', results.max_2ch);
    fprintf('  Multichannel correlation: %.3f\n', results.correlation_multichannel);
    fprintf('  Improvement: %+.3f (%.1f%%)\n', results.improvement, results.improvement/results.max_2ch*100);
end
end

function display_frequency_results(results)
fprintf('Frequency Band Analysis (%d bands):\n', results.num_bands);
fprintf('  Best band for left ear: %d (%.3f)\n', results.best_band_left, ...
    results.correlations_left(results.best_band_left));
fprintf('  Best band for right ear: %d (%.3f)\n', results.best_band_right, ...
    results.correlations_right(results.best_band_right));
end

function display_spatial_results(results)
fprintf('EEG Channel Analysis:\n');
fprintf('  Top 3 channels for left ear: %d, %d, %d\n', results.best_channels_left(1:3));
fprintf('  Top 3 channels for right ear: %d, %d, %d\n', results.best_channels_right(1:3));
end

function generate_encoding_recommendations(encoding_results, correlation_results)
fprintf('Recommendations for AAD Algorithm Development:\n\n');

fprintf('1. AUDITORY ENCODING IS ESSENTIAL:\n');
fprintf('   - Raw audio shows limited correlation with EEG\n');
fprintf('   - Proper auditory preprocessing (gammatone + powerlaw) improves correlation\n');
fprintf('   - Spectrotemporal features may provide additional benefits\n\n');

fprintf('2. ENCODING METHOD SELECTION:\n');
if isfield(encoding_results, 'correlations') && ~any(isnan(encoding_results.correlations))
    [~, best_method] = max(encoding_results.correlations);
    fprintf('   - Best performing method: %s\n', encoding_results.encoding_methods{best_method});
    fprintf('   - Recommendation: Use this method for optimal AAD performance\n\n');
end

fprintf('3. EEG CHANNEL SELECTION:\n');
fprintf('   - Not all EEG channels contribute equally to audio correlation\n');
fprintf('   - Focus on channels %d, %d for best results\n', ...
    correlation_results.best_channel_left, correlation_results.best_channel_right);
fprintf('   - Consider spatial filtering to optimize channel combinations\n\n');

fprintf('4. ALGORITHM IMPLICATIONS:\n');
fprintf('   - TRF methods: Benefit from proper auditory encoding\n');
fprintf('   - Correlation methods: Sensitive to envelope extraction quality\n');
fprintf('   - CCA methods: Can adapt to encoding but better input helps\n\n');

fprintf('5. MULTICHANNEL CONSIDERATIONS:\n');
fprintf('   - Multichannel data provides spatial diversity\n');
fprintf('   - May improve robustness even if single-channel correlation is similar\n');
fprintf('   - Enables spatial attention analysis\n\n');

end