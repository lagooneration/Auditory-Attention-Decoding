# Multichannel Audio Upmixing for AAD Research

This directory contains MATLAB scripts for creating multichannel spatial audio from the stereo KULeuven AAD dataset. The upmixing is designed to support research into how spatial audio configurations affect auditory attention decoding performance.

## Overview

The original KULeuven AAD dataset contains stereo (2-channel) audio stimuli presented dichotically (left/right ear). This implementation creates 6-channel (5.1) and 8-channel (7.1) spatial projections that simulate multi-speaker environments, enabling research into:

1. **Spatial AAD Performance**: How does attention decoding accuracy vary across different speaker positions?
2. **Multi-speaker Scenarios**: Performance in more realistic multi-speaker environments
3. **Spatial Attention Bias**: Understanding how spatial location affects attention detection
4. **Speaker Selection**: Identifying optimal speaker positions for AAD applications

## Speaker Configurations

### 6-Channel (5.1) Configuration
- **FL/FR**: Front Left/Right (±30°)
- **C**: Center (0°)
- **LFE**: Low Frequency Effects (0°)
- **SL/SR**: Side Left/Right (±110°)

### 8-Channel (7.1) Configuration
- **FL/FR**: Front Left/Right (±30°)
- **C**: Center (0°)
- **LFE**: Low Frequency Effects (0°)
- **SL/SR**: Side Left/Right (±110°)
- **BL/BR**: Back Left/Right (±150°)

## Spatial Projection Method

The upmixing algorithm uses:

1. **Angular Distance Mapping**: Each stereo channel is projected to speakers based on angular distance
2. **Psychoacoustic Weighting**: Gains calculated using exponential falloff with angular distance
3. **Channel-Specific Processing**: 
   - Center channel boosted for speech clarity
   - LFE channel reduced for speech content
   - Back channels moderated for spatial impression
4. **Decorrelation Filters**: Applied to enhance spatial perception and reduce artifacts

## Files

### Core Scripts
- `create_multichannel_aad_stimuli.m` - Creates multichannel competitive scenarios from mono tracks
- `test_aad_multichannel.m` - Test script for multichannel AAD stimuli creation
- `analyze_aad_multichannel_stimuli.m` - Analysis and visualization for AAD multichannel data
- `preprocess_multichannel_aad_data.m` - Envelope extraction for multichannel AAD data
- `complete_aad_multichannel_example.m` - Complete workflow demonstration

### Legacy Scripts (Initial Approach)
- `upmix_audio_multichannel.m` - Original upmixing function (for reference)
- `test_upmixing.m` - Original test script
- `analyze_multichannel_audio.m` - Original analysis tool

### Usage

#### Quick Start - Complete Pipeline
```matlab
% Run the complete pipeline
complete_aad_multichannel_example;
```

#### Step-by-Step Usage

##### 1. Create Multichannel Competitive Stimuli
```matlab
% For 8-channel configuration
create_multichannel_aad_stimuli('c:\Research\AAD', 8);

% For 6-channel configuration  
create_multichannel_aad_stimuli('c:\Research\AAD', 6);
```

##### 2. Analyze Spatial Distribution
```matlab
% Analyze 8-channel output (creates detailed plots)
analyze_aad_multichannel_stimuli('c:\Research\AAD', 8);
```

##### 3. Extract Envelopes for AAD Processing
```matlab
% Extract multichannel envelopes
preprocess_multichannel_aad_data('c:\Research\AAD', 8);
```

##### 4. Use in AAD Algorithms
```matlab
% Load multichannel envelope data
envelope_dir = 'c:\Research\AAD\stimuli\multichannel_8ch\envelopes\';
load(fullfile(envelope_dir, 'powerlaw subbands part1_competitive.mat'));

% envelope: [samples x features] - multichannel envelope data
% config_data: spatial configuration information
% Fs: sample rate (32 Hz)
```

## Output Structure

After running the complete pipeline, the following directories will be created:

```
stimuli/
├── multichannel_6ch/
│   ├── aad_spatial_configuration.mat     # Spatial setup info
│   ├── aad_spatial_configuration.txt     # Human-readable config
│   ├── part1_competitive_dry.wav          # 6-ch competitive scenario
│   ├── part2_competitive_dry.wav          # 6-ch competitive scenario
│   ├── part3_competitive_dry.wav          # 6-ch competitive scenario
│   ├── part4_competitive_dry.wav          # 6-ch competitive scenario
│   ├── rep_part1_competitive_dry.wav      # 6-ch repetition scenario
│   ├── rep_part2_competitive_dry.wav      # 6-ch repetition scenario
│   ├── rep_part3_competitive_dry.wav      # 6-ch repetition scenario
│   ├── rep_part4_competitive_dry.wav      # 6-ch repetition scenario
│   └── envelopes/                         # Processed envelope data
│       ├── powerlaw subbands part1_competitive.mat
│       ├── powerlaw subbands part2_competitive.mat
│       └── ... (envelope files for AAD processing)
└── multichannel_8ch/
    ├── aad_spatial_configuration.mat     # Spatial setup info
    ├── aad_spatial_configuration.txt     # Human-readable config
    ├── part1_competitive_dry.wav          # 8-ch competitive scenario
    ├── part2_competitive_dry.wav          # 8-ch competitive scenario
    ├── part3_competitive_dry.wav          # 8-ch competitive scenario
    ├── part4_competitive_dry.wav          # 8-ch competitive scenario
    ├── rep_part1_competitive_dry.wav      # 8-ch repetition scenario
    ├── rep_part2_competitive_dry.wav      # 8-ch repetition scenario
    ├── rep_part3_competitive_dry.wav      # 8-ch repetition scenario
    ├── rep_part4_competitive_dry.wav      # 8-ch repetition scenario
    └── envelopes/                         # Processed envelope data
        ├── powerlaw subbands part1_competitive.mat
        ├── powerlaw subbands part2_competitive.mat
        └── ... (envelope files for AAD processing)
```

## Integration with AAD Pipeline

### Modifying the Original Pipeline

To use multichannel audio with your AAD algorithms, you'll need to:

1. **Update Audio Loading**: Modify envelope extraction to handle multiple channels
2. **Channel Selection**: Implement channel selection strategies for comparison
3. **Spatial Features**: Extract spatial features from different speaker positions
4. **Performance Evaluation**: Compare decoding accuracy across speaker configurations

### Example Integration

```matlab
% In your modified preprocess_data.m
function preproc_trials = preprocess_multichannel_data(basedir, channel_config)
    % Load multichannel stimuli instead of stereo
    stimulusdir = fullfile(basedir, 'stimuli', sprintf('multichannel_%dch', channel_config));
    
    % Extract envelopes for each channel
    for ch = 1:channel_config
        envelope_ch = extract_envelope_single_channel(audio_multichannel(:, ch));
        % Store per-channel envelopes for analysis
    end
    
    % Implement channel selection strategies:
    % 1. Best single channel
    % 2. Channel pairs
    % 3. All channels with spatial filtering
end
```

## Research Applications

### Spatial Attention Analysis
1. **Position-Dependent Decoding**: Test AAD performance for attention to different speaker positions
2. **Spatial Selectivity**: Measure how well algorithms distinguish between spatially separated sources
3. **Multi-talker Scenarios**: Evaluate performance in realistic multi-speaker environments

### Algorithm Development
1. **Spatial Filtering**: Develop spatial filters that combine multiple channels optimally
2. **Channel Selection**: Automatic selection of best channel subset for AAD
3. **Spatial Features**: Extract features that capture spatial attention patterns

### Performance Benchmarking
1. **Baseline Comparison**: Compare multichannel performance against original stereo results
2. **Configuration Optimization**: Identify optimal speaker configurations for AAD
3. **Robustness Testing**: Evaluate algorithm robustness across different spatial setups

## Technical Notes

### Signal Processing Details
- **Energy Preservation**: Projection matrices are normalized to preserve signal energy
- **Decorrelation**: Small delays and all-pass filters create spatial impression
- **Phase Coherence**: Maintains phase relationships important for AAD algorithms

### Computational Considerations
- **Memory Usage**: Multichannel files are 3-4x larger than stereo originals
- **Processing Time**: Envelope extraction scales linearly with channel count
- **Storage**: Plan for increased storage requirements

### Validation
- **Energy Conservation**: Total energy is preserved across channels
- **Spatial Accuracy**: Speaker positions match standard surround configurations
- **Compatibility**: Output format compatible with existing MATLAB audio tools

## Future Extensions

1. **Binaural Rendering**: Add HRTF-based binaural rendering for headphone playback
2. **Room Acoustics**: Include room impulse responses for realistic environments
3. **Dynamic Positioning**: Implement moving sound sources
4. **Custom Configurations**: Support for arbitrary speaker arrangements

## References

Based on the KULeuven AAD dataset:
- Biesmans, W., et al. (2016). "Auditory-inspired speech envelope extraction methods for improved EEG-based auditory attention detection in a cocktail party scenario." IEEE TNSRE.
- Das, N., et al. (2019). "Stimulus-aware spatial filtering for single-trial neural response and temporal response function estimation in high-density EEG."

## Contact

This implementation was created to support AAD research using multichannel spatial audio. For questions about the implementation or research applications, please refer to the original dataset documentation and related publications.