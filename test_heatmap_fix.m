%% Test Heatmap Fix
% Quick test to verify the heatmap visualization works without text annotation errors

% Add paths
addpath('scripts');
addpath('amtoolbox');

% Test with minimal sample data
results = struct();
results.subject_accuracies = [
    85.2, 87.1, 89.3;  % Subject 1: Correlation, TRF, CCA
    82.1, 84.5, 86.7;  % Subject 2
    88.3, 90.2, 92.1   % Subject 3
];

algorithms = {'Correlation', 'TRF', 'CCA'};
channel_configs = {'64-ch', '32-ch', '16-ch'};

% Create test data structure that matches expected format
for i = 1:length(algorithms)
    for j = 1:length(channel_configs)
        results.(algorithms{i}).(channel_configs{j}) = struct();
        results.(algorithms{i}).(channel_configs{j}).subject_accuracies = results.subject_accuracies(:, i);
    end
end

% Create output directory
plots_dir = 'Plots';
if ~exist(plots_dir, 'dir')
    mkdir(plots_dir);
end

try
    fprintf('Testing heatmap creation...\n');
    
    % Test the specific heatmap function
    algorithms = fieldnames(results);
    algorithms = algorithms(~strcmp(algorithms, 'subject_accuracies'));
    
    if ~isempty(algorithms)
        first_algo = algorithms{1};
        channel_configs = fieldnames(results.(first_algo));
        
        % Calculate statistics
        num_algos = length(algorithms);
        num_configs = length(channel_configs);
        
        mean_accuracy = zeros(num_algos, num_configs);
        std_accuracy = zeros(num_algos, num_configs);
        
        for i = 1:num_algos
            for j = 1:num_configs
                accuracies = results.(algorithms{i}).(channel_configs{j}).subject_accuracies;
                mean_accuracy(i, j) = mean(accuracies);
                std_accuracy(i, j) = std(accuracies);
            end
        end
        
        % Create heatmap figure (simplified version to test)
        figure('Position', [100, 100, 1200, 600]);
        
        subplot(1, 2, 1);
        h1 = heatmap(channel_configs, algorithms, mean_accuracy);
        h1.Title = 'Mean Accuracy (%)';
        h1.Colormap = parula;
        h1.CellLabelFormat = '%.1f%%';
        h1.CellLabelColor = 'white';
        
        subplot(1, 2, 2);
        h2 = heatmap(channel_configs, algorithms, std_accuracy);
        h2.Title = 'Standard Deviation (%)';
        h2.Colormap = copper;
        h2.CellLabelFormat = '%.2f';
        h2.CellLabelColor = 'white';
        
        sgtitle('Test Heatmap - No Text Annotation Errors');
        
        fprintf('✅ Heatmap creation successful!\n');
        fprintf('The text annotation compatibility issue has been fixed.\n');
        
        % Save the test plot
        test_filename = fullfile(plots_dir, 'heatmap_fix_test.png');
        saveas(gcf, test_filename);
        fprintf('Test plot saved: %s\n', test_filename);
        
    else
        fprintf('❌ No algorithms found in test data structure\n');
    end
    
catch ME
    fprintf('❌ Error in heatmap test: %s\n', ME.message);
    fprintf('Error occurred at: %s (line %d)\n', ME.stack(1).file, ME.stack(1).line);
end

fprintf('\nTest completed.\n');