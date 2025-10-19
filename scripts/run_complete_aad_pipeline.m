%% AAD COMPLETE PIPELINE EXECUTION SCRIPT
% This script runs the complete AAD analysis pipeline in the correct order
% 
% IMPORTANT: Read EXECUTION_GUIDE.md first for detailed instructions
%
% Usage: 
%   1. Set your base directory below
%   2. Run this script section by section (recommended)
%   3. Or run the entire script (may take 1-2 hours)

%% CONFIGURATION
% Set your AAD data directory here
BASEDIR = 'c:\Research\AAD';

% Navigate to scripts directory
cd(fullfile(BASEDIR, 'scripts'));

% Execution options
RUN_MULTICHANNEL = true;        % Set to false to skip multichannel analysis
RUN_ENCODING_ANALYSIS = false;  % Set to true for detailed encoding analysis
QUICK_TEST = false;             % Set to true for faster testing with fewer algorithms

fprintf('=== AAD COMPLETE PIPELINE EXECUTION ===\n');
fprintf('Base directory: %s\n', BASEDIR);
if RUN_MULTICHANNEL
    fprintf('Multichannel analysis: Enabled\n');
else
    fprintf('Multichannel analysis: Disabled\n');
end

if RUN_ENCODING_ANALYSIS
    fprintf('Encoding analysis: Enabled\n');
else
    fprintf('Encoding analysis: Disabled\n');
end

if QUICK_TEST
    fprintf('Quick test mode: Enabled\n');
else
    fprintf('Quick test mode: Disabled\n');
end
fprintf('\nPress any key to continue...\n');
pause;

%% STEP 1: ENVIRONMENT SETUP
fprintf('\n=== STEP 1: ENVIRONMENT SETUP ===\n');
fprintf('Running setup_aad_environment...\n');

try
    setup_aad_environment(BASEDIR);
    fprintf('✓ Environment setup completed successfully\n');
catch ME
    fprintf('✗ Environment setup failed: %s\n', ME.message);
    fprintf('Please check the error and fix before continuing.\n');
    return;
end

fprintf('\nPress any key to continue to Step 2...\n');
pause;

%% STEP 2: CREATE MULTICHANNEL STIMULI
if RUN_MULTICHANNEL
    fprintf('\n=== STEP 2: CREATE MULTICHANNEL STIMULI ===\n');
    fprintf('This will create 6-channel and 8-channel competitive scenarios...\n');
    fprintf('Estimated time: 5-10 minutes\n\n');
    
    try
        complete_aad_multichannel_example;
        fprintf('✓ Multichannel stimuli created successfully\n');
    catch ME
        fprintf('✗ Multichannel stimuli creation failed: %s\n', ME.message);
        fprintf('Continuing with 2-channel analysis only...\n');
        RUN_MULTICHANNEL = false;
    end
else
    fprintf('\n=== STEP 2: SKIPPED (Multichannel disabled) ===\n');
end

fprintf('\nPress any key to continue to Step 3...\n');
pause;

%% STEP 3: PREPROCESS ORIGINAL DATA
fprintf('\n=== STEP 3: PREPROCESS ORIGINAL 2-CHANNEL DATA ===\n');
fprintf('Running original preprocessing pipeline...\n');
fprintf('Estimated time: 10-20 minutes\n\n');

try
    % Check if already preprocessed
    preprocdir = fullfile(BASEDIR, 'preprocessed_data');
    if exist(preprocdir, 'dir') && ~isempty(dir(fullfile(preprocdir, 'S*.mat')))
        fprintf('Preprocessed data already exists. Skipping...\n');
        fprintf('Delete %s to reprocess.\n', preprocdir);
    else
        preprocess_data(BASEDIR);
        fprintf('✓ 2-channel preprocessing completed successfully\n');
    end
catch ME
    fprintf('✗ 2-channel preprocessing failed: %s\n', ME.message);
    fprintf('Cannot continue without preprocessed data.\n');
    return;
end

fprintf('\nPress any key to continue to Step 4...\n');
pause;

%% STEP 4: PREPROCESS MULTICHANNEL DATA
if RUN_MULTICHANNEL
    fprintf('\n=== STEP 4: PREPROCESS MULTICHANNEL DATA ===\n');
    fprintf('Processing 8-channel envelope data...\n');
    fprintf('Estimated time: 5-10 minutes\n\n');
    
    try
        % Check if already preprocessed
        envelope_dir = fullfile(BASEDIR, 'stimuli', 'multichannel_8ch', 'envelopes');
        if exist(envelope_dir, 'dir') && ~isempty(dir(fullfile(envelope_dir, '*.mat')))
            fprintf('Multichannel envelopes already exist. Skipping...\n');
            fprintf('Delete %s to reprocess.\n', envelope_dir);
        else
            preprocess_multichannel_aad_data(BASEDIR, 8);
            fprintf('✓ 8-channel preprocessing completed successfully\n');
        end
    catch ME
        fprintf('✗ 8-channel preprocessing failed: %s\n', ME.message);
        fprintf('Continuing with 2-channel analysis only...\n');
        RUN_MULTICHANNEL = false;
    end
else
    fprintf('\n=== STEP 4: SKIPPED (Multichannel disabled) ===\n');
end

fprintf('\nPress any key to continue to Step 5...\n');
pause;

%% STEP 5: RUN AAD ALGORITHM COMPARISON
fprintf('\n=== STEP 5: AAD ALGORITHM COMPARISON ===\n');
fprintf('Running comprehensive AAD algorithm comparison...\n');
fprintf('Algorithms: Correlation, TRF, CCA\n');
fprintf('Configurations: 2-channel');
if RUN_MULTICHANNEL
    fprintf(' + 8-channel');
end
fprintf('\nEstimated time: 20-60 minutes\n\n');

try
    aad_algorithm_comparison_pipeline(BASEDIR, RUN_MULTICHANNEL);
    fprintf('✓ AAD algorithm comparison completed successfully\n');
catch ME
    fprintf('✗ AAD algorithm comparison failed: %s\n', ME.message);
    fprintf('Error details: %s\n', getReport(ME));
end

fprintf('\nPress any key to continue to Step 6...\n');
pause;

%% STEP 6: AUDITORY ENCODING ANALYSIS (Optional)
if RUN_ENCODING_ANALYSIS
    fprintf('\n=== STEP 6: AUDITORY ENCODING ANALYSIS ===\n');
    fprintf('Analyzing auditory perception encoding effects...\n');
    fprintf('Estimated time: 5-10 minutes\n\n');
    
    try
        auditory_encoding_analysis(BASEDIR);
        fprintf('✓ Auditory encoding analysis completed successfully\n');
    catch ME
        fprintf('✗ Auditory encoding analysis failed: %s\n', ME.message);
    end
else
    fprintf('\n=== STEP 6: SKIPPED (Encoding analysis disabled) ===\n');
end

fprintf('\nPress any key to continue to Step 7...\n');
pause;

%% STEP 7: RESULTS SUMMARY AND VERIFICATION
fprintf('\n=== STEP 7: RESULTS SUMMARY ===\n');
fprintf('Generating results summary...\n\n');

try
    test_aad_comparison;
    fprintf('✓ Results summary completed successfully\n');
catch ME
    fprintf('✗ Results summary failed: %s\n', ME.message);
end

%% FINAL SUMMARY
fprintf('\n=== EXECUTION COMPLETE ===\n');
fprintf('Pipeline execution finished!\n\n');

% Check what was created
results_dir = fullfile(BASEDIR, 'aad_comparison_results');
if exist(results_dir, 'dir')
    result_files = dir(results_dir);
    result_files = result_files(~[result_files.isdir]);
    
    fprintf('Generated %d result files in: %s\n', length(result_files), results_dir);
    
    % Show key files
    key_files = {
        'complete_aad_comparison_results.mat', 'Main results data'
        'aad_comparison_visualization.png', 'Performance plots'
        'comparison_report.txt', 'Text summary'
    };
    
    fprintf('\nKey result files:\n');
    for i = 1:size(key_files, 1)
        file_path = fullfile(results_dir, key_files{i, 1});
        if exist(file_path, 'file')
            fprintf('  ✓ %s - %s\n', key_files{i, 1}, key_files{i, 2});
        else
            fprintf('  ✗ %s - Missing\n', key_files{i, 1});
        end
    end
end

fprintf('\n=== RESEARCH QUESTIONS ANSWERED ===\n');
fprintf('1. Do multichannel stimuli improve AAD performance?\n');
fprintf('   → Check aad_comparison_visualization.png\n\n');

fprintf('2. Which AAD algorithm works best?\n');
fprintf('   → See algorithm comparison in results\n\n');

fprintf('3. Is auditory encoding important for AAD?\n');
if RUN_ENCODING_ANALYSIS
    fprintf('   → Detailed analysis completed\n\n');
else
    fprintf('   → Run: auditory_encoding_analysis(''%s'')\n\n', BASEDIR);
end

fprintf('4. How much improvement does spatial processing provide?\n');
if RUN_MULTICHANNEL
    fprintf('   → Statistical comparison in results\n\n');
else
    fprintf('   → Rerun with RUN_MULTICHANNEL = true\n\n');
end

fprintf('=== NEXT STEPS ===\n');
fprintf('1. Review results in: %s\n', results_dir);
fprintf('2. Open aad_comparison_visualization.png for plots\n');
fprintf('3. Read comparison_report.txt for statistics\n');
fprintf('4. Load complete_aad_comparison_results.mat for detailed data\n\n');

fprintf('For questions about results interpretation, see EXECUTION_GUIDE.md\n');

fprintf('\n🎉 AAD Analysis Pipeline Complete! 🎉\n');