%% Load Bearing Data - MFPT Dataset
% This script loads the Machinery Failure Prevention Technology (MFPT) 
% Challenge Dataset for bearing fault diagnosis

%% Clear workspace
clear; clc; close all;

%% Dataset Parameters
% Define bearing critical frequencies
bearing_params.BPFO = 236.4;  % Ball Pass Frequency Outer race
bearing_params.BPFI = 297.0;  % Ball Pass Frequency Inner race  
bearing_params.FTF = 15.9;    % Fundamental Train Frequency
bearing_params.BSF = 139.1;   % Ball Spin Frequency

%% Load Data
% Create file ensemble datastore for bearing data
% Note: Update the path to your actual MFPT dataset location
data_path = '../data/mfpt_bearing_data/';

if exist(data_path, 'dir')
    % Create ensemble datastore
    ensemble = fileEnsembleDatastore(data_path, '.mat');
    
    % Read first few files to inspect structure
    data_sample = read(ensemble);
    
    fprintf('Dataset loaded successfully!\n');
    fprintf('Number of files: %d\n', numpartitions(ensemble));
    fprintf('Sample data structure:\n');
    disp(data_sample);
    
    % Save bearing parameters for other scripts
    save('../data/bearing_parameters.mat', 'bearing_params');
    
else
    warning('MFPT dataset not found. Please download and place in %s', data_path);
    fprintf('Download from: https://www.mfpt.org/fault-data-sets/\n');
end

%% Display bearing parameters
fprintf('\nBearing Critical Frequencies (Hz):\n');
fprintf('BPFO (Outer Race): %.1f Hz\n', bearing_params.BPFO);
fprintf('BPFI (Inner Race): %.1f Hz\n', bearing_params.BPFI);
fprintf('FTF (Cage): %.1f Hz\n', bearing_params.FTF);
fprintf('BSF (Ball Spin): %.1f Hz\n', bearing_params.BSF);