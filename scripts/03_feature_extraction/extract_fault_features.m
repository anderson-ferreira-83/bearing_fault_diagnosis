%% Extract Fault Features for Classical ML Classification
% Extract features from envelope spectrum and signal statistics

%% Clear workspace
clear; clc; close all;

%% Load bearing parameters
load('../data/bearing_parameters.mat', 'bearing_params');

%% Initialize feature extraction
data_path = '../data/mfpt_bearing_data/';
if ~exist(data_path, 'dir')
    error('Data directory not found. Run load_bearing_data.m first.');
end

ensemble = fileEnsembleDatastore(data_path, '.mat');
num_files = numpartitions(ensemble);

%% Feature extraction parameters
fs = 97656;  % Sampling frequency
freq_tolerance = 5;  % Hz tolerance for frequency matching
window_length = 2048;
overlap = window_length / 2;

%% Initialize feature matrix
features = [];
labels = [];
file_names = {};

%% Process each file
reset(ensemble);
file_idx = 0;

while hasdata(ensemble)
    file_idx = file_idx + 1;
    
    % Read data
    data = read(ensemble);
    
    % Extract vibration signal
    if isfield(data, 'vibration')
        signal = data.vibration;
    elseif isfield(data, 'acceleration')  
        signal = data.acceleration;
    else
        fields = fieldnames(data);
        signal = data.(fields{1});
    end
    
    % Get label (adjust based on your dataset structure)
    if isfield(data, 'label')
        label = data.label;
    else
        % Default labeling pattern
        if file_idx <= 3
            label = 0;  % Normal
        elseif file_idx <= 6
            label = 1;  % Inner fault
        else
            label = 2;  % Outer fault
        end
    end
    
    % Extract features
    feature_vector = extract_bearing_features(signal, fs, bearing_params);
    
    % Store results
    features = [features; feature_vector];
    labels = [labels; label];
    file_names{end+1} = sprintf('file_%d', file_idx);
    
    fprintf('Processed file %d/%d\n', file_idx, num_files);
end

%% Feature names
feature_names = {
    'BPFI_Amplitude', 'BPFO_Amplitude', 'FTF_Amplitude', 'BSF_Amplitude', ...
    'Log_Ratio_BPFI_BPFO', 'RMS', 'Kurtosis', 'Skewness', 'Crest_Factor', ...
    'Peak_Amplitude', 'Mean_Freq', 'Freq_Std', 'Spectral_Centroid', ...
    'Spectral_Rolloff', 'Spectral_Flux'
};

%% Display feature statistics
fprintf('\nFeature Extraction Complete!\n');
fprintf('Number of samples: %d\n', size(features, 1));
fprintf('Number of features: %d\n', size(features, 2));
fprintf('Class distribution:\n');
for class = unique(labels)'
    count = sum(labels == class);
    percentage = count / length(labels) * 100;
    class_name = get_class_name(class);
    fprintf('  %s (Class %d): %d samples (%.1f%%)\n', ...
            class_name, class, count, percentage);
end

%% Save features
features_data.features = features;
features_data.labels = labels;
features_data.feature_names = feature_names;
features_data.file_names = file_names;
features_data.bearing_params = bearing_params;

save('../results/classical_approach/extracted_features.mat', 'features_data');

%% Visualize feature distributions
visualize_features(features, labels, feature_names);

%% Feature Extraction Function
function feature_vector = extract_bearing_features(signal, fs, bearing_params)
    % Extract comprehensive features for bearing fault diagnosis
    
    %% 1. Envelope Spectrum Features
    [env_spec, f_env] = compute_envelope_spectrum(signal, fs);
    
    freq_tolerance = 5;
    
    % BPFI amplitude
    bpfi_range = [bearing_params.BPFI - freq_tolerance, ...
                  bearing_params.BPFI + freq_tolerance];
    bpfi_idx = find(f_env >= bpfi_range(1) & f_env <= bpfi_range(2));
    bpfi_amplitude = max(env_spec(bpfi_idx));
    
    % BPFO amplitude
    bpfo_range = [bearing_params.BPFO - freq_tolerance, ...
                  bearing_params.BPFO + freq_tolerance];
    bpfo_idx = find(f_env >= bpfo_range(1) & f_env <= bpfo_range(2));
    bpfo_amplitude = max(env_spec(bpfo_idx));
    
    % FTF amplitude
    ftf_range = [bearing_params.FTF - freq_tolerance, ...
                 bearing_params.FTF + freq_tolerance];
    ftf_idx = find(f_env >= ftf_range(1) & f_env <= ftf_range(2));
    ftf_amplitude = max(env_spec(ftf_idx));
    
    % BSF amplitude
    bsf_range = [bearing_params.BSF - freq_tolerance, ...
                 bearing_params.BSF + freq_tolerance];
    bsf_idx = find(f_env >= bsf_range(1) & f_env <= bsf_range(2));
    bsf_amplitude = max(env_spec(bsf_idx));
    
    % Log ratio
    log_ratio = log10(bpfi_amplitude / (bpfo_amplitude + eps));
    
    %% 2. Time Domain Features
    rms_value = rms(signal);
    kurtosis_value = kurtosis(signal);
    skewness_value = skewness(signal);
    crest_factor = max(abs(signal)) / rms_value;
    peak_amplitude = max(abs(signal));
    
    %% 3. Frequency Domain Features
    [psd, f_psd] = pwelch(signal, 2048, 1024, 2048, fs);
    
    % Spectral centroid
    spectral_centroid = sum(f_psd .* psd) / sum(psd);
    
    % Spectral rolloff (95% energy)
    cumulative_energy = cumsum(psd) / sum(psd);
    rolloff_idx = find(cumulative_energy >= 0.95, 1);
    spectral_rolloff = f_psd(rolloff_idx);
    
    % Mean frequency and standard deviation
    mean_freq = spectral_centroid;
    freq_std = sqrt(sum((f_psd - mean_freq).^2 .* psd) / sum(psd));
    
    % Spectral flux (change in spectrum)
    spectral_flux = sum(diff(psd).^2);
    
    %% Combine features
    feature_vector = [
        bpfi_amplitude, bpfo_amplitude, ftf_amplitude, bsf_amplitude, ...
        log_ratio, rms_value, kurtosis_value, skewness_value, crest_factor, ...
        peak_amplitude, mean_freq, freq_std, spectral_centroid, ...
        spectral_rolloff, spectral_flux
    ];
end

%% Envelope Spectrum Helper Function
function [env_spec, f] = compute_envelope_spectrum(signal, fs)
    % High-pass filter
    [b, a] = butter(4, 1000/(fs/2), 'high');
    signal_filtered = filtfilt(b, a, signal);
    
    % Envelope
    envelope = abs(hilbert(signal_filtered));
    envelope = envelope - mean(envelope);
    
    % FFT
    N = length(envelope);
    Y = fft(envelope);
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    f = (0:(N/2)) * fs/N;
    env_spec = P1;
end

%% Visualization Function
function visualize_features(features, labels, feature_names)
    % Create feature visualization
    
    figure('Name', 'Feature Distributions', 'Position', [100, 100, 1200, 800]);
    
    num_features = min(9, size(features, 2));  % Show first 9 features
    
    for i = 1:num_features
        subplot(3, 3, i);
        
        % Plot histograms for each class
        unique_labels = unique(labels);
        colors = {'b', 'r', 'g'};
        
        hold on;
        for j = 1:length(unique_labels)
            class_data = features(labels == unique_labels(j), i);
            histogram(class_data, 'FaceColor', colors{j}, 'FaceAlpha', 0.6);
        end
        
        title(strrep(feature_names{i}, '_', ' '));
        xlabel('Feature Value');
        ylabel('Count');
        
        if i == 1
            legend({'Normal', 'Inner Fault', 'Outer Fault'}, 'Location', 'best');
        end
        
        grid on;
    end
    
    sgtitle('Feature Distributions by Fault Type');
end

%% Class Name Helper
function class_name = get_class_name(class_id)
    switch class_id
        case 0
            class_name = 'Normal';
        case 1
            class_name = 'Inner Fault';
        case 2
            class_name = 'Outer Fault';
        otherwise
            class_name = 'Unknown';
    end
end