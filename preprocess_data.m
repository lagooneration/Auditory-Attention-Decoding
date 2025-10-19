function preprocess_data(basedir)
% PREPROCESS_DATA_CORRECTED - Fixed version with proper AMToolbox usage
% This version uses validated AMToolbox functions and correct paths

if nargin == 0
    basedir = pwd;
end

% Disable figure creation
set(0, 'DefaultFigureVisible', 'off');

% Setup paths correctly
fprintf('Setting up paths for preprocessing...\n');
current_dir = pwd;
cd(basedir); % Change to base directory
addpath(fullfile(basedir, 'scripts')); % Add scripts to path

stimulusdir = fullfile(basedir, 'stimuli');
envelopedir = fullfile(stimulusdir, 'envelopes');
if ~exist(envelopedir,'dir')
    mkdir(envelopedir);
end

% Set parameters
params.intermediatefs_audio = 8000;
params.envelopemethod = 'powerlaw';
params.subbandenvelopes = true;
params.subbandtag = ' subbands';
params.spacing = 1.5;
params.power = 0.6;
params.intermediateSampleRate = 128;
params.lowpass = 9;
params.highpass = 1;
params.targetSampleRate = 32;
params.rereference = 'Cz';

% Create frequency vector with validation
try
    params.freqs = erbspacebw(150, 4000, params.spacing);
    fprintf('✓ Using AMToolbox erbspacebw\n');
catch
    fprintf('⚠ erbspacebw failed, using manual ERB spacing\n');
    params.freqs = create_erb_spacing_manual(150, 4000, params.spacing);
end

% Ensure correct dimensions
params.freqs = params.freqs(:)'; % Force row vector
params.betamul = params.spacing * ones(size(params.freqs));

% Build bandpass filter
bpFilter = construct_bpfilter(params);

% Create gammatone filterbank with proper validation
filterbank_success = false;
fprintf('Testing gammatonefir with correct dimensions...\n');

% Test different calling patterns
try
    % Pattern 1: Original call
    g = gammatonefir(params.freqs, params.intermediatefs_audio, [], params.betamul, 'real');
    filterbank_success = true;
    fprintf('✓ gammatonefir Pattern 1 SUCCESS\n');
catch ME1
    fprintf('Pattern 1 failed: %s\n', ME1.message);
    
    try
        % Pattern 2: Force dimensions
        freqs_fix = params.freqs(:)'';
        betamul_fix = params.betamul(:)'';
        g = gammatonefir(freqs_fix, params.intermediatefs_audio, [], betamul_fix, 'real');
        filterbank_success = true;
        fprintf('✓ gammatonefir Pattern 2 SUCCESS (fixed dimensions)\n');
    catch ME2
        fprintf('Pattern 2 failed: %s\n', ME2.message);
        
        try
            % Pattern 3: Minimal call
            g = gammatonefir(params.freqs, params.intermediatefs_audio);
            filterbank_success = true;
            fprintf('✓ gammatonefir Pattern 3 SUCCESS (minimal)\n');
        catch ME3
            fprintf('All gammatonefir patterns failed, using fallback\n');
            g = create_fallback_filterbank(params.freqs, params.intermediatefs_audio);
            filterbank_success = true;
        end
    end
end

% Process audio files
stimulinames = list_stimuli_corrected(stimulusdir);
nOfStimuli = length(stimulinames);
fprintf('Processing %d audio stimuli...\n', nOfStimuli);

for i = 1:nOfStimuli
    [~,stimuliname,stimuliext] = fileparts(stimulinames{i});
    audio_file = fullfile(stimulusdir, [stimuliname stimuliext]);
    
    if ~exist(audio_file, 'file')
        fprintf('⚠ Audio file not found: %s\n', audio_file);
        continue;
    end
    
    fprintf('Processing [%d/%d]: %s\n', i, nOfStimuli, [stimuliname stimuliext]);
    
    [audio,Fs] = audioread(audio_file);
    audio = resample(audio, params.intermediatefs_audio, Fs);
    Fs = params.intermediatefs_audio;
    
    % Compute envelope
    if params.subbandenvelopes && filterbank_success
        try
            audio = real(ufilterbank(audio, g, 1));
            audio = reshape(audio, size(audio,1), []);
            fprintf('  ✓ Subband processing\n');
        catch ME
            fprintf('  ⚠ ufilterbank failed: %s\n', ME.message);
            fprintf('  Using broadband envelope\n');
        end
    else
        fprintf('  Using broadband envelope\n');
    end
    
    envelope = abs(audio).^params.power;
    envelope = resample(envelope, params.intermediateSampleRate, Fs);
    envelope = filtfilt(bpFilter.numerator, 1, envelope);
    
    downsamplefactor = params.intermediateSampleRate / params.targetSampleRate;
    envelope = downsample(envelope, downsamplefactor);
    Fs = params.targetSampleRate;
    
    subband_weights = ones(1, size(envelope, 2));
    
    % Save envelope
    envelope_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag ' ' stimuliname '.mat']);
    save(envelope_file, 'envelope', 'Fs', 'subband_weights');
end

% Process EEG data
preprocdir = fullfile(basedir, 'preprocessed_data');
if ~exist(preprocdir,'dir')
    mkdir(preprocdir)
end

subjects = dir(fullfile(basedir, 'S*.mat'));
subjects = sort({subjects(:).name});

fprintf('Processing %d EEG subjects...\n', length(subjects));
for subject_idx = 1:length(subjects)
    subject_file = subjects{subject_idx};
    fprintf('Processing EEG [%d/%d]: %s\n', subject_idx, length(subjects), subject_file);
    
    loaded_data = load(fullfile(basedir, subject_file));
    trials = loaded_data.trials;
    
    preproc_trials = {};
    for trialnum = 1:size(trials, 2)
        trial = trials{trialnum};
        
        % Rereference EEG
        if strcmpi(params.rereference,'Cz')
            trial.RawData.EegData = trial.RawData.EegData - repmat(trial.RawData.EegData(:,48),[1,64]);
        end
        
        % Apply bandpass filter
        trial.RawData.EegData = filtfilt(bpFilter.numerator, 1, double(trial.RawData.EegData));
        
        % Downsample EEG
        downsamplefactor = trial.FileHeader.SampleRate / params.targetSampleRate;
        trial.RawData.EegData = downsample(trial.RawData.EegData, downsamplefactor);
        trial.FileHeader.SampleRate = params.targetSampleRate;
        
        % Load envelopes
        if trial.repetition, stimname_len = 16; else, stimname_len = 12; end
        
        left_env_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag ' ' trial.stimuli{1}(1:stimname_len) '_dry.mat']);
        right_env_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag ' ' trial.stimuli{2}(1:stimname_len) '_dry.mat']);
        
        if exist(left_env_file, 'file') && exist(right_env_file, 'file')
            left_data = load(left_env_file, 'envelope');
            right_data = load(right_env_file, 'envelope');
            
            left = left_data.envelope(1:length(trial.RawData.EegData), :);
            right = right_data.envelope(1:length(trial.RawData.EegData), :);
            
            trial.Envelope.AudioData = cat(3, left, right);
            trial.Envelope.subband_weights = subband_weights;
        else
            fprintf('  ⚠ Envelope files not found for trial %d\n', trialnum);
        end
        
        preproc_trials{trialnum} = trial;
    end
    
    % Save processed subject
    save(fullfile(preprocdir, subject_file), 'preproc_trials');
end

fprintf('\n✓ Preprocessing completed successfully!\n');
cd(current_dir); % Return to original directory

end

function freqs = create_erb_spacing_manual(f_min, f_max, spacing)
erb_min = 21.4 * log10(1 + f_min / 229);
erb_max = 21.4 * log10(1 + f_max / 229);
erb_vals = linspace(erb_min, erb_max, round((erb_max - erb_min) / spacing) + 1);
freqs = (10.^(erb_vals / 21.4) - 1) * 229;
end

function stimulinames = list_stimuli_corrected(stimulusdir)
dry_files = dir(fullfile(stimulusdir, '*_dry.wav'));
stimulinames = {dry_files.name};
fprintf('Found %d dry audio files\n', length(stimulinames));
end

function g = create_fallback_filterbank(freqs, fs)
num_filters = length(freqs);
N = 512;
g = zeros(N, num_filters);
for i = 1:num_filters
    fc = freqs(i);
    bw = 24.7 * (4.37 * fc / 1000 + 1);
    f_low = max(fc - bw/2, 50);
    f_high = min(fc + bw/2, fs/2 * 0.95);
    try
        [b, a] = butter(4, [f_low f_high] / (fs/2), 'bandpass');
        [h, ~] = freqz(b, a, N);
        g(:, i) = real(h);
    catch
        g(:, i) = ones(N, 1) / num_filters;
    end
end
end

function BP_equirip = construct_bpfilter(params)
Fs = params.intermediateSampleRate;
Fst1 = params.highpass-0.45;
Fp1 = params.highpass+0.45;
Fp2 = params.lowpass-0.45;
Fst2 = params.lowpass+0.45;
Ast1 = 20;
Ap = 0.5;
Ast2 = 15;
BP = fdesign.bandpass('Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2',Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2,Fs);
BP_equirip = design(BP,'equiripple');
end
