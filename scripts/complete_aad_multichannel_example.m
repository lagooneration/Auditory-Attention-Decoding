%% Complete AAD Multichannel Pipeline Example
% This script demonstrates the complete workflow for creating and analyzing
% multichannel spatial audio for AAD (Auditory Attention Decoding) research

%% Setup
clear; clc; close all;

% Set your base directory
basedir = 'c:\Research\AAD';

% Choose channel configuration (6 or 8)
channel_configs = [6, 8];

fprintf('=== AAD Multichannel Processing Pipeline ===\n\n');

%% Step 1: Create Multichannel Competitive Stimuli
fprintf('Step 1: Creating multichannel competitive stimuli...\n');

for config = channel_configs
    fprintf('\n--- Processing %d-channel configuration ---\n', config);
    
    try
        % Create multichannel AAD stimuli
        create_multichannel_aad_stimuli(basedir, config);
        
        % Verify creation
        output_dir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', config));
        files = dir(fullfile(output_dir, '*_competitive_dry.wav'));
        fprintf('✓ Created %d competitive stimuli files\n', length(files));
        
    catch ME
        fprintf('✗ Error creating %d-channel stimuli: %s\n', config, ME.message);
        continue;
    end
end

%% Step 2: Analyze Multichannel Stimuli
fprintf('\nStep 2: Analyzing multichannel stimuli...\n');

for config = channel_configs
    fprintf('\n--- Analyzing %d-channel configuration ---\n', config);
    
    try
        % Run analysis (this will create plots)
        analyze_aad_multichannel_stimuli(basedir, config);
        fprintf('✓ Analysis completed for %d-channel configuration\n', config);
        
    catch ME
        fprintf('✗ Error analyzing %d-channel stimuli: %s\n', config, ME.message);
    end
end

%% Step 3: Extract Multichannel Envelopes (for AAD processing)
fprintf('\nStep 3: Extracting multichannel envelopes...\n');

for config = channel_configs
    fprintf('\n--- Extracting envelopes for %d-channel configuration ---\n', config);
    
    try
        % Extract envelopes using the new multichannel preprocessor
        preprocess_multichannel_aad_data(basedir, config);
        
        % Verify envelope extraction
        envelope_dir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', config), 'envelopes');
        envelope_files = dir(fullfile(envelope_dir, '*.mat'));
        fprintf('✓ Extracted envelopes: %d files\n', length(envelope_files));
        
    catch ME
        fprintf('✗ Error extracting %d-channel envelopes: %s\n', config, ME.message);
    end
end

%% Step 4: Demonstrate AAD Algorithm Integration
fprintf('\nStep 4: Demonstrating AAD algorithm integration...\n');

% Example of how to load and use multichannel data in AAD algorithms
config = 8; % Use 8-channel as example

try
    % Load a multichannel envelope file
    envelope_dir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', config), 'envelopes');
    envelope_files = dir(fullfile(envelope_dir, '*.mat'));
    
    if ~isempty(envelope_files)
        % Load first envelope file as example
        example_file = fullfile(envelope_dir, envelope_files(1).name);
        load(example_file, 'envelope', 'Fs', 'config_data');
        
        fprintf('Loaded example envelope data:\n');
        fprintf('  File: %s\n', envelope_files(1).name);
        fprintf('  Envelope size: %d samples x %d features\n', size(envelope, 1), size(envelope, 2));
        fprintf('  Sample rate: %d Hz\n', Fs);
        fprintf('  Channels: %d\n', config_data.channel_config);
        
        % Demonstrate feature extraction strategies
        demonstrate_aad_feature_strategies(envelope, config_data);
        
    else
        fprintf('No envelope files found. Run preprocessing first.\n');
    end
    
catch ME
    fprintf('✗ Error demonstrating integration: %s\n', ME.message);
end

%% Step 5: Summary and Next Steps
fprintf('\n=== Pipeline Summary ===\n');
fprintf('✓ Multichannel competitive stimuli created\n');
fprintf('✓ Spatial analysis completed\n');
fprintf('✓ Envelopes extracted for AAD processing\n');
fprintf('✓ Integration examples demonstrated\n\n');

fprintf('Next Steps for AAD Research:\n');
fprintf('1. Adapt your existing AAD algorithms to use multichannel features\n');
fprintf('2. Compare performance across different channel configurations\n');
fprintf('3. Investigate optimal channel selection strategies\n');
fprintf('4. Analyze spatial attention patterns across speaker positions\n');
fprintf('5. Develop spatial filtering methods for improved AAD performance\n\n');

fprintf('Generated Files Structure:\n');
for config = channel_configs
    output_dir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', config));
    if exist(output_dir, 'dir')
        fprintf('  stimuli/multichannel_%dch/\n', config);
        fprintf('    ├── *_competitive_dry.wav (multichannel audio)\n');
        fprintf('    ├── aad_spatial_configuration.mat (config)\n');
        fprintf('    └── envelopes/ (processed for AAD)\n');
    end
end

fprintf('\nAAD Multichannel Pipeline Complete!\n');

%% Helper function for demonstrating AAD feature strategies
function demonstrate_aad_feature_strategies(envelope, config_data)

fprintf('\n--- AAD Feature Strategy Examples ---\n');

% Determine the number of subbands per channel
total_features = size(envelope, 2);
num_channels = config_data.channel_config;

% Count active channels (channels with significant energy)
features_per_channel = total_features / num_channels;
if mod(features_per_channel, 1) ~= 0
    % If not evenly divisible, we have spatial features appended
    fprintf('Note: Spatial contrast features detected\n');
end

% Strategy 1: Single best channel selection
fprintf('\n1. Single Channel Selection Strategy:\n');
channel_energies = zeros(1, num_channels);
base_features = floor(total_features / num_channels);

for ch = 1:num_channels
    start_idx = (ch-1) * base_features + 1;
    end_idx = min(ch * base_features, total_features);
    if end_idx >= start_idx
        channel_envelope = envelope(:, start_idx:end_idx);
        channel_energies(ch) = mean(sum(channel_envelope.^2, 2));
    end
end

[~, best_channel] = max(channel_energies);
fprintf('   Best channel: %s (%.4f energy)\n', ...
    config_data.speaker_names{best_channel}, channel_energies(best_channel));

% Strategy 2: Channel pair analysis
fprintf('\n2. Channel Pair Strategy:\n');
[sorted_energies, sorted_idx] = sort(channel_energies, 'descend');
if length(sorted_idx) >= 2
    ch1 = sorted_idx(1);
    ch2 = sorted_idx(2);
    fprintf('   Primary pair: %s vs %s\n', ...
        config_data.speaker_names{ch1}, config_data.speaker_names{ch2});
    fprintf('   Energy ratio: %.2f\n', sorted_energies(2)/sorted_energies(1));
    
    % Calculate angular separation
    angle1 = config_data.speaker_angles(ch1);
    angle2 = config_data.speaker_angles(ch2);
    angular_sep = abs(angle1 - angle2);
    if angular_sep > 180, angular_sep = 360 - angular_sep; end
    fprintf('   Angular separation: %.0f°\n', angular_sep);
end

% Strategy 3: All channels with spatial filtering
fprintf('\n3. Spatial Filtering Strategy:\n');
active_channels = sum(channel_energies > 0.001);
fprintf('   Active channels: %d/%d\n', active_channels, num_channels);
fprintf('   Recommended: Use all active channels with spatial weighting\n');

% Strategy 4: Adaptive channel selection
fprintf('\n4. Adaptive Selection Recommendations:\n');
if active_channels >= 4
    fprintf('   → Use multi-channel spatial filtering\n');
    fprintf('   → Compare with channel selection algorithms\n');
elseif active_channels >= 2
    fprintf('   → Use best channel pair\n');
    fprintf('   → Consider contrast features\n');
else
    fprintf('   → Use single best channel\n');
    fprintf('   → May need to adjust spatial configuration\n');
end

end