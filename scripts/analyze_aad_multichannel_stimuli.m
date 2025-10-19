function analyze_aad_multichannel_stimuli(basedir, channel_config)
% ANALYZE_AAD_MULTICHANNEL_STIMULI Analyzes multichannel competitive AAD stimuli
% This function analyzes the spatial distribution and characteristics of 
% multichannel competitive scenarios created for AAD research
%
% Inputs:
%   basedir: Directory containing the stimuli folder
%   channel_config: Number of channels to analyze (6 or 8)

if nargin < 1
    basedir = pwd;
end

if nargin < 2
    channel_config = 8;
end

% Define paths
multichannel_dir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', channel_config));
config_file = fullfile(multichannel_dir, 'aad_spatial_configuration.mat');

if ~exist(multichannel_dir, 'dir')
    error('Multichannel directory not found. Create AAD stimuli first.');
end

% Load configuration
if exist(config_file, 'file')
    load(config_file, 'config_data');
    fprintf('Loaded AAD configuration for %d channels\n', config_data.channel_config);
else
    error('Configuration file not found. Create AAD stimuli first.');
end

% Get list of competitive files
competitive_files = dir(fullfile(multichannel_dir, '*_competitive_dry.wav'));

if isempty(competitive_files)
    error('No competitive AAD files found.');
end

fprintf('\nAnalyzing AAD Competitive Stimuli\n');
fprintf('==================================\n');

% Analyze each competitive file
for i = 1:length(competitive_files)
    file_path = fullfile(multichannel_dir, competitive_files(i).name);
    [audio_mc, fs] = audioread(file_path);
    
    fprintf('\nFile %d: %s\n', i, competitive_files(i).name);
    fprintf('Duration: %.1f sec, Sample Rate: %d Hz\n', size(audio_mc, 1)/fs, fs);
    
    % Analyze spatial distribution
    analyze_spatial_distribution(audio_mc, config_data, competitive_files(i).name);
end

% Create comprehensive visualization
if length(competitive_files) > 0
    % Analyze one representative file for detailed visualization
    example_file = fullfile(multichannel_dir, competitive_files(1).name);
    [audio_example, fs] = audioread(example_file);
    create_aad_analysis_plots(audio_example, config_data, fs, competitive_files(1).name);
end

end

function analyze_spatial_distribution(audio_mc, config_data, filename)
% Analyze the spatial distribution of audio content

% Calculate RMS energy per channel
rms_values = rms(audio_mc);
total_energy = sum(rms_values.^2);

fprintf('  Spatial Energy Distribution:\n');
active_channels = 0;
for ch = 1:length(config_data.speaker_names)
    energy_percent = (rms_values(ch)^2 / total_energy) * 100;
    if rms_values(ch) > 0.001  % Only show active channels
        fprintf('    %s: %.4f (%.1f%% of total energy)\n', ...
            config_data.speaker_names{ch}, rms_values(ch), energy_percent);
        active_channels = active_channels + 1;
    end
end

fprintf('  Active channels: %d/%d\n', active_channels, length(config_data.speaker_names));

% Calculate separation metrics
separation_analysis = calculate_spatial_separation(audio_mc, config_data);
fprintf('  Spatial separation quality: %.2f\n', separation_analysis.separation_index);

end

function separation_analysis = calculate_spatial_separation(audio_mc, config_data)
% Calculate metrics related to spatial separation quality

separation_analysis = struct();

% Find the two most energetic channels (representing the two competing tracks)
rms_values = rms(audio_mc);
[~, sorted_indices] = sort(rms_values, 'descend');

if length(sorted_indices) >= 2
    ch1_idx = sorted_indices(1);
    ch2_idx = sorted_indices(2);
    
    % Calculate angular separation
    angle1 = config_data.speaker_angles(ch1_idx);
    angle2 = config_data.speaker_angles(ch2_idx);
    angular_separation = abs(angle1 - angle2);
    if angular_separation > 180
        angular_separation = 360 - angular_separation;
    end
    
    % Calculate cross-correlation between the two main channels
    cross_corr = corrcoef(audio_mc(:, ch1_idx), audio_mc(:, ch2_idx));
    correlation = abs(cross_corr(1, 2));
    
    % Calculate energy ratio
    energy_ratio = min(rms_values(ch1_idx), rms_values(ch2_idx)) / ...
                   max(rms_values(ch1_idx), rms_values(ch2_idx));
    
    % Composite separation index (higher is better separation)
    separation_analysis.angular_separation = angular_separation;
    separation_analysis.correlation = correlation;
    separation_analysis.energy_ratio = energy_ratio;
    separation_analysis.separation_index = (angular_separation / 180) * ...
                                         (1 - correlation) * energy_ratio;
    
    separation_analysis.primary_channels = {config_data.speaker_names{ch1_idx}, ...
                                          config_data.speaker_names{ch2_idx}};
else
    separation_analysis.separation_index = 0;
    separation_analysis.primary_channels = {};
end

end

function create_aad_analysis_plots(audio_mc, config_data, fs, filename)
% Create comprehensive analysis plots for AAD multichannel stimuli

% Create figure
figure('Position', [100, 100, 1400, 900], 'Name', sprintf('AAD Analysis: %s', filename));

%% Plot 1: Multichannel waveforms (first 10 seconds)
subplot(3, 3, 1);
t_end = min(10, size(audio_mc, 1)/fs); % First 10 seconds or full duration
samples_to_plot = min(round(t_end * fs), size(audio_mc, 1));
t = (0:samples_to_plot-1) / fs;

% Only plot channels with significant energy
rms_values = rms(audio_mc);
active_channels = find(rms_values > 0.001);

if ~isempty(active_channels)
    plot(t, audio_mc(1:samples_to_plot, active_channels));
    title('Waveforms (First 10s)');
    xlabel('Time (s)');
    ylabel('Amplitude');
    legend(config_data.speaker_names(active_channels), 'Location', 'eastoutside');
else
    text(0.5, 0.5, 'No active channels found', 'HorizontalAlignment', 'center');
    title('Waveforms (First 10s)');
end
grid on;

%% Plot 2: RMS Energy Distribution
subplot(3, 3, 2);
rms_all = rms(audio_mc);
bar(rms_all);
title('RMS Energy per Channel');
xlabel('Channel');
ylabel('RMS Energy');
set(gca, 'XTickLabel', config_data.speaker_names);
xtickangle(45);
grid on;

% Highlight primary channels
hold on;
[~, sorted_idx] = sort(rms_all, 'descend');
if length(sorted_idx) >= 2
    bar(sorted_idx(1), rms_all(sorted_idx(1)), 'r');
    bar(sorted_idx(2), rms_all(sorted_idx(2)), 'g');
end
hold off;

%% Plot 3: Speaker Layout with Energy
subplot(3, 3, 3);
angles_rad = config_data.speaker_angles * pi / 180;
x = cos(angles_rad);
y = sin(angles_rad);

% Scale by energy
energy_scale = rms_all / max(rms_all) * 0.8 + 0.2;

scatter(x, y, 300 * energy_scale, rms_all, 'filled');
colorbar;
title('Speaker Layout (Energy-scaled)');
xlabel('X');
ylabel('Y');

% Add speaker labels
for i = 1:length(config_data.speaker_names)
    text(x(i)*1.2, y(i)*1.2, config_data.speaker_names{i}, ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

% Add listener position
hold on;
plot(0, 0, 'k+', 'MarkerSize', 15, 'LineWidth', 3);
text(0, -0.15, 'Listener', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
hold off;

axis equal;
axis([-1.5 1.5 -1.5 1.5]);
grid on;

%% Plot 4: Frequency Spectrum (active channels only)
subplot(3, 3, 4);
window_length = min(4096, size(audio_mc, 1));

if ~isempty(active_channels)
    [psd, f] = pwelch(audio_mc(:, active_channels), window_length, [], [], fs);
    semilogx(f, 10*log10(psd));
    title('Power Spectral Density');
    xlabel('Frequency (Hz)');
    ylabel('PSD (dB/Hz)');
    legend(config_data.speaker_names(active_channels), 'Location', 'southwest');
    grid on;
    xlim([100, fs/2]);
else
    text(0.5, 0.5, 'No active channels', 'HorizontalAlignment', 'center');
    title('Power Spectral Density');
end

%% Plot 5: Channel Cross-Correlation (active channels only)
subplot(3, 3, 5);
if length(active_channels) >= 2
    corr_matrix = corrcoef(audio_mc(:, active_channels));
    imagesc(corr_matrix);
    colorbar;
    colormap('jet');
    title('Cross-Correlation (Active)');
    channel_labels = config_data.speaker_names(active_channels);
    set(gca, 'XTick', 1:length(channel_labels), 'XTickLabel', channel_labels, ...
             'YTick', 1:length(channel_labels), 'YTickLabel', channel_labels);
    xtickangle(45);
    
    % Add correlation values
    for i = 1:size(corr_matrix, 1)
        for j = 1:size(corr_matrix, 2)
            text(j, i, sprintf('%.2f', corr_matrix(i, j)), ...
                'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', 9);
        end
    end
else
    text(0.5, 0.5, 'Insufficient active channels', 'HorizontalAlignment', 'center');
    title('Cross-Correlation');
end

%% Plot 6: Envelope Analysis (first 30 seconds)
subplot(3, 3, 6);
envelope_window = round(0.064 * fs); % 64ms window for envelope
envelope_hop = round(0.032 * fs);    % 32ms hop

t_env_end = min(30, size(audio_mc, 1)/fs);
samples_env = min(round(t_env_end * fs), size(audio_mc, 1));

if ~isempty(active_channels) && samples_env > envelope_window
    % Calculate envelopes for active channels
    n_frames = floor((samples_env - envelope_window) / envelope_hop) + 1;
    envelopes = zeros(n_frames, length(active_channels));
    
    for i = 1:n_frames
        start_idx = (i-1) * envelope_hop + 1;
        end_idx = start_idx + envelope_window - 1;
        frame = audio_mc(start_idx:end_idx, active_channels);
        envelopes(i, :) = rms(frame);
    end
    
    t_env = (0:n_frames-1) * envelope_hop / fs;
    plot(t_env, envelopes);
    title('Speech Envelopes (30s)');
    xlabel('Time (s)');
    ylabel('RMS Amplitude');
    legend(config_data.speaker_names(active_channels), 'Location', 'best');
    grid on;
else
    text(0.5, 0.5, 'Insufficient data for envelope', 'HorizontalAlignment', 'center');
    title('Speech Envelopes');
end

%% Plot 7: Competitive Scenario Analysis
subplot(3, 3, 7);
separation_analysis = calculate_spatial_separation(audio_mc, config_data);

% Create a summary table
metrics = {'Angular Sep. (°)', 'Cross-Correlation', 'Energy Ratio', 'Separation Index'};
values = [separation_analysis.angular_separation, separation_analysis.correlation, ...
          separation_analysis.energy_ratio, separation_analysis.separation_index];

bar(values);
title('Competitive Quality Metrics');
set(gca, 'XTickLabel', metrics);
xtickangle(45);
ylabel('Value');
grid on;

% Add value labels on bars
for i = 1:length(values)
    text(i, values(i) + 0.02, sprintf('%.2f', values(i)), ...
        'HorizontalAlignment', 'center', 'FontWeight', 'bold');
end

%% Plot 8: AAD Relevance Analysis
subplot(3, 3, 8);
% Analyze characteristics relevant to AAD

% Calculate inter-channel delays (important for AAD)
if length(active_channels) >= 2
    ch1 = active_channels(1);
    ch2 = active_channels(2);
    
    % Cross-correlation to find delay
    [xcorr_result, lags] = xcorr(audio_mc(1:min(fs*5, end), ch1), ...
                                audio_mc(1:min(fs*5, end), ch2), 'coeff');
    [~, max_idx] = max(abs(xcorr_result));
    delay_samples = lags(max_idx);
    delay_ms = delay_samples / fs * 1000;
    
    stem(lags(max_idx-50:max_idx+50), xcorr_result(max_idx-50:max_idx+50));
    title(sprintf('Cross-correlation (Delay: %.1fms)', delay_ms));
    xlabel('Lag (samples)');
    ylabel('Correlation');
    grid on;
else
    text(0.5, 0.5, 'Need 2+ active channels', 'HorizontalAlignment', 'center');
    title('Cross-correlation Analysis');
end

%% Plot 9: Summary Statistics
subplot(3, 3, 9);
axis off;

% Create text summary
summary_text = {
    sprintf('AAD Multichannel Analysis Summary');
    sprintf('================================');
    sprintf('');
    sprintf('Configuration: %d channels', config_data.channel_config);
    sprintf('Active channels: %d', length(active_channels));
    sprintf('');
    sprintf('Primary competing channels:');
};

if ~isempty(separation_analysis.primary_channels)
    summary_text{end+1} = sprintf('  • %s vs %s', separation_analysis.primary_channels{1}, ...
                                  separation_analysis.primary_channels{2});
end

summary_text = [summary_text; {
    sprintf('');
    sprintf('Spatial separation: %.0f°', separation_analysis.angular_separation);
    sprintf('Channel correlation: %.3f', separation_analysis.correlation);
    sprintf('Energy balance: %.3f', separation_analysis.energy_ratio);
    sprintf('Overall quality: %.3f', separation_analysis.separation_index);
    sprintf('');
    sprintf('AAD Suitability: %s', get_aad_suitability_rating(separation_analysis.separation_index));
}];

text(0.05, 0.95, summary_text, 'VerticalAlignment', 'top', 'FontSize', 10, ...
     'FontName', 'Courier New');

% Main title
sgtitle(sprintf('AAD Multichannel Analysis: %s (%d-ch)', filename, config_data.channel_config), ...
    'FontSize', 14, 'FontWeight', 'bold');

end

function rating = get_aad_suitability_rating(separation_index)
% Get AAD suitability rating based on separation index

if separation_index >= 0.8
    rating = 'Excellent';
elseif separation_index >= 0.6
    rating = 'Good';
elseif separation_index >= 0.4
    rating = 'Fair';
else
    rating = 'Poor';
end

end