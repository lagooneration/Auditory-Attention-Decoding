%% Test Complete Visualization Fix
% Test to verify all visualization functions work without errors

% Add paths
addpath('scripts');
addpath('amtoolbox');

% Create comprehensive test data structure
results = struct();

% Create sample subject accuracies
results.subject_accuracies = [
    85.2, 87.1, 89.3;  % Subject 1: Correlation, TRF, CCA
    82.1, 84.5, 86.7;  % Subject 2
    88.3, 90.2, 92.1   % Subject 3
];

algorithms = {'Correlation', 'TRF', 'CCA'};
channel_configs = {'64_ch', '32_ch', '16_ch'};

% Create algorithm-based structure
for i = 1:length(algorithms)
    for j = 1:length(channel_configs)
        results.(algorithms{i}).(channel_configs{j}) = struct();
        results.(algorithms{i}).(channel_configs{j}).subject_accuracies = results.subject_accuracies(:, i) + randn(3,1);
    end
end

% Add statistics (properly formatted)
results.statistics = struct();
for i = 1:length(algorithms)
    algorithm = algorithms{i};
    results.statistics.(algorithm) = struct();
    results.statistics.(algorithm).p_value = rand() * 0.1;  % Random p-value < 0.1
    results.statistics.(algorithm).effect_size = rand() * 1.2;  % Random effect size
    results.statistics.(algorithm).mean_difference = randn() * 5;  % Random difference
    results.statistics.(algorithm).ci_lower = results.statistics.(algorithm).mean_difference - 2;
    results.statistics.(algorithm).ci_upper = results.statistics.(algorithm).mean_difference + 2;
end

% Add required fields for report generation
results.algorithms = algorithms;
results.channel_configs = channel_configs;

% Create output directory
plots_dir = 'Plots';
if ~exist(plots_dir, 'dir')
    mkdir(plots_dir);
end

try
    fprintf('Testing complete visualization pipeline...\n');
    
    % Test each component separately to isolate any remaining issues
    fprintf('1. Testing statistical plots...\n');
    create_statistical_plots(results, plots_dir);
    fprintf('   ✅ Statistical plots completed\n');
    
    fprintf('2. Testing visualization report...\n');
    generate_visualization_report(results, plots_dir);
    fprintf('   ✅ Visualization report completed\n');
    
    fprintf('3. Testing heatmap creation...\n');
    create_comparison_heatmaps(results, plots_dir);
    fprintf('   ✅ Heatmap creation completed\n');
    
    fprintf('\n🎉 All visualization components working successfully!\n');
    fprintf('All previous errors have been resolved:\n');
    fprintf('  - Heatmap text annotation compatibility ✅\n');
    fprintf('  - Statistical plots struct conversion ✅\n');
    fprintf('  - Visualization report data validation ✅\n');
    
catch ME
    fprintf('❌ Error in visualization test: %s\n', ME.message);
    fprintf('Error occurred at: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
    
    % Print stack trace for debugging
    if length(ME.stack) > 1
        fprintf('\nFull stack trace:\n');
        for k = 1:min(5, length(ME.stack))
            fprintf('  %d: %s (line %d) in %s\n', k, ME.stack(k).name, ME.stack(k).line, ME.stack(k).file);
        end
    end
end

fprintf('\nVisualization fix test completed.\n');