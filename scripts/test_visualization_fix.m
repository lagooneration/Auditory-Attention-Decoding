function test_visualization_fix()
% TEST_VISUALIZATION_FIX Test the fixed visualization function
% This function tests if the visualization works with the corrected field names

fprintf('=== Testing Fixed AAD Visualization ===\n');

% Check if results file exists
basedir = 'c:\Research\AAD';
results_file = fullfile(basedir, 'aad_comparison_results', 'complete_aad_comparison_results.mat');

if ~exist(results_file, 'file')
    fprintf('❌ Results file not found: %s\n', results_file);
    fprintf('Please run aad_algorithm_comparison_pipeline first.\n');
    return;
end

% Load and examine results structure
fprintf('Loading results file...\n');
load(results_file, 'results');

% Display structure information
fprintf('\n📊 Results Structure Analysis:\n');
fprintf('Available algorithms: %s\n', strjoin(results.algorithms, ', '));
fprintf('Available configurations: %s\n', strjoin(results.channel_configs, ', '));

% Check field names for each algorithm and configuration
for a = 1:length(results.algorithms)
    algorithm = results.algorithms{a};
    fprintf('\n🔍 %s Algorithm:\n', upper(algorithm));
    
    for c = 1:length(results.channel_configs)
        config = results.channel_configs{c};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            algo_results = results.(config).(algorithm);
            fields = fieldnames(algo_results);
            
            fprintf('  %s fields: %s\n', config, strjoin(fields, ', '));
            
            % Check specific fields we need
            if isfield(algo_results, 'subject_accuracies')
                n_subjects = length(algo_results.subject_accuracies);
                mean_acc = mean(algo_results.subject_accuracies);
                fprintf('  %s: %d subjects, mean accuracy: %.1f%%\n', config, n_subjects, mean_acc * 100);
            else
                fprintf('  ❌ %s: missing subject_accuracies field\n', config);
            end
        else
            fprintf('  ❌ %s: configuration not available\n', config);
        end
    end
end

% Test the visualization function
fprintf('\n🎨 Testing Visualization Function:\n');
try
    % Create plots directory if it doesn't exist
    plots_dir = fullfile(basedir, 'Plots');
    if ~exist(plots_dir, 'dir')
        mkdir(plots_dir);
    end
    
    fprintf('Calling create_aad_visualization_plots...\n');
    create_aad_visualization_plots(basedir);
    
    fprintf('✅ Visualization function completed successfully!\n');
    
    % List generated plots
    plot_files = dir(fullfile(plots_dir, '*.png'));
    if ~isempty(plot_files)
        fprintf('\n📈 Generated plots:\n');
        for i = 1:length(plot_files)
            fprintf('  - %s\n', plot_files(i).name);
        end
    else
        fprintf('⚠️ No plot files found in %s\n', plots_dir);
    end
    
catch ME
    fprintf('❌ Visualization function failed:\n');
    fprintf('Error: %s\n', ME.message);
    fprintf('Function: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    
    % Show the stack trace for debugging
    fprintf('\n🔍 Stack trace:\n');
    for i = 1:length(ME.stack)
        fprintf('  %d. %s (line %d): %s\n', i, ME.stack(i).name, ME.stack(i).line, ME.stack(i).file);
    end
end

fprintf('\n=== Test Complete ===\n');

end