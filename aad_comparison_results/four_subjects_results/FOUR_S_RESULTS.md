=== AAD Algorithm Comparison Report ===

Algorithm Performance Summary:
Algorithm    | ch2 Mean±STD    | ch8 Mean±STD   
------------------------------------------------
CORRELATION  |  49.0± 1.2%    |  92.5± 1.3%   
TRF          |  33.8± 6.3%    |  50.0±17.3%   
CCA          |  72.5±29.0%    |  52.5± 6.5%   

Channel Configuration Comparison:

CORRELATION Algorithm:
  Best configuration: ch8 (92.5%)
  Channel improvement: 43.5% (multichannel better)

TRF Algorithm:
  Best configuration: ch8 (50.0%)
  Channel improvement: 16.2% (multichannel better)

CCA Algorithm:
  Best configuration: ch2 (72.5%)
  Channel improvement: -20.0% (2-channel better)

----------------------------------------------------------

Statistical Analysis Results:
============================

CORRELATION Algorithm:
  2-channel: 49.0±1.2%
  8-channel: 92.5±1.3%
  Difference: 43.5% (p=0.000)
  Effect size (Cohen's d): 34.965
  Result: 8-channel significantly BETTER than 2-channel

TRF Algorithm:
  2-channel: 33.8±6.3%
  8-channel: 50.0±17.3%
  Difference: 16.2% (p=0.099)
  Effect size (Cohen's d): 1.247
  Result: No significant difference between configurations

CCA Algorithm:
  2-channel: 72.5±29.0%
  8-channel: 52.5±6.5%
  Difference: -20.0% (p=0.196)
  Effect size (Cohen's d): -0.952
  Result: No significant difference between configurations


=== AAD Comparison Pipeline Complete ===


=== Auditory Encoding Analysis for AAD ===

Analyzing auditory encoding for subject: S1.mat
Number of trials: 20

=== Analysis 1: Auditory Encoding Methods ===
Auditory Encoding Method Comparison:
  Raw Envelope: 0.007
  Processed Envelope: 0.041
  Spectrotemporal: 0.004
  Best method: Processed Envelope (0.041)

=== Analysis 2: EEG-Audio Correlation Analysis ===
EEG-Audio Correlation Analysis:
  Left ear - Best channel 47: 0.041
  Right ear - Best channel 12: 0.036
  Attended ear: R
  Correct prediction: No

=== Analysis 3: Multichannel vs 2-Channel Encoding ===
2-Channel vs Multichannel Encoding:
  2-channel best correlation: 0.041
  Multichannel correlation: 0.015
  Improvement: -0.026 (-62.9%)

=== Analysis 4: Frequency Band Contributions ===
Frequency Band Analysis (1 bands):
  Best band for left ear: 1 (0.041)
  Best band for right ear: 1 (0.036)

=== Analysis 5: EEG Channel Contributions ===
EEG Channel Analysis:
  Top 3 channels for left ear: 48, 47, 46
  Top 3 channels for right ear: 48, 12, 13

=== Summary and Recommendations ===
Recommendations for AAD Algorithm Development:

1. AUDITORY ENCODING IS ESSENTIAL:
   - Raw audio shows limited correlation with EEG
   - Proper auditory preprocessing (gammatone + powerlaw) improves correlation
   - Spectrotemporal features may provide additional benefits

2. ENCODING METHOD SELECTION:
   - Best performing method: Processed Envelope
   - Recommendation: Use this method for optimal AAD performance

3. EEG CHANNEL SELECTION:
   - Not all EEG channels contribute equally to audio correlation
   - Focus on channels 47, 12 for best results
   - Consider spatial filtering to optimize channel combinations

4. ALGORITHM IMPLICATIONS:
   - TRF methods: Benefit from proper auditory encoding
   - Correlation methods: Sensitive to envelope extraction quality
   - CCA methods: Can adapt to encoding but better input helps

5. MULTICHANNEL CONSIDERATIONS:
   - Multichannel data provides spatial diversity
   - May improve robustness even if single-channel correlation is similar
   - Enables spatial attention analysis


---------------------------------------------------------------

=== Processing 2-Channel Configuration ===
Loaded 2-channel data for subject S1.mat: 20 trials
Loaded 2-channel data for subject S2.mat: 20 trials
Loaded 2-channel data for subject S3.mat: 20 trials
Loaded 2-channel data for subject S4.mat: 20 trials

Running CORRELATION algorithm on 2-Channel data...
Completed CORRELATION on 2-Channel: Mean accuracy = 48.99%

Running TRF algorithm on 2-Channel data...
Completed TRF on 2-Channel: Mean accuracy = 33.75%

---------------------------------------------------------------

=== Processing 8-Channel Configuration ===
Loaded 8-channel data for subject S1.mat: 20 trials
Loaded 8-channel data for subject S2.mat: 20 trials
Loaded 8-channel data for subject S3.mat: 20 trials
Loaded 8-channel data for subject S4.mat: 20 trials

Running CORRELATION algorithm on 8-Channel data...
Completed CORRELATION on 8-Channel: Mean accuracy = 92.51%

Running TRF algorithm on 8-Channel data...
Completed TRF on 8-Channel: Mean accuracy = 50.00%

--------------------------------------------------------------


=== AAD Algorithm Comparison Report ===

Algorithm Performance Summary:
Algorithm    | ch2 Mean±STD    | ch8 Mean±STD   
------------------------------------------------
CORRELATION  |  49.0± 1.2%    |  92.5± 1.3%   
TRF          |  33.8± 6.3%    |  50.0±17.3%   
CCA          |  72.5±29.0%    |  52.5± 6.5%   

Channel Configuration Comparison:

CORRELATION Algorithm:
  Best configuration: ch8 (92.5%)
  Channel improvement: 43.5% (multichannel better)

TRF Algorithm:
  Best configuration: ch8 (50.0%)
  Channel improvement: 16.2% (multichannel better)

CCA Algorithm:
  Best configuration: ch2 (72.5%)
  Channel improvement: -20.0% (2-channel better)

Creating visualization plots...

Performing statistical analysis...
Statistical Analysis Results:
============================

CORRELATION Algorithm:
  2-channel: 49.0±1.2%
  8-channel: 92.5±1.3%
  Difference: 43.5% (p=0.000)
  Effect size (Cohen's d): 34.965
  Result: 8-channel significantly BETTER than 2-channel

TRF Algorithm:
  2-channel: 33.8±6.3%
  8-channel: 50.0±17.3%
  Difference: 16.2% (p=0.099)
  Effect size (Cohen's d): 1.247
  Result: No significant difference between configurations

CCA Algorithm:
  2-channel: 72.5±29.0%
  8-channel: 52.5±6.5%
  Difference: -20.0% (p=0.215)
  Effect size (Cohen's d): -0.952
  Result: No significant difference between configurations


=== AAD Comparison Pipeline Complete ===
Results saved to: c:\Research\AAD\aad_comparison_results

✓ AAD comparison completed successfully!
Results saved to: c:\Research\AAD\aad_comparison_results



=== Quick Results Summary ===

CORRELATION Algorithm:
  ch2: 49.0 ± 1.2%
  ch8: 92.5 ± 1.3%

TRF Algorithm:
  ch2: 33.8 ± 6.3%
  ch8: 50.0 ± 17.3%

CCA Algorithm:
  ch2: 72.5 ± 29.0%
  ch8: 52.5 ± 6.5%


⚠️ Algorithm Performance Issues (17% and 29% accuracy):
The statistical analysis reveals that the performance changes between 2 and 8 channels for these two methods are not statistically significant (p-values of 0.099 and 0.196, respectively).

Best Overall Algorithm: The CORRELATION algorithm is by far the most effective and reliable method. It shows a massive, statistically significant performance jump (from 49.0% to 92.5%) when using 8 channels instead of 2.

CCA's Counterintuitive Result: While CCA appears "better" with 2 channels (72.5%) than 8 (52.5%), its 2-channel performance has a massive standard deviation (±29.0%). This indicates that the 72.5% average is highly unreliable and not a robust result.