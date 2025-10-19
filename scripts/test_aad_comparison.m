function test_aad_comparison()
% TEST_AAD_COMPARISON Verify AAD comparison results and create visualizations
% This function checks if all necessary results files exist and then
% creates comprehensive visualization plots

fprintf('=== AAD Comparison Results Verification ===\n');

% Check if we're in the right directory
current_dir = pwd;
if ~contains(current_dir, 'AAD')
    fprintf('Warning: Current directory may not be the AAD project directory\n');
    fprintf('Current: %s\n', current_dir);
end

% Define expected directories and files
base_dir = fileparts(current_dir);
if contains(current_dir, 'scripts')
    base_dir = fileparts(current_dir);
else
    base_dir = current_dir;
end

fprintf('Base directory: %s\n', base_dir);

% Check for required directories
required_dirs = {
    'preprocessed_data',
    'stimuli/envelopes',
    'aad_comparison_results'
};

fprintf('\nChecking required directories...\n');
all_dirs_exist = true;
for i = 1:length(required_dirs)
    dir_path = fullfile(base_dir, required_dirs{i});
    if exist(dir_path, 'dir')
        fprintf('  ✓ %s\n', required_dirs{i});
    else
        fprintf('  ✗ %s (MISSING)\n', required_dirs{i});
        all_dirs_exist = false;
    end
end

% Check for results file
results_file = fullfile(base_dir, 'aad_comparison_results', 'complete_aad_comparison_results.mat');
fprintf('\nChecking results file...\n');
if exist(results_file, 'file')
    fprintf('  ✓ AAD comparison results found\n');
    
    % Load and examine results
    try
        load(results_file, 'results');
        fprintf('  ✓ Results loaded successfully\n');
        
        % Display results summary
        fprintf('\nResults Summary:\n');
        fprintf('  Algorithms: %s\n', strjoin(results.algorithms, ', '));
        fprintf('  Channel configs: %s\n', strjoin(results.channel_configs, ', '));
        
        % Check each configuration
        for i = 1:length(results.channel_configs)
            config = results.channel_configs{i};
            if isfield(results, config)
                fprintf('  %s configuration:\n', upper(config));
                for j = 1:length(results.algorithms)
                    algorithm = results.algorithms{j};
                    if isfield(results.(config), algorithm)
                        acc_data = results.(config).(algorithm).accuracy_per_subject;
                        fprintf('    %s: %.1f±%.1f%% (%d subjects)\n', ...
                            upper(algorithm), mean(acc_data), std(acc_data), length(acc_data));
                    end
                end
            end
        end
        
        results_available = true;
        
    catch ME
        fprintf('  ✗ Error loading results: %s\n', ME.message);
        results_available = false;
    end
else
    fprintf('  ✗ AAD comparison results file not found\n');
    fprintf('      Expected: %s\n', results_file);
    results_available = false;
end

% Check for multichannel data
fprintf('\nChecking multichannel data...\n');
multichannel_dirs = {'stimuli/multichannel_6ch', 'stimuli/multichannel_8ch'};
multichannel_available = false;

for i = 1:length(multichannel_dirs)
    dir_path = fullfile(base_dir, multichannel_dirs{i});
    if exist(dir_path, 'dir')
        % Count files in directory
        files = dir(fullfile(dir_path, '*.wav'));
        fprintf('  ✓ %s (%d audio files)\n', multichannel_dirs{i}, length(files));
        multichannel_available = true;
    else
        fprintf('  ✗ %s (MISSING)\n', multichannel_dirs{i});
    end
end

% Summary and recommendations
fprintf('\n=== Summary ===\n');
if all_dirs_exist && results_available
    fprintf('✓ All required components are available!\n');
    
    if multichannel_available
        fprintf('✓ Multichannel data is available\n');
    else
        fprintf('⚠ Multichannel data not found (run complete_aad_multichannel_example.m first)\n');
    end
    
    % Create visualizations
    fprintf('\n=== Creating Visualization Plots ===\n');
    try
        if exist('create_aad_visualization_plots', 'file')
            create_aad_visualization_plots(base_dir);
            fprintf('✓ Visualization plots created successfully!\n');
            
            plots_dir = fullfile(base_dir, 'Plots');
            fprintf('\nGenerated plots in: %s\n', plots_dir);
            
            % List generated plots
            plot_files = dir(fullfile(plots_dir, '*.png'));
            fprintf('Available visualizations:\n');
            for i = 1:length(plot_files)
                fprintf('  - %s\n', plot_files(i).name);
            end
            
        else
            fprintf('⚠ Visualization function not found\n');
            fprintf('  Please ensure create_aad_visualization_plots.m is in your path\n');
        end
        
    catch ME
        fprintf('✗ Error creating visualizations: %s\n', ME.message);
        fprintf('  Function: %s (line %d)\n', ME.stack(1).name, ME.stack(1).line);
    end
    
else
    fprintf('✗ Some required components are missing\n');
    
    if ~all_dirs_exist
        fprintf('\nTo fix missing directories, run the pipeline in order:\n');
        fprintf('1. preprocess_data(''%s'');\n', base_dir);
        fprintf('2. complete_aad_multichannel_example;\n');
        fprintf('3. aad_algorithm_comparison_pipeline(''%s'', true);\n', base_dir);
    end
    
    if ~results_available
        fprintf('\nTo generate results, run:\n');
        fprintf('aad_algorithm_comparison_pipeline(''%s'', true);\n', base_dir);
    end
end

% Check for specific visualization needs
fprintf('\n=== Available Analysis Options ===\n');
fprintf('You can create additional visualizations:\n');
fprintf('1. create_aad_visualization_plots(''%s''); %% Comprehensive plots\n', base_dir);

if results_available
    fprintf('2. Individual algorithm analysis available\n');
    fprintf('3. Statistical comparison plots available\n');
    fprintf('4. Subject-wise analysis available\n');
    fprintf('5. Performance improvement analysis available\n');
end

fprintf('\n=== Next Steps ===\n');
if results_available
    fprintf('Your AAD analysis is complete! Key findings:\n');
    
    if exist('results', 'var')
        % Quick analysis of best performing configuration
        best_performance = 0;
        best_config = '';
        best_algorithm = '';
        
        for i = 1:length(results.channel_configs)
            config = results.channel_configs{i};
            if isfield(results, config)
                for j = 1:length(results.algorithms)
                    algorithm = results.algorithms{j};
                    if isfield(results.(config), algorithm)
                        mean_acc = mean(results.(config).(algorithm).accuracy_per_subject);
                        if mean_acc > best_performance
                            best_performance = mean_acc;
                            best_config = config;
                            best_algorithm = algorithm;
                        end
                    end
                end
            end
        end
        
        fprintf('- Best performance: %s algorithm with %s (%.1f%%)\n', ...
            upper(best_algorithm), upper(best_config), best_performance);
        
        % Check for improvements
        if length(results.channel_configs) >= 2 && ...
           isfield(results, 'ch2') && isfield(results, 'ch8')
            
            improvements_found = false;
            for j = 1:length(results.algorithms)
                algorithm = results.algorithms{j};
                if isfield(results.ch2, algorithm) && isfield(results.ch8, algorithm)
                    mean_2ch = mean(results.ch2.(algorithm).accuracy_per_subject);
                    mean_8ch = mean(results.ch8.(algorithm).accuracy_per_subject);
                    if mean_8ch > mean_2ch
                        improvements_found = true;
                        fprintf('- %s shows %.1f%% improvement with 8-channel\n', ...
                            upper(algorithm), mean_8ch - mean_2ch);
                    end
                end
            end
            
            if ~improvements_found
                fprintf('- No significant improvements found with multichannel processing\n');
            end
        end
    end
    
    fprintf('\nRecommended next steps:\n');
    fprintf('1. Review visualization plots in the Plots directory\n');
    fprintf('2. Read the visualization_report.txt for detailed analysis\n');
    fprintf('3. Consider parameter tuning if results are suboptimal\n');
    fprintf('4. Use findings for research publication\n');
    
else
    fprintf('Please complete the AAD pipeline first:\n');
    fprintf('1. Ensure all preprocessing is complete\n');
    fprintf('2. Run the AAD algorithm comparison\n');
    fprintf('3. Return to this function for visualization\n');
end

fprintf('\n=== Test Complete ===\n');

end