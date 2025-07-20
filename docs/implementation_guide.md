# Bearing Fault Diagnosis Implementation Guide

## Overview
This repository implements two complementary approaches for rolling element bearing fault diagnosis based on MathWorks tutorials:

1. **Classical Signal Processing Approach**: Uses envelope spectrum analysis and rule-based classification
2. **Deep Learning Approach**: Uses transfer learning with SqueezeNet on scalogram images

## Implementation Workflow

### Phase 1: Classical Signal Processing Approach

#### Step 1: Data Preprocessing (`01_data_preprocessing/load_bearing_data.m`)
- Load MFPT (Machinery Failure Prevention Technology) dataset
- Define bearing critical frequencies:
  - BPFI (Ball Pass Frequency Inner): 297.0 Hz
  - BPFO (Ball Pass Frequency Outer): 236.4 Hz  
  - FTF (Fundamental Train Frequency): 15.9 Hz
  - BSF (Ball Spin Frequency): 139.1 Hz
- Create file ensemble datastore for batch processing

#### Step 2: Signal Processing (`02_signal_processing/`)

**Envelope Spectrum Analysis** (`envelope_spectrum_analysis.m`):
- Apply high-pass filtering (>1000 Hz) to remove low-frequency noise
- Compute envelope using Hilbert transform
- Extract amplitudes at critical frequencies (BPFI, BPFO, FTF, BSF)
- Calculate log ratio: log₁₀(BPFI_amplitude / BPFO_amplitude)

**Kurtogram Analysis** (`kurtogram_analysis.m`):
- Compute kurtogram to find optimal bandpass filter parameters
- Identify frequency band with maximum kurtosis for envelope analysis
- Design optimal bandpass filter for signal conditioning

#### Step 3: Feature Extraction (`03_feature_extraction/extract_fault_features.m`)
Extract comprehensive feature set:
- **Envelope features**: BPFI, BPFO, FTF, BSF amplitudes and ratios
- **Time domain**: RMS, kurtosis, skewness, crest factor, peak amplitude
- **Frequency domain**: Spectral centroid, rolloff, flux, variance

#### Step 4: Classification (`04_classical_ml/rule_based_classifier.m`)
Apply rule-based classifier using log ratio thresholds:
- Log ratio ≤ -1.5 → Outer Race Fault
- -1.5 < Log ratio ≤ 0.5 → Normal
- Log ratio > 0.5 → Inner Race Fault

### Phase 2: Deep Learning Approach

#### Step 1: Data Preprocessing (`01_data_preprocessing/prepare_scalogram_data.m`)
- Convert 1D vibration signals to 2D scalogram images using Continuous Wavelet Transform (CWT)
- Segment signals into fixed-length windows (8192 samples)
- Generate scalograms using Morlet wavelet ('cmor3-3')
- Resize images to 227×227×3 pixels for SqueezeNet compatibility
- Organize images by fault type: normal/, inner_fault/, outer_fault/

#### Step 2: Deep Learning (`05_deep_learning/train_squeezenet_classifier.m`)
- Load pre-trained SqueezeNet model
- Replace final layers for bearing fault classification (3 classes)
- Configure transfer learning parameters:
  - Learning rate: 1e-4
  - Epochs: 4
  - Mini-batch size: 20
  - 80/20 train/validation split
- Train network and evaluate performance

## Key Functions

### `bearing_fault_analysis.m`
Comprehensive analysis function supporting multiple methods:
```matlab
results = bearing_fault_analysis(signal, fs, bearing_params, method)
```
- **Inputs**: Signal, sampling frequency, bearing parameters, analysis method
- **Methods**: 'envelope', 'kurtogram', 'features', 'all'
- **Outputs**: Structured results with analysis outcomes and classifications

## Expected Performance

### Classical Approach
- **Accuracy**: ~85-95% (depends on data quality and noise levels)
- **Advantages**: Fast computation, interpretable results, no training required
- **Best for**: Clean signals, known bearing parameters, real-time applications

### Deep Learning Approach  
- **Accuracy**: ~95-98% (reported in MathWorks tutorial)
- **Advantages**: Robust to noise, automatic feature learning, scalable
- **Best for**: Large datasets, noisy signals, complex fault patterns

## Usage Instructions

### Quick Start
1. Place MFPT dataset in `data/mfpt_bearing_data/`
2. Run scripts in numerical order:
   - Classical: `01_` → `02_` → `03_` → `04_`
   - Deep Learning: `01_` → `05_`

### Custom Analysis
```matlab
% Load your data
load('your_bearing_data.mat');

% Define bearing parameters
bearing_params.BPFI = 297.0;
bearing_params.BPFO = 236.4;
bearing_params.FTF = 15.9;
bearing_params.BSF = 139.1;

% Run analysis
results = bearing_fault_analysis(signal, fs, bearing_params, 'all');

% Check classification
fprintf('Predicted fault: %s\n', results.classification.predicted_fault);
```

## Dependencies

### Required MATLAB Toolboxes
- **Signal Processing Toolbox**: For filtering, FFT, spectral analysis
- **Predictive Maintenance Toolbox**: For `envspectrum()`, `kurtogram()` functions
- **Deep Learning Toolbox**: For neural network training and evaluation
- **Wavelet Toolbox**: For scalogram generation using CWT

### Optional Toolboxes
- **Computer Vision Toolbox**: For advanced image preprocessing
- **Parallel Computing Toolbox**: For faster training on GPU

## Troubleshooting

### Common Issues

1. **Missing envspectrum/kurtogram functions**
   - Solution: Use manual implementations provided in scripts
   - Install Predictive Maintenance Toolbox for full functionality

2. **Deep learning model not loading**
   - Solution: Install Deep Learning Toolbox Model for SqueezeNet
   - Alternative: Use custom CNN architecture

3. **Memory issues with large datasets**
   - Solution: Process data in batches using `fileEnsembleDatastore`
   - Reduce image resolution for scalograms

4. **Low classification accuracy**
   - Check bearing parameter accuracy (BPFI, BPFO values)
   - Verify sampling frequency and data quality
   - Adjust frequency tolerance in feature extraction

## Results Interpretation

### Classical Approach Outputs
- **Log ratio**: Primary diagnostic feature for fault classification
- **Envelope spectrum**: Visual identification of fault frequencies
- **Feature matrix**: Input for advanced ML algorithms

### Deep Learning Outputs
- **Confusion matrix**: Classification performance by fault type
- **Grad-CAM**: Visual explanation of network decisions
- **Training curves**: Learning progress and convergence

## Extensions and Customization

### Adding New Fault Types
1. Modify classification thresholds in rule-based approach
2. Add new folder categories for deep learning approach
3. Update bearing parameter calculations for different bearing types

### Alternative Approaches
- **Spectral Analysis**: Power spectral density, cepstrum analysis
- **Time-Frequency**: Short-time Fourier transform, spectrogram analysis
- **Machine Learning**: SVM, Random Forest, ensemble methods
- **Advanced DL**: LSTM for sequential data, autoencoders for anomaly detection

## References
- [MathWorks: Rolling Element Bearing Fault Diagnosis](https://www.mathworks.com/help/predmaint/ug/Rolling-Element-Bearing-Fault-Diagnosis.html)
- [MathWorks: Deep Learning for Bearing Fault Diagnosis](https://www.mathworks.com/help/predmaint/ug/rolling-element-bearing-fault-diagnosis-using-deep-learning.html)
- MFPT Challenge Dataset: https://www.mfpt.org/fault-data-sets/