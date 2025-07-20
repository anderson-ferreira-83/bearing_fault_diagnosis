%% Kurtogram Analysis for Optimal Bandpass Filter Design
% Use kurtogram to find optimal frequency band for envelope analysis

%% Clear workspace
clear; clc; close all;

%% Load vibration data
data_path = '../data/mfpt_bearing_data/';
ensemble = fileEnsembleDatastore(data_path, '.mat');
sample_data = read(ensemble);

% Extract vibration signal
if isfield(sample_data, 'vibration')
    signal = sample_data.vibration;
elseif isfield(sample_data, 'acceleration')
    signal = sample_data.acceleration;
else
    fields = fieldnames(sample_data);
    signal = sample_data.(fields{1});
end

fs = 97656;  % Sampling frequency (Hz)

%% Kurtogram Computation
try
    % Use built-in kurtogram function
    [kurt_map, f_centers, bw] = kurtogram(signal, fs);
    
    % Find optimal filter parameters
    [max_kurt, max_idx] = max(kurt_map(:));
    [level_idx, freq_idx] = ind2sub(size(kurt_map), max_idx);
    
    optimal_center_freq = f_centers(freq_idx);
    optimal_bandwidth = bw(level_idx);
    
    % Display kurtogram
    figure('Name', 'Kurtogram Analysis');
    subplot(2,2,1);
    imagesc(f_centers, 1:size(kurt_map,1), kurt_map);
    colorbar;
    xlabel('Center Frequency (Hz)');
    ylabel('Filter Level');
    title('Kurtogram');
    
    % Mark optimal point
    hold on;
    plot(optimal_center_freq, level_idx, 'rx', 'MarkerSize', 15, 'LineWidth', 3);
    
catch
    % Manual kurtogram computation if function not available
    fprintf('kurtogram function not available. Using manual computation.\n');
    [kurt_map, f_centers, bw, optimal_center_freq, optimal_bandwidth] = ...
        compute_kurtogram_manual(signal, fs);
    
    % Display results
    figure('Name', 'Manual Kurtogram Analysis');
    subplot(2,2,1);
    imagesc(f_centers, 1:size(kurt_map,1), kurt_map);
    colorbar;
    xlabel('Center Frequency (Hz)');
    ylabel('Filter Level');
    title('Kurtogram (Manual)');
end

%% Design Optimal Bandpass Filter
% Design bandpass filter based on kurtogram results
low_freq = optimal_center_freq - optimal_bandwidth/2;
high_freq = optimal_center_freq + optimal_bandwidth/2;

% Ensure frequencies are within valid range
low_freq = max(low_freq, 1);
high_freq = min(high_freq, fs/2 - 1);

% Design Butterworth bandpass filter
filter_order = 4;
[b, a] = butter(filter_order, [low_freq, high_freq]/(fs/2), 'bandpass');

% Alternative: Use designfilt for more modern approach
try
    bp_filter = designfilt('bandpassiir', ...
        'FilterOrder', filter_order, ...
        'HalfPowerFrequency1', low_freq, ...
        'HalfPowerFrequency2', high_freq, ...
        'SampleRate', fs);
    
    % Apply filter
    filtered_signal = filtfilt(bp_filter, signal);
    
    subplot(2,2,2);
    freqz(bp_filter, 1024, fs);
    title('Optimal Bandpass Filter Response');
    
catch
    % Use traditional filter design
    filtered_signal = filtfilt(b, a, signal);
    
    subplot(2,2,2);
    freqz(b, a, 1024, fs);
    title('Optimal Bandpass Filter Response');
end

%% Compute Envelope of Filtered Signal
envelope = abs(hilbert(filtered_signal));

% Plot time domain signals
subplot(2,2,3);
t = (0:length(signal)-1) / fs;
plot(t, signal);
xlabel('Time (s)');
ylabel('Amplitude');
title('Original Signal');
grid on;

subplot(2,2,4);
plot(t, envelope);
xlabel('Time (s)');
ylabel('Amplitude');
title('Envelope of Filtered Signal');
grid on;

%% Spectral Kurtosis Analysis
% Compute spectral kurtosis at optimal frequency
window_length = 2048;
overlap = window_length / 2;
nfft = 2048;

[psd, f_psd] = pwelch(signal, window_length, overlap, nfft, fs);

% Find spectral kurtosis around optimal frequency
freq_range = [low_freq, high_freq];
freq_idx = find(f_psd >= freq_range(1) & f_psd <= freq_range(2));
optimal_psd = mean(psd(freq_idx));

%% Display Results
fprintf('\nKurtogram Analysis Results:\n');
fprintf('Optimal Center Frequency: %.1f Hz\n', optimal_center_freq);
fprintf('Optimal Bandwidth: %.1f Hz\n', optimal_bandwidth);
fprintf('Filter Range: %.1f - %.1f Hz\n', low_freq, high_freq);
fprintf('Maximum Kurtosis: %.4f\n', max(kurt_map(:)));
fprintf('PSD at Optimal Frequency: %.2e\n', optimal_psd);

%% Save Results
kurtogram_results.kurtogram_map = kurt_map;
kurtogram_results.frequency_centers = f_centers;
kurtogram_results.bandwidths = bw;
kurtogram_results.optimal_center_freq = optimal_center_freq;
kurtogram_results.optimal_bandwidth = optimal_bandwidth;
kurtogram_results.filter_coefficients = [b; a];
kurtogram_results.filtered_signal = filtered_signal;
kurtogram_results.envelope = envelope;

save('../results/classical_approach/kurtogram_results.mat', 'kurtogram_results');

%% Helper Function for Manual Kurtogram
function [kurt_map, f_centers, bw, opt_center, opt_bw] = compute_kurtogram_manual(signal, fs)
    % Manual kurtogram computation
    
    % Parameters
    num_levels = 8;
    num_centers = 64;
    
    % Frequency range
    f_max = fs/2;
    f_centers = linspace(f_max/num_centers, f_max, num_centers);
    
    % Initialize kurtogram
    kurt_map = zeros(num_levels, num_centers);
    bw = zeros(num_levels, 1);
    
    % Compute kurtosis for different filter configurations
    for level = 1:num_levels
        current_bw = f_max / (2^level);
        bw(level) = current_bw;
        
        for center_idx = 1:num_centers
            center_freq = f_centers(center_idx);
            
            % Design bandpass filter
            low_f = max(center_freq - current_bw/2, 1);
            high_f = min(center_freq + current_bw/2, f_max - 1);
            
            if high_f > low_f
                [b, a] = butter(4, [low_f, high_f]/(fs/2), 'bandpass');
                
                % Filter signal and compute envelope
                try
                    filtered = filtfilt(b, a, signal);
                    envelope = abs(hilbert(filtered));
                    
                    % Compute kurtosis
                    kurt_map(level, center_idx) = kurtosis(envelope);
                catch
                    kurt_map(level, center_idx) = 0;
                end
            end
        end
    end
    
    % Find optimal parameters
    [max_kurt, max_idx] = max(kurt_map(:));
    [level_idx, center_idx] = ind2sub(size(kurt_map), max_idx);
    
    opt_center = f_centers(center_idx);
    opt_bw = bw(level_idx);
end