%% Prepare Scalogram Data for Deep Learning
% Convert 1D vibration signals to 2D scalogram images for CNN training

%% Clear workspace
clear; clc; close all;

%% Parameters
fs = 97656;  % Sampling frequency (Hz)
target_size = [227, 227, 3];  % SqueezeNet input size
segment_length = 8192;  % Signal segment length

%% Create output directories
scalogram_dir = '../data/scalograms/';
if ~exist(scalogram_dir, 'dir')
    mkdir(scalogram_dir);
    mkdir([scalogram_dir 'normal/']);
    mkdir([scalogram_dir 'inner_fault/']);
    mkdir([scalogram_dir 'outer_fault/']);
end

%% Load raw vibration data
data_path = '../data/mfpt_bearing_data/';
if ~exist(data_path, 'dir')
    error('Raw data not found. Run load_bearing_data.m first.');
end

% Create file ensemble
ensemble = fileEnsembleDatastore(data_path, '.mat');

%% Process each data file
file_count = 0;
while hasdata(ensemble)
    file_count = file_count + 1;
    
    % Read data file
    data = read(ensemble);
    
    % Extract vibration signal (adjust field name as needed)
    if isfield(data, 'vibration')
        signal = data.vibration;
    elseif isfield(data, 'acceleration')
        signal = data.acceleration;
    else
        % Find first numeric field
        fields = fieldnames(data);
        signal = data.(fields{1});
    end
    
    % Determine fault type from filename or data structure
    fault_type = determine_fault_type(data, file_count);
    
    % Segment signal
    num_segments = floor(length(signal) / segment_length);
    
    for seg = 1:num_segments
        start_idx = (seg-1) * segment_length + 1;
        end_idx = seg * segment_length;
        segment = signal(start_idx:end_idx);
        
        % Generate scalogram using wavelet transform
        scalogram = generate_scalogram(segment, fs);
        
        % Resize to target size
        scalogram_resized = imresize(scalogram, target_size(1:2));
        
        % Convert to RGB if needed
        if size(scalogram_resized, 3) == 1
            scalogram_rgb = repmat(scalogram_resized, [1, 1, 3]);
        else
            scalogram_rgb = scalogram_resized;
        end
        
        % Save scalogram image
        filename = sprintf('file%d_seg%d.png', file_count, seg);
        save_path = fullfile(scalogram_dir, fault_type, filename);
        imwrite(scalogram_rgb, save_path);
    end
    
    fprintf('Processed file %d: %s\n', file_count, fault_type);
end

fprintf('\nScalogram generation complete!\n');
fprintf('Images saved in: %s\n', scalogram_dir);

%% Helper Functions
function fault_type = determine_fault_type(data, file_idx)
    % Determine fault type based on data structure or file pattern
    % This is a placeholder - adjust based on your dataset structure
    
    if isfield(data, 'fault_type')
        fault_type = data.fault_type;
    elseif isfield(data, 'label')
        switch data.label
            case 0
                fault_type = 'normal';
            case 1
                fault_type = 'inner_fault';
            case 2
                fault_type = 'outer_fault';
            otherwise
                fault_type = 'normal';
        end
    else
        % Default pattern based on file index
        if file_idx <= 3
            fault_type = 'normal';
        elseif file_idx <= 6
            fault_type = 'inner_fault';
        else
            fault_type = 'outer_fault';
        end
    end
end

function scalogram = generate_scalogram(signal, fs)
    % Generate scalogram using continuous wavelet transform
    
    % Define wavelet and frequency range
    wavelet_name = 'cmor3-3';
    frequency_limits = [1, fs/4];
    
    % Compute CWT
    [wt, f] = cwt(signal, wavelet_name, fs, 'FrequencyLimits', frequency_limits);
    
    % Convert to scalogram (log magnitude)
    scalogram = log(abs(wt) + eps);
    
    % Normalize to [0, 1]
    scalogram = (scalogram - min(scalogram(:))) / ...
                (max(scalogram(:)) - min(scalogram(:)));
end