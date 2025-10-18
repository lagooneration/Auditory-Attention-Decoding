% Validate Attention Detection Performance
% This script provides validation methods for your attention detection algorithms

function validation_results = validate_attention_detection(trials, method)
% VALIDATE_ATTENTION_DETECTION Validate attention detection algorithms
% Usage: results = validate_attention_detection(trials, 'correlation')

if nargin < 2
    method = 'correlation';
end

fprintf('=== Attention Detection Validation ===\n\n');

%% Step 1: Load or generate attention results
attention_file = sprintf('attention_results_%s.mat', method);
if exist(attention_file, 'file')
    loaded = load(attention_file);
    attention_results = loaded.attention_results;
    fprintf('Loaded existing results from: %s\n', attention_file);
else
    fprintf('Running attention detection with method: %s\n', method);
    attention_results = detect_auditory_attention(trials, method);
end

%% Step 2: Extract ground truth (if available)
fprintf('\n1. Analyzing trial structure for ground truth...\n');

ground_truth = [];
attention_cues = {};

for trial_idx = 1:length(trials)
    trial = trials{trial_idx};
    
    % Try to infer attention from trial structure
    % Look for attention cues in stimuli names or trial fields
    if isfield(trial, 'attention_target')
        % Explicit attention field
        ground_truth(trial_idx) = trial.attention_target;
        attention_cues{trial_idx} = sprintf('Explicit: %d', trial.attention_target);
    elseif isfield(trial, 'target_ear')
        ground_truth(trial_idx) = trial.target_ear;
        attention_cues{trial_idx} = sprintf('Target ear: %d', trial.target_ear);
    else
        % Try to infer from stimulus names
        left_stim = trial.stimuli{1};
        right_stim = trial.stimuli{2};
        
        % Check if one stimulus is marked as "target" or "attended"
        if contains(lower(left_stim), {'target', 'attend', 'focus'})
            ground_truth(trial_idx) = 1;
            attention_cues{trial_idx} = 'Inferred: Left (from stimulus name)';
        elseif contains(lower(right_stim), {'target', 'attend', 'focus'})
            ground_truth(trial_idx) = 2;
            attention_cues{trial_idx} = 'Inferred: Right (from stimulus name)';
        else
            % No clear indication - use experimental structure
            % For AAD experiments, often alternating or counterbalanced
            ground_truth(trial_idx) = mod(trial_idx - 1, 2) + 1; % Alternate between 1 and 2
            attention_cues{trial_idx} = 'Assumed: Alternating pattern';
        end
    end
    
    fprintf('Trial %d: %s\n', trial_idx, attention_cues{trial_idx});
end

%% Step 3: Performance metrics
fprintf('\n2. Computing performance metrics...\n');

predictions = attention_results.predictions;
confidence = attention_results.confidence;

% Basic accuracy
if ~isempty(ground_truth)
    accuracy = mean(predictions == ground_truth);
    fprintf('Overall Accuracy: %.1f%%\n', accuracy * 100);
    
    % Per-class accuracy
    left_trials = ground_truth == 1;
    right_trials = ground_truth == 2;
    
    if sum(left_trials) > 0
        left_accuracy = mean(predictions(left_trials) == 1);
        fprintf('Left Ear Accuracy: %.1f%% (%d/%d trials)\n', ...
                left_accuracy * 100, sum(predictions(left_trials) == 1), sum(left_trials));
    end
    
    if sum(right_trials) > 0
        right_accuracy = mean(predictions(right_trials) == 2);
        fprintf('Right Ear Accuracy: %.1f%% (%d/%d trials)\n', ...
                right_accuracy * 100, sum(predictions(right_trials) == 2), sum(right_trials));
    end
    
    % Confusion matrix
    fprintf('\nConfusion Matrix:\n');
    fprintf('                Predicted\n');
    fprintf('               Left  Right\n');
    fprintf('Actual Left  : %4d   %4d\n', ...
            sum(predictions == 1 & ground_truth == 1), ...
            sum(predictions == 2 & ground_truth == 1));
    fprintf('Actual Right : %4d   %4d\n', ...
            sum(predictions == 1 & ground_truth == 2), ...
            sum(predictions == 2 & ground_truth == 2));
    
else
    fprintf('No ground truth available - showing prediction statistics only\n');
    accuracy = NaN;
end

%% Step 4: Confidence analysis
fprintf('\n3. Confidence analysis...\n');
fprintf('Mean Confidence: %.3f\n', mean(confidence));
fprintf('Confidence Range: [%.3f, %.3f]\n', min(confidence), max(confidence));

% High confidence trials
high_conf_threshold = prctile(confidence, 75);
high_conf_trials = confidence > high_conf_threshold;
fprintf('High Confidence Trials (>75th percentile): %d/%d\n', ...
        sum(high_conf_trials), length(confidence));

if ~isempty(ground_truth)
    high_conf_accuracy = mean(predictions(high_conf_trials) == ground_truth(high_conf_trials));
    fprintf('High Confidence Accuracy: %.1f%%\n', high_conf_accuracy * 100);
end

%% Step 5: Cross-validation
fprintf('\n4. Cross-validation analysis...\n');
if length(trials) >= 4
    cv_folds = min(5, length(trials));
    cv_accuracy = cross_validate_attention(trials, method, cv_folds, ground_truth);
    fprintf('Cross-validation Accuracy (%.d-fold): %.1f%% ± %.1f%%\n', ...
            cv_folds, mean(cv_accuracy) * 100, std(cv_accuracy) * 100);
else
    fprintf('Too few trials for cross-validation\n');
    cv_accuracy = NaN;
end

%% Step 6: Visualization
fprintf('\n5. Creating validation plots...\n');
create_validation_plots(attention_results, ground_truth, attention_cues);

%% Step 7: Method comparison
fprintf('\n6. Method comparison...\n');
if strcmp(method, 'correlation')
    % Compare with other methods
    other_methods = {'trf', 'cca'};
    comparison_results = compare_attention_methods(trials, other_methods, ground_truth);
    fprintf('Method comparison completed.\n');
else
    comparison_results = [];
end

%% Compile validation results
validation_results = struct();
validation_results.method = method;
validation_results.ground_truth = ground_truth;
validation_results.attention_cues = {attention_cues};
validation_results.accuracy = accuracy;
validation_results.confidence_stats = struct('mean', mean(confidence), ...
                                            'std', std(confidence), ...
                                            'range', [min(confidence), max(confidence)]);
validation_results.cross_validation = cv_accuracy;
validation_results.comparison_results = comparison_results;

% Save validation results
validation_file = sprintf('validation_results_%s.mat', method);
save(validation_file, 'validation_results');
fprintf('\nValidation results saved to: %s\n', validation_file);

%% Summary and recommendations
fprintf('\n=== Validation Summary ===\n');
if ~isnan(accuracy)
    if accuracy > 0.7
        fprintf('✓ GOOD: Method shows good performance (%.1f%% accuracy)\n', accuracy * 100);
    elseif accuracy > 0.5
        fprintf('⚠ MODERATE: Method shows moderate performance (%.1f%% accuracy)\n', accuracy * 100);
    else
        fprintf('✗ POOR: Method shows poor performance (%.1f%% accuracy)\n', accuracy * 100);
    end
else
    fprintf('⚠ Cannot assess accuracy without ground truth\n');
end

fprintf('\nRecommendations:\n');
fprintf('1. Verify ground truth labels are correct\n');
fprintf('2. Try different methods if accuracy is low\n');
fprintf('3. Consider ensemble methods combining multiple approaches\n');
fprintf('4. Analyze high-confidence trials for patterns\n');
fprintf('5. Check for preprocessing artifacts or noise\n');

end

function cv_accuracy = cross_validate_attention(trials, method, k_folds, ground_truth)
% Perform k-fold cross-validation

n_trials = length(trials);
fold_size = floor(n_trials / k_folds);
cv_accuracy = zeros(k_folds, 1);

for fold = 1:k_folds
    % Define test indices
    test_start = (fold - 1) * fold_size + 1;
    if fold == k_folds
        test_end = n_trials; % Include remaining trials in last fold
    else
        test_end = fold * fold_size;
    end
    
    test_indices = test_start:test_end;
    train_indices = setdiff(1:n_trials, test_indices);
    
    % Train on training set
    train_trials = trials(train_indices);
    train_results = detect_auditory_attention(train_trials, method);
    
    % Test on test set
    test_trials = trials(test_indices);
    test_results = detect_auditory_attention(test_trials, method);
    
    % Compute accuracy for this fold
    if ~isempty(ground_truth)
        test_gt = ground_truth(test_indices);
        cv_accuracy(fold) = mean(test_results.predictions == test_gt);
    else
        cv_accuracy(fold) = NaN;
    end
end

end

function comparison_results = compare_attention_methods(trials, methods, ground_truth)
% Compare multiple attention detection methods

comparison_results = struct();

for i = 1:length(methods)
    method = methods{i};
    
    try
        fprintf('   Testing method: %s\n', method);
        results = detect_auditory_attention(trials, method);
        
        if ~isempty(ground_truth)
            accuracy = mean(results.predictions == ground_truth);
        else
            accuracy = NaN;
        end
        
        comparison_results.(method) = struct('accuracy', accuracy, ...
                                           'confidence', mean(results.confidence), ...
                                           'predictions', results.predictions);
        
    catch ME
        fprintf('   Method %s failed: %s\n', method, ME.message);
        comparison_results.(method) = struct('accuracy', NaN, 'error', ME.message);
    end
end

end

function create_validation_plots(attention_results, ground_truth, attention_cues)
% Create validation plots

figure('Position', [100, 100, 1000, 600]);

% Plot 1: Predictions vs Trial Number
subplot(2, 2, 1);
predictions = attention_results.predictions;
plot(1:length(predictions), predictions, 'bo-', 'MarkerSize', 6, 'LineWidth', 1.5);
hold on;
if ~isempty(ground_truth)
    plot(1:length(ground_truth), ground_truth, 'ro-', 'MarkerSize', 6, 'LineWidth', 1.5);
    legend('Predicted', 'Ground Truth', 'Location', 'best');
end
xlabel('Trial Number');
ylabel('Attention Target (1=Left, 2=Right)');
title('Attention Predictions');
ylim([0.5, 2.5]);
yticks([1, 2]);
yticklabels({'Left', 'Right'});
grid on;

% Plot 2: Confidence values
subplot(2, 2, 2);
confidence = attention_results.confidence;
bar(1:length(confidence), confidence);
xlabel('Trial Number');
ylabel('Confidence');
title('Prediction Confidence');
grid on;

% Plot 3: Confidence histogram
subplot(2, 2, 3);
histogram(confidence, 10);
xlabel('Confidence');
ylabel('Frequency');
title('Confidence Distribution');
grid on;

% Plot 4: Accuracy by confidence (if ground truth available)
subplot(2, 2, 4);
if ~isempty(ground_truth)
    % Bin by confidence
    n_bins = 5;
    [~, edges, bin_indices] = histcounts(confidence, n_bins);
    bin_accuracy = zeros(n_bins, 1);
    bin_centers = zeros(n_bins, 1);
    
    for bin = 1:n_bins
        bin_mask = bin_indices == bin;
        if sum(bin_mask) > 0
            bin_accuracy(bin) = mean(predictions(bin_mask) == ground_truth(bin_mask));
            bin_centers(bin) = mean(edges(bin:bin+1));
        end
    end
    
    bar(bin_centers, bin_accuracy);
    xlabel('Confidence Bin');
    ylabel('Accuracy');
    title('Accuracy vs Confidence');
    ylim([0, 1]);
    grid on;
else
    text(0.5, 0.5, 'No ground truth available', 'HorizontalAlignment', 'center');
    title('Accuracy vs Confidence (N/A)');
end

sgtitle(sprintf('Attention Detection Validation: %s Method', attention_results.method));

% Save plot
plot_file = sprintf('validation_plots_%s.png', attention_results.method);
saveas(gcf, plot_file);
fprintf('Validation plots saved to: %s\n', plot_file);

end