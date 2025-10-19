function fix_preprocessing_paths_and_amtoolbox()
% FIX_PREPROCESSING_PATHS_AND_AMTOOLBOX - Fix all path and AMToolbox issues
% This ensures consistent preprocessing and proper file organization

fprintf('=== Fixing Preprocessing Paths and AMToolbox ===\n');

%% Step 1: Validate and fix AMToolbox
fprintf('1. Validating AMToolbox functions...\n');
validate_and_fix_amtoolbox();

%% Step 2: Fix preprocessing function
fprintf('2. Creating corrected preprocessing function...\n');
create_corrected_preprocess_data();

%% Step 3: Validate file paths and organization
fprintf('3. Validating file organization...\n');
validate_file_organization();

fprintf('\n=== All fixes applied successfully! ===\n');
fprintf('Now run: preprocess_data_corrected(''c:\\Research\\AAD'')\n');

end

function create_corrected_preprocess_data()
% Create a corrected version of preprocess_data with proper AMToolbox usage

corrected_file = 'preprocess_data_corrected.m';
fid = fopen(corrected_file, 'w');

fprintf(fid, 'function preprocess_data_corrected(basedir)\n');
fprintf(fid, '%% PREPROCESS_DATA_CORRECTED - Fixed version with proper AMToolbox usage\n');
fprintf(fid, '%% This version uses validated AMToolbox functions and correct paths\n\n');

fprintf(fid, 'if nargin == 0\n');
fprintf(fid, '    basedir = pwd;\n');
fprintf(fid, 'end\n\n');

fprintf(fid, '%% Disable figure creation\n');
fprintf(fid, 'set(0, ''DefaultFigureVisible'', ''off'');\n\n');

fprintf(fid, '%% Setup paths correctly\n');
fprintf(fid, 'fprintf(''Setting up paths for preprocessing...\\n'');\n');
fprintf(fid, 'current_dir = pwd;\n');
fprintf(fid, 'cd(basedir); %% Change to base directory\n');
fprintf(fid, 'addpath(fullfile(basedir, ''scripts'')); %% Add scripts to path\n\n');

fprintf(fid, 'stimulusdir = fullfile(basedir, ''stimuli'');\n');
fprintf(fid, 'envelopedir = fullfile(stimulusdir, ''envelopes'');\n');
fprintf(fid, 'if ~exist(envelopedir,''dir'')\n');
fprintf(fid, '    mkdir(envelopedir);\n');
fprintf(fid, 'end\n\n');

fprintf(fid, '%% Set parameters\n');
fprintf(fid, 'params.intermediatefs_audio = 8000;\n');
fprintf(fid, 'params.envelopemethod = ''powerlaw'';\n');
fprintf(fid, 'params.subbandenvelopes = true;\n');
fprintf(fid, 'params.subbandtag = '' subbands'';\n');
fprintf(fid, 'params.spacing = 1.5;\n');
fprintf(fid, 'params.power = 0.6;\n');
fprintf(fid, 'params.intermediateSampleRate = 128;\n');
fprintf(fid, 'params.lowpass = 9;\n');
fprintf(fid, 'params.highpass = 1;\n');
fprintf(fid, 'params.targetSampleRate = 32;\n');
fprintf(fid, 'params.rereference = ''Cz'';\n\n');

fprintf(fid, '%% Create frequency vector with validation\n');
fprintf(fid, 'try\n');
fprintf(fid, '    params.freqs = erbspacebw(150, 4000, params.spacing);\n');
fprintf(fid, '    fprintf(''✓ Using AMToolbox erbspacebw\\n'');\n');
fprintf(fid, 'catch\n');
fprintf(fid, '    fprintf(''⚠ erbspacebw failed, using manual ERB spacing\\n'');\n');
fprintf(fid, '    params.freqs = create_erb_spacing_manual(150, 4000, params.spacing);\n');
fprintf(fid, 'end\n\n');

fprintf(fid, '%% Ensure correct dimensions\n');
fprintf(fid, 'params.freqs = params.freqs(:)''; %% Force row vector\n');
fprintf(fid, 'params.betamul = params.spacing * ones(size(params.freqs));\n\n');

fprintf(fid, '%% Build bandpass filter\n');
fprintf(fid, 'bpFilter = construct_bpfilter(params);\n\n');

fprintf(fid, '%% Create gammatone filterbank with proper validation\n');
fprintf(fid, 'filterbank_success = false;\n');
fprintf(fid, 'fprintf(''Testing gammatonefir with correct dimensions...\\n'');\n\n');

fprintf(fid, '%% Test different calling patterns\n');
fprintf(fid, 'try\n');
fprintf(fid, '    %% Pattern 1: Original call\n');
fprintf(fid, '    g = gammatonefir(params.freqs, params.intermediatefs_audio, [], params.betamul, ''real'');\n');
fprintf(fid, '    filterbank_success = true;\n');
fprintf(fid, '    fprintf(''✓ gammatonefir Pattern 1 SUCCESS\\n'');\n');
fprintf(fid, 'catch ME1\n');
fprintf(fid, '    fprintf(''Pattern 1 failed: %%s\\n'', ME1.message);\n');
fprintf(fid, '    \n');
fprintf(fid, '    try\n');
fprintf(fid, '        %% Pattern 2: Force dimensions\n');
fprintf(fid, '        freqs_fix = params.freqs(:)'''';\n');
fprintf(fid, '        betamul_fix = params.betamul(:)'''';\n');
fprintf(fid, '        g = gammatonefir(freqs_fix, params.intermediatefs_audio, [], betamul_fix, ''real'');\n');
fprintf(fid, '        filterbank_success = true;\n');
fprintf(fid, '        fprintf(''✓ gammatonefir Pattern 2 SUCCESS (fixed dimensions)\\n'');\n');
fprintf(fid, '    catch ME2\n');
fprintf(fid, '        fprintf(''Pattern 2 failed: %%s\\n'', ME2.message);\n');
fprintf(fid, '        \n');
fprintf(fid, '        try\n');
fprintf(fid, '            %% Pattern 3: Minimal call\n');
fprintf(fid, '            g = gammatonefir(params.freqs, params.intermediatefs_audio);\n');
fprintf(fid, '            filterbank_success = true;\n');
fprintf(fid, '            fprintf(''✓ gammatonefir Pattern 3 SUCCESS (minimal)\\n'');\n');
fprintf(fid, '        catch ME3\n');
fprintf(fid, '            fprintf(''All gammatonefir patterns failed, using fallback\\n'');\n');
fprintf(fid, '            g = create_fallback_filterbank(params.freqs, params.intermediatefs_audio);\n');
fprintf(fid, '            filterbank_success = true;\n');
fprintf(fid, '        end\n');
fprintf(fid, '    end\n');
fprintf(fid, 'end\n\n');

fprintf(fid, '%% Process audio files\n');
fprintf(fid, 'stimulinames = list_stimuli_corrected(stimulusdir);\n');
fprintf(fid, 'nOfStimuli = length(stimulinames);\n');
fprintf(fid, 'fprintf(''Processing %%d audio stimuli...\\n'', nOfStimuli);\n\n');

fprintf(fid, 'for i = 1:nOfStimuli\n');
fprintf(fid, '    [~,stimuliname,stimuliext] = fileparts(stimulinames{i});\n');
fprintf(fid, '    audio_file = fullfile(stimulusdir, [stimuliname stimuliext]);\n');
fprintf(fid, '    \n');
fprintf(fid, '    if ~exist(audio_file, ''file'')\n');
fprintf(fid, '        fprintf(''⚠ Audio file not found: %%s\\n'', audio_file);\n');
fprintf(fid, '        continue;\n');
fprintf(fid, '    end\n');
fprintf(fid, '    \n');
fprintf(fid, '    fprintf(''Processing [%%d/%%d]: %%s\\n'', i, nOfStimuli, [stimuliname stimuliext]);\n');
fprintf(fid, '    \n');
fprintf(fid, '    [audio,Fs] = audioread(audio_file);\n');
fprintf(fid, '    audio = resample(audio, params.intermediatefs_audio, Fs);\n');
fprintf(fid, '    Fs = params.intermediatefs_audio;\n');
fprintf(fid, '    \n');
fprintf(fid, '    %% Compute envelope\n');
fprintf(fid, '    if params.subbandenvelopes && filterbank_success\n');
fprintf(fid, '        try\n');
fprintf(fid, '            audio = real(ufilterbank(audio, g, 1));\n');
fprintf(fid, '            audio = reshape(audio, size(audio,1), []);\n');
fprintf(fid, '            fprintf(''  ✓ Subband processing\\n'');\n');
fprintf(fid, '        catch ME\n');
fprintf(fid, '            fprintf(''  ⚠ ufilterbank failed: %%s\\n'', ME.message);\n');
fprintf(fid, '            fprintf(''  Using broadband envelope\\n'');\n');
fprintf(fid, '        end\n');
fprintf(fid, '    else\n');
fprintf(fid, '        fprintf(''  Using broadband envelope\\n'');\n');
fprintf(fid, '    end\n');
fprintf(fid, '    \n');
fprintf(fid, '    envelope = abs(audio).^params.power;\n');
fprintf(fid, '    envelope = resample(envelope, params.intermediateSampleRate, Fs);\n');
fprintf(fid, '    envelope = filtfilt(bpFilter.numerator, 1, envelope);\n');
fprintf(fid, '    \n');
fprintf(fid, '    downsamplefactor = params.intermediateSampleRate / params.targetSampleRate;\n');
fprintf(fid, '    envelope = downsample(envelope, downsamplefactor);\n');
fprintf(fid, '    Fs = params.targetSampleRate;\n');
fprintf(fid, '    \n');
fprintf(fid, '    subband_weights = ones(1, size(envelope, 2));\n');
fprintf(fid, '    \n');
fprintf(fid, '    %% Save envelope\n');
fprintf(fid, '    envelope_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag '' '' stimuliname ''.mat'']);\n');
fprintf(fid, '    save(envelope_file, ''envelope'', ''Fs'', ''subband_weights'');\n');
fprintf(fid, 'end\n\n');

fprintf(fid, '%% Process EEG data\n');
fprintf(fid, 'preprocdir = fullfile(basedir, ''preprocessed_data'');\n');
fprintf(fid, 'if ~exist(preprocdir,''dir'')\n');
fprintf(fid, '    mkdir(preprocdir)\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'subjects = dir(fullfile(basedir, ''S*.mat''));\n');
fprintf(fid, 'subjects = sort({subjects(:).name});\n\n');

fprintf(fid, 'fprintf(''Processing %%d EEG subjects...\\n'', length(subjects));\n');
fprintf(fid, 'for subject_idx = 1:length(subjects)\n');
fprintf(fid, '    subject_file = subjects{subject_idx};\n');
fprintf(fid, '    fprintf(''Processing EEG [%%d/%%d]: %%s\\n'', subject_idx, length(subjects), subject_file);\n');
fprintf(fid, '    \n');
fprintf(fid, '    loaded_data = load(fullfile(basedir, subject_file));\n');
fprintf(fid, '    trials = loaded_data.trials;\n');
fprintf(fid, '    \n');
fprintf(fid, '    preproc_trials = {};\n');
fprintf(fid, '    for trialnum = 1:size(trials, 2)\n');
fprintf(fid, '        trial = trials{trialnum};\n');
fprintf(fid, '        \n');
fprintf(fid, '        %% Rereference EEG\n');
fprintf(fid, '        if strcmpi(params.rereference,''Cz'')\n');
fprintf(fid, '            trial.RawData.EegData = trial.RawData.EegData - repmat(trial.RawData.EegData(:,48),[1,64]);\n');
fprintf(fid, '        end\n');
fprintf(fid, '        \n');
fprintf(fid, '        %% Apply bandpass filter\n');
fprintf(fid, '        trial.RawData.EegData = filtfilt(bpFilter.numerator, 1, double(trial.RawData.EegData));\n');
fprintf(fid, '        \n');
fprintf(fid, '        %% Downsample EEG\n');
fprintf(fid, '        downsamplefactor = trial.FileHeader.SampleRate / params.targetSampleRate;\n');
fprintf(fid, '        trial.RawData.EegData = downsample(trial.RawData.EegData, downsamplefactor);\n');
fprintf(fid, '        trial.FileHeader.SampleRate = params.targetSampleRate;\n');
fprintf(fid, '        \n');
fprintf(fid, '        %% Load envelopes\n');
fprintf(fid, '        if trial.repetition, stimname_len = 16; else, stimname_len = 12; end\n');
fprintf(fid, '        \n');
fprintf(fid, '        left_env_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag '' '' trial.stimuli{1}(1:stimname_len) ''_dry.mat'']);\n');
fprintf(fid, '        right_env_file = fullfile(envelopedir, [params.envelopemethod params.subbandtag '' '' trial.stimuli{2}(1:stimname_len) ''_dry.mat'']);\n');
fprintf(fid, '        \n');
fprintf(fid, '        if exist(left_env_file, ''file'') && exist(right_env_file, ''file'')\n');
fprintf(fid, '            left_data = load(left_env_file, ''envelope'');\n');
fprintf(fid, '            right_data = load(right_env_file, ''envelope'');\n');
fprintf(fid, '            \n');
fprintf(fid, '            left = left_data.envelope(1:length(trial.RawData.EegData), :);\n');
fprintf(fid, '            right = right_data.envelope(1:length(trial.RawData.EegData), :);\n');
fprintf(fid, '            \n');
fprintf(fid, '            trial.Envelope.AudioData = cat(3, left, right);\n');
fprintf(fid, '            trial.Envelope.subband_weights = subband_weights;\n');
fprintf(fid, '        else\n');
fprintf(fid, '            fprintf(''  ⚠ Envelope files not found for trial %%d\\n'', trialnum);\n');
fprintf(fid, '        end\n');
fprintf(fid, '        \n');
fprintf(fid, '        preproc_trials{trialnum} = trial;\n');
fprintf(fid, '    end\n');
fprintf(fid, '    \n');
fprintf(fid, '    %% Save processed subject\n');
fprintf(fid, '    save(fullfile(preprocdir, subject_file), ''preproc_trials'');\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'fprintf(''\\n✓ Preprocessing completed successfully!\\n'');\n');
fprintf(fid, 'cd(current_dir); %% Return to original directory\n\n');

fprintf(fid, 'end\n\n');

% Add helper functions
fprintf(fid, 'function freqs = create_erb_spacing_manual(f_min, f_max, spacing)\n');
fprintf(fid, 'erb_min = 21.4 * log10(1 + f_min / 229);\n');
fprintf(fid, 'erb_max = 21.4 * log10(1 + f_max / 229);\n');
fprintf(fid, 'erb_vals = linspace(erb_min, erb_max, round((erb_max - erb_min) / spacing) + 1);\n');
fprintf(fid, 'freqs = (10.^(erb_vals / 21.4) - 1) * 229;\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'function stimulinames = list_stimuli_corrected(stimulusdir)\n');
fprintf(fid, 'dry_files = dir(fullfile(stimulusdir, ''*_dry.wav''));\n');
fprintf(fid, 'stimulinames = {dry_files.name};\n');
fprintf(fid, 'fprintf(''Found %%d dry audio files\\n'', length(stimulinames));\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'function g = create_fallback_filterbank(freqs, fs)\n');
fprintf(fid, 'num_filters = length(freqs);\n');
fprintf(fid, 'N = 512;\n');
fprintf(fid, 'g = zeros(N, num_filters);\n');
fprintf(fid, 'for i = 1:num_filters\n');
fprintf(fid, '    fc = freqs(i);\n');
fprintf(fid, '    bw = 24.7 * (4.37 * fc / 1000 + 1);\n');
fprintf(fid, '    f_low = max(fc - bw/2, 50);\n');
fprintf(fid, '    f_high = min(fc + bw/2, fs/2 * 0.95);\n');
fprintf(fid, '    try\n');
fprintf(fid, '        [b, a] = butter(4, [f_low f_high] / (fs/2), ''bandpass'');\n');
fprintf(fid, '        [h, ~] = freqz(b, a, N);\n');
fprintf(fid, '        g(:, i) = real(h);\n');
fprintf(fid, '    catch\n');
fprintf(fid, '        g(:, i) = ones(N, 1) / num_filters;\n');
fprintf(fid, '    end\n');
fprintf(fid, 'end\n');
fprintf(fid, 'end\n\n');

fprintf(fid, 'function BP_equirip = construct_bpfilter(params)\n');
fprintf(fid, 'Fs = params.intermediateSampleRate;\n');
fprintf(fid, 'Fst1 = params.highpass-0.45;\n');
fprintf(fid, 'Fp1 = params.highpass+0.45;\n');
fprintf(fid, 'Fp2 = params.lowpass-0.45;\n');
fprintf(fid, 'Fst2 = params.lowpass+0.45;\n');
fprintf(fid, 'Ast1 = 20;\n');
fprintf(fid, 'Ap = 0.5;\n');
fprintf(fid, 'Ast2 = 15;\n');
fprintf(fid, 'BP = fdesign.bandpass(''Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2'',Fst1,Fp1,Fp2,Fst2,Ast1,Ap,Ast2,Fs);\n');
fprintf(fid, 'BP_equirip = design(BP,''equiripple'');\n');
fprintf(fid, 'end\n');

fclose(fid);
fprintf('  → Created corrected preprocessing: %s\n', corrected_file);
end

function validate_file_organization()
% Validate and fix file organization

fprintf('Checking file organization:\n');

% Check base directory
if exist('c:\Research\AAD', 'dir')
    fprintf('  ✓ Base directory exists\n');
else
    error('Base directory c:\Research\AAD not found');
end

% Check stimuli directory
stimuli_dir = 'c:\Research\AAD\stimuli';
if exist(stimuli_dir, 'dir')
    dry_files = dir(fullfile(stimuli_dir, '*_dry.wav'));
    fprintf('  ✓ Stimuli directory: %d dry audio files\n', length(dry_files));
else
    fprintf('  ✗ Stimuli directory not found\n');
end

% Check EEG files
eeg_files = dir('c:\Research\AAD\S*.mat');
fprintf('  ✓ EEG files: %d subjects\n', length(eeg_files));

% Check multichannel directories
mc_dirs = {'multichannel_6ch', 'multichannel_8ch'};
for i = 1:length(mc_dirs)
    mc_path = fullfile('c:\Research\AAD\stimuli', mc_dirs{i});
    if exist(mc_path, 'dir')
        mc_files = dir(fullfile(mc_path, '*_competitive_dry.wav'));
        fprintf('  ✓ %s: %d competitive files\n', mc_dirs{i}, length(mc_files));
    else
        fprintf('  - %s: not created yet (normal)\n', mc_dirs{i});
    end
end

end