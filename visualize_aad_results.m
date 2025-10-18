function visualize_aad_results()
% VISUALIZE_AAD_RESULTS Create comprehensive visualizations for auditory attention detection results
% This function generates multiple plots to help interpret and present AAD findings

fprintf('🎨 Creating visual representations of AAD results...\n\n');

%% Load all available data
methods = {'correlation', 'trf', 'cca'};
results_data = struct();
colors = [0.2 0.6 0.8; 0.8 0.4 0.2; 0.4 0.8 0.3]; % Blue, Orange, Green

% Load attention results
for i = 1:length(methods)
    method = methods{i};
    filename = sprintf('attention_results_%s.mat', method);
    if exist(filename, 'file')
        loaded = load(filename);
        results_data.(method) = loaded.attention_results;
    end
end

% Load validation results
validation_data = [];
if exist('validation_results_correlation.mat', 'file')
    loaded_val = load('validation_results_correlation.mat');
    validation_data = loaded_val.validation_results;
end

method_names = fieldnames(results_data);
if isempty(method_names)
    fprintf('❌ No attention results found. Run detect_auditory_attention.m first.\n');
    return;
end

%% Define dark theme colors
dark_colors = struct();
dark_colors.bg = [0.15 0.15 0.25];        % Dark blue-gray background
dark_colors.plot_bg = [0.2 0.2 0.3];      % Plot area background
dark_colors.text = [0.9 0.9 0.9];         % Light text
dark_colors.grid = [0.5 0.5 0.5];         % Grid color
dark_colors.blue = [0.3 0.7 1.0];         % Bright blue
dark_colors.orange = [1.0 0.6 0.2];       % Bright orange
dark_colors.green = [0.4 0.9 0.4];        % Bright green
dark_colors.purple = [0.8 0.5 0.9];       % Bright purple
dark_colors.red = [1.0 0.3 0.3];          % Bright red

%% Create figure with multiple subplots
fig = figure('Position', [100, 100, 1400, 1000], 'Name', 'AAD Results Visualization - Dark Theme');
set(fig, 'Color', dark_colors.bg);

%% 1. Method Comparison - Attention Distribution
subplot(3, 4, 1);
method_colors = colors(1:length(method_names), :);
left_percentages = [];
right_percentages = [];
method_labels = {};

for i = 1:length(method_names)
    method = method_names{i};
    data = results_data.(method);
    left_pct = sum(data.predictions == 1) / data.num_trials * 100;
    right_pct = sum(data.predictions == 2) / data.num_trials * 100;
    
    left_percentages(i) = left_pct;
    right_percentages(i) = right_pct;
    method_labels{i} = upper(method);
end

x = 1:length(method_names);
bar_width = 0.35;
bar1 = bar(x - bar_width/2, left_percentages, bar_width, 'FaceColor', dark_colors.blue);
hold on;
bar2 = bar(x + bar_width/2, right_percentages, bar_width, 'FaceColor', dark_colors.orange);

set(gca, 'XTick', x, 'XTickLabel', method_labels, 'Color', dark_colors.text);
set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
ylabel('Percentage of Trials (%)', 'Color', dark_colors.text);
title('Attention Distribution by Method', 'Color', dark_colors.text);
legend({'Left Ear', 'Right Ear'}, 'Location', 'best', 'TextColor', dark_colors.text);
grid on;
set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);
ylim([0 100]);

% Add percentage labels on bars
for i = 1:length(left_percentages)
    text(i - bar_width/2, left_percentages(i) + 2, sprintf('%.1f%%', left_percentages(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', dark_colors.text);
    text(i + bar_width/2, right_percentages(i) + 2, sprintf('%.1f%%', right_percentages(i)), ...
         'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', dark_colors.text);
end

%% 2. Confidence Comparison Across Methods
subplot(3, 4, 2);
confidence_means = [];
confidence_stds = [];

for i = 1:length(method_names)
    method = method_names{i};
    data = results_data.(method);
    confidence_means(i) = mean(data.confidence);
    confidence_stds(i) = std(data.confidence);
end

bar_handle = bar(1:length(method_names), confidence_means, 'FaceColor', dark_colors.purple);
hold on;
errorbar(1:length(method_names), confidence_means, confidence_stds, 'Color', dark_colors.text, 'LineWidth', 2);

set(gca, 'XTick', 1:length(method_names), 'XTickLabel', method_labels, 'Color', dark_colors.text);
set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
ylabel('Mean Confidence', 'Color', dark_colors.text);
title('Confidence Levels by Method', 'Color', dark_colors.text);
grid on;
set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);

% Add value labels
for i = 1:length(confidence_means)
    text(i, confidence_means(i) + confidence_stds(i) + 0.001, ...
         sprintf('%.3f', confidence_means(i)), 'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', dark_colors.text);
end

%% 3. Trial Distribution Histogram (Primary Method)
subplot(3, 4, 3);
primary_method = method_names{1};
primary_data = results_data.(primary_method);

histogram(primary_data.confidence, 'FaceColor', dark_colors.purple, 'EdgeColor', dark_colors.text, 'FaceAlpha', 0.7);
xlabel('Confidence Values', 'Color', dark_colors.text);
ylabel('Number of Trials', 'Color', dark_colors.text);
title(sprintf('Confidence Distribution (%s)', upper(primary_method)), 'Color', dark_colors.text);
set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
grid on;
set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);

% Add statistics text
mean_conf = mean(primary_data.confidence);
std_conf = std(primary_data.confidence);
text(0.7*max(primary_data.confidence), 0.8*max(ylim), ...
     sprintf('Mean: %.3f\nStd: %.3f', mean_conf, std_conf), ...
     'BackgroundColor', dark_colors.plot_bg, 'EdgeColor', dark_colors.text, 'Color', dark_colors.text);

%% 4. Performance Metrics (if validation data available)
subplot(3, 4, 4);
if ~isempty(validation_data) && ~isnan(validation_data.accuracy)
    % Performance gauge-style plot
    accuracy = validation_data.accuracy * 100;
    
    % Create semicircle gauge
    theta = linspace(pi, 0, 100);
    
    % Color zones
    fill([cos(pi:-pi/100:2*pi/3), cos(2*pi/3:pi/100:pi)], ...
         [sin(pi:-pi/100:2*pi/3), sin(2*pi/3:pi/100:pi)], dark_colors.red, 'EdgeColor', 'none'); % Red (poor)
    hold on;
    fill([cos(2*pi/3:-pi/100:pi/3), cos(pi/3:pi/100:2*pi/3)], ...
         [sin(2*pi/3:-pi/100:pi/3), sin(pi/3:pi/100:2*pi/3)], dark_colors.orange, 'EdgeColor', 'none'); % Yellow (moderate)
    fill([cos(pi/3:-pi/100:0), cos(0:pi/100:pi/3)], ...
         [sin(pi/3:-pi/100:0), sin(0:pi/100:pi/3)], dark_colors.green, 'EdgeColor', 'none'); % Green (good)
    
    % Accuracy needle
    needle_angle = pi - (accuracy/100) * pi;
    needle_x = [0, 0.8*cos(needle_angle)];
    needle_y = [0, 0.8*sin(needle_angle)];
    plot(needle_x, needle_y, 'Color', dark_colors.text, 'LineWidth', 4);
    plot(0, 0, 'o', 'MarkerSize', 8, 'MarkerFaceColor', dark_colors.text, 'MarkerEdgeColor', dark_colors.text);
    
    axis equal;
    xlim([-1.2 1.2]);
    ylim([-0.2 1.2]);
    title(sprintf('Accuracy: %.1f%%', accuracy), 'Color', dark_colors.text);
    
    % Add labels
    text(-0.9, 0.1, '0%', 'HorizontalAlignment', 'center', 'Color', dark_colors.text);
    text(0, 1.1, '50%', 'HorizontalAlignment', 'center', 'Color', dark_colors.text);
    text(0.9, 0.1, '100%', 'HorizontalAlignment', 'center', 'Color', dark_colors.text);
    
    axis off;
else
    text(0.5, 0.5, 'No Validation\nData Available', 'HorizontalAlignment', 'center', ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', dark_colors.text);
    axis off;
    title('Performance Metrics', 'Color', dark_colors.text);
end
set(gca, 'Color', dark_colors.plot_bg);

%% 5. Trial-by-Trial Timeline (Primary Method)
subplot(3, 4, [5, 6]);
primary_data = results_data.(primary_method);

trial_nums = 1:primary_data.num_trials;
confidences = primary_data.confidence;
predictions = primary_data.predictions;

% Create timeline plot
scatter(trial_nums(predictions == 1), confidences(predictions == 1), 100, 'o', ...
        'MarkerFaceColor', dark_colors.blue, 'MarkerEdgeColor', dark_colors.text, 'LineWidth', 1.5);
hold on;
scatter(trial_nums(predictions == 2), confidences(predictions == 2), 100, 's', ...
        'MarkerFaceColor', dark_colors.orange, 'MarkerEdgeColor', dark_colors.text, 'LineWidth', 1.5);

% Add trend line
p = polyfit(trial_nums, confidences, 1);
trend_line = polyval(p, trial_nums);
plot(trial_nums, trend_line, '--', 'Color', dark_colors.text, 'LineWidth', 1.5);

xlabel('Trial Number', 'Color', dark_colors.text);
ylabel('Confidence', 'Color', dark_colors.text);
title(sprintf('Trial-by-Trial Results (%s Method)', upper(primary_method)), 'Color', dark_colors.text);
set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
legend({'Left Ear', 'Right Ear', 'Trend'}, 'Location', 'best', 'TextColor', dark_colors.text);
grid on;
set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);

% Add mean line
mean_line = mean(confidences);
plot([1, primary_data.num_trials], [mean_line, mean_line], '--', 'Color', dark_colors.red, 'LineWidth', 2);

%% 6. Confidence vs Prediction Scatter
subplot(3, 4, 7);
left_conf = primary_data.confidence(primary_data.predictions == 1);
right_conf = primary_data.confidence(primary_data.predictions == 2);

if ~isempty(left_conf)
    scatter(ones(size(left_conf)), left_conf, 100, 'o', ...
            'MarkerFaceColor', dark_colors.blue, 'MarkerEdgeColor', dark_colors.text, 'LineWidth', 1.5);
end
hold on;
if ~isempty(right_conf)
    scatter(2*ones(size(right_conf)), right_conf, 100, 's', ...
            'MarkerFaceColor', dark_colors.orange, 'MarkerEdgeColor', dark_colors.text, 'LineWidth', 1.5);
end

% Add mean lines
if ~isempty(left_conf)
    plot([0.8, 1.2], [mean(left_conf), mean(left_conf)], 'Color', dark_colors.blue, 'LineWidth', 3);
    text(1, mean(left_conf) + 0.002, sprintf('μ=%.3f', mean(left_conf)), ...
         'HorizontalAlignment', 'center', 'BackgroundColor', dark_colors.plot_bg, 'Color', dark_colors.text);
end
if ~isempty(right_conf)
    plot([1.8, 2.2], [mean(right_conf), mean(right_conf)], 'Color', dark_colors.orange, 'LineWidth', 3);
    text(2, mean(right_conf) + 0.002, sprintf('μ=%.3f', mean(right_conf)), ...
         'HorizontalAlignment', 'center', 'BackgroundColor', dark_colors.plot_bg, 'Color', dark_colors.text);
end

set(gca, 'XTick', [1, 2], 'XTickLabel', {'Left Ear', 'Right Ear'}, 'Color', dark_colors.text);
set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
ylabel('Confidence', 'Color', dark_colors.text);
title('Confidence by Prediction', 'Color', dark_colors.text);
grid on;
set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);
xlim([0.5, 2.5]);

%% 7. Cross-Validation Results (if available)
subplot(3, 4, 8);
if ~isempty(validation_data) && ~isempty(validation_data.cross_validation) && ...
   ~any(isnan(validation_data.cross_validation))
    
    cv_scores = validation_data.cross_validation * 100;
    fold_nums = 1:length(cv_scores);
    
    bar(fold_nums, cv_scores, 'FaceColor', dark_colors.green, 'EdgeColor', dark_colors.text);
    hold on;
    
    % Add mean line
    mean_cv = mean(cv_scores);
    plot([0.5, length(cv_scores)+0.5], [mean_cv, mean_cv], '--', 'Color', dark_colors.red, 'LineWidth', 2);
    
    % Add chance level line
    plot([0.5, length(cv_scores)+0.5], [50, 50], ':', 'Color', dark_colors.text, 'LineWidth', 2);
    
    xlabel('Cross-Validation Fold', 'Color', dark_colors.text);
    ylabel('Accuracy (%)', 'Color', dark_colors.text);
    title('Cross-Validation Performance', 'Color', dark_colors.text);
    set(gca, 'YColor', dark_colors.text, 'XColor', dark_colors.text);
    legend({'CV Accuracy', sprintf('Mean: %.1f%%', mean_cv), 'Chance Level'}, 'Location', 'best', 'TextColor', dark_colors.text);
    grid on;
    set(gca, 'GridColor', dark_colors.grid, 'Color', dark_colors.plot_bg);
    
    % Add individual values
    for i = 1:length(cv_scores)
        text(i, cv_scores(i) + 2, sprintf('%.1f', cv_scores(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 9, 'Color', dark_colors.text);
    end
else
    text(0.5, 0.5, 'No Cross-Validation\nData Available', 'HorizontalAlignment', 'center', ...
         'FontSize', 12, 'FontWeight', 'bold', 'Color', dark_colors.text);
    axis off;
    title('Cross-Validation Results', 'Color', dark_colors.text);
end
set(gca, 'Color', dark_colors.plot_bg);

%% 8. Method Comparison Radar Chart
subplot(3, 4, [9, 10]);
if length(method_names) > 1
    % Create radar chart data
    metrics = {'Accuracy', 'Confidence', 'Consistency', 'L/R Balance'};
    
    % Normalize metrics for radar chart (0-1 scale)
    radar_data = zeros(length(method_names), length(metrics));
    
    for i = 1:length(method_names)
        method = method_names{i};
        data = results_data.(method);
        
        % Accuracy (use validation if available, otherwise use balance as proxy)
        if ~isempty(validation_data) && strcmp(method, 'correlation')
            radar_data(i, 1) = validation_data.accuracy;
        else
            % Use balance as proxy (closer to 50/50 = better)
            left_pct = sum(data.predictions == 1) / data.num_trials;
            balance_score = 1 - abs(left_pct - 0.5) * 2; % 0.5 = perfect balance
            radar_data(i, 1) = balance_score;
        end
        
        % Confidence (normalize to 0-1)
        all_confidences = [];
        for j = 1:length(method_names)
            all_confidences = [all_confidences; results_data.(method_names{j}).confidence];
        end
        max_conf = max(all_confidences);
        radar_data(i, 2) = mean(data.confidence) / max_conf;
        
        % Consistency (high confidence predictions percentage)
        high_conf_threshold = mean(data.confidence) + 0.5 * std(data.confidence);
        radar_data(i, 3) = sum(data.confidence > high_conf_threshold) / length(data.confidence);
        
        % L/R Balance (closer to 50/50 = better)
        left_pct = sum(data.predictions == 1) / data.num_trials;
        radar_data(i, 4) = 1 - abs(left_pct - 0.5) * 2;
    end
    
    % Create radar chart
    angles = linspace(0, 2*pi, length(metrics) + 1);
    angles = angles(1:end-1);
    
    hold on;
    for i = 1:length(method_names)
        values = [radar_data(i, :), radar_data(i, 1)]; % Close the polygon
        plot_angles = [angles, angles(1)];
        
        plot(plot_angles, values, 'o-', 'LineWidth', 2, 'Color', method_colors(i, :), ...
             'MarkerSize', 6, 'MarkerFaceColor', method_colors(i, :));
    end
    
    % Add grid circles
    for r = 0.2:0.2:1
        plot(angles, r * ones(size(angles)), ':', 'Color', [0.5 0.5 0.5]);
    end
    
    % Add metric labels
    for i = 1:length(metrics)
        text(angles(i) * 1.1, 1.1, metrics{i}, 'HorizontalAlignment', 'center', 'Color', dark_colors.text);
    end
    
    axis equal;
    axis off;
    title('Method Comparison (Radar Chart)', 'Color', dark_colors.text);
    legend(method_labels, 'Location', 'eastoutside', 'TextColor', dark_colors.text);
else
    text(0.5, 0.5, 'Multiple Methods\nNeeded for Comparison', 'HorizontalAlignment', 'center', ...
         'FontSize', 12, 'FontWeight', 'bold', 'Color', dark_colors.text);
    axis off;
    title('Method Comparison', 'Color', dark_colors.text);
end
set(gca, 'Color', dark_colors.plot_bg);

%% 9. Detailed Statistics Summary
subplot(3, 4, [11, 12]);
axis off;

% Create text summary
summary_text = {};
summary_text{end+1} = '📊 STATISTICAL SUMMARY';
summary_text{end+1} = '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
summary_text{end+1} = '';

for i = 1:length(method_names)
    method = method_names{i};
    data = results_data.(method);
    
    summary_text{end+1} = sprintf('🔹 %s METHOD:', upper(method));
    summary_text{end+1} = sprintf('   Trials: %d', data.num_trials);
    summary_text{end+1} = sprintf('   Left/Right: %d/%d (%.1f%%/%.1f%%)', ...
                                  sum(data.predictions == 1), sum(data.predictions == 2), ...
                                  sum(data.predictions == 1)/data.num_trials*100, ...
                                  sum(data.predictions == 2)/data.num_trials*100);
    summary_text{end+1} = sprintf('   Confidence: μ=%.3f, σ=%.3f', ...
                                  mean(data.confidence), std(data.confidence));
    summary_text{end+1} = sprintf('   Range: [%.3f, %.3f]', ...
                                  min(data.confidence), max(data.confidence));
    summary_text{end+1} = '';
end

if ~isempty(validation_data)
    summary_text{end+1} = '🔹 VALIDATION RESULTS:';
    summary_text{end+1} = sprintf('   Accuracy: %.1f%%', validation_data.accuracy * 100);
    if ~isempty(validation_data.cross_validation) && ~any(isnan(validation_data.cross_validation))
        summary_text{end+1} = sprintf('   Cross-validation: %.1f%% ± %.1f%%', ...
                                      mean(validation_data.cross_validation) * 100, ...
                                      std(validation_data.cross_validation) * 100);
    end
end

% Display text
y_pos = 0.95;
for i = 1:length(summary_text)
    if startsWith(summary_text{i}, '📊') || startsWith(summary_text{i}, '🔹')
        font_weight = 'bold';
        font_size = 11;
    else
        font_weight = 'normal';
        font_size = 10;
    end
    
    text(0.05, y_pos, summary_text{i}, 'FontSize', font_size, 'FontWeight', font_weight, ...
         'VerticalAlignment', 'top', 'Color', dark_colors.text);
    y_pos = y_pos - 0.04;
end

%% Save the visualization
sgtitle('Auditory Attention Detection - Results Visualization', 'FontSize', 16, 'FontWeight', 'bold', 'Color', dark_colors.text);

% Save high-resolution figure
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('AAD_Results_Visualization_%s.png', timestamp);
saveas(fig, filename, 'png');

fprintf('✅ Visualization saved as: %s\n', filename);

% Also save as MATLAB figure for further editing
fig_filename = sprintf('AAD_Results_Visualization_%s.fig', timestamp);
savefig(fig, fig_filename);
fprintf('✅ MATLAB figure saved as: %s\n', fig_filename);

fprintf('\n🎨 Visualization complete! The plot shows:\n');
fprintf('   1. Attention distribution comparison across methods\n');
fprintf('   2. Confidence levels and variability\n');
fprintf('   3. Trial-by-trial timeline analysis\n');
fprintf('   4. Performance metrics and cross-validation\n');
fprintf('   5. Statistical summaries and method comparisons\n\n');

end