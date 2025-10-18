
DATA INTERPRETATION:
==================================================
1. DATA QUALITY:
   - Check data structure analysis for any issues
   - Verify EEG and audio envelope alignment
   - Look for artifacts or missing data

2. ATTENTION DETECTION RESULTS:
   - Predictions: 1 = Left ear attention, 2 = Right ear attention
   - Higher confidence values indicate more reliable predictions
   - Compare different methods to see consistency

3. VALIDATION METRICS:
   - Accuracy >70%: Good performance
   - Accuracy 50-70%: Moderate performance
   - Accuracy <50%: Poor performance (below chance)


=== Attention Detection Results Analysis ===

📊 STEP 1: Loading attention detection results...
==================================================
✅ Loading: attention_results_correlation.mat
   Method: Correlation
   Trials: 4
   Left attention: 3 trials (75.0%)
   Right attention: 1 trials (25.0%)
   Mean confidence: 0.023 (range: 0.013 to 0.032)

✅ Loading: attention_results_trf.mat
   Method: Temporal Response Function
   Trials: 20
   Left attention: 9 trials (45.0%)
   Right attention: 11 trials (55.0%)
   Mean confidence: 0.010 (range: 0.000 to 0.023)

✅ Loading: attention_results_cca.mat
   Method: Canonical Correlation Analysis
   Trials: 20
   Left attention: 7 trials (35.0%)
   Right attention: 13 trials (65.0%)
   Mean confidence: 0.017 (range: 0.000 to 0.163)

🔍 STEP 2: Loading validation results...
==================================================
✅ Loading: validation_results_correlation.mat
   Method: correlation
   Overall Accuracy: 60.0%
   Performance: 🟠 MODERATE (50-60%)
   Confidence stats: Mean=0.015, Std=0.011
   Cross-validation: 60.0% ± 22.4%

📈 STEP 3: Detailed method comparison...
==================================================
Method Comparison:
Method       | Left%    | Right%   | Mean Conf    | Consistency 
------------------------------------------------------------
correlation  |    75.0% |    25.0% |       0.023 |        50.0%
trf          |    45.0% |    55.0% |       0.010 |        30.0%
cca          |    35.0% |    65.0% |       0.017 |         5.0%

Method Agreement Analysis:
Cannot compare methods - different number of trials:
• correlation: 4 trials
• trf: 20 trials
• cca: 20 trials

🔬 STEP 4: Trial-by-trial detailed analysis...
==================================================
Detailed analysis using correlation method:

Trial-by-trial results (sorted by confidence):
Trial | Prediction | Confidence | Interpretation 
--------------------------------------------------
    3 | Left ear   |      0.032 | Above average  
    4 | Left ear   |      0.031 | Above average  
    1 | Left ear   |      0.015 | Below average  
    2 | Right ear  |      0.013 | Below average  

📊 STEP 5: Statistical analysis...
==================================================
Statistical Summary:
• Total trials: 4
• Left ear predictions: 3 (75.0%)
• Right ear predictions: 1 (25.0%)

Confidence Analysis:
• Mean: 0.023
• Median: 0.023
• Standard deviation: 0.010
• Range: [0.013, 0.032]

Distribution Analysis:
• 25th percentile: 0.014
• 50th percentile (median): 0.023
• 75th percentile: 0.032

Bias Analysis:
• Left ear mean confidence: 0.026
• Right ear mean confidence: 0.013
• Confidence difference p-value: 0.369 (no significant difference)




----------------------------------------

Biesmans, W., Das, N., Francart, T., & Bertrand, A. (2016). Auditory-inspired speech envelope extraction methods for improved EEG-based auditory attention detection in a cocktail party scenario. IEEE Transactions on Neural Systems and Rehabilitation Engineering, 25(5), 402-412.

***************************************
IMPORTANT UPDATE FROM THE AUTHORS (January 2024):

We have observed the widespread utilization of this dataset in numerous research papers, establishing it as a standard benchmark for evaluating novel decoding strategies in auditory attention decoding (AAD).
We wish to underscore the vital importance of conducting rigorous cross-validation in such investigations. In the original study by Biesmans et al., which produced this dataset, linear correlation-based methods were employed, and a straightforward random cross-validation sufficed. However, with the recent surge in the application of machine learning techniques, particularly deep neural networks, in tackling the AAD challenge, a more stringent cross-validation approach becomes imperative. Deep networks are susceptible to overfitting to trial-specific patterns in EEG data, even from very brief segments (less than 1 second), leading to the ability to identify the trial source. Since a subject typically maintains attention to the same speaker throughout a trial, having knowledge of the trial effectively results in a perfect attention decoding.

We observed that many research papers utilizing our dataset still adhere to the basic random cross-validation method, neglecting the separation of trials into training and testing sets. Consequently, these studies frequently report remarkably high AAD accuracies when using extremely short EEG segments (one or a few seconds). Nevertheless, research has demonstrated that such an approach yields inaccurate and excessively optimistic outcomes. Accuracies often plummet significantly, sometimes even falling below chance levels, when employing a proper cross-validation where this trial bias is removed (e.g., leave-one-trial-out, leave-one-story-out, or leave-one-subject-out cross-validation).
This overfitting effect is described in:

Corentin Puffay et al., "Relating EEG to continuous speech using deep neural networks: a review", Journal of Neural Engineering 20, 041003, 2023 DOI:10.1088/1741-2552/ace73f

Moreover, it's important to note that AAD strategies which directly classify an EEG snippet, rather than explicitly computing a correlation between the decoder output and the corresponding speech envelopes, may be susceptible to an eye-gaze bias. This bias refers to the tendency of the subject to subtly and often unknowingly direct their gaze towards the attended speaker. Given that EEG equipment can inadvertently capture these gaze patterns, it becomes possible to leverage this gaze information, whether intentionally or unintentionally, to enhance AAD performance. It's crucial to highlight that within this dataset, there are no controls in place to account for or mitigate this eye-gaze bias.

This eye-gaze overfitting effects is discussed in:
Rotaru et al. "What are we really decoding? Unveiling biases in EEG-based decoding of the spatial focus of auditory attention", published in Journal of Neural Engineering, also available on bioRxiv 2023.07.13.548824; doi: https://doi.org/10.1101/2023.07.13.548824


***************************************
Explanation about the data set:


Auditory Attention Detection Dataset KULeuven

This work was done at ExpORL, Dept. Neurosciences, KULeuven and Dept. Electrical Engineering (ESAT), KULeuven.
This dataset contains EEG data collected from 16 normal-hearing subjects. EEG recordings were made in a soundproof, electromagnetically shielded room at ExpORL, KULeuven. The BioSemi ActiveTwo system was used to record 64-channel EEG signals at 8196 Hz sample rate. The audio signals, low pass filtered at 4 kHz, were administered to each subject at 60 dBA through a pair of insert phones (Etymotic ER3A). The experiments were conducted using the APEX 3 program developed at ExpORL [1].

Four Dutch short stories [2], narrated by different male speakers, were used as stimuli. All silences longer than 500 ms in the audio files were truncated to 500 ms. Each story was divided into two parts of approximately 6 minutes each. During a presentation, the subjects were presented with the six-minutes part of two (out of four) stories played simultaneously. There were two stimulus conditions, i.e., `HRTF' or `dry' (dichotic).  An experiment here is defined as a sequence of 4 presentations, 2 for each stimulus condition and ear of stimulation, with questions asked to the subject after each presentation. All subjects sat through three experiments within a single recording session. An example for the design of an experiment is shown in Table 1 in [3]. The first two experiments included four presentations each.  During a presentation, the subjects were instructed to listen to the story in one ear, while ignoring the story in the other ear. After each presentation, the subjects were presented with a set of multiple-choice questions about the story they were listening to in order to help them stay motivated to focus on the task. In the next presentation, the subjects were presented with the next part of the two stories. This time they were instructed to attend to their other ear. In this manner, one experiment involved four presentations in which the subjects listened to a total of two stories, switching attended ear between presentations. The second experiment had the same design but with two other stories. Note that the Table was different for each subject or recording session, i.e., each of the elements in the table were permuted between different recording sessions to ensure that the different conditions (stimulus condition and the attended ear) were equally distributed over the four presentations. Finally, the third experiment included a set of presentations where the first two minutes of the story parts from the first experiment, i.e. a total of four shorter presentations, were repeated three times, to build a set of recordings of repetitions. Thus, a total of approximately 72 minutes of EEG was recorded per subject. 

We refer to EEG recorded from each presentation as a trial. For each subject, we recorded 20 trials - 4 from  the first experiment, 4 from the second experiment, and 12 from the third experiment (first 2 minutes of the 4 presentations from experiment 1 X 3 repetitions). The EEG data is stored in subject specific mat files of the format 'Sx', 'x' referring to the subject number. The audio data is stored as wav files in the folder 'stimuli'. Please note that the stories were not of equal lengths, and the subjects were allowed to finish listening to a story, even in cases where the competing story was over. Therefore, for each trial, we suggest referring to the length of the EEG recordings to truncate the ends of the corresponding audio data. This will ensure that the processed data (EEG and audio) contains only competing talker scenarios. Each trial was high-pass filtered  (0.5 Hz cut off) and downsampled from the recorded sampling rate of 8192 Hz to 128 Hz. 

Each trial (trial*.mat) contains the following information: 

RawData.Channels : channel numbers (1 to 64)
RawData.EegData :   EEG data (samples X channels)
FileHeader.SampleRate : Sampling frequency of the saved data
TrialID : a number between 1 to 20, showing the trial number
attended_ear : the direction of attention of the subject. 'L' for left, 'R' for right
stimuli : cell array with stimuli{1} and stimuli{2} indicating the name of audio files presented in the left ear and the right ear of the subject respectively
condition : stimulus presentation condition. 'HRTF' - stimuli were filtered with HRTF functions to simulate audio from 90 degrees to the left and 90 degrees to the right of the speaker, 'dry' - a dichotic presentation in which there was one story track each presented separately via the left and the right earphones.
experiment : the number of the experiment (1,2 or 3)
part : part of the story track being presented (can be 1 to 4 for experiments 1 and 2, and 1 to 12 for experiment 3)
attended_track : the attended story track. '1' for track 1 and '2' for track 2. Each track maintains continuity of the story. In Experiment 1, attention is always to track 1, and in Experiment 2, attention is always to track 2. 
repetition : binary variable indicating where the trial is a repetition (of presented stimuli) or not.
subject : subject id of the format 'Sx', 'x' being the subject number.

The 'stimuli' folder contains wav files of the format: part{part number}_track{track number}_{condition}.wav. Although the folder contains stimuli with HRTF filtering as well, for the analysis, we have assumed knowledge of the original clean stimuli (i.e. stimuli presented under the 'dry' condition), and hence envelopes were extracted only from part{part number}_track{tracknumber}_dry.wav files.

The Matlab file 'preprocess_data.m' gives an example of how the synchronization and preprocessing of EEG and audio data can be done as described in [5]. Dependency: AMToolbox.

This dataset has been used in [3, 5-14]. 

[1] Francart, T., Van Wieringen, A., & Wouters, J. (2008). APEX 3: a multi-purpose test platform for auditory psychophysical experiments. Journal of neuroscience methods, 172(2), 283-293.
[2] Radioboeken voor kinderen, http://radioboeken.eu/kinderradioboeken.php?lang=NL, 2007 (Accessed: 30 March 2015)
[3] Das, N., Biesmans, W., Bertrand, A., & Francart, T. (2016). The effect of head-related filtering and ear-specific decoding bias on auditory attention detection. Journal of neural engineering, 13(5), 056014.
[4] Somers, B., Francart, T., & Bertrand, A. (2018). A generic EEG artifact removal algorithm based on the multi-channel Wiener filter. Journal of neural engineering, 15(3), 036007.
[5] Das, N., Vanthornhout, J., Francart, T., & Bertrand, A. (2019). Stimulus-aware spatial filtering for single-trial neural response and temporal response function estimation in high-density EEG with applications in auditory research. bioRxiv 541318; doi: https://doi.org/10.1101/541318
[6] Biesmans, W., Das, N., Francart, T., & Bertrand, A. (2016). Auditory-inspired speech envelope extraction methods for improved EEG-based auditory attention detection in a cocktail party scenario. IEEE Transactions on Neural Systems and Rehabilitation Engineering, 25(5), 402-412.
[7] Das, N., Van Eyndhoven, S., Francart, T., & Bertrand, A. (2016, August). Adaptive attention-driven speech enhancement for EEG-informed hearing prostheses. In 2016 38th Annual International Conference of the IEEE Engineering in Medicine and Biology Society (EMBC) (pp. 77-80). IEEE.
[8] Van Eyndhoven, S., Francart, T., & Bertrand, A. (2016). EEG-informed attended speaker extraction from recorded speech mixtures with application in neuro-steered hearing prostheses. IEEE Transactions on Biomedical Engineering, 64(5), 1045-1056.
[9] Das, N., Van Eyndhoven, S., Francart, T., & Bertrand, A. (2017, August). EEG-based attention-driven speech enhancement for noisy speech mixtures using N-fold multi-channel Wiener filters. In 2017 25th European Signal Processing Conference (EUSIPCO) (pp. 1660-1664). IEEE.
[10] Narayanan, A. M., & Bertrand, A. (2018, July). The effect of miniaturization and galvanic separation of EEG sensor devices in an auditory attention detection task. In 2018 40th Annual International Conference of the IEEE Engineering in Medicine and Biology Society (EMBC) (pp. 77-80). IEEE.
[11] Deckers, L., Das, N., Ansari, A. H., Bertrand, A., & Francart, T. (2018). EEG-based detection of the attended speaker and the locus of auditory attention with convolutional neural networks. bioRxiv 475673; doi: https://doi.org/10.1101/475673
[12] Narayanan, A. M., & Bertrand, A. (2019). Analysis of miniaturization effects and channel selection strategies for EEG sensor networks with application to auditory attention detection. IEEE Transactions on Biomedical Engineering.
[13] Geirnaert, S., Francart, T., & Bertrand, A. A New Metric to evaluate auditory attention detection performance based on a Markov chain. Accepted for publication in Proc. European Signal Processing Conference (EUSIPCO), A Coruna, Spain, Sep. 2019.
[14] Geirnaert, S., Francart,T., Bertrand A. (2019). An  Interpretable performance metric for auditory attention decoding algorithms in  a  context  of  neuro-steered  gain  control. bioRxiv 745695; doi: https://doi.org/10.1101/745695 





