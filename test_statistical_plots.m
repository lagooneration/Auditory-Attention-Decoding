%% Test Statistical Plots Fix
% Test to verify the statistical plots function works without struct conversion errors

% Add paths
addpath('scripts');
addpath('amtoolbox');

% Create test data structure with statistics
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
        results.(algorithms{i}).(channel_configs{j}).subject_accuracies = results.subject_accuracies(:, i);
    end
end

% Add mock statistics (if they don't exist, the function should handle gracefully)
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

% Add algorithms field
results.algorithms = algorithms;

% Create output directory
plots_dir = 'Plots';
if ~exist(plots_dir, 'dir')
    mkdir(plots_dir);
end

try
    fprintf('Testing statistical plots function...\n');
    
    % Call the create_statistical_plots function directly
    figure;  % Create a figure first
    create_statistical_plots(results, plots_dir);
    
    fprintf('✅ Statistical plots created successfully!\n');
    fprintf('The struct conversion error has been fixed.\n');
    
catch ME
    fprintf('❌ Error in statistical plots test: %s\n', ME.message);
    fprintf('Error occurred at: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
    
    % Print more details for debugging
    if length(ME.stack) > 1
        for k = 1:min(3, length(ME.stack))
            fprintf('  Stack %d: %s (line %d)\n', k, ME.stack(k).file, ME.stack(k).line);
        end
    end
end

fprintf('\nStatistical plots test completed.\n');