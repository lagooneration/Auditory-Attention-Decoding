% Getting Started with Auditory Attention Detection Analysis
% This script guides you through analyzing your preprocessed EEG data

function getting_started_aad()
% GETTING_STARTED_AAD Complete workflow for auditory attention detection analysis

fprintf('=== Auditory Attention Detection Analysis Workflow ===\n\n');

%% Step 1: Check if preprocessed data exists
preprocessed_file = fullfile('preprocessed_data', 'S1.mat');

if ~exist(preprocessed_file, 'file')
    fprintf('❌ Preprocessed data not found: %s\n', preprocessed_file);
    fprintf('Please run: test_single_subject(pwd, ''S1.mat'') first\n\n');
    return;
end

fprintf('✅ Found preprocessed data: %s\n\n', preprocessed_file);

%% Step 2: Load and analyze the data structure
fprintf('📊 STEP 1: Analyzing preprocessed data structure...\n');
fprintf('%s\n', repmat('=', 1, 50));

try
    analyze_preprocessed_data(preprocessed_file);
    fprintf('✅ Data structure analysis completed\n\n');
catch ME
    fprintf('❌ Data analysis failed: %s\n\n', ME.message);
    return;
end

% Load trials for subsequent analysis
loaded_data = load(preprocessed_file);
trials = loaded_data.preproc_trials;

%% Step 3: Visualize sample trial
fprintf('📈 STEP 2: Visualizing trial data...\n');
fprintf('%s\n', repmat('=', 1, 50));

try
    % Plot first trial
    plot_trial_data(trials, 1, [0, 30]); % First 30 seconds
    fprintf('✅ Trial visualization completed\n');
    fprintf('   Check the generated figure: trial_1_visualization.png\n\n');
catch ME
    fprintf('❌ Visualization failed: %s\n\n', ME.message);
end

%% Step 4: Run attention detection algorithms
fprintf('🧠 STEP 3: Running attention detection algorithms...\n');
fprintf('%s\n', repmat('=', 1, 50));

% Test multiple methods
methods = {'correlation', 'trf', 'cca'};
method_results = {};

for i = 1:length(methods)
    method = methods{i};
    fprintf('\nTesting method: %s\n', method);
    
    try
        results = detect_auditory_attention(trials, method);
        method_results{i} = results;
        fprintf('✅ %s method completed\n', method);
    catch ME
        fprintf('❌ %s method failed: %s\n', method, ME.message);
        method_results{i} = [];
    end
end

%% Step 5: Validate results
fprintf('\n🔍 STEP 4: Validating attention detection performance...\n');
fprintf('%s\n', repmat('=', 1, 50));

% Validate the best performing method
best_method = 'correlation'; % Start with correlation as default

try
    validation_results = validate_attention_detection(trials, best_method);
    fprintf('✅ Validation completed for %s method\n', best_method);
catch ME
    fprintf('❌ Validation failed: %s\n', ME.message);
end

%% Step 6: Summary and recommendations
fprintf('\n📋 STEP 5: Summary and Next Steps\n');
fprintf('%s\n', repmat('=', 1, 50));

fprintf('Analysis completed! Here''s what was generated:\n\n');

% List generated files
generated_files = {
    'trial_1_visualization.png', 'Trial visualization'
    'attention_results_correlation.mat', 'Correlation method results'
    'attention_results_trf.mat', 'TRF method results'
    'attention_results_cca.mat', 'CCA method results'
    'validation_results_correlation.mat', 'Validation results'
    'validation_plots_correlation.png', 'Validation plots'
    'S1_analysis.mat', 'Data structure analysis'
};

fprintf('Generated Files:\n');
for i = 1:size(generated_files, 1)
    filename = generated_files{i, 1};
    description = generated_files{i, 2};
    
    if exist(filename, 'file')
        fprintf('  ✅ %s - %s\n', filename, description);
    else
        fprintf('  ❌ %s - %s (not created)\n', filename, description);
    end
end

%% Step 7: Interpretation guidance
fprintf('\n🎯 INTERPRETATION GUIDE:\n');
fprintf('%s\n', repmat('=', 1, 50));

fprintf('1. DATA QUALITY:\n');
fprintf('   - Check data structure analysis for any issues\n');
fprintf('   - Verify EEG and audio envelope alignment\n');
fprintf('   - Look for artifacts or missing data\n\n');

fprintf('2. ATTENTION DETECTION RESULTS:\n');
fprintf('   - Predictions: 1 = Left ear attention, 2 = Right ear attention\n');
fprintf('   - Higher confidence values indicate more reliable predictions\n');
fprintf('   - Compare different methods to see consistency\n\n');

fprintf('3. VALIDATION METRICS:\n');
fprintf('   - Accuracy >70%%: Good performance\n');
fprintf('   - Accuracy 50-70%%: Moderate performance\n');
fprintf('   - Accuracy <50%%: Poor performance (below chance)\n\n');

fprintf('4. NEXT STEPS FOR RESEARCH:\n');
fprintf('   a) Process more subjects: test_single_subject(pwd, ''S2.mat'')\n');
fprintf('   b) Aggregate results across subjects\n');
fprintf('   c) Fine-tune algorithm parameters\n');
fprintf('   d) Implement ensemble methods\n');
fprintf('   e) Validate with known attention paradigms\n\n');

%% Step 8: Advanced analysis suggestions
fprintf('🔬 ADVANCED ANALYSIS OPTIONS:\n');
fprintf('%s\n', repmat('=', 1, 50));

fprintf('Available functions for deeper analysis:\n');
fprintf('• Cross-correlation analysis: cross_correlation_analysis(trials)\n');
fprintf('• Spectral analysis: spectral_analysis(trials)\n');
fprintf('• Source localization: source_localization_analysis(trials)\n');
fprintf('• Machine learning: ml_attention_detection(trials)\n');
fprintf('• Real-time simulation: realtime_attention_detection(trials)\n\n');

% Create a simple analysis summary
summary = struct();
summary.num_trials = length(trials);
summary.data_file = preprocessed_file;
summary.methods_tested = methods;
summary.timestamp = datestr(now);

% Save summary
save('analysis_summary.mat', 'summary');
fprintf('📁 Analysis summary saved to: analysis_summary.mat\n\n');

fprintf('🎉 ANALYSIS COMPLETE!\n');
fprintf('You now have a complete pipeline for auditory attention detection.\n');
fprintf('Review the generated files and validation results to assess performance.\n\n');

end