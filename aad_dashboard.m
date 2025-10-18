function aad_dashboard()
% CREATE_IMPROVED_DASHBOARD Create a clean, professional AAD results visualization
% Improved styling, colors, and readability

fprintf('🎨 Creating improved AAD Results Dashboard...\n\n');

%% Load data
methods = {'correlation', 'trf', 'cca'};
results_data = struct();

for i = 1:length(methods)
    filename = sprintf('attention_results_%s.mat', methods{i});
    if exist(filename, 'file')
        loaded = load(filename);
        results_data.(methods{i}) = loaded.attention_results;
    end
end

% Load validation data
validation_data = [];
if exist('validation_results_correlation.mat', 'file')
    loaded_val = load('validation_results_correlation.mat');
    validation_data = loaded_val.validation_results;
end

%% Define consistent colors and styling
colors = struct();
colors.blue = [0.3 0.7 1.0];        % Brighter blue for dark theme
colors.orange = [1.0 0.6 0.2];      % Brighter orange
colors.green = [0.4 0.9 0.4];       % Brighter green
colors.red = [1.0 0.3 0.3];         % Brighter red
colors.purple = [0.8 0.5 0.9];      % Brighter purple
colors.gray = [0.7 0.7 0.7];        % Lighter gray for visibility
colors.light_gray = [0.9 0.9 0.9];  % Keep for text
colors.dark_bg = [0.15 0.15 0.25];  % Dark blue-gray background
colors.plot_bg = [0.2 0.2 0.3];     % Slightly lighter for plot areas
colors.text_light = [0.9 0.9 0.9];  % Light text color

%% Create main dashboard figure
fig = figure('Position', [100, 100, 1400, 900], 'Name', 'AAD Results Dashboard - Dark Theme');
set(fig, 'Color', colors.dark_bg);

%% 1. Left/Right Prediction Comparison
subplot(2, 4, 1);

% Data from your results
methods_display = {'CORR', 'TRF', 'CCA'};
left_pcts = [75, 45, 35];
right_pcts = [25, 55, 65];
confidences = [0.023, 0.010, 0.017];

% Create grouped bar chart with better colors
x = 1:3;
bar_width = 0.35;
h1 = bar(x - bar_width/2, left_pcts, bar_width, 'FaceColor', colors.blue, 'EdgeColor', 'none');
hold on;
h2 = bar(x + bar_width/2, right_pcts, bar_width, 'FaceColor', colors.orange, 'EdgeColor', 'none');

% Add value labels with better positioning
for i = 1:3
    text(i - bar_width/2, left_pcts(i) + 3, sprintf('%d%%', left_pcts(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10, 'Color', colors.text_light);
    text(i + bar_width/2, right_pcts(i) + 3, sprintf('%d%%', right_pcts(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 10, 'Color', colors.text_light);
end

set(gca, 'XTick', x, 'XTickLabel', methods_display, 'FontSize', 11, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
ylabel('Attention Predictions (%)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Left vs Right Ear Predictions', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
legend({'Left Ear', 'Right Ear'}, 'Location', 'northeast', 'FontSize', 10, 'TextColor', colors.text_light);
grid on;
grid('minor');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1, 'GridColor', colors.gray, 'MinorGridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
ylim([0, 85]);
set(gca, 'Box', 'off');

%% 2. Confidence Levels Comparison
subplot(2, 4, 2);

h = bar(1:3, confidences, 'FaceColor', colors.purple, 'EdgeColor', 'none', 'BarWidth', 0.6);
hold on;

% Add value labels
for i = 1:3
    text(i, confidences(i) + 0.002, sprintf('%.3f', confidences(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11, 'Color', colors.text_light);
end

% Add threshold line
threshold = 0.05;
plot([0.5, 3.5], [threshold, threshold], '--', 'Color', colors.red, 'LineWidth', 2);
text(2, threshold + 0.005, 'Typical Min Threshold', 'HorizontalAlignment', 'center', ...
     'Color', colors.red, 'FontWeight', 'bold', 'FontSize', 10, 'BackgroundColor', colors.plot_bg);

set(gca, 'XTick', 1:3, 'XTickLabel', methods_display, 'FontSize', 11, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
ylabel('Mean Confidence', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Confidence Levels by Method', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
grid on;
grid('minor');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1, 'GridColor', colors.gray, 'MinorGridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'Box', 'off');

%% 3. Trial Count Issue Visualization
subplot(2, 4, 3);

trial_counts = [4, 20, 20];
colors_trials = [colors.red; colors.green; colors.green];

for i = 1:3
    h = bar(i, trial_counts(i), 'FaceColor', colors_trials(i, :), 'EdgeColor', 'none', 'BarWidth', 0.6);
    hold on;
    text(i, trial_counts(i) + 1, sprintf('%d', trial_counts(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 12, 'Color', colors.text_light);
end

% Add warning for low trial count
text(1, 15, {'WARNING:', 'Low Trial Count'}, 'HorizontalAlignment', 'center', ...
     'Color', colors.red, 'FontWeight', 'bold', 'FontSize', 10, ...
     'BackgroundColor', [0.3 0.3 0.1], 'EdgeColor', colors.red);

set(gca, 'XTick', 1:3, 'XTickLabel', methods_display, 'FontSize', 11, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
ylabel('Number of Trials', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Trial Counts (Issue Detected)', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
grid on;
grid('minor');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1, 'GridColor', colors.gray, 'MinorGridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'Box', 'off');

%% 4. Performance Gauge
subplot(2, 4, 4);

accuracy = 60; % From your results

% Create a cleaner pie chart
accuracy_data = [accuracy, 100-accuracy];
h = pie(accuracy_data);

% Customize pie chart colors
h(1).FaceColor = colors.green;
h(1).EdgeColor = 'white';
h(1).LineWidth = 2;
h(3).FaceColor = colors.red;
h(3).EdgeColor = 'white';
h(3).LineWidth = 2;

% Update text labels
h(2).String = sprintf('Correct\n(%d%%)', accuracy);
h(2).FontSize = 11;
h(2).FontWeight = 'bold';
h(4).String = sprintf('Incorrect\n(%d%%)', 100-accuracy);
h(4).FontSize = 11;
h(4).FontWeight = 'bold';

title('Overall Accuracy', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);

% Add performance rating below
text(0, -1.7, 'Performance: MODERATE', 'HorizontalAlignment', 'center', ...
     'FontWeight', 'bold', 'FontSize', 12, 'Color', colors.orange, ...
     'BackgroundColor', [0.2 0.15 0.05], 'EdgeColor', colors.orange);

% Set axis colors
set(gca, 'Color', colors.plot_bg);

%% 5. Attention Bias Visualization
subplot(2, 4, 5);

% Create a diverging bar chart
h1 = barh(1:3, left_pcts, 'FaceColor', colors.blue, 'EdgeColor', 'none');
hold on;
h2 = barh(1:3, -right_pcts, 'FaceColor', colors.orange, 'EdgeColor', 'none');

% Add center line
plot([0, 0], [0.5, 3.5], 'k-', 'LineWidth', 2);

% Add balanced reference lines
plot([50, 50], [0.5, 3.5], '--', 'Color', colors.green, 'LineWidth', 1.5);
plot([-50, -50], [0.5, 3.5], '--', 'Color', colors.green, 'LineWidth', 1.5);

% Add labels
for i = 1:3
    text(left_pcts(i) + 5, i, sprintf('%d%%', left_pcts(i)), ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 10, 'Color', colors.text_light);
    text(-right_pcts(i) - 5, i, sprintf('%d%%', right_pcts(i)), ...
         'VerticalAlignment', 'middle', 'FontWeight', 'bold', 'FontSize', 10, 'Color', colors.text_light);
end

set(gca, 'YTick', 1:3, 'YTickLabel', methods_display, 'FontSize', 11, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
xlabel('Attention Bias (%)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Left/Right Attention Bias', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
xlim([-80, 80]);
grid on;
grid('minor');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1, 'GridColor', colors.gray, 'MinorGridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'Box', 'off');

% Add legend
text(-70, 3.3, 'Left Ear', 'Color', colors.blue, 'FontWeight', 'bold', 'FontSize', 10);
text(40, 3.3, 'Right Ear', 'Color', colors.orange, 'FontWeight', 'bold', 'FontSize', 10);
text(52, 3.3, 'Balanced', 'Color', colors.green, 'FontWeight', 'bold', 'FontSize', 10);

%% 6. Confidence vs Bias Relationship
subplot(2, 4, 6);

scatter(confidences, left_pcts, 120, [colors.blue; colors.purple; colors.green], 'filled', 'MarkerEdgeColor', 'black', 'LineWidth', 1.5);
hold on;

% Add method labels
labels = {'CORR', 'TRF', 'CCA'};
for i = 1:3
    text(confidences(i), left_pcts(i) + 4, labels{i}, ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11);
end

% Add trend line if possible
if length(confidences) > 2
    p = polyfit(confidences, left_pcts, 1);
    x_trend = linspace(min(confidences), max(confidences), 100);
    y_trend = polyval(p, x_trend);
    plot(x_trend, y_trend, '--', 'Color', colors.gray, 'LineWidth', 2);
end

xlabel('Mean Confidence', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
ylabel('Left Ear Bias (%)', 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Confidence vs Bias Relationship', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
grid on;
grid('minor');
set(gca, 'GridAlpha', 0.3, 'MinorGridAlpha', 0.1, 'GridColor', colors.gray, 'MinorGridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
set(gca, 'Box', 'off');

%% 7. Key Statistics Summary
subplot(2, 4, 7);
axis off;

% Create clean text summary
stats_text = {
    'KEY STATISTICS';
    '─────────────────────';
    '';
    'CORRELATION METHOD:';
    sprintf('  • Trials: %d', 4);
    sprintf('  • Accuracy: %d%%', 60);
    sprintf('  • Left Bias: %d%%', 75);
    sprintf('  • Confidence: %.3f', 0.023);
    '';
    'TRF METHOD:';
    sprintf('  • Trials: %d', 20);
    sprintf('  • Balanced: %d%%/%d%%', 45, 55);
    sprintf('  • Confidence: %.3f', 0.010);
    '';
    'CCA METHOD:';
    sprintf('  • Trials: %d', 20);
    sprintf('  • Right Bias: %d%%', 65);
    sprintf('  • Confidence: %.3f', 0.017);
};

y_start = 0.95;
for i = 1:length(stats_text)
    if i == 1 || (length(stats_text{i}) >= 7 && strcmp(stats_text{i}(end-6:end), 'METHOD:'))
        font_weight = 'bold';
        font_size = 12;
        color = colors.blue;
    elseif strcmp(stats_text{i}, '─────────────────────')
        font_weight = 'normal';
        font_size = 10;
        color = colors.gray;
    elseif length(stats_text{i}) >= 3 && startsWith(stats_text{i}, '  •')
        font_weight = 'normal';
        font_size = 10;
        color = colors.text_light;
    else
        font_weight = 'bold';
        font_size = 11;
        color = colors.text_light;
    end
    
    text(0.05, y_start - (i-1)*0.06, stats_text{i}, ...
         'FontSize', font_size, 'FontWeight', font_weight, 'Color', color);
end

%% 8. Action Items
subplot(2, 4, 8);
axis off;

action_items = {
    'IMMEDIATE ACTIONS';
    '─────────────────────';
    '';
    '1. STANDARDIZE TRIALS';
    '   Fix trial count mismatch';
    '';
    '2. INVESTIGATE CONFIDENCE';
    '   Values too low (<0.03)';
    '';
    '3. ADDRESS BIAS';
    '   Check channel balance';
    '';
    '4. EXPAND VALIDATION';
    '   Test more subjects';
    '';
    '5. CONSIDER ENSEMBLE';
    '   Combine methods';
};

y_start = 0.95;
for i = 1:length(action_items)
    if i == 1
        font_weight = 'bold';
        font_size = 12;
        color = colors.red;
    elseif strcmp(action_items{i}, '─────────────────────')
        font_weight = 'normal';
        font_size = 10;
        color = colors.gray;
    elseif length(action_items{i}) >= 2 && ~isempty(str2double(action_items{i}(1))) && ~isnan(str2double(action_items{i}(1)))
        font_weight = 'bold';
        font_size = 11;
        color = colors.blue;
    elseif length(action_items{i}) >= 3 && startsWith(action_items{i}, '   ')
        font_weight = 'normal';
        font_size = 10;
        color = colors.text_light;
    else
        font_weight = 'normal';
        font_size = 10;
        color = colors.text_light;
    end
    
    text(0.05, y_start - (i-1)*0.055, action_items{i}, ...
         'FontSize', font_size, 'FontWeight', font_weight, 'Color', color);
end

%% Add overall title and improve layout
sgtitle('Auditory Attention Detection - Results Analysis Dashboard', ...
        'FontSize', 16, 'FontWeight', 'bold', 'Color', colors.text_light);

% Adjust subplot spacing
set(fig, 'Units', 'normalized');
subplots = findall(fig, 'Type', 'axes');
for i = 1:length(subplots)
    if ~strcmp(get(subplots(i), 'Tag'), 'sgtitle')
        pos = get(subplots(i), 'Position');
        pos(3) = pos(3) * 0.9; % Reduce width slightly
        pos(4) = pos(4) * 0.85; % Reduce height slightly
        set(subplots(i), 'Position', pos);
    end
end

%% Save the improved dashboard
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('AAD_Dashboard_Improved_%s.png', timestamp);
print(fig, filename, '-dpng', '-r300');

fprintf('✅ Improved dashboard saved as: %s\n\n', filename);

%% Create a simplified summary figure
fig2 = figure('Position', [150, 150, 1000, 600], 'Name', 'AAD Summary - Dark Theme');
set(fig2, 'Color', colors.dark_bg);

% Summary plot 1: Method comparison
subplot(1, 3, 1);
methods_short = {'CORR', 'TRF', 'CCA'};
data_matrix = [left_pcts; right_pcts]';
h = bar(data_matrix, 'grouped');
h(1).FaceColor = colors.blue;
h(1).EdgeColor = 'none';
h(2).FaceColor = colors.orange;
h(2).EdgeColor = 'none';

set(gca, 'XTickLabel', methods_short, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
ylabel('Predictions (%)', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Attention Predictions by Method', 'FontSize', 14, 'FontWeight', 'bold', 'Color', colors.text_light);
legend({'Left Ear', 'Right Ear'}, 'Location', 'best', 'FontSize', 11, 'TextColor', colors.text_light);
grid on;
set(gca, 'GridAlpha', 0.3, 'GridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'Box', 'off');

% Summary plot 2: Confidence levels
subplot(1, 3, 2);
h = bar(confidences, 'FaceColor', colors.purple, 'EdgeColor', 'none');
hold on;
plot([0.5, 3.5], [0.05, 0.05], '--r', 'LineWidth', 2);

for i = 1:3
    text(i, confidences(i) + 0.003, sprintf('%.3f', confidences(i)), ...
         'HorizontalAlignment', 'center', 'FontWeight', 'bold', 'FontSize', 11, 'Color', colors.text_light);
end

set(gca, 'XTick', 1:3, 'XTickLabel', methods_short, 'FontSize', 12, 'FontWeight', 'bold', 'Color', colors.text_light);
set(gca, 'YColor', colors.text_light, 'XColor', colors.text_light);
ylabel('Mean Confidence', 'FontSize', 13, 'FontWeight', 'bold', 'Color', colors.text_light);
title('Confidence Levels', 'FontSize', 14, 'FontWeight', 'bold', 'Color', colors.text_light);
text(2, 0.052, 'Min Threshold', 'HorizontalAlignment', 'center', 'Color', 'red', 'FontWeight', 'bold');
grid on;
set(gca, 'GridAlpha', 0.3, 'GridColor', colors.gray);
set(gca, 'Color', colors.plot_bg);
set(gca, 'Box', 'off');

% Summary plot 3: Key insights
subplot(1, 3, 3);
axis off;

insights = {
    'KEY INSIGHTS';
    '';
    '⚠️  CRITICAL ISSUES:';
    '  • Unequal trial counts';
    '  • Low confidence values';
    '  • Strong attention bias';
    '';
    '📊 PERFORMANCE:';
    '  • 60% accuracy (moderate)';
    '  • Cross-validation: 60±22%';
    '';
    '🎯 NEXT STEPS:';
    '  • Standardize processing';
    '  • Investigate low confidence';
    '  • Test more subjects';
    '  • Consider method ensemble';
};

y_pos = 0.9;
for i = 1:length(insights)
    if contains(insights{i}, 'KEY INSIGHTS')
        font_size = 14;
        font_weight = 'bold';
        color = colors.blue;
    elseif contains(insights{i}, '⚠️') || contains(insights{i}, '📊') || contains(insights{i}, '🎯')
        font_size = 12;
        font_weight = 'bold';
        color = colors.red;
    elseif startsWith(insights{i}, '  •')
        font_size = 11;
        font_weight = 'normal';
        color = colors.text_light;
    else
        font_size = 11;
        font_weight = 'normal';
        color = colors.text_light;
    end
    
    text(0.05, y_pos, insights{i}, 'FontSize', font_size, 'FontWeight', font_weight, 'Color', color);
    y_pos = y_pos - 0.07;
end

sgtitle('AAD Analysis - Executive Summary', 'FontSize', 16, 'FontWeight', 'bold', 'Color', colors.text_light);

% Save summary
summary_filename = sprintf('AAD_Summary_Clean_%s.png', timestamp);
print(fig2, summary_filename, '-dpng', '-r300');

fprintf('✅ Clean summary saved as: %s\n\n', summary_filename);

fprintf('🎨 Improved visualization complete!\n');
fprintf('📊 Generated professional-quality dark theme dashboards with:\n');
fprintf('   • Dark blue-gray background for easy viewing\n');
fprintf('   • High contrast colors for better visibility\n');
fprintf('   • Consistent dark theme throughout\n');
fprintf('   • Bright, vibrant colors for data visualization\n');
fprintf('   • Professional styling optimized for presentations\n\n');

end