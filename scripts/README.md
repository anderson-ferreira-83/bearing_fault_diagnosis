# Scripts de Implementação

Este diretório contém todos os scripts organizados em fases sequenciais para implementar o diagnóstico de falhas em rolamentos.

## Estrutura dos Scripts

### 📊 01_data_preprocessing/
**Objetivo**: Carregar e preparar os dados para análise
- `load_bearing_data.m` - Carrega conjunto de dados MFPT e define parâmetros do rolamento
- `prepare_scalogram_data.m` - Converte sinais 1D em escalogramas 2D para deep learning

### 🔊 02_signal_processing/
**Objetivo**: Analisar sinais de vibração usando técnicas clássicas
- `envelope_spectrum_analysis.m` - Análise do espectro envoltório para detecção de falhas
- `kurtogram_analysis.m` - Análise de kurtograma para otimização de filtros

### 🔍 03_feature_extraction/
**Objetivo**: Extrair características relevantes dos sinais processados
- `extract_fault_features.m` - Extrai características nos domínios tempo e frequência

### 🧠 04_classical_ml/
**Objetivo**: Classificar falhas usando abordagem tradicional
- `rule_based_classifier.m` - Implementa classificador baseado em regras e limiares

### 🤖 05_deep_learning/
**Objetivo**: Classificar falhas usando redes neurais profundas
- `train_squeezenet_classifier.m` - Treina SqueezeNet para classificação de escalogramas

## Ordem de Execução

### Para Abordagem Clássica:
```
01_data_preprocessing/load_bearing_data.m
↓
02_signal_processing/envelope_spectrum_analysis.m
↓
02_signal_processing/kurtogram_analysis.m
↓
03_feature_extraction/extract_fault_features.m
↓
04_classical_ml/rule_based_classifier.m
```

### Para Abordagem de Deep Learning:
```
01_data_preprocessing/load_bearing_data.m
↓
01_data_preprocessing/prepare_scalogram_data.m
↓
05_deep_learning/train_squeezenet_classifier.m
```

## Tipos de Falhas Detectadas

- **Normal**: Rolamento sem falhas
- **Falha na Pista Interna (Inner Race)**: Defeito na superfície interna do rolamento
- **Falha na Pista Externa (Outer Race)**: Defeito na superfície externa do rolamento

## Parâmetros Críticos do Rolamento

Os seguintes parâmetros são essenciais para a análise:
- **BPFI** (Ball Pass Frequency Inner): 297.0 Hz
- **BPFO** (Ball Pass Frequency Outer): 236.4 Hz
- **FTF** (Fundamental Train Frequency): 15.9 Hz
- **BSF** (Ball Spin Frequency): 139.1 Hz

Estes valores são específicos para o conjunto de dados MFPT e devem ser ajustados para outros tipos de rolamentos.