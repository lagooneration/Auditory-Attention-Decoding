function create_aad_visualization_plots(basedir)
% CREATE_AAD_VISUALIZATION_PLOTS Generate comprehensive visualizations for AAD results
% This function creates detailed plots comparing AAD algorithm performance
% between 2-channel and 8-channel configurations
%
% Input:
%   basedir: Base directory containing AAD results (default: current directory)
%
% Generated plots:
% 1. Individual algorithm performance (2ch vs 8ch)
% 2. Algorithm comparison heatmaps
% 3. Statistical significance plots
% 4. Performance improvement analysis
% 5. Subject-wise comparison
% 6. Combined summary visualization

if nargin < 1
    basedir = pwd;
end

fprintf('=== Creating AAD Visualization Plots ===\n');

% Setup paths
results_dir = fullfile(basedir, 'aad_comparison_results');
plots_dir = fullfile(basedir, 'Plots');
if ~exist(plots_dir, 'dir')
    mkdir(plots_dir);
end

% Load results
results_file = fullfile(results_dir, 'complete_aad_comparison_results.mat');
if ~exist(results_file, 'file')
    error('Results file not found: %s\nPlease run aad_algorithm_comparison_pipeline first.', results_file);
end

fprintf('Loading results from: %s\n', results_file);
load(results_file, 'results');

% Extract data for visualization
algorithms = results.algorithms;
channel_configs = results.channel_configs;

%% 1. Individual Algorithm Performance Plots
fprintf('Creating individual algorithm performance plots...\n');
create_individual_algorithm_plots(results, plots_dir);

%% 2. Algorithm Comparison Heatmaps
fprintf('Creating algorithm comparison heatmaps...\n');
create_comparison_heatmaps(results, plots_dir);

%% 3. Statistical Analysis Plots
fprintf('Creating statistical analysis plots...\n');
if isfield(results, 'statistics')
    create_statistical_plots(results, plots_dir);
end

%% 4. Performance Improvement Analysis
fprintf('Creating performance improvement analysis...\n');
create_improvement_analysis(results, plots_dir);

%% 5. Subject-wise Analysis
fprintf('Creating subject-wise analysis plots...\n');
create_subject_analysis(results, plots_dir);

%% 6. Combined Summary Visualization
fprintf('Creating combined summary visualization...\n');
create_summary_visualization(results, plots_dir);

%% 7. Generate Report
fprintf('Generating visualization report...\n');
generate_visualization_report(results, plots_dir);

fprintf('\n=== Visualization Complete! ===\n');
fprintf('All plots saved to: %s\n', plots_dir);
fprintf('Check visualization_report.txt for detailed analysis\n');

end

function create_individual_algorithm_plots(results, plots_dir)
% Create individual plots for each algorithm showing 2ch vs 8ch performance

algorithms = results.algorithms;
channel_configs = results.channel_configs;

for algo_idx = 1:length(algorithms)
    algorithm = algorithms{algo_idx};
    
    figure('Position', [100, 100, 1200, 800]);
    
    % Collect data for this algorithm
    data_2ch = [];
    data_8ch = [];
    subject_labels = {};
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            algo_results = results.(config).(algorithm);
            
            if strcmp(config, 'ch2')
                data_2ch = algo_results.subject_accuracies;
                % Try to get subject names if available
                if isfield(algo_results, 'subject_names')
                    subject_labels = algo_results.subject_names;
                else
                    subject_labels = arrayfun(@(x) sprintf('S%d', x), 1:length(data_2ch), 'UniformOutput', false);
                end
            elseif strcmp(config, 'ch8')
                data_8ch = algo_results.subject_accuracies;
            end
        end
    end
    
    % Create subplot layout
    subplot(2, 2, 1);
    % Box plot comparison
    if ~isempty(data_2ch) && ~isempty(data_8ch)
        data_combined = [data_2ch(:); data_8ch(:)];
        groups = [ones(length(data_2ch), 1); 2*ones(length(data_8ch), 1)];
        boxplot(data_combined, groups, 'Labels', {'2-Channel', '8-Channel'});
        title(sprintf('%s Algorithm: Accuracy Distribution', upper(algorithm)));
        ylabel('Accuracy (%)');
        grid on;
    end
    
    subplot(2, 2, 2);
    % Subject-wise comparison
    if ~isempty(data_2ch) && ~isempty(data_8ch)
        num_subjects = min(length(data_2ch), length(data_8ch));
        x_pos = 1:num_subjects;
        
        bar_width = 0.35;
        bar(x_pos - bar_width/2, data_2ch(1:num_subjects), bar_width, 'DisplayName', '2-Channel');
        hold on;
        bar(x_pos + bar_width/2, data_8ch(1:num_subjects), bar_width, 'DisplayName', '8-Channel');
        
        xlabel('Subject');
        ylabel('Accuracy (%)');
        title(sprintf('%s Algorithm: Subject-wise Comparison', upper(algorithm)));
        legend('Location', 'best');
        grid on;
        
        if length(subject_labels) >= num_subjects
            set(gca, 'XTickLabel', subject_labels(1:num_subjects));
        end
    end
    
    subplot(2, 2, 3);
    % Improvement per subject
    if ~isempty(data_2ch) && ~isempty(data_8ch)
        num_subjects = min(length(data_2ch), length(data_8ch));
        improvement = data_8ch(1:num_subjects) - data_2ch(1:num_subjects);
        
        colors = improvement;
        colors(improvement >= 0) = 1; % Positive improvements in one color
        colors(improvement < 0) = -1; % Negative improvements in another color
        
        bar(1:num_subjects, improvement, 'FaceColor', 'flat', 'CData', colors);
        colormap([0.8 0.2 0.2; 0.2 0.8 0.2]); % Red for negative, green for positive
        
        xlabel('Subject');
        ylabel('Accuracy Improvement (%)');
        title(sprintf('%s Algorithm: 8ch - 2ch Improvement', upper(algorithm)));
        grid on;
        
        % Add zero line
        hold on;
        plot([0, num_subjects+1], [0, 0], 'k--', 'LineWidth', 1);
        
        if length(subject_labels) >= num_subjects
            set(gca, 'XTickLabel', subject_labels(1:num_subjects));
        end
    end
    
    subplot(2, 2, 4);
    % Summary statistics
    if ~isempty(data_2ch) && ~isempty(data_8ch)
        % Calculate statistics
        mean_2ch = mean(data_2ch);
        mean_8ch = mean(data_8ch);
        std_2ch = std(data_2ch);
        std_8ch = std(data_8ch);
        
        % Create bar plot with error bars
        means = [mean_2ch, mean_8ch];
        stds = [std_2ch, std_8ch];
        
        bar_handle = bar(means);
        hold on;
        errorbar(1:2, means, stds, 'k.', 'LineWidth', 2);
        
        set(gca, 'XTickLabel', {'2-Channel', '8-Channel'});
        ylabel('Mean Accuracy (%)');
        title(sprintf('%s Algorithm: Summary Statistics', upper(algorithm)));
        grid on;
        
        % Add significance test if available
        if isfield(results, 'statistics') && isfield(results.statistics, algorithm)
            stats = results.statistics.(algorithm);
            if isfield(stats, 'p_value')
                if stats.p_value < 0.05
                    sig_text = sprintf('p = %.3f *', stats.p_value);
                else
                    sig_text = sprintf('p = %.3f', stats.p_value);
                end
                text(1.5, max(means) + max(stds), sig_text, 'HorizontalAlignment', 'center');
            end
        end
    end
    
    sgtitle(sprintf('AAD Algorithm Analysis: %s', upper(algorithm)), 'FontSize', 16, 'FontWeight', 'bold');
    
    % Save plot
    plot_filename = fullfile(plots_dir, sprintf('individual_%s_analysis.png', algorithm));
    saveas(gcf, plot_filename);
    close(gcf);
    
    fprintf('  Saved: %s\n', plot_filename);
end

end

function create_comparison_heatmaps(results, plots_dir)
% Create heatmaps comparing all algorithms across channel configurations

algorithms = results.algorithms;
channel_configs = results.channel_configs;

% Prepare data matrix
num_algos = length(algorithms);
num_configs = length(channel_configs);

mean_accuracy = zeros(num_algos, num_configs);
std_accuracy = zeros(num_algos, num_configs);

for algo_idx = 1:num_algos
    algorithm = algorithms{algo_idx};
    for config_idx = 1:num_configs
        config = channel_configs{config_idx};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            accuracies = results.(config).(algorithm).subject_accuracies;
            mean_accuracy(algo_idx, config_idx) = mean(accuracies);
            std_accuracy(algo_idx, config_idx) = std(accuracies);
        end
    end
end

% Create heatmap figure
figure('Position', [100, 100, 1200, 600]);

subplot(1, 2, 1);
% Mean accuracy heatmap with text annotations
h1 = heatmap(channel_configs, algorithms, mean_accuracy);
h1.Title = 'Mean Accuracy (%)';
h1.Colormap = parula;

% For modern MATLAB, use CellLabelFormat to show values
h1.CellLabelFormat = '%.1f%%';
h1.CellLabelColor = 'white';

subplot(1, 2, 2);
% Standard deviation heatmap with text annotations
h2 = heatmap(channel_configs, algorithms, std_accuracy);
h2.Title = 'Standard Deviation (%)';
h2.Colormap = copper;

% Show std deviation values
h2.CellLabelFormat = '%.2f';
h2.CellLabelColor = 'white';

sgtitle('AAD Algorithm Comparison Heatmaps', 'FontSize', 16, 'FontWeight', 'bold');

% Save plot
plot_filename = fullfile(plots_dir, 'algorithm_comparison_heatmaps.png');
saveas(gcf, plot_filename);
close(gcf);

fprintf('  Saved: %s\n', plot_filename);

end

function create_statistical_plots(results, plots_dir)
% Create plots showing statistical significance of comparisons

% Check if statistics exist in results
if ~isfield(results, 'statistics')
    fprintf('No statistics field found in results. Skipping statistical plots.\n');
    return;
end

stats = results.statistics;

% Get algorithms from results structure
if isfield(results, 'algorithms')
    algorithms = results.algorithms;
else
    % Try to extract algorithms from field names (excluding 'statistics' and 'subject_accuracies')
    all_fields = fieldnames(results);
    algorithms = all_fields(~ismember(all_fields, {'statistics', 'subject_accuracies'}));
    if isempty(algorithms)
        fprintf('No algorithms found in results. Skipping statistical plots.\n');
        return;
    end
end

figure('Position', [100, 100, 1200, 400]);

% P-values plot
subplot(1, 3, 1);
p_values = [];
algo_names = {};

for i = 1:length(algorithms)
    algorithm = algorithms{i};
    % More robust checking for p_value
    if isfield(stats, algorithm) && isstruct(stats.(algorithm)) && isfield(stats.(algorithm), 'p_value')
        p_val = stats.(algorithm).p_value;
        if isnumeric(p_val) && ~isempty(p_val)
            p_values(end+1) = p_val;
            algo_names{end+1} = upper(algorithm);
        end
    end
end

if ~isempty(p_values)
    bar_colors = p_values < 0.05;
    bar_handle = bar(p_values);
    
    % Color bars based on significance
    for i = 1:length(p_values)
        if p_values(i) < 0.05
            bar_handle.CData(i,:) = [0.2 0.8 0.2]; % Green for significant
        else
            bar_handle.CData(i,:) = [0.8 0.2 0.2]; % Red for non-significant
        end
    end
    
    set(gca, 'XTickLabel', algo_names);
    ylabel('p-value');
    title('Statistical Significance (8ch vs 2ch)');
    
    % Add significance line
    hold on;
    plot([0, length(p_values)+1], [0.05, 0.05], 'r--', 'LineWidth', 2);
    text(length(p_values)/2, 0.06, '\alpha = 0.05', 'HorizontalAlignment', 'center');
    
    grid on;
end

% Effect sizes plot
subplot(1, 3, 2);
effect_sizes = [];
effect_algo_names = {};

for i = 1:length(algorithms)
    algorithm = algorithms{i};
    % More robust checking for effect_size
    if isfield(stats, algorithm) && isstruct(stats.(algorithm)) && isfield(stats.(algorithm), 'effect_size')
        effect_val = stats.(algorithm).effect_size;
        if isnumeric(effect_val) && ~isempty(effect_val)
            effect_sizes(end+1) = effect_val;
            effect_algo_names{end+1} = upper(algorithm);
        end
    end
end

if ~isempty(effect_sizes)
    bar_handle = bar(effect_sizes);
    
    % Color based on effect size magnitude
    bar_colors = abs(effect_sizes);
    colormap(gca, parula);
    if length(effect_sizes) == 1
        bar_handle.FaceColor = 'flat';
        bar_handle.CData = bar_colors;
    else
        bar_handle.CData = bar_colors;
    end
    
    set(gca, 'XTickLabel', effect_algo_names);
    ylabel('Effect Size (Cohen''s d)');
    title('Effect Size (8ch vs 2ch)');
    
    % Add effect size interpretation lines
    hold on;
    plot([0, length(effect_sizes)+1], [0.2, 0.2], 'g--', 'LineWidth', 1);
    plot([0, length(effect_sizes)+1], [0.5, 0.5], 'y--', 'LineWidth', 1);
    plot([0, length(effect_sizes)+1], [0.8, 0.8], 'r--', 'LineWidth', 1);
    text(length(effect_sizes)/2, 0.9, 'Large', 'HorizontalAlignment', 'center');
    text(length(effect_sizes)/2, 0.6, 'Medium', 'HorizontalAlignment', 'center');
    text(length(effect_sizes)/2, 0.3, 'Small', 'HorizontalAlignment', 'center');
else
    text(0.5, 0.5, 'No effect size data available', 'HorizontalAlignment', 'center');
    set(gca, 'XLim', [0 1], 'YLim', [0 1]);
    title('Effect Size (8ch vs 2ch)');
end

% Confidence intervals plot
subplot(1, 3, 3);
mean_diffs = [];
ci_lower = [];
ci_upper = [];

for i = 1:length(algorithms)
    algorithm = algorithms{i};
    % More robust checking for confidence interval data
    if isfield(stats, algorithm) && isstruct(stats.(algorithm))
        has_mean = isfield(stats.(algorithm), 'mean_difference');
        has_ci = isfield(stats.(algorithm), 'ci_lower') && isfield(stats.(algorithm), 'ci_upper');
        
        if has_mean || has_ci
            % Get mean difference
            if has_mean
                mean_val = stats.(algorithm).mean_difference;
                if isnumeric(mean_val) && ~isempty(mean_val)
                    mean_diffs(end+1) = mean_val;
                else
                    mean_diffs(end+1) = 0;
                end
            else
                mean_diffs(end+1) = 0;
            end
            
            % Get confidence intervals
            if has_ci
                lower_val = stats.(algorithm).ci_lower;
                upper_val = stats.(algorithm).ci_upper;
                if isnumeric(lower_val) && isnumeric(upper_val) && ~isempty(lower_val) && ~isempty(upper_val)
                    ci_lower(end+1) = lower_val;
                    ci_upper(end+1) = upper_val;
                else
                    ci_lower(end+1) = mean_diffs(end) - 1;
                    ci_upper(end+1) = mean_diffs(end) + 1;
                end
            else
                ci_lower(end+1) = mean_diffs(end) - 1;
                ci_upper(end+1) = mean_diffs(end) + 1;
            end
        end
    end
end

if ~isempty(mean_diffs)
    errorbar(1:length(mean_diffs), mean_diffs, ...
        mean_diffs - ci_lower, ci_upper - mean_diffs, 'o', 'LineWidth', 2);
    
    set(gca, 'XTickLabel', algo_names);
    ylabel('Mean Difference (8ch - 2ch)');
    title('95% Confidence Intervals');
    
    % Add zero line
    hold on;
    plot([0, length(mean_diffs)+1], [0, 0], 'k--', 'LineWidth', 1);
    
    grid on;
end

sgtitle('Statistical Analysis of Channel Configuration Effects', 'FontSize', 16, 'FontWeight', 'bold');

% Save plot
plot_filename = fullfile(plots_dir, 'statistical_analysis.png');
saveas(gcf, plot_filename);
close(gcf);

fprintf('  Saved: %s\n', plot_filename);

end

function create_improvement_analysis(results, plots_dir)
% Create detailed analysis of performance improvements

algorithms = results.algorithms;
channel_configs = results.channel_configs;

% Only proceed if we have both 2ch and 8ch data
if length(channel_configs) < 2
    fprintf('  Skipping improvement analysis (need both 2ch and 8ch data)\n');
    return;
end

figure('Position', [100, 100, 1400, 800]);

% Calculate improvements for each algorithm
improvements = struct();
for algo_idx = 1:length(algorithms)
    algorithm = algorithms{algo_idx};
    
    data_2ch = [];
    data_8ch = [];
    
    if isfield(results, 'ch2') && isfield(results.ch2, algorithm)
        data_2ch = results.ch2.(algorithm).subject_accuracies;
    end
    
    if isfield(results, 'ch8') && isfield(results.ch8, algorithm)
        data_8ch = results.ch8.(algorithm).subject_accuracies;
    end
    
    if ~isempty(data_2ch) && ~isempty(data_8ch)
        num_subjects = min(length(data_2ch), length(data_8ch));
        improvements.(algorithm) = data_8ch(1:num_subjects) - data_2ch(1:num_subjects);
    end
end

% Plot 1: Overall improvement distribution
subplot(2, 3, 1);
all_improvements = [];
improvement_labels = {};

for algo_idx = 1:length(algorithms)
    algorithm = algorithms{algo_idx};
    if isfield(improvements, algorithm)
        all_improvements = [all_improvements; improvements.(algorithm)(:)];
        improvement_labels = [improvement_labels; repmat({upper(algorithm)}, length(improvements.(algorithm)), 1)];
    end
end

if ~isempty(all_improvements)
    boxplot(all_improvements, improvement_labels);
    ylabel('Improvement (8ch - 2ch) %');
    title('Improvement Distribution by Algorithm');
    grid on;
    
    % Add zero line
    hold on;
    plot([0, length(algorithms)+1], [0, 0], 'r--', 'LineWidth', 2);
end

% Plot 2: Mean improvements with confidence intervals
subplot(2, 3, 2);
mean_improvements = [];
sem_improvements = [];
algo_labels = {};

for algo_idx = 1:length(algorithms)
    algorithm = algorithms{algo_idx};
    if isfield(improvements, algorithm)
        mean_improvements(end+1) = mean(improvements.(algorithm));
        sem_improvements(end+1) = std(improvements.(algorithm)) / sqrt(length(improvements.(algorithm)));
        algo_labels{end+1} = upper(algorithm);
    end
end

if ~isempty(mean_improvements)
    bar_handle = bar(mean_improvements);
    hold on;
    errorbar(1:length(mean_improvements), mean_improvements, sem_improvements, 'k.', 'LineWidth', 2);
    
    % Color bars based on positive/negative improvement
    for i = 1:length(mean_improvements)
        if mean_improvements(i) >= 0
            bar_handle.CData(i,:) = [0.2 0.8 0.2]; % Green for positive
        else
            bar_handle.CData(i,:) = [0.8 0.2 0.2]; % Red for negative
        end
    end
    
    set(gca, 'XTickLabel', algo_labels);
    ylabel('Mean Improvement (%)');
    title('Mean Improvement ± SEM');
    grid on;
    
    % Add zero line
    plot([0, length(mean_improvements)+1], [0, 0], 'k--', 'LineWidth', 1);
end

% Plot 3: Percentage of subjects showing improvement
subplot(2, 3, 3);
improvement_percentages = [];

for algo_idx = 1:length(algorithms)
    algorithm = algorithms{algo_idx};
    if isfield(improvements, algorithm)
        positive_improvements = sum(improvements.(algorithm) > 0);
        total_subjects = length(improvements.(algorithm));
        improvement_percentages(end+1) = (positive_improvements / total_subjects) * 100;
    end
end

if ~isempty(improvement_percentages)
    bar_handle = bar(improvement_percentages);
    
    % Color based on percentage
    for i = 1:length(improvement_percentages)
        if improvement_percentages(i) >= 50
            bar_handle.CData(i,:) = [0.2 0.8 0.2]; % Green for majority improved
        else
            bar_handle.CData(i,:) = [0.8 0.2 0.2]; % Red for minority improved
        end
    end
    
    set(gca, 'XTickLabel', algo_labels);
    ylabel('% of Subjects Improved');
    title('Percentage of Subjects Showing Improvement');
    grid on;
    
    % Add 50% line
    hold on;
    plot([0, length(improvement_percentages)+1], [50, 50], 'k--', 'LineWidth', 1);
end

% Plot 4: Improvement magnitude distribution
subplot(2, 3, 4);
if ~isempty(all_improvements)
    histogram(all_improvements, 'BinWidth', 1, 'FaceAlpha', 0.7);
    xlabel('Improvement (%)');
    ylabel('Frequency');
    title('Distribution of All Improvements');
    grid on;
    
    % Add vertical line at zero
    hold on;
    plot([0, 0], ylim, 'r--', 'LineWidth', 2);
    
    % Add statistics
    mean_all = mean(all_improvements);
    std_all = std(all_improvements);
    text(0.7*max(all_improvements), 0.8*max(ylim), ...
        sprintf('Mean: %.2f%%\nStd: %.2f%%', mean_all, std_all), ...
        'BackgroundColor', 'white');
end

% Plot 5: Algorithm ranking by improvement
subplot(2, 3, 5);
if ~isempty(mean_improvements)
    [sorted_improvements, sort_idx] = sort(mean_improvements, 'descend');
    sorted_labels = algo_labels(sort_idx);
    
    bar_colors = (1:length(sorted_improvements)) / length(sorted_improvements);
    bar_handle = bar(sorted_improvements);
    colormap(gca, parula);
    bar_handle.CData = bar_colors;
    
    set(gca, 'XTickLabel', sorted_labels);
    ylabel('Mean Improvement (%)');
    title('Algorithm Ranking by Improvement');
    grid on;
    
    % Add zero line
    hold on;
    plot([0, length(sorted_improvements)+1], [0, 0], 'k--', 'LineWidth', 1);
end

% Plot 6: Subject consistency analysis
subplot(2, 3, 6);
if length(algorithms) >= 2 && all(isfield(improvements, algorithms))
    % Calculate correlation between algorithm improvements across subjects
    corr_matrix = zeros(length(algorithms));
    
    for i = 1:length(algorithms)
        for j = 1:length(algorithms)
            if isfield(improvements, algorithms{i}) && isfield(improvements, algorithms{j})
                imp_i = improvements.(algorithms{i});
                imp_j = improvements.(algorithms{j});
                min_len = min(length(imp_i), length(imp_j));
                if min_len > 1
                    corr_matrix(i, j) = corr(imp_i(1:min_len), imp_j(1:min_len));
                end
            end
        end
    end
    
    imagesc(corr_matrix);
    colorbar;
    colormap(gca, redblue);
    caxis([-1, 1]);
    
    set(gca, 'XTick', 1:length(algorithms), 'XTickLabel', cellfun(@upper, algorithms, 'UniformOutput', false));
    set(gca, 'YTick', 1:length(algorithms), 'YTickLabel', cellfun(@upper, algorithms, 'UniformOutput', false));
    title('Cross-Algorithm Improvement Correlation');
    
    % Add correlation values as text
    for i = 1:length(algorithms)
        for j = 1:length(algorithms)
            text(j, i, sprintf('%.2f', corr_matrix(i, j)), ...
                'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
        end
    end
end

sgtitle('Detailed Performance Improvement Analysis (8-Channel vs 2-Channel)', 'FontSize', 16, 'FontWeight', 'bold');

% Save plot
plot_filename = fullfile(plots_dir, 'improvement_analysis.png');
saveas(gcf, plot_filename);
close(gcf);

fprintf('  Saved: %s\n', plot_filename);

end

function create_subject_analysis(results, plots_dir)
% Create subject-wise analysis plots

algorithms = results.algorithms;
channel_configs = results.channel_configs;

% Collect all subject data
subject_data = struct();
subject_names = {};

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            algo_results = results.(config).(algorithm);
            
            if isfield(algo_results, 'subject_names') && ~isempty(subject_names)
                subject_names = algo_results.subject_names;
            end
            
            field_name = sprintf('%s_%s', config, algorithm);
            subject_data.(field_name) = algo_results.subject_accuracies;
        end
    end
end

if isempty(subject_names)
    % Generate generic subject names
    max_subjects = 0;
    fields = fieldnames(subject_data);
    for i = 1:length(fields)
        max_subjects = max(max_subjects, length(subject_data.(fields{i})));
    end
    subject_names = arrayfun(@(x) sprintf('S%d', x), 1:max_subjects, 'UniformOutput', false);
end

num_subjects = length(subject_names);

% Create subject-wise comparison figure
figure('Position', [100, 100, 1400, 1000]);

% Plot 1: Subject performance across all conditions
subplot(2, 2, 1);
plot_data = [];
plot_labels = {};
x_positions = [];

x_pos = 1;
for subj_idx = 1:min(num_subjects, 10) % Limit to first 10 subjects for readability
    subject_accuracies = [];
    condition_labels = {};
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            field_name = sprintf('%s_%s', config, algorithm);
            
            if isfield(subject_data, field_name) && length(subject_data.(field_name)) >= subj_idx
                subject_accuracies(end+1) = subject_data.(field_name)(subj_idx);
                condition_labels{end+1} = sprintf('%s-%s', upper(config(3:end)), upper(algorithm));
            end
        end
    end
    
    if ~isempty(subject_accuracies)
        x_range = x_pos:(x_pos + length(subject_accuracies) - 1);
        bar(x_range, subject_accuracies);
        hold on;
        
        % Add subject separator
        if subj_idx < min(num_subjects, 10)
            plot([x_pos + length(subject_accuracies) - 0.5, x_pos + length(subject_accuracies) - 0.5], ...
                [0, max(subject_accuracies) + 5], 'k--', 'LineWidth', 1);
        end
        
        x_pos = x_pos + length(subject_accuracies) + 1;
    end
end

title('Subject Performance Across All Conditions');
ylabel('Accuracy (%)');
xlabel('Conditions');
grid on;

% Plot 2: Best performing algorithm per subject
subplot(2, 2, 2);
best_algorithms = {};
best_configs = {};
best_accuracies = [];

for subj_idx = 1:min(num_subjects, 15)
    max_accuracy = 0;
    best_algo = '';
    best_config = '';
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            field_name = sprintf('%s_%s', config, algorithm);
            
            if isfield(subject_data, field_name) && length(subject_data.(field_name)) >= subj_idx
                accuracy = subject_data.(field_name)(subj_idx);
                if accuracy > max_accuracy
                    max_accuracy = accuracy;
                    best_algo = algorithm;
                    best_config = config;
                end
            end
        end
    end
    
    if ~isempty(best_algo)
        best_algorithms{end+1} = best_algo;
        best_configs{end+1} = best_config;
        best_accuracies(end+1) = max_accuracy;
    end
end

if ~isempty(best_accuracies)
    bar(best_accuracies);
    title('Best Performance per Subject');
    ylabel('Best Accuracy (%)');
    xlabel('Subject');
    
    % Add algorithm labels
    for i = 1:length(best_algorithms)
        text(i, best_accuracies(i) + 1, ...
            sprintf('%s\n%s', upper(best_algorithms{i}), upper(best_configs{i}(3:end))), ...
            'HorizontalAlignment', 'center', 'FontSize', 8);
    end
    
    grid on;
end

% Plot 3: Subject variability analysis
subplot(2, 2, 3);
subject_means = [];
subject_stds = [];
valid_subjects = [];

for subj_idx = 1:min(num_subjects, 15)
    subject_accuracies = [];
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            field_name = sprintf('%s_%s', config, algorithm);
            
            if isfield(subject_data, field_name) && length(subject_data.(field_name)) >= subj_idx
                subject_accuracies(end+1) = subject_data.(field_name)(subj_idx);
            end
        end
    end
    
    if length(subject_accuracies) >= 2
        subject_means(end+1) = mean(subject_accuracies);
        subject_stds(end+1) = std(subject_accuracies);
        valid_subjects(end+1) = subj_idx;
    end
end

if ~isempty(subject_means)
    errorbar(valid_subjects, subject_means, subject_stds, 'o-', 'LineWidth', 2);
    title('Subject Performance Variability');
    ylabel('Mean Accuracy ± Std (%)');
    xlabel('Subject');
    grid on;
end

% Plot 4: Configuration preference by subject
subplot(2, 2, 4);
if length(channel_configs) >= 2
    config_preferences = zeros(1, length(channel_configs));
    
    for subj_idx = 1:min(num_subjects, 15)
        config_means = [];
        
        for config_idx = 1:length(channel_configs)
            config = channel_configs{config_idx};
            config_accuracies = [];
            
            for algo_idx = 1:length(algorithms)
                algorithm = algorithms{algo_idx};
                field_name = sprintf('%s_%s', config, algorithm);
                
                if isfield(subject_data, field_name) && length(subject_data.(field_name)) >= subj_idx
                    config_accuracies(end+1) = subject_data.(field_name)(subj_idx);
                end
            end
            
            if ~isempty(config_accuracies)
                config_means(end+1) = mean(config_accuracies);
            else
                config_means(end+1) = 0;
            end
        end
        
        if ~isempty(config_means)
            [~, best_config_idx] = max(config_means);
            config_preferences(best_config_idx) = config_preferences(best_config_idx) + 1;
        end
    end
    
    pie(config_preferences, cellfun(@(x) upper(x(3:end)), channel_configs, 'UniformOutput', false));
    title('Channel Configuration Preference');
end

sgtitle('Subject-wise Analysis', 'FontSize', 16, 'FontWeight', 'bold');

% Save plot
plot_filename = fullfile(plots_dir, 'subject_analysis.png');
saveas(gcf, plot_filename);
close(gcf);

fprintf('  Saved: %s\n', plot_filename);

end

function create_summary_visualization(results, plots_dir)
% Create a comprehensive summary visualization

algorithms = results.algorithms;
channel_configs = results.channel_configs;

figure('Position', [100, 100, 1600, 1200]);

% Calculate summary statistics
summary_stats = struct();
for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            accuracies = results.(config).(algorithm).subject_accuracies;
            summary_stats.(config).(algorithm).mean = mean(accuracies);
            summary_stats.(config).(algorithm).std = std(accuracies);
            summary_stats.(config).(algorithm).median = median(accuracies);
            summary_stats.(config).(algorithm).min = min(accuracies);
            summary_stats.(config).(algorithm).max = max(accuracies);
        end
    end
end

% Plot 1: Overall performance comparison
subplot(2, 3, 1);
bar_data = [];
bar_labels = {};
bar_colors = [];

color_map = [0.2 0.4 0.8; 0.8 0.4 0.2; 0.2 0.8 0.2]; % Different colors for algorithms

group_pos = 1;
for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
            bar_data(end+1) = summary_stats.(config).(algorithm).mean;
            bar_labels{end+1} = sprintf('%s\n%s', upper(config(3:end)), upper(algorithm));
            bar_colors(end+1,:) = color_map(mod(algo_idx-1, size(color_map, 1)) + 1, :);
        end
    end
    
    if config_idx < length(channel_configs)
        bar_data(end+1) = NaN; % Add separator
        bar_labels{end+1} = '';
        bar_colors(end+1,:) = [1 1 1];
    end
end

if ~isempty(bar_data)
    bar_handle = bar(bar_data);
    bar_handle.FaceColor = 'flat';
    bar_handle.CData = bar_colors;
    
    set(gca, 'XTickLabel', bar_labels);
    xtickangle(45);
    ylabel('Mean Accuracy (%)');
    title('Overall Performance Comparison');
    grid on;
end

% Plot 2: Performance range (min-max) with median
subplot(2, 3, 2);
range_data = [];
median_data = [];
range_labels = {};

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
            stats = summary_stats.(config).(algorithm);
            range_data(end+1,:) = [stats.min, stats.max];
            median_data(end+1) = stats.median;
            range_labels{end+1} = sprintf('%s-%s', upper(config(3:end)), upper(algorithm));
        end
    end
end

if ~isempty(range_data)
    for i = 1:size(range_data, 1)
        plot([i i], range_data(i,:), 'b-', 'LineWidth', 3);
        hold on;
        plot(i, median_data(i), 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'r');
    end
    
    set(gca, 'XTick', 1:length(range_labels), 'XTickLabel', range_labels);
    xtickangle(45);
    ylabel('Accuracy Range (%)');
    title('Performance Range with Median');
    legend({'Min-Max Range', 'Median'}, 'Location', 'best');
    grid on;
end

% Plot 3: Coefficient of variation (consistency measure)
subplot(2, 3, 3);
cv_data = [];
cv_labels = {};

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
            stats = summary_stats.(config).(algorithm);
            cv = (stats.std / stats.mean) * 100; % Coefficient of variation as percentage
            cv_data(end+1) = cv;
            cv_labels{end+1} = sprintf('%s-%s', upper(config(3:end)), upper(algorithm));
        end
    end
end

if ~isempty(cv_data)
    bar_handle = bar(cv_data);
    
    % Color based on consistency (lower CV is better)
    max_cv = max(cv_data);
    for i = 1:length(cv_data)
        normalized_cv = cv_data(i) / max_cv;
        bar_handle.CData(i,:) = [normalized_cv, 1-normalized_cv, 0.2]; % Red to green gradient
    end
    
    set(gca, 'XTickLabel', cv_labels);
    xtickangle(45);
    ylabel('Coefficient of Variation (%)');
    title('Performance Consistency (Lower is Better)');
    grid on;
end

% Plot 4: Algorithm ranking summary
subplot(2, 3, 4);
if length(algorithms) >= 2
    ranking_scores = zeros(length(algorithms), length(channel_configs));
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        config_means = [];
        
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            
            if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
                config_means(end+1) = summary_stats.(config).(algorithm).mean;
            else
                config_means(end+1) = 0;
            end
        end
        
        % Rank algorithms (higher rank = better performance)
        [~, rank_order] = sort(config_means, 'descend');
        for i = 1:length(rank_order)
            ranking_scores(rank_order(i), config_idx) = length(algorithms) - i + 1;
        end
    end
    
    % Create stacked bar chart
    bar_handle = bar(ranking_scores', 'stacked');
    
    % Set colors for algorithms
    colors = lines(length(algorithms));
    for i = 1:length(algorithms)
        bar_handle(i).FaceColor = colors(i,:);
    end
    
    config_labels = cellfun(@(x) upper(x(3:end)), channel_configs, 'UniformOutput', false);
    set(gca, 'XTickLabel', config_labels);
    ylabel('Ranking Score');
    title('Algorithm Rankings by Configuration');
    legend(cellfun(@upper, algorithms, 'UniformOutput', false), 'Location', 'best');
    grid on;
end

% Plot 5: Statistical summary table (as text)
subplot(2, 3, 5);
axis off;

% Create summary text
summary_text = {};
summary_text{end+1} = 'SUMMARY STATISTICS';
summary_text{end+1} = '==================';
summary_text{end+1} = '';

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    summary_text{end+1} = sprintf('%s CONFIGURATION:', upper(config));
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
            stats = summary_stats.(config).(algorithm);
            summary_text{end+1} = sprintf('  %s: %.1f±%.1f%% (%.1f-%.1f%%)', ...
                upper(algorithm), stats.mean, stats.std, stats.min, stats.max);
        end
    end
    summary_text{end+1} = '';
end

% Add improvement analysis if both configs exist
if length(channel_configs) >= 2 && isfield(summary_stats, 'ch2') && isfield(summary_stats, 'ch8')
    summary_text{end+1} = 'IMPROVEMENTS (8CH vs 2CH):';
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(summary_stats.ch2, algorithm) && isfield(summary_stats.ch8, algorithm)
            improvement = summary_stats.ch8.(algorithm).mean - summary_stats.ch2.(algorithm).mean;
            summary_text{end+1} = sprintf('  %s: %+.1f%%', upper(algorithm), improvement);
        end
    end
end

% Display text
text(0.05, 0.95, strjoin(summary_text, '\n'), 'Units', 'normalized', ...
    'VerticalAlignment', 'top', 'FontName', 'Courier', 'FontSize', 9);

% Plot 6: Performance matrix visualization
subplot(2, 3, 6);
if ~isempty(summary_stats)
    % Create performance matrix
    perf_matrix = [];
    row_labels = {};
    col_labels = {};
    
    for config_idx = 1:length(channel_configs)
        config = channel_configs{config_idx};
        col_labels{end+1} = upper(config(3:end));
        
        config_means = [];
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            
            if config_idx == 1
                row_labels{end+1} = upper(algorithm);
            end
            
            if isfield(summary_stats, config) && isfield(summary_stats.(config), algorithm)
                config_means(end+1) = summary_stats.(config).(algorithm).mean;
            else
                config_means(end+1) = NaN;
            end
        end
        
        if config_idx == 1
            perf_matrix = config_means';
        else
            perf_matrix = [perf_matrix, config_means'];
        end
    end
    
    % Create heatmap
    imagesc(perf_matrix);
    colorbar;
    colormap(parula);
    
    set(gca, 'XTick', 1:length(col_labels), 'XTickLabel', col_labels);
    set(gca, 'YTick', 1:length(row_labels), 'YTickLabel', row_labels);
    title('Performance Matrix (%)');
    
    % Add text annotations
    for i = 1:size(perf_matrix, 1)
        for j = 1:size(perf_matrix, 2)
            if ~isnan(perf_matrix(i, j))
                text(j, i, sprintf('%.1f', perf_matrix(i, j)), ...
                    'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
            end
        end
    end
end

sgtitle('AAD Algorithm Comparison - Comprehensive Summary', 'FontSize', 18, 'FontWeight', 'bold');

% Save plot
plot_filename = fullfile(plots_dir, 'comprehensive_summary.png');
saveas(gcf, plot_filename);
close(gcf);

fprintf('  Saved: %s\n', plot_filename);

end

function generate_visualization_report(results, plots_dir)
% Generate a text report summarizing the visualization findings

report_filename = fullfile(plots_dir, 'visualization_report.txt');
fid = fopen(report_filename, 'w');

if fid == -1
    error('Could not create report file: %s', report_filename);
end

% Write header
fprintf(fid, 'AAD ALGORITHM COMPARISON - VISUALIZATION REPORT\n');
fprintf(fid, '==============================================\n');
fprintf(fid, 'Generated on: %s\n\n', datestr(now));

% Get algorithms and channel configs with robust extraction
if isfield(results, 'algorithms')
    algorithms = results.algorithms;
else
    % Extract algorithms from field names (excluding known non-algorithm fields)
    all_fields = fieldnames(results);
    algorithms = all_fields(~ismember(all_fields, {'statistics', 'subject_accuracies', 'channel_configs'}));
end

if isfield(results, 'channel_configs')
    channel_configs = results.channel_configs;
elseif ~isempty(algorithms)
    % Try to extract channel configs from first algorithm
    first_algo = algorithms{1};
    if isfield(results, first_algo) && isstruct(results.(first_algo))
        channel_configs = fieldnames(results.(first_algo));
    else
        channel_configs = {'64_ch', '32_ch', '16_ch'}; % Default fallback
    end
else
    channel_configs = {'64_ch', '32_ch', '16_ch'}; % Default fallback
end

% Write summary statistics
fprintf(fid, 'ANALYSIS OVERVIEW:\n');
fprintf(fid, '------------------\n');
if ~isempty(algorithms)
    fprintf(fid, 'Algorithms tested: %s\n', strjoin(cellfun(@upper, algorithms, 'UniformOutput', false), ', '));
else
    fprintf(fid, 'Algorithms tested: Not available\n');
end
if ~isempty(channel_configs)
    fprintf(fid, 'Channel configurations: %s\n', strjoin(cellfun(@(x) upper(strrep(x, '_', '')), channel_configs, 'UniformOutput', false), ', '));
else
    fprintf(fid, 'Channel configurations: Not available\n');
end
fprintf(fid, '\n');

% Calculate and write performance summary
fprintf(fid, 'PERFORMANCE SUMMARY:\n');
fprintf(fid, '--------------------\n');

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    fprintf(fid, '\n%s CONFIGURATION:\n', upper(strrep(config, '_', ' ')));
    
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        % Check for data in the correct structure: results.(algorithm).(config)
        if isfield(results, algorithm) && isfield(results.(algorithm), config) && isfield(results.(algorithm).(config), 'subject_accuracies')
            accuracies = results.(algorithm).(config).subject_accuracies;
            
            % Validate that accuracies is numeric
            if isnumeric(accuracies) && ~isempty(accuracies)
                fprintf(fid, '  %s:\n', upper(algorithm));
                fprintf(fid, '    Mean: %.2f%% ± %.2f%%\n', mean(accuracies), std(accuracies));
                fprintf(fid, '    Range: %.2f%% - %.2f%%\n', min(accuracies), max(accuracies));
                fprintf(fid, '    Median: %.2f%%\n', median(accuracies));
                fprintf(fid, '    Subjects: %d\n', length(accuracies));
            else
                fprintf(fid, '  %s: No valid accuracy data\n', upper(algorithm));
            end
        else
            fprintf(fid, '  %s: No data available\n', upper(algorithm));
        end
    end
end

% Write improvement analysis
if length(channel_configs) >= 2
    fprintf(fid, '\nIMPROVEMENT ANALYSIS:\n');
    fprintf(fid, '---------------------\n');
    
    % Find configs that might represent high vs low channel counts
    high_ch_config = '';
    low_ch_config = '';
    
    for i = 1:length(channel_configs)
        config_name = lower(channel_configs{i});
        if contains(config_name, '64') || contains(config_name, '8')
            high_ch_config = channel_configs{i};
        elseif contains(config_name, '16') || contains(config_name, '2')
            low_ch_config = channel_configs{i};
        end
    end
    
    if ~isempty(high_ch_config) && ~isempty(low_ch_config)
        fprintf(fid, 'Comparing %s vs %s:\n', upper(strrep(high_ch_config, '_', ' ')), upper(strrep(low_ch_config, '_', ' ')));
        
        for algo_idx = 1:length(algorithms)
            algorithm = algorithms{algo_idx};
            
            % Check if data exists for both configurations
            if isfield(results, algorithm) && isfield(results.(algorithm), low_ch_config) && ...
               isfield(results.(algorithm), high_ch_config) && ...
               isfield(results.(algorithm).(low_ch_config), 'subject_accuracies') && ...
               isfield(results.(algorithm).(high_ch_config), 'subject_accuracies')
                
                acc_low = results.(algorithm).(low_ch_config).subject_accuracies;
                acc_high = results.(algorithm).(high_ch_config).subject_accuracies;
                
                % Validate data is numeric
                if isnumeric(acc_low) && isnumeric(acc_high) && ~isempty(acc_low) && ~isempty(acc_high)
                    min_len = min(length(acc_low), length(acc_high));
                    improvements = acc_high(1:min_len) - acc_low(1:min_len);
                    
                    mean_improvement = mean(improvements);
                    positive_count = sum(improvements > 0);
                    percentage_improved = (positive_count / min_len) * 100;
                    
                    fprintf(fid, '\n%s:\n', upper(algorithm));
                    fprintf(fid, '  Mean improvement: %+.2f%%\n', mean_improvement);
                    fprintf(fid, '  Subjects improved: %d/%d (%.1f%%)\n', positive_count, min_len, percentage_improved);
                    fprintf(fid, '  Max improvement: %+.2f%%\n', max(improvements));
                    fprintf(fid, '  Min improvement: %+.2f%%\n', min(improvements));
                else
                    fprintf(fid, '\n%s: Invalid accuracy data for comparison\n', upper(algorithm));
                end
            else
                fprintf(fid, '\n%s: Missing data for comparison\n', upper(algorithm));
            end
        end
    else
        fprintf(fid, 'No suitable channel configurations found for comparison.\n');
    end
end

% Write statistical analysis
if isfield(results, 'statistics')
    fprintf(fid, '\nSTATISTICAL ANALYSIS:\n');
    fprintf(fid, '---------------------\n');
    
    stats = results.statistics;
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(stats, algorithm)
            algo_stats = stats.(algorithm);
            
            fprintf(fid, '\n%s:\n', upper(algorithm));
            
            if isfield(algo_stats, 'p_value')
                p_val = algo_stats.p_value;
                % Validate that p_value is numeric
                if isnumeric(p_val) && ~isempty(p_val) && isfinite(p_val) && p_val >= 0 && p_val <= 1
                    if p_val < 0.001
                        fprintf(fid, '  p-value: < 0.001 ***\n');
                    elseif p_val < 0.01
                        fprintf(fid, '  p-value: %.3f **\n', p_val);
                    elseif p_val < 0.05
                        fprintf(fid, '  p-value: %.3f *\n', p_val);
                    else
                        fprintf(fid, '  p-value: %.3f (n.s.)\n', p_val);
                    end
                else
                    fprintf(fid, '  p-value: Invalid or missing data\n');
                end
            end
            
            if isfield(algo_stats, 'effect_size')
                effect_size = algo_stats.effect_size;
                % Validate that effect_size is numeric
                if isnumeric(effect_size) && ~isempty(effect_size) && isfinite(effect_size)
                    if abs(effect_size) >= 0.8
                        effect_desc = 'Large';
                    elseif abs(effect_size) >= 0.5
                        effect_desc = 'Medium';
                    elseif abs(effect_size) >= 0.2
                        effect_desc = 'Small';
                    else
                        effect_desc = 'Negligible';
                    end
                    fprintf(fid, '  Effect size (Cohen''s d): %.3f (%s)\n', effect_size, effect_desc);
                else
                    fprintf(fid, '  Effect size: Invalid or missing data\n');
                end
            end
        end
    end
end

% Write recommendations
fprintf(fid, '\nRECOMMENDations:\n');
fprintf(fid, '----------------\n');

% Find best performing algorithm overall
best_overall = '';
best_overall_acc = 0;

for config_idx = 1:length(channel_configs)
    config = channel_configs{config_idx};
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(results, config) && isfield(results.(config), algorithm)
            mean_acc = mean(results.(config).(algorithm).subject_accuracies);
            if mean_acc > best_overall_acc
                best_overall_acc = mean_acc;
                best_overall = sprintf('%s with %s configuration', upper(algorithm), upper(config));
            end
        end
    end
end

if ~isempty(best_overall)
    fprintf(fid, '\n1. Best overall performance: %s (%.2f%%)\n', best_overall, best_overall_acc);
end

% Multichannel recommendation
if length(channel_configs) >= 2
    improvements_found = false;
    for algo_idx = 1:length(algorithms)
        algorithm = algorithms{algo_idx};
        
        if isfield(results, 'ch2') && isfield(results.ch2, algorithm) && ...
           isfield(results, 'ch8') && isfield(results.ch8, algorithm)
            
            mean_2ch = mean(results.ch2.(algorithm).subject_accuracies);
            mean_8ch = mean(results.ch8.(algorithm).subject_accuracies);
            
            if mean_8ch > mean_2ch
                improvements_found = true;
                break;
            end
        end
    end
    
    if improvements_found
        fprintf(fid, '\n2. Multichannel processing shows benefits for some algorithms\n');
    else
        fprintf(fid, '\n2. Limited benefits observed from multichannel processing\n');
    end
end

fprintf(fid, '\n3. Generated visualizations:\n');
fprintf(fid, '   - Individual algorithm analysis plots\n');
fprintf(fid, '   - Algorithm comparison heatmaps\n');
fprintf(fid, '   - Statistical significance plots\n');
fprintf(fid, '   - Performance improvement analysis\n');
fprintf(fid, '   - Subject-wise analysis\n');
fprintf(fid, '   - Comprehensive summary visualization\n');

fprintf(fid, '\nEND OF REPORT\n');

fclose(fid);

fprintf('  Generated: %s\n', report_filename);

end

% Helper function for redblue colormap
function map = redblue(n)
if nargin < 1
    n = 64;
end

% Create red-white-blue colormap
red = [1, 0, 0];
white = [1, 1, 1];
blue = [0, 0, 1];

half_n = floor(n/2);
map = [linspace(red(1), white(1), half_n)', linspace(red(2), white(2), half_n)', linspace(red(3), white(3), half_n)'; ...
       linspace(white(1), blue(1), n-half_n)', linspace(white(2), blue(2), n-half_n)', linspace(white(3), blue(3), n-half_n)'];
end