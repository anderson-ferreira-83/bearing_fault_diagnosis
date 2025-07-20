%% Rule-Based Bearing Fault Classifier
% Implement the classical rule-based approach using log ratio thresholds

%% Clear workspace
clear; clc; close all;

%% Load extracted features
if ~exist('../results/classical_approach/extracted_features.mat', 'file')
    error('Features not found. Run extract_fault_features.m first.');
end

load('../results/classical_approach/extracted_features.mat', 'features_data');

features = features_data.features;
true_labels = features_data.labels;
feature_names = features_data.feature_names;

%% Extract log ratio feature (index 5)
log_ratio_idx = strcmp(feature_names, 'Log_Ratio_BPFI_BPFO');
log_ratios = features(:, log_ratio_idx);

%% Apply rule-based classification
% Thresholds from MathWorks tutorial
threshold_1 = -1.5;  % Outer fault threshold
threshold_2 = 0.5;   % Inner fault threshold

predicted_labels = zeros(size(log_ratios));

for i = 1:length(log_ratios)
    if log_ratios(i) <= threshold_1
        predicted_labels(i) = 2;  % Outer race fault
    elseif log_ratios(i) > threshold_1 && log_ratios(i) <= threshold_2
        predicted_labels(i) = 0;  % Normal
    else
        predicted_labels(i) = 1;  % Inner race fault
    end
end

%% Calculate Performance Metrics
accuracy = sum(predicted_labels == true_labels) / length(true_labels) * 100;

% Confusion matrix
unique_labels = unique([true_labels; predicted_labels]);
conf_matrix = zeros(length(unique_labels));

for i = 1:length(unique_labels)
    for j = 1:length(unique_labels)
        conf_matrix(i,j) = sum(true_labels == unique_labels(i) & ...
                              predicted_labels == unique_labels(j));
    end
end

% Per-class metrics
class_names = {'Normal', 'Inner Fault', 'Outer Fault'};
precision = zeros(3,1);
recall = zeros(3,1);
f1_score = zeros(3,1);

for i = 1:3
    if i <= length(unique_labels)
        class_id = unique_labels(i);
        
        % True positives, false positives, false negatives
        tp = sum(true_labels == class_id & predicted_labels == class_id);
        fp = sum(true_labels ~= class_id & predicted_labels == class_id);
        fn = sum(true_labels == class_id & predicted_labels ~= class_id);
        
        % Calculate metrics
        if (tp + fp) > 0
            precision(i) = tp / (tp + fp);
        else
            precision(i) = 0;
        end
        
        if (tp + fn) > 0
            recall(i) = tp / (tp + fn);
        else
            recall(i) = 0;
        end
        
        if (precision(i) + recall(i)) > 0
            f1_score(i) = 2 * precision(i) * recall(i) / (precision(i) + recall(i));
        else
            f1_score(i) = 0;
        end
    end
end

%% Display Results
fprintf('\n=== Rule-Based Classifier Results ===\n');
fprintf('Overall Accuracy: %.2f%%\n\n', accuracy);

fprintf('Classification Thresholds:\n');
fprintf('  Log Ratio ≤ %.1f  → Outer Race Fault\n', threshold_1);
fprintf('  %.1f < Log Ratio ≤ %.1f → Normal\n', threshold_1, threshold_2);
fprintf('  Log Ratio > %.1f  → Inner Race Fault\n\n', threshold_2);

fprintf('Confusion Matrix:\n');
fprintf('%-12s', 'True\\Pred');
for i = 1:length(class_names)
    fprintf('%12s', class_names{i});
end
fprintf('\n');

for i = 1:length(unique_labels)
    fprintf('%-12s', class_names{unique_labels(i)+1});
    for j = 1:length(unique_labels)
        fprintf('%12d', conf_matrix(i,j));
    end
    fprintf('\n');
end

fprintf('\nPer-Class Performance:\n');
fprintf('%-12s %10s %10s %10s\n', 'Class', 'Precision', 'Recall', 'F1-Score');
fprintf('%-12s %10s %10s %10s\n', '-----', '---------', '------', '--------');
for i = 1:3
    fprintf('%-12s %10.3f %10.3f %10.3f\n', ...
            class_names{i}, precision(i), recall(i), f1_score(i));
end

%% Visualize Results
figure('Name', 'Rule-Based Classification Results', 'Position', [100, 100, 1200, 800]);

% Plot 1: Log ratio distribution with thresholds
subplot(2,3,1);
hold on;
colors = {'b', 'r', 'g'};
class_labels = [0, 1, 2];

for i = 1:3
    class_data = log_ratios(true_labels == class_labels(i));
    histogram(class_data, 'FaceColor', colors{i}, 'FaceAlpha', 0.6);
end

xline(threshold_1, 'k--', 'LineWidth', 2);
xline(threshold_2, 'k--', 'LineWidth', 2);

xlabel('Log Ratio (BPFI/BPFO)');
ylabel('Count');
title('Log Ratio Distribution with Thresholds');
legend(class_names, 'Location', 'best');
grid on;

% Plot 2: Scatter plot of true vs predicted
subplot(2,3,2);
scatter(true_labels, predicted_labels, 50, 'filled');
xlabel('True Labels');
ylabel('Predicted Labels');
title('True vs Predicted Labels');
grid on;
axis equal;
xlim([-0.5, 2.5]);
ylim([-0.5, 2.5]);

% Plot 3: Confusion matrix heatmap
subplot(2,3,3);
imagesc(conf_matrix);
colorbar;
colormap(hot);
xlabel('Predicted Class');
ylabel('True Class');
title('Confusion Matrix');

% Add text annotations
for i = 1:size(conf_matrix,1)
    for j = 1:size(conf_matrix,2)
        text(j, i, num2str(conf_matrix(i,j)), ...
             'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold');
    end
end

% Plot 4: Performance metrics bar chart
subplot(2,3,4);
metrics_matrix = [precision, recall, f1_score];
bar(metrics_matrix);
xlabel('Class');
ylabel('Score');
title('Performance Metrics by Class');
legend({'Precision', 'Recall', 'F1-Score'}, 'Location', 'best');
set(gca, 'XTickLabel', class_names);
grid on;

% Plot 5: Classification boundary visualization
subplot(2,3,[5,6]);
x_range = linspace(min(log_ratios)-0.5, max(log_ratios)+0.5, 1000);
y_pred = zeros(size(x_range));

for i = 1:length(x_range)
    if x_range(i) <= threshold_1
        y_pred(i) = 2;  % Outer fault
    elseif x_range(i) <= threshold_2
        y_pred(i) = 0;  % Normal
    else
        y_pred(i) = 1;  % Inner fault
    end
end

% Plot decision boundaries
plot(x_range, y_pred, 'k-', 'LineWidth', 3);
hold on;

% Overlay actual data points
for i = 1:3
    class_data = log_ratios(true_labels == class_labels(i));
    y_values = class_labels(i) * ones(size(class_data));
    scatter(class_data, y_values, 50, colors{i}, 'filled', 'MarkerEdgeColor', 'k');
end

xlabel('Log Ratio (BPFI/BPFO)');
ylabel('Fault Class');
title('Classification Decision Boundaries');
ylim([-0.5, 2.5]);
yticks([0, 1, 2]);
yticklabels(class_names);
grid on;

% Add threshold lines
xline(threshold_1, 'r--', 'Threshold 1', 'LineWidth', 2);
xline(threshold_2, 'r--', 'Threshold 2', 'LineWidth', 2);

%% Save Results
classification_results.predicted_labels = predicted_labels;
classification_results.true_labels = true_labels;
classification_results.log_ratios = log_ratios;
classification_results.accuracy = accuracy;
classification_results.confusion_matrix = conf_matrix;
classification_results.precision = precision;
classification_results.recall = recall;
classification_results.f1_score = f1_score;
classification_results.thresholds = [threshold_1, threshold_2];

save('../results/classical_approach/classification_results.mat', 'classification_results');

fprintf('\nResults saved to: ../results/classical_approach/classification_results.mat\n');