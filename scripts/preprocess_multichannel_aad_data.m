function preprocess_multichannel_aad_data(basedir, channel_config)
% PREPROCESS_MULTICHANNEL_AAD_DATA Preprocesses multichannel AAD data
% This function extends the original preprocess_data.m to handle multichannel
% competitive scenarios for AAD research
%
% Based on the original preprocessing by Neetha Das, KULeuven
% Extended for multichannel spatial analysis
%
% Inputs:
%   basedir: Directory containing stimuli and subject data
%   channel_config: Number of channels (6 or 8)

if nargin == 0 
    basedir = pwd;
end

if nargin < 2
    channel_config = 8;
end

% Multichannel stimuli directory
multichannel_stimulusdir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', channel_config));
envelopedir = fullfile(multichannel_stimulusdir, 'envelopes');

if ~exist(envelopedir,'dir')
    mkdir(envelopedir);
end

% Load spatial configuration
config_file = fullfile(multichannel_stimulusdir, 'aad_spatial_configuration.mat');
if exist(config_file, 'file')
    load(config_file, 'config_data');
    fprintf('Processing %d-channel AAD data\n', config_data.channel_config);
else
    error('Spatial configuration not found. Create multichannel stimuli first.');
end

% Set parameters (matching original preprocessing)
params.intermediatefs_audio = 8000; %Hz
params.envelopemethod = 'powerlaw';
params.subbandenvelopes = true;
params.subbandtag = ' subbands'; 
params.spacing = 1.5;
params.freqs = erbspacebw(150,4000,params.spacing); % gammatone filter centerfrequencies
params.betamul = params.spacing*ones(size(params.freqs)); 
params.power = 0.6; % Powerlaw envelopes
params.intermediateSampleRate = 128; %Hz
params.lowpass = 9; % Hz
params.highpass = 1; % Hz
params.targetSampleRate = 32; % Hz
params.rereference = 'Cz';

% Multichannel-specific parameters
params.channel_config = channel_config;
params.spatial_analysis = true;

% Build the bandpass filter
bpFilter = construct_bpfilter(params);

% Create gammatone filters
try
    g = gammatonefir(params.freqs,params.intermediatefs_audio,[],params.betamul,'real');
catch
    warning('Gammatone filters not available. Using basic envelope extraction.');
    g = [];
end

%% Preprocess the multichannel audio files
multichannel_files = dir(fullfile(multichannel_stimulusdir, '*_competitive_dry.wav'));
nOfStimuli = length(multichannel_files);

fprintf('Processing %d multichannel competitive stimuli...\n', nOfStimuli);

for i = 1:nOfStimuli
    % Load multichannel competitive stimulus
    [~, stimuliname, stimuliext] = fileparts(multichannel_files(i).name);
    [audio_multichannel, Fs] = audioread(fullfile(multichannel_stimulusdir, ...
                                                 [stimuliname stimuliext]));
    
    fprintf('Processing [%d/%d]: %s\n', i, nOfStimuli, [stimuliname stimuliext]);
    
    % Process each channel
    num_channels = size(audio_multichannel, 2);
    all_channel_envelopes = cell(num_channels, 1);
    
    for ch = 1:num_channels
        % Extract single channel
        audio_single = audio_multichannel(:, ch);
        
        % Skip processing if channel is essentially silent
        if rms(audio_single) < 0.001
            continue;
        end
        
        % Resample to 8kHz 
        audio_resampled = resample(audio_single, params.intermediatefs_audio, Fs); 
        Fs_work = params.intermediatefs_audio;
        
        % Compute envelope
        if params.subbandenvelopes && ~isempty(g)
            % Apply gammatone filterbank
            audio_filtered = real(ufilterbank(audio_resampled, g, 1));
            audio_filtered = reshape(audio_filtered, size(audio_filtered,1), []);
        else
            % Use simple broadband envelope
            audio_filtered = audio_resampled;
        end
        
        % Apply the powerlaw
        envelope = abs(audio_filtered).^params.power;
        
        % Intermediary downsampling
        envelope = resample(envelope, params.intermediateSampleRate, Fs_work);
        Fs_work = params.intermediateSampleRate;
        
        % Bandpass filter the envelope
        envelope = filtfilt(bpFilter.numerator, 1, envelope);
        
        % Downsample to ultimate frequency
        downsamplefactor = Fs_work / params.targetSampleRate;
        if round(downsamplefactor) ~= downsamplefactor
            error('Downsample factor is not integer');
        end
        envelope = downsample(envelope, downsamplefactor);
        
        all_channel_envelopes{ch} = envelope;
    end
    
    % Combine envelopes and save
    % Create combined envelope matrix for all channels
    envelope_multichannel = combine_channel_envelopes(all_channel_envelopes, config_data);
    
    % Subband weights (uniform for now, could be optimized per channel)
    if params.subbandenvelopes && ~isempty(g)
        subband_weights = ones(1, size(envelope_multichannel, 2));
    else
        subband_weights = ones(1, size(envelope_multichannel, 2));
    end
    
    % Save multichannel envelopes
    envelope = envelope_multichannel; % For compatibility with original format
    Fs = params.targetSampleRate;
    save(fullfile(envelopedir, [params.envelopemethod params.subbandtag ' ' stimuliname]), ...
         'envelope', 'Fs', 'subband_weights', 'config_data');
end

fprintf('Multichannel envelope extraction completed!\n');
fprintf('Results saved to: %s\n', envelopedir);

end

function envelope_combined = combine_channel_envelopes(all_channel_envelopes, config_data)
% Combine envelopes from different channels

num_channels = length(all_channel_envelopes);
active_channels = [];
max_length = 0;
num_subbands = 0;

% Find active channels and determine dimensions
for ch = 1:num_channels
    if ~isempty(all_channel_envelopes{ch})
        active_channels = [active_channels, ch];
        max_length = max(max_length, size(all_channel_envelopes{ch}, 1));
        num_subbands = max(num_subbands, size(all_channel_envelopes{ch}, 2));
    end
end

if isempty(active_channels)
    error('No active channels found');
end

% Strategy 1: Concatenate all channel envelopes (for comprehensive analysis)
total_features = length(active_channels) * num_subbands;
envelope_combined = zeros(max_length, total_features);

feature_idx = 1;
for ch_idx = 1:length(active_channels)
    ch = active_channels(ch_idx);
    env = all_channel_envelopes{ch};
    
    if ~isempty(env)
        % Pad if necessary
        if size(env, 1) < max_length
            env = [env; zeros(max_length - size(env, 1), size(env, 2))];
        end
        
        % Place in combined matrix
        end_idx = feature_idx + size(env, 2) - 1;
        envelope_combined(:, feature_idx:end_idx) = env;
        feature_idx = end_idx + 1;
    end
end

% Optional: Add spatial-specific processing
envelope_combined = add_spatial_features(envelope_combined, active_channels, config_data);

end

function envelope_enhanced = add_spatial_features(envelope_combined, active_channels, config_data)
% Add spatial-specific features for AAD analysis

envelope_enhanced = envelope_combined;

% If we have competing channels, add contrast features
if length(active_channels) >= 2
    % Find the two most energetic channels (primary competitors)
    channel_energies = zeros(1, length(active_channels));
    subbands_per_channel = size(envelope_combined, 2) / length(active_channels);
    
    for i = 1:length(active_channels)
        start_idx = (i-1) * subbands_per_channel + 1;
        end_idx = i * subbands_per_channel;
        channel_envelope = envelope_combined(:, start_idx:end_idx);
        channel_energies(i) = mean(sum(channel_envelope.^2, 2));
    end
    
    [~, sorted_idx] = sort(channel_energies, 'descend');
    
    if length(sorted_idx) >= 2
        % Extract primary competing envelopes
        ch1_idx = sorted_idx(1);
        ch2_idx = sorted_idx(2);
        
        start1 = (ch1_idx-1) * subbands_per_channel + 1;
        end1 = ch1_idx * subbands_per_channel;
        start2 = (ch2_idx-1) * subbands_per_channel + 1;
        end2 = ch2_idx * subbands_per_channel;
        
        env1 = envelope_combined(:, start1:end1);
        env2 = envelope_combined(:, start2:end2);
        
        % Add contrast features (difference and ratio)
        contrast_features = abs(env1 - env2); % Difference
        ratio_features = env1 ./ (env2 + eps); % Ratio (avoid division by zero)
        
        % Append spatial features
        envelope_enhanced = [envelope_enhanced, contrast_features, ratio_features];
    end
end

end

function [ BP_equirip ] = construct_bpfilter( params )
% Construct bandpass filter (from original preprocessing)

Fs = params.intermediateSampleRate;
Fst1 = params.highpass-0.45;
Fp1 = params.highpass+0.45;
Fp2 = params.lowpass-0.45;
Fst2 = params.lowpass+0.45;
Ast1 = 20; %attenuation in dB
Ap = 0.5;
Ast2 = 15;
BP = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2,Fs);
BP_equirip = design(BP,'equiripple');

end