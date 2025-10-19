function analyze_multichannel_audio(basedir, channel_config)
% ANALYZE_MULTICHANNEL_AUDIO Analyzes and visualizes multichannel audio output
% This function helps understand the spatial distribution created by upmixing
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
config_file = fullfile(multichannel_dir, 'spatial_configuration.mat');

if ~exist(multichannel_dir, 'dir')
    error('Multichannel directory not found. Run upmixing first.');
end

% Load configuration
if exist(config_file, 'file')
    load(config_file, 'config_data');
    fprintf('Loaded configuration for %d channels\n', config_data.channel_config);
else
    error('Configuration file not found. Run upmixing first.');
end

% Get list of multichannel files
audio_files = dir(fullfile(multichannel_dir, '*_dry.wav'));

if isempty(audio_files)
    error('No multichannel audio files found.');
end

% Analyze first file as example
example_file = fullfile(multichannel_dir, audio_files(1).name);
[audio_mc, fs] = audioread(example_file);

fprintf('\nAnalyzing: %s\n', audio_files(1).name);
fprintf('Channels: %d, Sample rate: %d Hz, Duration: %.1f sec\n', ...
    size(audio_mc, 2), fs, size(audio_mc, 1)/fs);

%% Analysis 1: RMS Energy Distribution
fprintf('\n=== RMS Energy Distribution ===\n');
rms_values = rms(audio_mc);
for ch = 1:length(config_data.speaker_names)
    fprintf('Channel %d (%s): %.4f\n', ch, config_data.speaker_names{ch}, rms_values(ch));
end

%% Analysis 2: Cross-correlation between channels
fprintf('\n=== Cross-correlation Analysis ===\n');
corr_matrix = corrcoef(audio_mc);
fprintf('Channel correlation matrix:\n');
for i = 1:size(corr_matrix, 1)
    for j = 1:size(corr_matrix, 2)
        fprintf('%6.3f ', corr_matrix(i, j));
    end
    fprintf('\n');
end

%% Visualization
create_analysis_plots(audio_mc, config_data, fs);

end

function create_analysis_plots(audio_mc, config_data, fs)
% Create visualization plots for multichannel analysis

% Create figure with multiple subplots
figure('Position', [100, 100, 1200, 800], 'Name', 'Multichannel Audio Analysis');

%% Plot 1: Waveforms
subplot(2, 3, 1);
t = (0:size(audio_mc, 1)-1) / fs;
plot(t, audio_mc);
title('Multichannel Waveforms');
xlabel('Time (s)');
ylabel('Amplitude');
legend(config_data.speaker_names, 'Location', 'eastoutside');
grid on;

%% Plot 2: RMS Energy per channel
subplot(2, 3, 2);
rms_values = rms(audio_mc);
bar(rms_values);
title('RMS Energy per Channel');
xlabel('Channel');
ylabel('RMS Energy');
set(gca, 'XTickLabel', config_data.speaker_names);
xtickangle(45);
grid on;

%% Plot 3: Speaker configuration (top view)
subplot(2, 3, 3);
angles_rad = config_data.speaker_angles * pi / 180;
x = cos(angles_rad);
y = sin(angles_rad);

% Scale by energy for visualization
energy_scale = rms_values / max(rms_values) * 0.5 + 0.5;

scatter(x, y, 200 * energy_scale, rms_values, 'filled');
colorbar;
title('Speaker Layout (Top View)');
xlabel('X');
ylabel('Y');

% Add speaker labels
for i = 1:length(config_data.speaker_names)
    text(x(i)*1.1, y(i)*1.1, config_data.speaker_names{i}, ...
        'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
end

% Add center point
hold on;
plot(0, 0, 'k+', 'MarkerSize', 10, 'LineWidth', 2);
text(0, -0.15, 'Listener', 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
hold off;

axis equal;
axis([-1.5 1.5 -1.5 1.5]);
grid on;

%% Plot 4: Frequency spectrum
subplot(2, 3, 4);
window_length = min(2048, size(audio_mc, 1));
[psd, f] = pwelch(audio_mc, window_length, [], [], fs);
semilogx(f, 10*log10(psd));
title('Power Spectral Density');
xlabel('Frequency (Hz)');
ylabel('PSD (dB/Hz)');
legend(config_data.speaker_names, 'Location', 'southwest');
grid on;
xlim([1, fs/2]);

%% Plot 5: Correlation matrix heatmap
subplot(2, 3, 5);
corr_matrix = corrcoef(audio_mc);
imagesc(corr_matrix);
colorbar;
colormap('jet');
title('Channel Cross-Correlation');
set(gca, 'XTick', 1:length(config_data.speaker_names), ...
         'XTickLabel', config_data.speaker_names, ...
         'YTick', 1:length(config_data.speaker_names), ...
         'YTickLabel', config_data.speaker_names);
xtickangle(45);

% Add correlation values as text
for i = 1:size(corr_matrix, 1)
    for j = 1:size(corr_matrix, 2)
        text(j, i, sprintf('%.2f', corr_matrix(i, j)), ...
            'HorizontalAlignment', 'center', 'Color', 'white', 'FontSize', 8);
    end
end

%% Plot 6: Gain distribution for left/right inputs
subplot(2, 3, 6);
gains = [config_data.left_gains; config_data.right_gains]';
bar(gains);
title('Spatial Projection Gains');
xlabel('Channel');
ylabel('Gain');
legend({'Left Input', 'Right Input'}, 'Location', 'best');
set(gca, 'XTickLabel', config_data.speaker_names);
xtickangle(45);
grid on;

% Adjust layout
sgtitle(sprintf('%d-Channel Spatial Audio Analysis', config_data.channel_config), ...
    'FontSize', 16, 'FontWeight', 'bold');

end