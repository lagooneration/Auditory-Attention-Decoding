function create_multichannel_aad_stimuli(basedir, channel_config)
% CREATE_MULTICHANNEL_AAD_STIMULI Creates multichannel stimuli for AAD research
% This function creates competitive multichannel scenarios from the mono tracks
% in the KULeuven AAD dataset, suitable for testing spatial attention decoding
%
% Inputs:
%   basedir: Directory containing the stimuli folder (default: current directory)
%   channel_config: Number of output channels - 6 or 8 (default: 8)
%
% The function creates competitive scenarios where:
% - Track 1 and Track 2 are placed at different spatial locations
% - Multiple channel configurations test different speaker arrangements
% - Maintains the competitive paradigm essential for AAD research
%
% Output: Creates multichannel competitive scenarios in 'stimuli/multichannel_{config}ch/' folder

if nargin < 1
    basedir = pwd;
end

if nargin < 2
    channel_config = 8; % Default to 8-channel configuration
end

% Validate channel configuration
if ~ismember(channel_config, [6, 8])
    error('channel_config must be 6 or 8');
end

% Define paths
stimulusdir = fullfile(basedir, 'stimuli');
output_dir = fullfile(stimulusdir, sprintf('multichannel_%dch', channel_config));

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Define speaker configuration
speaker_config = setup_speaker_configuration(channel_config);

% Get list of stimulus parts and tracks
stimulus_info = get_stimulus_combinations();

fprintf('Creating multichannel AAD stimuli...\n');
fprintf('Configuration: %d channels\n', channel_config);
fprintf('Processing %d stimulus combinations\n', length(stimulus_info));

%% Process each stimulus combination
for i = 1:length(stimulus_info)
    stim = stimulus_info(i);
    
    fprintf('Processing [%d/%d]: %s\n', i, length(stimulus_info), stim.name);
    
    % Load the two competing tracks
    track1_file = fullfile(stimulusdir, stim.track1_file);
    track2_file = fullfile(stimulusdir, stim.track2_file);
    
    if ~exist(track1_file, 'file') || ~exist(track2_file, 'file')
        warning('Skipping %s - audio files not found', stim.name);
        continue;
    end
    
    [track1_audio, fs1] = audioread(track1_file);
    [track2_audio, fs2] = audioread(track2_file);
    
    if fs1 ~= fs2
        error('Sample rates do not match between tracks');
    end
    
    % Ensure tracks are same length (take minimum)
    min_length = min(length(track1_audio), length(track2_audio));
    track1_audio = track1_audio(1:min_length);
    track2_audio = track2_audio(1:min_length);
    
    % Create multichannel competitive scenario
    multichannel_audio = create_competitive_scenario(track1_audio, track2_audio, ...
                                                   speaker_config, stim.scenario);
    
    % Save multichannel competitive stimulus
    output_filename = fullfile(output_dir, stim.output_file);
    audiowrite(output_filename, multichannel_audio, fs1);
end

fprintf('Multichannel AAD stimuli creation completed!\n');
fprintf('Files saved to: %s\n', output_dir);

% Generate configuration summary
save_configuration_info(output_dir, speaker_config, channel_config);

end

function speaker_config = setup_speaker_configuration(channel_config)
% Setup 3D speaker configuration for AAD competitive scenarios with elevation

if channel_config == 6
    % 5.1 3D Configuration for AAD (includes height layer)
    speaker_config.names = {'FL', 'FR', 'C', 'LFE', 'SL', 'SR'};
    speaker_config.angles = [30, -30, 0, 0, 110, -110]; % degrees (azimuth)
    speaker_config.elevations = [15, 15, 0, 0, 10, 10]; % degrees (elevation - front higher, sides moderate)
    
    % Define primary positions for competitive scenarios (exclude LFE for speech)
    speaker_config.primary_positions = [1, 2, 5, 6]; % FL, FR, SL, SR
    
elseif channel_config == 8
    % 7.1 3D Configuration for AAD with full height layer
    speaker_config.names = {'FL', 'FR', 'C', 'LFE', 'SL', 'SR', 'BL', 'BR'};
    speaker_config.angles = [30, -30, 0, 0, 110, -110, 150, -150]; % degrees (azimuth)
    speaker_config.elevations = [20, 20, 0, 0, 15, 15, 25, 25]; % degrees (elevation - gradient from center to back)
    
    % Define primary positions for competitive scenarios (exclude C and LFE)
    speaker_config.primary_positions = [1, 2, 5, 6, 7, 8]; % FL, FR, SL, SR, BL, BR
end

% Add 3D spatial parameters
speaker_config.num_channels = channel_config;
speaker_config.use_3d_positioning = true;

% Define height-based competitive scenarios
speaker_config.elevation_scenarios = setup_elevation_scenarios(channel_config);

end

function elevation_scenarios = setup_elevation_scenarios(channel_config)
% Define elevation-based competitive scenarios for 3D AAD research

if channel_config == 6
    elevation_scenarios = struct();
    elevation_scenarios.low_vs_high = [2, 1]; % FR (low) vs FL (high)
    elevation_scenarios.side_contrast = [5, 6]; % SL vs SR (moderate elevation)
    
elseif channel_config == 8
    elevation_scenarios = struct();
    elevation_scenarios.low_vs_high = [2, 1]; % FR vs FL (front height contrast)
    elevation_scenarios.side_contrast = [5, 6]; % SL vs SR (side elevation)
    elevation_scenarios.back_elevation = [7, 8]; % BL vs BR (highest elevation)
    elevation_scenarios.front_vs_back = [1, 7]; % FL vs BL (front low vs back high)
    elevation_scenarios.cross_elevation = [2, 7]; % FR vs BL (diagonal height)
end

end

function stimulus_info = get_stimulus_combinations()
% Get all stimulus combinations for AAD competitive scenarios including 3D positioning

stimulus_info = [];
idx = 1;

% Standard experiment combinations (non-repetition)
for part = 1:4
    % Create competitive scenario between track1 and track2 for this part
    stimulus_info(idx).name = sprintf('Part%d_Competitive', part);
    stimulus_info(idx).track1_file = sprintf('part%d_track1_dry.wav', part);
    stimulus_info(idx).track2_file = sprintf('part%d_track2_dry.wav', part);
    stimulus_info(idx).output_file = sprintf('part%d_competitive_dry.wav', part);
    stimulus_info(idx).scenario = 'standard';
    stimulus_info(idx).part = part;
    idx = idx + 1;
end

% Repetition experiment combinations
for part = 1:4
    stimulus_info(idx).name = sprintf('Rep_Part%d_Competitive', part);
    stimulus_info(idx).track1_file = sprintf('rep_part%d_track1_dry.wav', part);
    stimulus_info(idx).track2_file = sprintf('rep_part%d_track2_dry.wav', part);
    stimulus_info(idx).output_file = sprintf('rep_part%d_competitive_dry.wav', part);
    stimulus_info(idx).scenario = 'repetition';
    stimulus_info(idx).part = part;
    idx = idx + 1;
end

end

function multichannel_audio = create_competitive_scenario(track1_audio, track2_audio, ...
                                                        speaker_config, scenario)
% Create 3D multichannel competitive scenario from two mono tracks with elevation

num_samples = length(track1_audio);
num_channels = speaker_config.num_channels;

% Initialize multichannel output
multichannel_audio = zeros(num_samples, num_channels);

% Define different 3D competitive scenarios for research variety
switch scenario
    case 'standard'
        % Enhanced 3D positioning: Front left-right with elevation contrast
        if num_channels >= 8
            pos1_idx = 1; % Front Left (elevated 20°)
            pos2_idx = 2; % Front Right (elevated 20°)
        else
            pos1_idx = 1; % Front Left (elevated 15°)
            pos2_idx = 2; % Front Right (elevated 15°)
        end
        
    case 'repetition'  
        % 3D elevation-based separation for repetition trials
        if num_channels >= 8
            % Use back speakers with highest elevation (25°)
            pos1_idx = 7; % Back Left (elevated 25°)
            pos2_idx = 8; % Back Right (elevated 25°)
        else
            % Use side speakers with moderate elevation (10°)
            pos1_idx = 5; % Side Left (elevated 10°)
            pos2_idx = 6; % Side Right (elevated 10°)
        end
        
        % Fallback to front if channels not available
        if pos1_idx > num_channels || pos2_idx > num_channels
            pos1_idx = 1; % Front Left
            pos2_idx = 2; % Front Right
        end
end

% Place track 1 at position 1 with 3D spatial processing
if pos1_idx <= num_channels
    multichannel_audio(:, pos1_idx) = apply_elevation_processing(track1_audio, ...
        speaker_config.elevations(pos1_idx), speaker_config.angles(pos1_idx));
end

% Place track 2 at position 2 with 3D spatial processing  
if pos2_idx <= num_channels
    multichannel_audio(:, pos2_idx) = apply_elevation_processing(track2_audio, ...
        speaker_config.elevations(pos2_idx), speaker_config.angles(pos2_idx));
end

% Add 3D spatial enhancement through controlled cross-talk and decorrelation
multichannel_audio = add_3d_spatial_enhancement(multichannel_audio, speaker_config, ...
                                               pos1_idx, pos2_idx);

end

function processed_audio = apply_elevation_processing(audio_signal, elevation, azimuth)
% Apply 3D spatial processing based on elevation and azimuth angles
% Simulates head-related transfer function (HRTF) effects for height perception

processed_audio = audio_signal;

% Apply elevation-dependent filtering (simplified HRTF modeling)
if elevation > 0
    % Higher frequencies are enhanced for elevated sources
    elevation_gain = 1 + (elevation / 180) * 0.3; % Up to 30% gain for 90° elevation
    
    % Create simple high-frequency emphasis for elevation cues
    [b, a] = butter(2, [3000 8000] / (22050), 'bandpass'); % Assuming ~44kHz sample rate
    try
        elevation_component = filtfilt(b, a, audio_signal);
        processed_audio = audio_signal + elevation_component * (elevation_gain - 1);
    catch
        % Fallback if filtering fails
        processed_audio = audio_signal * elevation_gain;
    end
end

% Apply subtle delay based on azimuth (interaural time difference simulation)
azimuth_delay_ms = sin(azimuth * pi/180) * 0.7; % Max 0.7ms ITD
delay_samples = round(abs(azimuth_delay_ms) * 44.1); % Assuming ~44kHz

if delay_samples > 0 && delay_samples < length(processed_audio)/2
    if azimuth_delay_ms > 0
        % Positive delay
        processed_audio = [zeros(delay_samples, 1); processed_audio(1:end-delay_samples)];
    else
        % Negative delay (advance)
        processed_audio = [processed_audio(delay_samples+1:end); zeros(delay_samples, 1)];
    end
end

end

function enhanced_audio = add_3d_spatial_enhancement(multichannel_audio, speaker_config, ...
                                                   pos1_idx, pos2_idx)
% Add 3D spatial enhancement to improve spatial perception with elevation

enhanced_audio = multichannel_audio;
[~, num_channels] = size(multichannel_audio);

% Get the primary signals
track1_signal = multichannel_audio(:, pos1_idx);
track2_signal = multichannel_audio(:, pos2_idx);

% Add controlled 3D cross-talk to adjacent speakers for spatial continuity
crossfalk_gain = 0.12; % Slightly reduced for 3D to maintain clarity

% For track 1 (add small amount to adjacent channels considering elevation)
adjacent_channels_1 = get_3d_adjacent_channels(pos1_idx, speaker_config);
for ch = adjacent_channels_1
    if ch <= num_channels && ch ~= pos2_idx % Don't contaminate competing track position
        % Adjust cross-talk based on elevation difference
        elevation_diff = abs(speaker_config.elevations(pos1_idx) - speaker_config.elevations(ch));
        elevation_factor = 1 - (elevation_diff / 90); % Reduce cross-talk for large elevation differences
        
        enhanced_audio(:, ch) = enhanced_audio(:, ch) + ...
            track1_signal * crossfalk_gain * max(elevation_factor, 0.3);
    end
end

% For track 2 (add small amount to adjacent channels considering elevation)
adjacent_channels_2 = get_3d_adjacent_channels(pos2_idx, speaker_config);
for ch = adjacent_channels_2
    if ch <= num_channels && ch ~= pos1_idx % Don't contaminate competing track position
        % Adjust cross-talk based on elevation difference
        elevation_diff = abs(speaker_config.elevations(pos2_idx) - speaker_config.elevations(ch));
        elevation_factor = 1 - (elevation_diff / 90);
        
        enhanced_audio(:, ch) = enhanced_audio(:, ch) + ...
            track2_signal * crossfalk_gain * max(elevation_factor, 0.3);
    end
end

% Apply 3D-aware decorrelation to enhance spatial impression
enhanced_audio = apply_3d_decorrelation(enhanced_audio, speaker_config);

end

function adjacent_channels = get_adjacent_channels(channel_idx, speaker_config)
% Get indices of channels adjacent to the given channel

angles = speaker_config.angles;
current_angle = angles(channel_idx);

adjacent_channels = [];
angle_threshold = 60; % degrees

for i = 1:length(angles)
    if i ~= channel_idx
        angle_diff = abs(angular_difference(current_angle * pi/180, angles(i) * pi/180));
        if angle_diff * 180/pi <= angle_threshold
            adjacent_channels = [adjacent_channels, i];
        end
    end
end

end

function diff = angular_difference(angle1, angle2)
% Calculate the shortest angular difference between two angles
diff = angle1 - angle2;
diff = mod(diff + pi, 2*pi) - pi;
end

function decorrelated_audio = apply_subtle_decorrelation(multichannel_audio)
% Apply subtle decorrelation to enhance spatial perception

decorrelated_audio = multichannel_audio;
[num_samples, num_channels] = size(multichannel_audio);

% Apply different small delays to non-zero channels
for ch = 1:num_channels
    if any(multichannel_audio(:, ch) ~= 0) % Only process non-zero channels
        % Small channel-specific delay (0.5-2 ms)
        delay_samples = round((ch * 0.5 + 0.5) * 44.1); % Assuming ~44kHz sample rate
        delay_samples = min(delay_samples, 100); % Cap at reasonable delay
        
        if delay_samples > 0 && delay_samples < num_samples
            temp_signal = [zeros(delay_samples, 1); 
                          multichannel_audio(1:end-delay_samples, ch)];
            decorrelated_audio(:, ch) = temp_signal;
        end
    end
end

end

function adjacent_channels = get_3d_adjacent_channels(channel_idx, speaker_config)
% Get indices of channels adjacent to the given channel in 3D space

angles = speaker_config.angles;
elevations = speaker_config.elevations;
current_angle = angles(channel_idx);
current_elevation = elevations(channel_idx);

adjacent_channels = [];
angle_threshold = 60; % degrees
elevation_threshold = 30; % degrees

for i = 1:length(angles)
    if i ~= channel_idx
        angle_diff = abs(angular_difference(current_angle * pi/180, angles(i) * pi/180));
        elevation_diff = abs(current_elevation - elevations(i));
        
        % Consider adjacent if close in either angle or elevation
        if (angle_diff * 180/pi <= angle_threshold) || (elevation_diff <= elevation_threshold)
            adjacent_channels = [adjacent_channels, i];
        end
    end
end

end

function decorrelated_audio = apply_3d_decorrelation(multichannel_audio, speaker_config)
% Apply 3D-aware decorrelation to enhance spatial perception

decorrelated_audio = multichannel_audio;
[num_samples, num_channels] = size(multichannel_audio);

% Apply elevation and azimuth-dependent delays
for ch = 1:num_channels
    if any(multichannel_audio(:, ch) ~= 0) % Only process non-zero channels
        % Calculate delay based on both azimuth and elevation
        azimuth = speaker_config.angles(ch);
        elevation = speaker_config.elevations(ch);
        
        % Delay increases with elevation and varies with azimuth
        base_delay = (elevation / 30) * 2; % 0-6ms based on elevation (0-90°)
        azimuth_variation = (abs(azimuth) / 180) * 1; % 0-1ms based on azimuth
        
        delay_ms = base_delay + azimuth_variation + (ch * 0.3); % Channel-specific component
        delay_samples = round(delay_ms * 44.1); % Assuming ~44kHz sample rate
        delay_samples = min(delay_samples, 200); % Cap at reasonable delay
        
        if delay_samples > 0 && delay_samples < num_samples
            temp_signal = [zeros(delay_samples, 1); 
                          multichannel_audio(1:end-delay_samples, ch)];
            decorrelated_audio(:, ch) = temp_signal;
        end
    end
end

end

function save_configuration_info(output_dir, speaker_config, channel_config)
% Save configuration information for reference

config_file = fullfile(output_dir, 'aad_spatial_configuration.mat');

% Prepare 3D configuration data
config_data.channel_config = channel_config;
config_data.speaker_names = speaker_config.names;
config_data.speaker_angles = speaker_config.angles;
config_data.speaker_elevations = speaker_config.elevations;
config_data.primary_positions = speaker_config.primary_positions;
config_data.use_3d_positioning = speaker_config.use_3d_positioning;
config_data.elevation_scenarios = speaker_config.elevation_scenarios;
config_data.creation_date = datestr(now);
config_data.description = sprintf('%d-channel 3D AAD competitive spatial configuration with elevation', channel_config);

% Add 3D spatial analysis parameters
config_data.spatial_features = struct();
config_data.spatial_features.azimuth_range = [min(speaker_config.angles), max(speaker_config.angles)];
config_data.spatial_features.elevation_range = [min(speaker_config.elevations), max(speaker_config.elevations)];
config_data.spatial_features.num_elevation_levels = length(unique(speaker_config.elevations));

save(config_file, 'config_data');

% Also save as text file
txt_file = fullfile(output_dir, 'aad_spatial_configuration.txt');
fid = fopen(txt_file, 'w');
fprintf(fid, 'AAD Multichannel Spatial Configuration\n');
fprintf(fid, '=====================================\n\n');
fprintf(fid, 'Channels: %d\n', channel_config);
fprintf(fid, 'Creation Date: %s\n\n', config_data.creation_date);
fprintf(fid, '3D Speaker Configuration:\n');
for i = 1:length(speaker_config.names)
    fprintf(fid, '%d. %s: Azimuth=%d°, Elevation=%d°\n', ...
        i, speaker_config.names{i}, speaker_config.angles(i), speaker_config.elevations(i));
end
fprintf(fid, '\nPrimary AAD Positions: ');
for i = 1:length(speaker_config.primary_positions)
    pos_idx = speaker_config.primary_positions(i);
    fprintf(fid, '%s(%.0f°/%.0f°) ', speaker_config.names{pos_idx}, ...
        speaker_config.angles(pos_idx), speaker_config.elevations(pos_idx));
end
fprintf(fid, '\n\n3D Competitive Scenario Design:\n');
fprintf(fid, '- Track 1 and Track 2 placed at different 3D spatial positions\n');
fprintf(fid, '- Elevation-dependent HRTF simulation for height perception\n');
fprintf(fid, '- 3D-aware cross-talk to adjacent speakers (12%% base level)\n');
fprintf(fid, '- Elevation-dependent decorrelation (0-6ms delays)\n');
fprintf(fid, '- Azimuth and elevation cues for enhanced spatial attention\n');
fprintf(fid, '- Maintains competitive paradigm for 3D AAD research\n');

fprintf(fid, '\nElevation Benefits for AAD:\n');
fprintf(fid, '- Enhanced spatial separation between competing sources\n');
fprintf(fid, '- Additional neural cues for attention decoding\n');
fprintf(fid, '- More realistic 3D listening environment\n');
fprintf(fid, '- Potential for improved algorithm performance\n');
fclose(fid);

fprintf('AAD configuration saved to: %s\n', config_file);

end