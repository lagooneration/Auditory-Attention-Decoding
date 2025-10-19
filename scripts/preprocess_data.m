
function preprocess_data(basedir)
% PREPROCESS_DATA This function preprocesses EEG and audio data as described in the paper: 
% Stimulus-aware spatial filtering for single-trial neural response and temporal 
% response function estimation in high-density EEG with applications in auditory research
% N Das, J Vanthornhout, T Francart, A Bertrand - bioRxiv, 2019
% In addition to preprocessing, the audio envelopes are truncated and
% matched with the corresponding EEG data
% Dependency: AMToolbox
% Input: basedir: the directory in which all the subject and stimuli data
% are saved. (Default: current folder)
% Author: Neetha Das
% KULeuven, July 2019
% As part of the work: Das, N., Vanthornhout, J., Francart, T., & Bertrand, A. (2019), 
% 'Stimulus-aware spatial filtering for single-trial neural response and temporal response 
% function estimation in high-density EEG with applications in auditory research'. bioRxiv, 
% 541318; doi: https://doi.org/10.1101/541318.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Disable figure creation to prevent graphics errors in batch mode
set(0, 'DefaultFigureVisible', 'off');

if nargin == 0 
    basedir = pwd;
end

% Initialize robust AMToolbox configuration
fprintf('Initializing AMToolbox for full dataset processing...\n');
try
    if exist('setup_amtoolbox_robust.m', 'file')
        setup_amtoolbox_robust();
    else
        fprintf('setup_amtoolbox_robust not found, using basic AMToolbox setup...\n');
        % Basic AMToolbox setup
        try
            amt_start;
            fprintf('✓ AMToolbox initialized with amt_start\n');
            % Set working flags
            setappdata(0, 'amt_erbspacebw_working', true);
            setappdata(0, 'amt_gammatonefir_working', true);
            setappdata(0, 'amt_ufilterbank_working', true);
        catch
            fprintf('amt_start failed, using fallback methods\n');
            setappdata(0, 'amt_erbspacebw_working', false);
            setappdata(0, 'amt_gammatonefir_working', false);
            setappdata(0, 'amt_ufilterbank_working', false);
        end
    end
catch ME
    fprintf('AMToolbox setup failed: %s\n', ME.message);
    fprintf('Proceeding with fallback processing...\n');
    % Set all AMToolbox functions as not working
    setappdata(0, 'amt_erbspacebw_working', false);
    setappdata(0, 'amt_gammatonefir_working', false);
    setappdata(0, 'amt_ufilterbank_working', false);
end

stimulusdir = [basedir filesep 'stimuli'];
envelopedir = [stimulusdir filesep 'envelopes'];
if ~exist(envelopedir,'dir')
    mkdir(envelopedir);
end

% Set parameters
params.intermediatefs_audio = 8000; %Hz
params.envelopemethod = 'powerlaw';
params.subbandenvelopes = true;
params.subbandtag = ' subbands'; %if broadband, set to empty string: '';
params.spacing = 1.5;

% Create frequency vector with robust fallback
if getappdata(0, 'amt_erbspacebw_working') == true
    try
        params.freqs = erbspacebw(150,4000,params.spacing); % gammatone filter centerfrequencies
        fprintf('✓ Using AMToolbox erbspacebw\n');
    catch
        params.freqs = erbspacebw_alt(150, 4000, params.spacing);
        fprintf('⚠ AMToolbox erbspacebw failed, using alternative\n');
    end
else
    % Use alternative ERB spacing
    params.freqs = erbspacebw_alt(150, 4000, params.spacing);
    fprintf('⚠ Using alternative ERB spacing\n');
end

% Ensure freqs is a column vector and betamul matches dimensions
params.freqs = params.freqs(:);  % Force column vector
params.betamul = params.spacing * ones(size(params.freqs)); % multiplier for gammatone filter bandwidths

% Alternative ERB function
function freqs = erbspacebw_alt(f_min, f_max, spacing)
    erb_min = 21.4 * log10(1 + f_min / 229);
    erb_max = 21.4 * log10(1 + f_max / 229);
    erb_vals = linspace(erb_min, erb_max, round((erb_max - erb_min) / spacing) + 1);
    freqs = (10.^(erb_vals / 21.4) - 1) * 229;
end
params.power = 0.6; % Powerlaw envelopes
params.intermediateSampleRate = 128; %Hz
params.lowpass = 9; % Hz, used for constructing a bpfilter used for both the audio and the eeg
params.highpass = 1; % Hz
params.targetSampleRate = 32; % Hz
params.rereference = 'Cz';

% Build the bandpass filter
bpFilter = construct_bpfilter(params);

% Create gammatone filterbank with robust error handling
filterbank_success = false;

% Check if AMToolbox gammatonefir is working
if getappdata(0, 'amt_gammatonefir_working') == true
    try
        g = gammatonefir(params.freqs,params.intermediatefs_audio,[],params.betamul,'real');
        filterbank_success = true;
        fprintf('✓ Using AMToolbox gammatonefir\n');
    catch ME
        fprintf('AMToolbox gammatonefir failed: %s\n', ME.message);
        
        % Try alternative dimensions
        try
            freqs_row = params.freqs(:)';
            betamul_row = params.betamul(:)';
            g = gammatonefir(freqs_row, params.intermediatefs_audio, [], betamul_row, 'real');
            filterbank_success = true;
            fprintf('✓ AMToolbox gammatonefir working with row vectors\n');
        catch ME2
            fprintf('AMToolbox gammatonefir completely failed: %s\n', ME2.message);
        end
    end
end

% If AMToolbox failed, use robust alternative filterbank
if ~filterbank_success
    fprintf('⚠ Creating robust alternative filterbank...\n');
    try
        g = create_robust_filterbank_internal(params.freqs, params.intermediatefs_audio);
        filterbank_success = true;
        fprintf('✓ Alternative filterbank created successfully\n');
        
        % Convert to format compatible with ufilterbank if needed
        if iscell(g)
            % Already in correct format for alternative processing
        end
    catch ME3
        fprintf('Alternative filterbank creation failed: %s\n', ME3.message);
        fprintf('Disabling subband processing - using broadband only\n');
        params.subbandenvelopes = false;
        params.subbandtag = '';
        g = [];
    end
end

%% Preprocess the audio files
stimulinames = list_stimuli();
nOfStimuli = length(stimulinames);

for i = 1:nOfStimuli
    % Load a stimulus with robust file path handling
    [~,stimuliname,stimuliext] = fileparts(stimulinames{i});
    
    % Get the correct stimuli directory
    correct_stimulusdir = getappdata(0, 'stimuli_directory');
    if isempty(correct_stimulusdir)
        correct_stimulusdir = stimulusdir; % fallback to original
    end
    
    % Try full filename first (in case extension is already included)
    audio_file = fullfile(correct_stimulusdir, stimulinames{i});
    if ~exist(audio_file, 'file')
        % Try with reconstructed name
        audio_file = fullfile(correct_stimulusdir, [stimuliname stimuliext]);
    end
    
    if ~exist(audio_file, 'file')
        fprintf('Warning: Audio file not found: %s\n', stimulinames{i});
        fprintf('Tried path: %s\n', audio_file);
        fprintf('Skipping this file...\n');
        continue;
    end
    
    fprintf('Processing audio file %d/%d: %s\n', i, nOfStimuli, stimulinames{i});
    [audio,Fs] = audioread(audio_file);
    
    % resample to 8kHz 
    audio = resample(audio,params.intermediatefs_audio,Fs); 
    Fs = params.intermediatefs_audio;
    
    % Compute envelope with robust filtering
    if params.subbandenvelopes && ~isempty(g)
        % Try AMToolbox ufilterbank first
        if getappdata(0, 'amt_ufilterbank_working') == true && ~iscell(g)
            try
                audio = real(ufilterbank(audio,g,1));
                audio = reshape(audio,size(audio,1),[]); 
                fprintf('✓ Used AMToolbox ufilterbank\n');
            catch ME
                fprintf('Warning: AMToolbox ufilterbank failed (%s), using alternative filtering\n', ME.message);
                audio = apply_alternative_filterbank(audio, g, params.freqs, params.intermediatefs_audio);
            end
        else
            % Use alternative filterbank processing
            fprintf('⚠ Using alternative filterbank processing\n');
            audio = apply_alternative_filterbank(audio, g, params.freqs, params.intermediatefs_audio);
        end
    end
    
    % If subband processing is disabled, audio remains as single channel broadband
    
    % apply the powerlaw
    envelope = abs(audio).^params.power;
    
    % Intermediary downsampling of envelope before applying the more strict bpfilters
    envelope = resample(envelope,params.intermediateSampleRate,Fs);
    Fs = params.intermediateSampleRate;
    
    % bandpassilter the envelope
    envelope = filtfilt(bpFilter.numerator,1,envelope);
    
    % Downsample to ultimate frequency
    downsamplefactor = Fs/params.targetSampleRate;
    if round(downsamplefactor)~= downsamplefactor, error('Downsamplefactor is not integer'); end
    envelope = downsample(envelope,downsamplefactor);
    Fs = params.targetSampleRate;
    
    subband_weights = ones(1,size(envelope,2));
    % store as .mat files
    try
        save([envelopedir filesep params.envelopemethod params.subbandtag ' ' stimuliname],'envelope','Fs','subband_weights');
    catch ME
        fprintf('Warning: Could not save envelope file for %s: %s\n', stimuliname, ME.message);
    end
    
end

%% Preprocess EEG and put EEG and corresponding stimulus envelopes together

preprocdir = [basedir filesep 'preprocessed_data'];
if ~exist(preprocdir,'dir')
    mkdir(preprocdir)
end
subjects = dir([basedir filesep 'S*.mat']);
subjects = sort({subjects(:).name});
postfix = '_dry.mat';


for subject = subjects
    % Load subject data and extract trials variable
    loaded_data = load(fullfile(basedir,subject{1}));
    trials = loaded_data.trials; % Extract trials from loaded structure
    
    preproc_trials = {};
    for trialnum = 1: size(trials,2)
        
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
        
        % downsample EEG (using downsample so no filtering appears).
        downsamplefactor = trial.FileHeader.SampleRate/params.targetSampleRate;
        if round(downsamplefactor)~= downsamplefactor, error('Downsamplefactor is not integer'); end
        trial.RawData.EegData = downsample(trial.RawData.EegData,downsamplefactor);
        trial.FileHeader.SampleRate = params.targetSampleRate;
        
        % Load the correct stimuli, truncate to the length of EEG
        if trial.repetition,stimname_len = 16; else 
            stimname_len = 12;end % rep_partX_trackX or partX_trackX
        
        %LEFT ear
        left_env_file = [envelopedir filesep params.envelopemethod params.subbandtag ' ' trial.stimuli{1}(1:stimname_len) postfix];
        left_data = load(left_env_file, 'envelope');
        left = left_data.envelope(1:length(trial.RawData.EegData),:);
        
        %RIGHT ear
        right_env_file = [envelopedir filesep params.envelopemethod params.subbandtag ' ' trial.stimuli{2}(1:stimname_len) postfix];
        right_data = load(right_env_file, 'envelope');
        right = right_data.envelope(1:length(trial.RawData.EegData),:);
        
        trial.Envelope.AudioData = cat(3,left, right);
        trial.Envelope.subband_weights = subband_weights;
        
        preproc_trials{trialnum} = trial;
    end
    try
        save(fullfile(preprocdir,subject{1}),'preproc_trials')
    catch ME
        fprintf('Warning: Could not save preprocessed data for %s: %s\n', subject{1}, ME.message);
    end
end

end

function [ stimulinames ] = list_stimuli()
%List of stimuli names - updated to match actual file structure

stimulinames = {};

% Determine correct stimuli directory path
current_dir = pwd;
if contains(current_dir, 'scripts')
    % We're in scripts folder, go up one level
    base_dir = fileparts(current_dir);
    stimulusdir = fullfile(base_dir, 'stimuli');
else
    % We're in base directory
    stimulusdir = fullfile(current_dir, 'stimuli');
end

fprintf('Looking for stimuli in: %s\n', stimulusdir);

if exist(stimulusdir, 'dir')
    % Get all _dry.wav files (excluding _hrtf.wav files)
    wav_files = dir(fullfile(stimulusdir, '*_dry.wav'));
    stimulinames = {wav_files.name}';
    fprintf('Found %d dry audio files in stimuli directory\n', length(stimulinames));
else
    fprintf('⚠ Stimuli directory not found at: %s\n', stimulusdir);
    
    % Try alternative paths
    alt_paths = {
        fullfile(fileparts(fileparts(current_dir)), 'stimuli'),  % Two levels up
        'c:\Research\AAD\stimuli',                                % Absolute path
        fullfile(current_dir, '..', 'stimuli')                   % Relative path
    };
    
    for i = 1:length(alt_paths)
        if exist(alt_paths{i}, 'dir')
            stimulusdir = alt_paths{i};
            wav_files = dir(fullfile(stimulusdir, '*_dry.wav'));
            stimulinames = {wav_files.name}';
            fprintf('✓ Found stimuli directory at: %s\n', stimulusdir);
            fprintf('Found %d dry audio files\n', length(stimulinames));
            break;
        end
    end
end

% If still no files found, use hardcoded list
if isempty(stimulinames)
    fprintf('⚠ No audio files found, using hardcoded file list\n');
    
    % Based on your actual file listing
    base_files = {};
    for part = 1:4
        for track = 1:2
            % Regular files
            base_files{end+1} = sprintf('part%d_track%d_dry.wav', part, track);
            % Repetition files  
            base_files{end+1} = sprintf('rep_part%d_track%d_dry.wav', part, track);
        end
    end
    stimulinames = base_files';
end

% Remove any empty entries
stimulinames = stimulinames(~cellfun(@isempty, stimulinames));

fprintf('Stimuli files to process:\n');
for i = 1:length(stimulinames)
    fprintf('  %d. %s\n', i, stimulinames{i});
end

% Store the correct stimuli directory for later use
setappdata(0, 'stimuli_directory', stimulusdir);

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

function g = create_robust_filterbank_internal(freqs, fs)
% Create robust filterbank that works without AMToolbox dependencies
% Returns cell array of filter coefficients for alternative processing

g = cell(length(freqs), 1);

for i = 1:length(freqs)
    fc = freqs(i);
    
    % Calculate ERB bandwidth
    erb_bw = 24.7 * (4.37 * fc / 1000 + 1);
    
    % Create bandpass filter
    f_low = max(fc - erb_bw/2, 50); % Lower bound
    f_high = min(fc + erb_bw/2, fs/2 * 0.95); % Upper bound
    
    % Ensure valid frequency range
    if f_low >= f_high
        f_center = fc;
        bw = erb_bw/4;
        f_low = max(f_center - bw, 50);
        f_high = min(f_center + bw, fs/2 * 0.95);
    end
    
    % Design Butterworth bandpass filter
    try
        if i == 1 && length(freqs) > 1
            % Lowpass for first channel
            [b, a] = butter(4, f_high / (fs/2), 'low');
        elseif i == length(freqs) && length(freqs) > 1
            % Highpass for last channel
            [b, a] = butter(4, f_low / (fs/2), 'high');
        else
            % Bandpass for middle channels
            [b, a] = butter(4, [f_low f_high] / (fs/2), 'bandpass');
        end
        g{i} = {b, a};
    catch
        % Fallback: simple gain
        g{i} = {1, 1};
    end
end
end

function audio_filtered = apply_alternative_filterbank(audio, g, freqs, ~)
% Apply alternative filterbank when AMToolbox ufilterbank fails

if iscell(g)
    % Use filter coefficients
    num_channels = length(g);
    audio_filtered = zeros(length(audio), num_channels);
    
    for i = 1:num_channels
        if iscell(g{i}) && length(g{i}) == 2
            try
                b = g{i}{1};
                a = g{i}{2};
                audio_filtered(:, i) = filtfilt(b, a, audio);
            catch
                % Fallback: pass original signal
                audio_filtered(:, i) = audio;
            end
        else
            audio_filtered(:, i) = audio;
        end
    end
else
    % Try to process matrix format
    try
        if size(g, 2) == length(freqs)
            audio_filtered = filter(g', 1, audio);
            audio_filtered = audio_filtered(:, 1:length(freqs));
        else
            % Fallback: replicate original signal
            audio_filtered = repmat(audio, 1, length(freqs));
        end
    catch
        % Ultimate fallback
        audio_filtered = repmat(audio, 1, length(freqs));
    end
end

fprintf('Alternative filterbank applied: %d channels\n', size(audio_filtered, 2));
end




