# 📋 AAD Pipeline Execution - Quick Reference

## 🎯 **ANSWER TO YOUR QUESTION**

### **Yes, auditory perception encoding is ESSENTIAL for AAD algorithms!**

The reason is that EEG signals reflect **auditory cortical processing**, not raw sound waves. You need to:
1. **Transform audio** → auditory features (using gammatone filterbank + power-law)
2. **Extract envelopes** that represent how the auditory system processes sound
3. **Correlate these features** with EEG to find attention patterns

**Without proper auditory encoding, AAD accuracy drops significantly!**

---

## 🚀 **EXECUTION ORDER - COPY & PASTE THESE COMMANDS**

### **Method 1: Complete Automated Pipeline (Recommended)**
```matlab
% 1. Navigate to your scripts directory
cd('c:\Research\AAD\scripts');

% 2. Run complete pipeline (will take 1-2 hours)
run_complete_aad_pipeline;
```

### **Method 2: Step-by-Step Execution (For Learning/Debugging)**
```matlab
% Step 0: Setup
cd('c:\Research\AAD\scripts');
setup_aad_environment('c:\Research\AAD');

% Step 1: Create multichannel stimuli (5-10 min)
complete_aad_multichannel_example;

% Step 2: Run AAD comparison (20-60 min)  
aad_algorithm_comparison_pipeline('c:\Research\AAD', true);

% Step 3: View results
test_aad_comparison;

% Step 4: (Optional) Deep auditory encoding analysis
auditory_encoding_analysis('c:\Research\AAD');
```

### **Method 3: Quick Test (Minimum Viable)**
```matlab
cd('c:\Research\AAD\scripts');
setup_aad_environment('c:\Research\AAD');
aad_algorithm_comparison_pipeline('c:\Research\AAD', false);  % 2-channel only
```

---

## 📁 **FILE EXECUTION ORDER**

| Step | File Name | Purpose | Time | Required |
|------|-----------|---------|------|----------|
| 0 | `setup_aad_environment.m` | Initialize environment | 2 min | ✅ YES |
| 1 | `complete_aad_multichannel_example.m` | Create 6/8-ch stimuli | 10 min | ⚠️ For multichannel |
| 2 | `preprocess_data.m` | Original 2-ch preprocessing | 15 min | ✅ YES |
| 3 | `preprocess_multichannel_aad_data.m` | 8-ch preprocessing | 10 min | ⚠️ For multichannel |
| 4 | `aad_algorithm_comparison_pipeline.m` | **MAIN ANALYSIS** | 45 min | ✅ YES |
| 5 | `test_aad_comparison.m` | View results | 1 min | ✅ YES |
| 6 | `auditory_encoding_analysis.m` | Deep encoding analysis | 10 min | ❌ Optional |

---

## ⚡ **FASTEST PATH TO RESULTS**

If you just want to see if multichannel helps AAD:

```matlab
% 1. Setup (one-time)
cd('c:\Research\AAD\scripts');
setup_aad_environment;

% 2. Create multichannel data
complete_aad_multichannel_example;

% 3. Run comparison (this does everything)
aad_algorithm_comparison_pipeline('c:\Research\AAD', true);
```

**Total time: ~60 minutes**

---

## 🔍 **WHAT EACH ALGORITHM DOES**

### **1. Correlation-based AAD**
- **Method**: Cross-correlates EEG with audio envelopes
- **Encoding**: Needs envelope extraction (gammatone + powerlaw)
- **Output**: Correlation coefficients → attention classification

### **2. Temporal Response Function (TRF)**
- **Method**: Models brain response to audio features over time
- **Encoding**: Critical! Uses auditory filterbank features
- **Output**: Temporal filters → reconstruct audio from EEG

### **3. Canonical Correlation Analysis (CCA)**
- **Method**: Finds maximally correlated components between EEG and audio
- **Encoding**: Benefits from multi-dimensional auditory features
- **Output**: Canonical components → attention decoding

---

## 📊 **EXPECTED RESULTS**

After running the pipeline, you'll answer:

### **Q1: Do multichannel stimuli improve AAD?**
- **Answer**: Check `aad_comparison_visualization.png`
- **Typical result**: 2-10% improvement for some algorithms

### **Q2: Which AAD algorithm works best?**
- **Answer**: Usually TRF > CCA > Correlation
- **Depends on**: Data quality, preprocessing, subject variability

### **Q3: Is auditory encoding important?**
- **Answer**: YES! ~50-300% improvement with proper encoding
- **Evidence**: Run `auditory_encoding_analysis.m` to see

### **Q4: Best spatial configuration?**
- **Answer**: Side speakers (SL/SR) often better than front (FL/FR)
- **Reason**: Larger spatial separation improves discrimination

---

## 🛠️ **TROUBLESHOOTING**

### **"AMToolbox not found"**
```matlab
% Download from http://amtoolbox.org/ and run:
addpath('path/to/amtoolbox');
amt_start;
```

### **"Out of memory"**
```matlab
% Use fewer subjects or shorter trials
% Edit algorithm parameters in comparison pipeline
```

### **"No audio files found"**
- Download KULeuven dataset from: https://zenodo.org/records/4004271
- Ensure files are in `stimuli/` directory

### **"Preprocessing failed"**
- AMToolbox may not be installed correctly
- Try running without AMToolbox (basic envelope extraction)

---

## 🎯 **RESEARCH IMPLICATIONS**

### **For 2-Channel → Multichannel Comparison:**
1. **Spatial Diversity**: More channels → more spatial information
2. **Robustness**: Multichannel may be more robust to noise
3. **Position Effects**: Different speaker positions → different AAD accuracy
4. **Algorithm Specificity**: Some algorithms benefit more than others

### **For Auditory Encoding:**
1. **Brain Compatibility**: EEG reflects auditory cortical processing
2. **Feature Selection**: Gammatone mimics cochlear filtering
3. **Nonlinearity**: Power-law compression models hair cell response
4. **Frequency Bands**: Different frequencies contribute differently

---

## 🏁 **FINAL COMMAND SEQUENCE**

**Copy-paste this entire block:**

```matlab
% Complete AAD Analysis Pipeline
cd('c:\Research\AAD\scripts');

% 1. Setup environment
setup_aad_environment('c:\Research\AAD');

% 2. Create multichannel stimuli  
complete_aad_multichannel_example;

% 3. Run complete AAD comparison
aad_algorithm_comparison_pipeline('c:\Research\AAD', true);

% 4. View results
test_aad_comparison;

% 5. (Optional) Deep encoding analysis
% auditory_encoding_analysis('c:\Research\AAD');

fprintf('\n🎉 AAD Analysis Complete! Check aad_comparison_results/ folder 🎉\n');
```

**That's it! Your AAD analysis will be complete.**