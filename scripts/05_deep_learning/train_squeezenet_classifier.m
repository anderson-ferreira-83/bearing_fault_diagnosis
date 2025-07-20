%% Train SqueezeNet for Bearing Fault Classification
% Transfer learning approach using scalogram images

%% Clear workspace
clear; clc; close all;

%% Check for scalogram data
scalogram_dir = '../data/scalograms/';
if ~exist(scalogram_dir, 'dir')
    error('Scalogram data not found. Run prepare_scalogram_data.m first.');
end

%% Create Image Datastore
imds = imageDatastore(scalogram_dir, ...
    'IncludeSubfolders', true, ...
    'LabelSource', 'foldernames');

% Display dataset info
fprintf('Dataset Information:\n');
fprintf('Total Images: %d\n', numel(imds.Files));
labelCounts = countEachLabel(imds);
disp(labelCounts);

%% Data Preprocessing
% Resize images to SqueezeNet input size (227x227x3)
target_size = [227, 227];
imds.ReadFcn = @(filename) imresize(imread(filename), target_size);

%% Split Data
% 80% training, 20% validation
[imdsTrain, imdsValidation] = splitEachLabel(imds, 0.8, 'randomized');

fprintf('\nData Split:\n');
fprintf('Training Images: %d\n', numel(imdsTrain.Files));
fprintf('Validation Images: %d\n', numel(imdsValidation.Files));

%% Load Pre-trained SqueezeNet
try
    net = squeezenet;
    fprintf('\nLoaded pre-trained SqueezeNet\n');
catch
    error('SqueezeNet not available. Please install Deep Learning Toolbox Model for SqueezeNet.');
end

%% Analyze Network Architecture
lgraph = layerGraph(net);
numClasses = numel(categories(imdsTrain.Labels));

% Find the last learnable layer and classification layer
learnableLayer = findLayersToReplace(lgraph);
classificationLayer = findClassificationLayer(lgraph);

%% Modify Network for Transfer Learning
% Replace final layers
if numClasses ~= 1000  % SqueezeNet default is 1000 classes
    newLearnableLayer = convolution2dLayer(1, numClasses, ...
        'Name', 'new_conv', ...
        'WeightLearnRateFactor', 10, ...
        'BiasLearnRateFactor', 10);
    
    lgraph = replaceLayer(lgraph, learnableLayer.Name, newLearnableLayer);
    
    newClassificationLayer = classificationLayer('new_classoutput', numClasses);
    lgraph = replaceLayer(lgraph, classificationLayer.Name, newClassificationLayer);
end

%% Training Options
options = trainingOptions('sgdm', ...
    'MiniBatchSize', 20, ...
    'MaxEpochs', 4, ...
    'InitialLearnRate', 1e-4, ...
    'ValidationData', imdsValidation, ...
    'ValidationFrequency', 30, ...
    'Verbose', true, ...
    'Plots', 'training-progress', ...
    'ExecutionEnvironment', 'auto');

%% Train Network
fprintf('\nStarting training...\n');
tic;
netTransfer = trainNetwork(imdsTrain, lgraph, options);
training_time = toc;

fprintf('Training completed in %.2f seconds\n', training_time);

%% Evaluate Model
fprintf('\nEvaluating model...\n');

% Predict on validation set
YPred = classify(netTransfer, imdsValidation);
YValidation = imdsValidation.Labels;

% Calculate accuracy
accuracy = sum(YPred == YValidation) / numel(YValidation) * 100;
fprintf('Validation Accuracy: %.2f%%\n', accuracy);

%% Confusion Matrix
figure('Name', 'Deep Learning Results');
subplot(2,2,1);
confusionchart(YValidation, YPred);
title('Confusion Matrix');

%% Per-Class Performance
classes = categories(YValidation);
confMat = confusionmat(YValidation, YPred);

precision = zeros(length(classes), 1);
recall = zeros(length(classes), 1);
f1_score = zeros(length(classes), 1);

for i = 1:length(classes)
    tp = confMat(i,i);
    fp = sum(confMat(:,i)) - tp;
    fn = sum(confMat(i,:)) - tp;
    
    if (tp + fp) > 0
        precision(i) = tp / (tp + fp);
    end
    
    if (tp + fn) > 0
        recall(i) = tp / (tp + fn);
    end
    
    if (precision(i) + recall(i)) > 0
        f1_score(i) = 2 * precision(i) * recall(i) / (precision(i) + recall(i));
    end
end

%% Display Results
fprintf('\nPer-Class Performance:\n');
fprintf('%-15s %10s %10s %10s\n', 'Class', 'Precision', 'Recall', 'F1-Score');
fprintf('%-15s %10s %10s %10s\n', '-----', '---------', '------', '--------');
for i = 1:length(classes)
    fprintf('%-15s %10.3f %10.3f %10.3f\n', ...
            string(classes{i}), precision(i), recall(i), f1_score(i));
end

%% Visualize Performance Metrics
subplot(2,2,2);
metrics_matrix = [precision, recall, f1_score];
bar(metrics_matrix);
xlabel('Class');
ylabel('Score');
title('Performance Metrics by Class');
legend({'Precision', 'Recall', 'F1-Score'}, 'Location', 'best');
set(gca, 'XTickLabel', classes);
grid on;

%% Sample Predictions Visualization
subplot(2,2,[3,4]);
sample_indices = randperm(numel(imdsValidation.Files), min(12, numel(imdsValidation.Files)));

for i = 1:min(12, length(sample_indices))
    subplot(3,4,i);
    
    % Read and display image
    img = readimage(imdsValidation, sample_indices(i));
    imshow(img);
    
    % Get prediction and true label
    pred_label = YPred(sample_indices(i));
    true_label = YValidation(sample_indices(i));
    
    % Color code: green for correct, red for incorrect
    if pred_label == true_label
        title_color = 'green';
        title_text = sprintf('✓ %s', string(pred_label));
    else
        title_color = 'red';
        title_text = sprintf('✗ %s (True: %s)', string(pred_label), string(true_label));
    end
    
    title(title_text, 'Color', title_color, 'FontSize', 8);
end

sgtitle('Sample Predictions (Green=Correct, Red=Incorrect)');

%% Feature Visualization (Grad-CAM)
try
    % Select a sample image for Grad-CAM
    sample_img = readimage(imdsValidation, 1);
    sample_label = YValidation(1);
    
    % Generate Grad-CAM
    gradcam_map = gradCAM(netTransfer, sample_img, sample_label);
    
    figure('Name', 'Grad-CAM Visualization');
    subplot(1,3,1);
    imshow(sample_img);
    title('Original Scalogram');
    
    subplot(1,3,2);
    imshow(gradcam_map);
    title('Grad-CAM Heatmap');
    
    subplot(1,3,3);
    imshowpair(sample_img, gradcam_map, 'blend');
    title('Overlay');
    
catch
    fprintf('Grad-CAM visualization not available.\n');
end

%% Save Results
deep_learning_results.trained_network = netTransfer;
deep_learning_results.training_options = options;
deep_learning_results.validation_accuracy = accuracy;
deep_learning_results.confusion_matrix = confMat;
deep_learning_results.precision = precision;
deep_learning_results.recall = recall;
deep_learning_results.f1_score = f1_score;
deep_learning_results.class_names = classes;
deep_learning_results.training_time = training_time;
deep_learning_results.predictions = YPred;
deep_learning_results.true_labels = YValidation;

save('../results/deep_learning_approach/squeezenet_results.mat', 'deep_learning_results');

fprintf('\nResults saved to: ../results/deep_learning_approach/squeezenet_results.mat\n');

%% Helper Functions
function layer = findLayersToReplace(lgraph)
    % Find the last learnable layer (usually a convolution or fully connected layer)
    layers = lgraph.Layers;
    
    for i = length(layers):-1:1
        if isa(layers(i), 'nnet.cnn.layer.Convolution2DLayer') || ...
           isa(layers(i), 'nnet.cnn.layer.FullyConnectedLayer')
            layer = layers(i);
            return;
        end
    end
    
    error('Could not find a suitable layer to replace');
end

function layer = findClassificationLayer(lgraph)
    % Find the classification layer
    layers = lgraph.Layers;
    
    for i = 1:length(layers)
        if isa(layers(i), 'nnet.cnn.layer.ClassificationOutputLayer')
            layer = layers(i);
            return;
        end
    end
    
    % If not found, create a new one
    layer = classificationLayer('Name', 'new_classoutput');
end