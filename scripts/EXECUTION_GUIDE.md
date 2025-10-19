# AAD Analysis Pipeline - Complete Execution Guide

This guide provides step-by-step instructions for running the complete AAD (Auditory Attention Decoding) analysis pipeline, from initial setup through final comparison and visualization.

## 📋 Prerequisites

1. **MATLAB** with Signal Processing Toolbox
2. **AMToolbox** (Auditory Modeling Toolbox) - Download from: http://amtoolbox.org/
3. **KULeuven AAD Dataset** - Download from: https://zenodo.org/records/4004271
4. **Directory Structure**: Ensure your data is organized as:
   ```
   c:\Research\AAD\
   ├── S1.mat, S2.mat, ..., S16.mat (EEG data)
   ├── stimuli\
   │   ├── part1_track1_dry.wav
   │   ├── part1_track2_dry.wav
   │   └── ... (all audio files)
   └── scripts\ (this folder with all MATLAB scripts)
   ```

## 🚀 Complete Execution Pipeline

### STEP 0: Initial Setup
**File to run:** `setup_aad_environment.m` (created below)
```matlab
% Navigate to your scripts directory
cd('c:\Research\AAD\scripts');

% Run setup
setup_aad_environment;
```

### STEP 1: Initialize AMToolbox
**File to run:** Manual AMToolbox setup
```matlab
% Add AMToolbox to path (adjust path as needed)
addpath('c:\Research\AAD\amtoolbox');

% Initialize AMToolbox
amt_start;

% Verify AMToolbox is working
amt_info;
```

### STEP 2: Create Multichannel Stimuli (Upmixing)
**File to run:** `complete_aad_multichannel_example.m`
```matlab
% This creates 6-channel and 8-channel competitive scenarios
complete_aad_multichannel_example;
```
**Expected output:** 
- `stimuli/multichannel_6ch/` and `stimuli/multichannel_8ch/` directories
- Competitive audio files and spatial configurations

### STEP 3: Preprocess Original 2-Channel Data
**File to run:** `preprocess_data.m` (original)
```matlab
% Preprocess original 2-channel data
preprocess_data('c:\Research\AAD');
```
**Expected output:** 
- `preprocessed_data/` directory with processed EEG and audio envelopes

### STEP 4: Preprocess Multichannel Data  
**File to run:** `preprocess_multichannel_aad_data.m`
```matlab
% Preprocess 8-channel data
preprocess_multichannel_aad_data('c:\Research\AAD', 8);

% Preprocess 6-channel data (optional)
preprocess_multichannel_aad_data('c:\Research\AAD', 6);
```
**Expected output:** 
- Envelope files in `stimuli/multichannel_*ch/envelopes/`

### STEP 5: Run Complete AAD Algorithm Comparison
**File to run:** `aad_algorithm_comparison_pipeline.m`
```matlab
% Run complete comparison (this may take 10-30 minutes)
aad_algorithm_comparison_pipeline('c:\Research\AAD', true);
```
**Expected output:** 
- `aad_comparison_results/` directory with all results and visualizations

### STEP 6: Analyze Auditory Encoding (Optional Deep Analysis)
**File to run:** `auditory_encoding_analysis.m`
```matlab
% Analyze auditory perception encoding
auditory_encoding_analysis('c:\Research\AAD');
```
**Expected output:** 
- Detailed analysis of how different audio encodings affect EEG correlation

### STEP 7: Quick Test and Verification
**File to run:** `test_aad_comparison.m`
```matlab
% Quick test to verify everything worked
test_aad_comparison;
```
**Expected output:** 
- Summary of all results and file locations

## 📁 File Reference Guide

### Core Execution Files (Run These)
1. `setup_aad_environment.m` - Initial setup and verification
2. `complete_aad_multichannel_example.m` - Creates multichannel stimuli
3. `preprocess_data.m` - Original preprocessing (2-channel)
4. `preprocess_multichannel_aad_data.m` - Multichannel preprocessing  
5. `aad_algorithm_comparison_pipeline.m` - Main analysis pipeline
6. `auditory_encoding_analysis.m` - Deep auditory encoding analysis
7. `test_aad_comparison.m` - Results verification

### Support Files (Called Automatically)
- `create_multichannel_aad_stimuli.m` - Multichannel stimuli creation
- `analyze_aad_multichannel_stimuli.m` - Multichannel analysis
- Various helper functions within the main scripts

## ⚡ Quick Start (Minimum Steps)

If you want to run the essential analysis quickly:

```matlab
% 1. Setup (one time only)
cd('c:\Research\AAD\scripts');
setup_aad_environment;

% 2. Core pipeline (run these in order)
complete_aad_multichannel_example;  % Creates multichannel data
aad_algorithm_comparison_pipeline('c:\Research\AAD', true);  % Main analysis

% 3. View results
test_aad_comparison;  % Summary of results
```

## 📊 Expected Results Structure

After completion, you'll have:

```
c:\Research\AAD\
├── preprocessed_data\           # 2-channel preprocessed data
├── stimuli\
│   ├── envelopes\              # Original 2-channel envelopes  
│   ├── multichannel_6ch\       # 6-channel competitive stimuli
│   └── multichannel_8ch\       # 8-channel competitive stimuli
├── aad_comparison_results\      # Complete analysis results
│   ├── complete_aad_comparison_results.mat
│   ├── aad_comparison_visualization.png
│   └── comparison_report.txt
└── scripts\                     # All MATLAB scripts
```

## ⏱️ Estimated Execution Times

- **Setup**: 2-5 minutes
- **Multichannel creation**: 5-10 minutes  
- **2-channel preprocessing**: 10-20 minutes
- **Multichannel preprocessing**: 5-10 minutes
- **AAD algorithm comparison**: 20-60 minutes (depends on data size)
- **Total**: 45-105 minutes

## 🔧 Troubleshooting

### Common Issues and Solutions

1. **"AMToolbox not found"**
   ```matlab
   % Add AMToolbox to path
   addpath('path/to/amtoolbox');
   amt_start;
   ```

2. **"No audio files found"**
   - Verify stimuli directory contains .wav files
   - Check file naming matches expected format

3. **"Out of memory"**
   - Process fewer subjects at once
   - Use smaller analysis windows
   - Close other MATLAB instances

4. **"Preprocessing failed"**
   - Ensure AMToolbox is properly initialized
   - Check that gammatone filters are available

## 📈 Results Interpretation

After completion, check these key results:

1. **Algorithm Performance** (in `aad_comparison_visualization.png`):
   - Correlation, TRF, CCA performance comparison
   - 2-channel vs 8-channel comparison

2. **Statistical Significance** (in `comparison_report.txt`):
   - p-values for multichannel improvement
   - Effect sizes for different algorithms

3. **Best Configuration** (in console output):
   - Which algorithm performs best
   - Whether multichannel provides improvement

## 🎯 Research Questions Answered

This pipeline addresses:

1. **Do multichannel stimuli improve AAD performance?**
   - Compare 2ch vs 8ch results in visualization

2. **Which AAD algorithm works best?**
   - See algorithm comparison in results

3. **Is auditory encoding important?**
   - Run `auditory_encoding_analysis.m` for detailed answer

4. **What spatial configurations are optimal?**
   - Analyze multichannel spatial separation metrics

## 📞 Next Steps

After running the pipeline:

1. **Analyze Results**: Review generated plots and statistics
2. **Customize Parameters**: Modify algorithm parameters for your research
3. **Extend Analysis**: Add your own AAD algorithms to the comparison
4. **Publication**: Use results and visualizations for research papers

---

**Note**: All file paths assume Windows format. Adjust paths for Linux/Mac systems by changing `\` to `/`.