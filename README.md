# Auditory Attention Decoding (AAD) Analysis

## Overview

This repository contains an implementation and analysis of auditory attention decoding algorithms using EEG data. The project implements multiple methods for detecting which speaker a listener is attending to in a cocktail party scenario.

## Authors and References

**Primary Dataset Authors:**
- Biesmans, W., Das, N., Francart, T., & Bertrand, A. (2016). Auditory-inspired speech envelope extraction methods for improved EEG-based auditory attention detection in a cocktail party scenario. *IEEE Transactions on Neural Systems and Rehabilitation Engineering*, 25(5), 402-412.

**Dataset Origin:**
- ExpORL, Dept. Neurosciences, KULeuven
- Dept. Electrical Engineering (ESAT), KULeuven

## Dataset Description

The dataset contains EEG recordings from 16 normal-hearing subjects recorded using:
- **EEG System:** BioSemi ActiveTwo (64-channel)
- **Sampling Rate:** 8196 Hz (downsampled to 128 Hz)
- **Audio Stimuli:** Four Dutch short stories by different male speakers
- **Presentation:** Dichotic and HRTF-filtered conditions
- **Total Recording:** ~72 minutes per subject (20 trials each)

### Experimental Conditions
- **Stimulus Conditions:** 'HRTF' (spatially filtered) and 'dry' (dichotic)
- **Attention Directions:** Left ear vs. Right ear
- **Trial Structure:** 6-minute presentations with attention switching

## Analysis Results

### Method Comparison Summary

![AAD Summary](Plots/AAD%20Summary.jpg)

Our analysis implemented and compared three different auditory attention decoding methods:

| Method | Trials | Left Attention | Right Attention | Mean Confidence | Performance |
|--------|--------|----------------|-----------------|-----------------|-------------|
| **Correlation** | 4 | 75.0% | 25.0% | 0.023 | 60.0% accuracy |
| **TRF** | 20 | 45.0% | 55.0% | 0.010 | - |
| **CCA** | 20 | 35.0% | 65.0% | 0.017 | - |

### Performance Analysis

![AAD Comparison Results](Plots/AAD%20comparison%20results.jpg)

#### Correlation Method Results
- **Overall Accuracy:** 60.0% (Moderate Performance)
- **Cross-validation:** 60.0% ± 22.4%
- **Confidence Range:** 0.013 to 0.032

![AAD Validation (Correlation Method)](Plots/AAD%20validation%20(Correlation%20Method).jpg)

### Trial-by-Trial Analysis

![Trial 1](Plots/Trial%201.jpg)

#### Detailed Trial Results (Correlation Method)
| Trial | Prediction | Confidence | Interpretation |
|-------|------------|------------|----------------|
| 3 | Left ear | 0.032 | Above average |
| 4 | Left ear | 0.031 | Above average |
| 1 | Left ear | 0.015 | Below average |
| 2 | Right ear | 0.013 | Below average |

### Statistical Summary

**Confidence Analysis:**
- Mean: 0.023
- Median: 0.023
- Standard deviation: 0.010
- Range: [0.013, 0.032]

**Distribution Analysis:**
- 25th percentile: 0.014
- 50th percentile (median): 0.023
- 75th percentile: 0.032

**Bias Analysis:**
- Left ear mean confidence: 0.026
- Right ear mean confidence: 0.013
- Confidence difference p-value: 0.369 (no significant difference)

## Performance Interpretation

### Accuracy Guidelines
- **>70%:** Good performance
- **50-70%:** Moderate performance ✅ **(Our Result: 60.0%)**
- **<50%:** Poor performance (below chance)

## Important Methodological Considerations

⚠️ **Critical Note from Original Authors (January 2024):**

This dataset has become a standard benchmark for AAD research. However, proper cross-validation is crucial when using machine learning approaches:

1. **Trial Separation:** Deep networks can overfit to trial-specific patterns, leading to artificially high accuracies
2. **Cross-validation:** Use leave-one-trial-out, leave-one-story-out, or leave-one-subject-out validation
3. **Eye-gaze Bias:** EEG may inadvertently capture gaze patterns toward the attended speaker

### Recommended Reading
- Puffay et al. (2023). "Relating EEG to continuous speech using deep neural networks: a review." *Journal of Neural Engineering* 20, 041003
- Rotaru et al. (2023). "What are we really decoding? Unveiling biases in EEG-based decoding of the spatial focus of auditory attention." *Journal of Neural Engineering*

## Repository Structure

```
├── README.md                           # This file
├── .gitignore                         # Git ignore file for MATLAB projects
├── getting_started_aad.m              # Main analysis script
├── detect_auditory_attention.m       # Core detection algorithm
├── validate_attention_detection.m    # Validation framework
├── visualize_aad_results.m           # Visualization functions
├── attention_results_*.mat           # Analysis results
├── S1.mat                            # Example subject data
├── Plots/                            # Analysis visualizations
│   ├── AAD Summary.jpg
│   ├── AAD comparison results.jpg
│   ├── AAD validation (Correlation Method).jpg
│   └── Trial 1.jpg
├── amtoolbox/                        # AMToolbox dependency
├── preprocessed_data/                # Processed EEG data
├── scripts/                          # Preprocessing scripts
└── stimuli/                          # Audio stimuli and envelopes
```

## Usage

1. **Setup Environment:**
   ```matlab
   run('setup_amt_simple.m')  % Initialize AMToolbox
   ```

2. **Run Analysis:**
   ```matlab
   getting_started_aad        % Main analysis pipeline
   ```

3. **Validate Results:**
   ```matlab
   validate_attention_detection
   ```

4. **Visualize Results:**
   ```matlab
   visualize_aad_results
   ```

## Dependencies

- MATLAB (R2018b or later recommended)
- AMToolbox (included in repository)
- Signal Processing Toolbox
- Statistics and Machine Learning Toolbox

## Data Files

- **S1.mat:** Example subject data with EEG recordings and metadata
- **attention_results_*.mat:** Pre-computed analysis results for different methods
- **preprocessed_data/:** Processed EEG data ready for analysis
- **stimuli/:** Original audio stimuli and extracted speech envelopes

## Dataset Access

The complete dataset is available on Zenodo: https://zenodo.org/records/4004271

This includes the full EEG recordings, audio stimuli, and experimental metadata for all 16 subjects across both HRTF and dichotic conditions.

## Key Features

- ✅ Multiple AAD algorithms (Correlation, TRF, CCA)
- ✅ Comprehensive validation framework
- ✅ Statistical analysis and visualization
- ✅ Cross-validation with proper trial separation
- ✅ Confidence interval estimation
- ✅ Method comparison and consistency analysis

## Citation

If you use this code or dataset, please cite:

```bibtex
@article{biesmans2016auditory,
  title={Auditory-inspired speech envelope extraction methods for improved EEG-based auditory attention detection in a cocktail party scenario},
  author={Biesmans, Wim and Das, Neetha and Francart, Tom and Bertrand, Alexander},
  journal={IEEE Transactions on Neural Systems and Rehabilitation Engineering},
  volume={25},
  number={5},
  pages={402--412},
  year={2016},
  publisher={IEEE}
}
```

## License

This project uses the KULeuven Auditory Attention Detection dataset. Please refer to the original dataset documentation for licensing terms.

## Contact

For questions about the analysis implementation, please refer to the original publications and the ExpORL laboratory at KULeuven.