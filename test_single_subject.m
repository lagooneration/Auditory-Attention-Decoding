function test_single_subject(basedir, subject_file)
% TEST_SINGLE_SUBJECT Test preprocessing with a single subject file
% Usage: test_single_subject('p:\Research\AAD', 'S1.mat')

if nargin < 1
    basedir = pwd;
end
if nargin < 2
    subject_file = 'S1.mat';
end

%% Auto-setup AMToolbox if available locally
fprintf('Setting up AMToolbox...\n');
local_amtoolbox = fullfile(basedir, 'amtoolbox');
global_amtoolbox = 'C:/MATLAB/amtoolbox';

if exist(local_amtoolbox, 'dir')
    fprintf('Using local AMToolbox: %s\n', local_amtoolbox);
    addpath(genpath(local_amtoolbox));
elseif exist(global_amtoolbox, 'dir')
    fprintf('Using global AMToolbox: %s\n', global_amtoolbox);
    addpath(genpath(global_amtoolbox));
else
    error('AMToolbox not found. Please run setup_local_amtoolbox first.');
end

% Try to initialize AMToolbox
try
    amt_start;
    fprintf('AMToolbox initialized successfully.\n');
catch ME
    fprintf('AMToolbox initialization failed: %s\n', ME.message);
    fprintf('Attempting workaround...\n');
    
    % Try alternative initialization methods
    try
        % Method 1: Try amt_init if it exists
        if exist('amt_init', 'file')
            amt_init;
            fprintf('AMToolbox initialized using amt_init.\n');
        else
            fprintf('Continuing without initialization - AMToolbox functions should still work.\n');
        end
    catch ME2
        fprintf('Alternative initialization also failed: %s\n', ME2.message);
        fprintf('Continuing without initialization - testing if functions work...\n');
    end
end

% Test if key functions are available even without proper initialization
fprintf('Testing if AMToolbox functions are accessible...\n');
try
    % Quick test of critical functions
    test_freqs = erbspacebw(100, 1000, 1.0);
    fprintf('✓ erbspacebw works (generated %d frequencies)\n', length(test_freqs));
catch ME
    error('AMToolbox functions not accessible. Error: %s\nPlease check your AMToolbox installation.', ME.message);
end

stimulusdir = [basedir filesep 'stimuli'];
envelopedir = [stimulusdir filesep 'envelopes'];
if ~exist(envelopedir,'dir')
    mkdir(envelopedir);
end

% Set parameters (same as original)
params.intermediatefs_audio = 8000; %Hz
params.envelopemethod = 'powerlaw';
params.subbandenvelopes = true;
params.subbandtag = ' subbands'; %if broadband, set to empty string: '';
params.spacing = 1.5;
params.freqs = erbspacebw(150,4000,params.spacing); % gammatone filter centerfrequencies

% Debug: Check dimensions and fix betamul
fprintf('Debug: params.freqs dimensions: %dx%d\n', size(params.freqs,1), size(params.freqs,2));
fprintf('Debug: params.freqs contains %d frequencies\n', length(params.freqs));

% Ensure freqs is a column vector and betamul matches its dimensions
params.freqs = params.freqs(:); % Force column vector
params.betamul = params.spacing * ones(size(params.freqs)); % multiplier for gammatone filter bandwidths

fprintf('Debug: After fixing - params.freqs dimensions: %dx%d\n', size(params.freqs,1), size(params.freqs,2));
fprintf('Debug: params.betamul dimensions: %dx%d\n', size(params.betamul,1), size(params.betamul,2));

params.power = 0.6; % Powerlaw envelopes
params.intermediateSampleRate = 128; %Hz
params.lowpass = 9; % Hz, used for constructing a bpfilter used for both the audio and the eeg
params.highpass = 1; % Hz
params.targetSampleRate = 32; % Hz
params.rereference = 'Cz';

% Build the bandpass filter
bpFilter = construct_bpfilter(params);

% Create gammatone filters with proper error handling
fprintf('Creating gammatone filterbank...\n');
try
    g = gammatonefir(params.freqs,params.intermediatefs_audio,[],params.betamul,'real'); % create real, FIR gammatone filters.
    fprintf('✓ Gammatone filterbank created successfully with %d filters\n', size(g,2));
catch ME
    fprintf('Error creating gammatone filterbank: %s\n', ME.message);
    fprintf('Attempting alternative approach...\n');
    
    % Try with simplified parameters
    try
        % Use default betamul if there's a dimension issue
        g = gammatonefir(params.freqs, params.intermediatefs_audio);
        fprintf('✓ Gammatone filterbank created with default parameters\n');
    catch ME2
        fprintf('Alternative approach also failed: %s\n', ME2.message);
        
        % Try with explicit column vectors
        freqs_col = params.freqs(:);
        betamul_col = params.spacing * ones(length(freqs_col), 1);
        
        try
            g = gammatonefir(freqs_col, params.intermediatefs_audio, [], betamul_col, 'real');
            fprintf('✓ Gammatone filterbank created with explicit column vectors\n');
        catch ME3
            error('Failed to create gammatone filterbank. Error: %s', ME3.message);
        end
    end
end

%% First, check if audio files exist and preprocess them
stimulinames = list_stimuli();
nOfStimuli = length(stimulinames);

fprintf('Checking for audio files in: %s\n', stimulusdir);
missing_files = {};
for i = 1:nOfStimuli
    [~,stimuliname,stimuliext] = fileparts(stimulinames{i});
    audio_file = [stimulusdir filesep stimuliname stimuliext];
    if ~exist(audio_file, 'file')
        missing_files{end+1} = stimulinames{i};
    end
end

if ~isempty(missing_files)
    fprintf('WARNING: Missing audio files:\n');
    for i = 1:length(missing_files)
        fprintf('  %s\n', missing_files{i});
    end
    fprintf('You can create dummy audio files for testing.\n');
    create_dummy = input('Create dummy audio files for testing? (y/n): ', 's');
    if strcmpi(create_dummy, 'y')
        create_dummy_audio_files(stimulusdir, missing_files);
    else
        error('Cannot proceed without audio files');
    end
end

% Preprocess audio files
fprintf('Preprocessing audio files...\n');
for i = 1:nOfStimuli
    [~,stimuliname,stimuliext] = fileparts(stimulinames{i});
    [audio,Fs] = audioread([stimulusdir filesep stimuliname stimuliext]);
    
    % resample to 8kHz 
    audio = resample(audio,params.intermediatefs_audio,Fs); 
    Fs = params.intermediatefs_audio;
    
    % Compute envelope
    if params.subbandenvelopes
        audio = real(ufilterbank(audio,g,1));
        audio = reshape(audio,size(audio,1),[]); 
    end
    
    % apply the powerlaw
    envelope = abs(audio).^params.power;
    
    % Intermediary downsampling of envelope before applying the more strict bpfilters
    envelope = resample(envelope,params.intermediateSampleRate,Fs);
    Fs = params.intermediateSampleRate;
    
    % bandpassfilter the envelope
    envelope = filtfilt(bpFilter.numerator,1,envelope);
    
    % Downsample to ultimate frequency
    downsamplefactor = Fs/params.targetSampleRate;
    if round(downsamplefactor)~= downsamplefactor, error('Downsamplefactor is not integer'); end
    envelope = downsample(envelope,downsamplefactor);
    Fs = params.targetSampleRate;
    
    subband_weights = ones(1,size(envelope,2));
    % store as .mat files
    save([envelopedir filesep params.envelopemethod params.subbandtag ' ' stimuliname],'envelope','Fs','subband_weights');
    fprintf('  Processed: %s\n', stimulinames{i});
end

%% Test with single subject
preprocdir = [basedir filesep 'preprocessed_data'];
if ~exist(preprocdir,'dir')
    mkdir(preprocdir)
end

% Check if subject file exists
subject_path = fullfile(basedir, subject_file);
if ~exist(subject_path, 'file')
    error('Subject file %s not found in %s', subject_file, basedir);
end

fprintf('Processing subject: %s\n', subject_file);
loaded_data = load(subject_path);

if ~isfield(loaded_data, 'trials')
    error('Variable "trials" not found in %s. Check the structure of your subject file.', subject_file);
end

trials = loaded_data.trials;
postfix = '_dry.mat';
preproc_trials = {};

for trialnum = 1: size(trials,2)
    fprintf('  Processing trial %d/%d\n', trialnum, size(trials,2));
    
    trial = trials{trialnum};
    
    % Rereference the EEG data if necessary
    if strcmpi(params.rereference,'Cz')
        trial.RawData.EegData = trial.RawData.EegData - repmat(trial.RawData.EegData(:,48),[1,64]);
    elseif strcmpi(params.rereference,'mean')
        trial.RawData.EegData = trial.RawData.EegData - repmat(mean(trial.RawData.EegData,2),[1,64]);
    end
    
    % Apply the bandpass filter
    trial.RawData.EegData = filtfilt(bpFilter.numerator,1,double(trial.RawData.EegData));
    trial.RawData.HighPass = params.highpass;
    trial.RawData.LowPass = params.lowpass;
    trial.RawData.bpFilter = bpFilter;
    
    % downsample EEG
    downsamplefactor = trial.FileHeader.SampleRate/params.targetSampleRate;
    if round(downsamplefactor)~= downsamplefactor, error('Downsamplefactor is not integer'); end
    trial.RawData.EegData = downsample(trial.RawData.EegData,downsamplefactor);
    trial.FileHeader.SampleRate = params.targetSampleRate;
    
    % Load the correct stimuli, truncate to the length of EEG
    if trial.repetition
        stimname_len = 16; 
    else 
        stimname_len = 12;
    end % rep_partX_trackX or partX_trackX
    
    %LEFT ear
    left_envelope_file = [envelopedir filesep params.envelopemethod params.subbandtag ' ' trial.stimuli{1}(1:stimname_len) postfix];
    fprintf('    Loading left ear envelope: %s\n', left_envelope_file);
    left_data = load(left_envelope_file, 'envelope', 'subband_weights');
    left = left_data.envelope(1:length(trial.RawData.EegData),:);
    
    %RIGHT ear
    right_envelope_file = [envelopedir filesep params.envelopemethod params.subbandtag ' ' trial.stimuli{2}(1:stimname_len) postfix];
    fprintf('    Loading right ear envelope: %s\n', right_envelope_file);
    right_data = load(right_envelope_file, 'envelope', 'subband_weights');
    right = right_data.envelope(1:length(trial.RawData.EegData),:);
    
    trial.Envelope.AudioData = cat(3,left, right);
    trial.Envelope.subband_weights = left_data.subband_weights;
    
    preproc_trials{trialnum} = trial;
end

output_file = fullfile(preprocdir, subject_file);
save(output_file,'preproc_trials')
fprintf('Successfully processed and saved: %s\n', output_file);

end

function create_dummy_audio_files(stimulusdir, missing_files)
% Create dummy audio files for testing
fprintf('Creating dummy audio files...\n');
for i = 1:length(missing_files)
    [~,filename,ext] = fileparts(missing_files{i});
    filepath = fullfile(stimulusdir, [filename ext]);
    
    % Create 10 seconds of white noise at 44.1kHz
    fs = 44100;
    duration = 10; % seconds
    dummy_audio = 0.1 * randn(fs * duration, 1); % Low amplitude white noise
    
    audiowrite(filepath, dummy_audio, fs);
    fprintf('  Created: %s\n', missing_files{i});
end
end

function [ stimulinames ] = list_stimuli()
%List of stimuli names

stimulinames = {};

for experiment = [1 3]
    for track = 1:2
        if experiment == 1 % experiment 3 uses the same stimuli, but the attention of the listener is switched
            no_parts = 4;
            rep = false;
        elseif experiment ==3
            no_parts = 4;
            rep = true;
        end
        
        for part = 1:no_parts
            stimulinames =[stimulinames; {gen_stimuli_names(part,track,rep)}];
        end
    end
end
end

function [ filename ] = gen_stimuli_names(part,track,rep)
%Generates filename for audio stimuli

assert(islogical(rep));
assert(isnumeric(part));
assert(any(track == [1 2]));


part_tag = ['part' num2str(part)];
track_tag = ['track' num2str(track)];

cond_tag = 'dry';
extension = '.wav';

if rep == true
    rep_tag = 'rep';
elseif rep == false
    rep_tag = '';
end

separator = '_';
filename = [rep_tag separator part_tag separator track_tag separator cond_tag extension];
filename = regexprep(filename,[separator '+'],separator); %remove multiple underscores
filename = regexprep(filename,['^' separator],''); %remove starting underscore

end

function [ BP_equirip ] = construct_bpfilter( params )

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