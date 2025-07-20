# Rolling Element Bearing Fault Diagnosis

This repository implements bearing fault diagnosis using both classical signal processing and deep learning approaches based on MathWorks tutorials.

## Project Structure

```
bearing_fault_diagnosis/
├── data/                           # Raw and processed datasets
├── scripts/                        # Implementation scripts
│   ├── 01_data_preprocessing/      # Data loading and preparation
│   ├── 02_signal_processing/       # Signal analysis and filtering
│   ├── 03_feature_extraction/      # Feature calculation
│   ├── 04_classical_ml/           # Traditional ML approaches
│   └── 05_deep_learning/          # Neural network implementations
├── functions/                      # Reusable MATLAB functions
├── results/                        # Output results and plots
│   ├── classical_approach/        # Signal processing results
│   └── deep_learning_approach/    # Deep learning results
└── docs/                          # Documentation
```

## Implementation Order

### Phase 1: Classical Signal Processing Approach
1. **Data Preprocessing** (`01_data_preprocessing/`)
   - Load MFPT dataset
   - Extract bearing parameters (BPFO, BPFI, FTF, BSF)
   
2. **Signal Processing** (`02_signal_processing/`)
   - Envelope spectrum analysis
   - Kurtogram implementation
   - Bandpass filtering

3. **Feature Extraction** (`03_feature_extraction/`)
   - Calculate envelope spectrum amplitudes
   - Compute BPFI/BPFO amplitude ratios
   - Extract kurtosis features

4. **Classification** (`04_classical_ml/`)
   - Rule-based classifier implementation
   - Threshold-based fault detection

### Phase 2: Deep Learning Approach
1. **Data Preprocessing** (`01_data_preprocessing/`)
   - Convert 1D signals to 2D scalograms
   - Wavelet transform implementation
   - Image resize to 227x227x3

2. **Deep Learning** (`05_deep_learning/`)
   - SqueezeNet transfer learning
   - Training configuration
   - Model evaluation

## Getting Started

1. Run scripts in numerical order within each phase
2. Classical approach scripts: `01_` → `02_` → `03_` → `04_`
3. Deep learning scripts: `01_` → `05_`

## Dependencies
- MATLAB Predictive Maintenance Toolbox
- Deep Learning Toolbox
- Signal Processing Toolbox
- Wavelet Toolbox