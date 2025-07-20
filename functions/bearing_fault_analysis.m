function results = bearing_fault_analysis(signal, fs, bearing_params, method)
%BEARING_FAULT_ANALYSIS Comprehensive bearing fault analysis function
%
% Inputs:
%   signal - Vibration signal (vector)
%   fs - Sampling frequency (Hz)
%   bearing_params - Structure with BPFI, BPFO, FTF, BSF frequencies
%   method - Analysis method: 'envelope', 'kurtogram', 'features', or 'all'
%
% Outputs:
%   results - Structure containing analysis results

%% Input validation
if nargin < 4
    method = 'all';
end

if ~isstruct(bearing_params)
    error('bearing_params must be a structure with BPFI, BPFO, FTF, BSF fields');
end

required_fields = {'BPFI', 'BPFO', 'FTF', 'BSF'};
for i = 1:length(required_fields)
    if ~isfield(bearing_params, required_fields{i})
        error('bearing_params missing field: %s', required_fields{i});
    end
end

%% Initialize results structure
results = struct();
results.method = method;
results.fs = fs;
results.signal_length = length(signal);
results.bearing_params = bearing_params;

%% Envelope Spectrum Analysis
if strcmp(method, 'envelope') || strcmp(method, 'all')
    fprintf('Computing envelope spectrum...\n');
    
    [env_spec, f_env] = compute_envelope_spectrum(signal, fs);
    
    % Extract amplitudes at critical frequencies
    freq_tolerance = 5;
    
    results.envelope.spectrum = env_spec;
    results.envelope.frequencies = f_env;
    results.envelope.bpfi_amplitude = extract_amplitude_at_freq(env_spec, f_env, bearing_params.BPFI, freq_tolerance);
    results.envelope.bpfo_amplitude = extract_amplitude_at_freq(env_spec, f_env, bearing_params.BPFO, freq_tolerance);
    results.envelope.ftf_amplitude = extract_amplitude_at_freq(env_spec, f_env, bearing_params.FTF, freq_tolerance);
    results.envelope.bsf_amplitude = extract_amplitude_at_freq(env_spec, f_env, bearing_params.BSF, freq_tolerance);
    
    % Compute diagnostic ratios
    results.envelope.log_ratio_bpfi_bpfo = log10(results.envelope.bpfi_amplitude / (results.envelope.bpfo_amplitude + eps));
    results.envelope.ratio_bpfi_ftf = results.envelope.bpfi_amplitude / (results.envelope.ftf_amplitude + eps);
    results.envelope.ratio_bpfo_ftf = results.envelope.bpfo_amplitude / (results.envelope.ftf_amplitude + eps);
end

%% Kurtogram Analysis
if strcmp(method, 'kurtogram') || strcmp(method, 'all')
    fprintf('Computing kurtogram...\n');
    
    try
        [kurt_map, f_centers, bw] = kurtogram(signal, fs);
        
        % Find optimal filter parameters
        [max_kurt, max_idx] = max(kurt_map(:));
        [level_idx, freq_idx] = ind2sub(size(kurt_map), max_idx);
        
        results.kurtogram.map = kurt_map;
        results.kurtogram.frequencies = f_centers;
        results.kurtogram.bandwidths = bw;
        results.kurtogram.optimal_center_freq = f_centers(freq_idx);
        results.kurtogram.optimal_bandwidth = bw(level_idx);
        results.kurtogram.max_kurtosis = max_kurt;
        
    catch
        fprintf('Kurtogram function not available. Using manual computation.\n');
        [kurt_result] = compute_kurtogram_manual(signal, fs);
        results.kurtogram = kurt_result;
    end
end

%% Feature Extraction
if strcmp(method, 'features') || strcmp(method, 'all')
    fprintf('Extracting features...\n');
    
    % Time domain features
    results.features.rms = rms(signal);
    results.features.kurtosis = kurtosis(signal);
    results.features.skewness = skewness(signal);
    results.features.crest_factor = max(abs(signal)) / rms(signal);
    results.features.peak_amplitude = max(abs(signal));
    results.features.mean_absolute = mean(abs(signal));
    results.features.variance = var(signal);
    
    % Frequency domain features
    [psd, f_psd] = pwelch(signal, 2048, 1024, 2048, fs);
    
    results.features.spectral_centroid = sum(f_psd .* psd) / sum(psd);
    results.features.spectral_variance = sum((f_psd - results.features.spectral_centroid).^2 .* psd) / sum(psd);
    results.features.spectral_skewness = sum(((f_psd - results.features.spectral_centroid).^3) .* psd) / ...
                                         (sum(psd) * results.features.spectral_variance^(3/2));
    results.features.spectral_kurtosis = sum(((f_psd - results.features.spectral_centroid).^4) .* psd) / ...
                                         (sum(psd) * results.features.spectral_variance^2);
    
    % Spectral rolloff (95% energy)
    cumulative_energy = cumsum(psd) / sum(psd);
    rolloff_idx = find(cumulative_energy >= 0.95, 1);
    if ~isempty(rolloff_idx)
        results.features.spectral_rolloff = f_psd(rolloff_idx);
    else
        results.features.spectral_rolloff = f_psd(end);
    end
    
    % Spectral flux
    results.features.spectral_flux = sum(diff(psd).^2);
    
    % Envelope-based features (if envelope analysis was performed)
    if isfield(results, 'envelope')
        results.features.envelope_rms = rms(abs(hilbert(signal)));
        results.features.envelope_peak = max(abs(hilbert(signal)));
    end
end

%% Rule-based Classification (if envelope analysis available)
if isfield(results, 'envelope')
    log_ratio = results.envelope.log_ratio_bpfi_bpfo;
    
    if log_ratio <= -1.5
        results.classification.predicted_fault = 'Outer Race Fault';
        results.classification.fault_code = 2;
    elseif log_ratio > -1.5 && log_ratio <= 0.5
        results.classification.predicted_fault = 'Normal';
        results.classification.fault_code = 0;
    else
        results.classification.predicted_fault = 'Inner Race Fault';
        results.classification.fault_code = 1;
    end
    
    results.classification.confidence = abs(log_ratio);  % Simple confidence measure
end

fprintf('Analysis complete!\n');

end

%% Helper Functions
function [env_spec, f] = compute_envelope_spectrum(signal, fs)
    % High-pass filter to remove low frequency content
    [b, a] = butter(4, 1000/(fs/2), 'high');
    signal_filtered = filtfilt(b, a, signal);
    
    % Compute envelope using Hilbert transform
    envelope = abs(hilbert(signal_filtered));
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
    env_spec = P1;
end

function amplitude = extract_amplitude_at_freq(spectrum, frequencies, target_freq, tolerance)
    % Extract amplitude around target frequency
    freq_range = [target_freq - tolerance, target_freq + tolerance];
    freq_idx = find(frequencies >= freq_range(1) & frequencies <= freq_range(2));
    
    if ~isempty(freq_idx)
        amplitude = max(spectrum(freq_idx));
    else
        amplitude = 0;
    end
end

function kurt_result = compute_kurtogram_manual(signal, fs)
    % Manual kurtogram computation
    
    num_levels = 6;
    num_centers = 32;
    
    f_max = fs/2;
    f_centers = linspace(f_max/num_centers, f_max, num_centers);
    
    kurt_map = zeros(num_levels, num_centers);
    bw = zeros(num_levels, 1);
    
    for level = 1:num_levels
        current_bw = f_max / (2^level);
        bw(level) = current_bw;
        
        for center_idx = 1:num_centers
            center_freq = f_centers(center_idx);
            
            low_f = max(center_freq - current_bw/2, 1);
            high_f = min(center_freq + current_bw/2, f_max - 1);
            
            if high_f > low_f
                [b, a] = butter(4, [low_f, high_f]/(fs/2), 'bandpass');
                
                try
                    filtered = filtfilt(b, a, signal);
                    envelope = abs(hilbert(filtered));
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
    
    kurt_result.map = kurt_map;
    kurt_result.frequencies = f_centers;
    kurt_result.bandwidths = bw;
    kurt_result.optimal_center_freq = f_centers(center_idx);
    kurt_result.optimal_bandwidth = bw(level_idx);
    kurt_result.max_kurtosis = max_kurt;
end