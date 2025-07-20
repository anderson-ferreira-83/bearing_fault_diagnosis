%% Envelope Spectrum Analysis for Bearing Fault Detection
% Compute envelope spectrum to identify bearing fault frequencies

%% Clear workspace
clear; clc; close all;

%% Load data and parameters
load('../data/bearing_parameters.mat', 'bearing_params');

% Load a sample vibration signal
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

%% Envelope Spectrum Computation
% Method 1: Using envspectrum function (if available)
try
    [env_spec, f_env] = envspectrum(signal, fs);
    
    % Plot envelope spectrum
    figure('Name', 'Envelope Spectrum Analysis');
    subplot(2,1,1);
    plot(f_env, env_spec);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    title('Envelope Spectrum');
    grid on;
    
    % Highlight bearing fault frequencies
    hold on;
    xline(bearing_params.BPFI, 'r--', 'BPFI', 'LineWidth', 2);
    xline(bearing_params.BPFO, 'g--', 'BPFO', 'LineWidth', 2);
    xline(bearing_params.FTF, 'b--', 'FTF', 'LineWidth', 2);
    xline(bearing_params.BSF, 'm--', 'BSF', 'LineWidth', 2);
    legend('Envelope Spectrum', 'BPFI', 'BPFO', 'FTF', 'BSF');
    
catch
    % Method 2: Manual envelope spectrum computation
    fprintf('envspectrum function not available. Using manual computation.\n');
    [env_spec, f_env] = compute_envelope_spectrum_manual(signal, fs);
    
    % Plot results
    figure('Name', 'Manual Envelope Spectrum Analysis');
    subplot(2,1,1);
    plot(f_env, env_spec);
    xlabel('Frequency (Hz)');
    ylabel('Magnitude');
    title('Envelope Spectrum (Manual)');
    grid on;
    
    % Highlight bearing fault frequencies
    hold on;
    xline(bearing_params.BPFI, 'r--', 'BPFI', 'LineWidth', 2);
    xline(bearing_params.BPFO, 'g--', 'BPFO', 'LineWidth', 2);
    xline(bearing_params.FTF, 'b--', 'FTF', 'LineWidth', 2);
    xline(bearing_params.BSF, 'm--', 'BSF', 'LineWidth', 2);
    legend('Envelope Spectrum', 'BPFI', 'BPFO', 'FTF', 'BSF');
end

%% Extract Amplitudes at Critical Frequencies
% Find amplitudes around BPFI and BPFO
freq_tolerance = 5;  % Hz tolerance for frequency matching

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

% Compute log ratio for classification
log_ratio = log10(bpfi_amplitude / bpfo_amplitude);

%% Display Results
fprintf('\nEnvelope Spectrum Analysis Results:\n');
fprintf('BPFI Amplitude: %.4f\n', bpfi_amplitude);
fprintf('BPFO Amplitude: %.4f\n', bpfo_amplitude);
fprintf('Log Ratio (BPFI/BPFO): %.4f\n', log_ratio);

% Classification based on log ratio
if log_ratio <= -1.5
    fault_type = 'Outer Race Fault';
elseif log_ratio > -1.5 && log_ratio <= 0.5
    fault_type = 'Normal';
else
    fault_type = 'Inner Race Fault';
end

fprintf('Predicted Fault Type: %s\n', fault_type);

%% Save Results
results.envelope_spectrum = env_spec;
results.frequencies = f_env;
results.bpfi_amplitude = bpfi_amplitude;
results.bpfo_amplitude = bpfo_amplitude;
results.log_ratio = log_ratio;
results.predicted_fault = fault_type;

save('../results/classical_approach/envelope_spectrum_results.mat', 'results');

%% Helper Function for Manual Envelope Spectrum
function [env_spec, f] = compute_envelope_spectrum_manual(signal, fs)
    % Manual computation of envelope spectrum
    
    % High-pass filter to remove low frequency content
    [b, a] = butter(4, 1000/(fs/2), 'high');
    signal_filtered = filtfilt(b, a, signal);
    
    % Compute envelope using Hilbert transform
    analytic_signal = hilbert(signal_filtered);
    envelope = abs(analytic_signal);
    
    % Remove DC component
    envelope = envelope - mean(envelope);
    
    % Compute FFT of envelope
    N = length(envelope);
    Y = fft(envelope);
    
    % Single-sided spectrum
    P2 = abs(Y/N);
    P1 = P2(1:N/2+1);
    P1(2:end-1) = 2*P1(2:end-1);
    
    % Frequency vector
    f = (0:(N/2)) * fs/N;
    
    % Return envelope spectrum
    env_spec = P1;
end