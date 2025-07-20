# Guia de Implementação do Diagnóstico de Falhas em Rolamentos

## Visão Geral
Este repositório implementa duas abordagens complementares para diagnóstico de falhas em rolamentos de elementos rolantes baseadas nos tutoriais da MathWorks:

1. **Abordagem de Processamento Clássico de Sinais**: Utiliza análise do espectro envoltório e classificação baseada em regras
2. **Abordagem de Aprendizado Profundo**: Utiliza aprendizado por transferência com SqueezeNet em imagens de escalogramas

## Fluxo de Implementação

### Fase 1: Abordagem de Processamento Clássico de Sinais

#### Passo 1: Pré-processamento de Dados (`01_data_preprocessing/load_bearing_data.m`)
- Carregar conjunto de dados MFPT (Machinery Failure Prevention Technology)
- Definir frequências críticas do rolamento:
  - BPFI (Ball Pass Frequency Inner): 297.0 Hz
  - BPFO (Ball Pass Frequency Outer): 236.4 Hz  
  - FTF (Fundamental Train Frequency): 15.9 Hz
  - BSF (Ball Spin Frequency): 139.1 Hz
- Criar armazenamento de dados em conjunto para processamento em lote

#### Passo 2: Processamento de Sinais (`02_signal_processing/`)

**Análise do Espectro Envoltório** (`envelope_spectrum_analysis.m`):
- Aplicar filtragem passa-alta (>1000 Hz) para remover ruído de baixa frequência
- Computar envoltório usando transformada de Hilbert
- Extrair amplitudes nas frequências críticas (BPFI, BPFO, FTF, BSF)
- Calcular razão logarítmica: log₁₀(amplitude_BPFI / amplitude_BPFO)

**Análise de Kurtograma** (`kurtogram_analysis.m`):
- Computar kurtograma para encontrar parâmetros ótimos do filtro passa-banda
- Identificar banda de frequência com máxima curtose para análise do envoltório
- Projetar filtro passa-banda ótimo para condicionamento do sinal

#### Passo 3: Extração de Características (`03_feature_extraction/extract_fault_features.m`)
Extrair conjunto abrangente de características:
- **Características do envoltório**: Amplitudes e razões BPFI, BPFO, FTF, BSF
- **Domínio do tempo**: RMS, curtose, assimetria, fator de crista, amplitude de pico
- **Domínio da frequência**: Centroide espectral, rolloff, fluxo, variância

#### Passo 4: Classificação (`04_classical_ml/rule_based_classifier.m`)
Aplicar classificador baseado em regras usando limiares de razão logarítmica:
- Razão log ≤ -1.5 → Falha na Pista Externa
- -1.5 < Razão log ≤ 0.5 → Normal
- Razão log > 0.5 → Falha na Pista Interna

### Fase 2: Abordagem de Aprendizado Profundo

#### Passo 1: Pré-processamento de Dados (`01_data_preprocessing/prepare_scalogram_data.m`)
- Converter sinais de vibração 1D para imagens de escalograma 2D usando Transformada Wavelet Contínua (CWT)
- Segmentar sinais em janelas de comprimento fixo (8192 amostras)
- Gerar escalogramas usando wavelet de Morlet ('cmor3-3')
- Redimensionar imagens para 227×227×3 pixels para compatibilidade com SqueezeNet
- Organizar imagens por tipo de falha: normal/, inner_fault/, outer_fault/

#### Passo 2: Aprendizado Profundo (`05_deep_learning/train_squeezenet_classifier.m`)
- Carregar modelo SqueezeNet pré-treinado
- Substituir camadas finais para classificação de falhas em rolamentos (3 classes)
- Configurar parâmetros de aprendizado por transferência:
  - Taxa de aprendizado: 1e-4
  - Épocas: 4
  - Tamanho do mini-lote: 20
  - Divisão treino/validação: 80/20
- Treinar rede e avaliar desempenho

## Funções Principais

### `bearing_fault_analysis.m`
Função de análise abrangente suportando múltiplos métodos:
```matlab
results = bearing_fault_analysis(signal, fs, bearing_params, method)
```
- **Entradas**: Sinal, frequência de amostragem, parâmetros do rolamento, método de análise
- **Métodos**: 'envelope', 'kurtogram', 'features', 'all'
- **Saídas**: Resultados estruturados com resultados de análise e classificações

## Desempenho Esperado

### Abordagem Clássica
- **Precisão**: ~85-95% (depende da qualidade dos dados e níveis de ruído)
- **Vantagens**: Computação rápida, resultados interpretáveis, não requer treinamento
- **Melhor para**: Sinais limpos, parâmetros conhecidos do rolamento, aplicações em tempo real

### Abordagem de Aprendizado Profundo  
- **Precisão**: ~95-98% (reportado no tutorial da MathWorks)
- **Vantagens**: Robusto ao ruído, aprendizado automático de características, escalável
- **Melhor para**: Grandes conjuntos de dados, sinais ruidosos, padrões complexos de falhas

## Instruções de Uso

### Início Rápido
1. Coloque o conjunto de dados MFPT em `data/mfpt_bearing_data/`
2. Execute os scripts em ordem numérica:
   - Clássico: `01_` → `02_` → `03_` → `04_`
   - Aprendizado Profundo: `01_` → `05_`

### Análise Personalizada
```matlab
% Carregar seus dados
load('your_bearing_data.mat');

% Definir parâmetros do rolamento
bearing_params.BPFI = 297.0;
bearing_params.BPFO = 236.4;
bearing_params.FTF = 15.9;
bearing_params.BSF = 139.1;

% Executar análise
results = bearing_fault_analysis(signal, fs, bearing_params, 'all');

% Verificar classificação
fprintf('Falha prevista: %s\n', results.classification.predicted_fault);
```

## Dependências

### Toolboxes MATLAB Necessários
- **Signal Processing Toolbox**: Para filtragem, FFT, análise espectral
- **Predictive Maintenance Toolbox**: Para funções `envspectrum()`, `kurtogram()`
- **Deep Learning Toolbox**: Para treinamento e avaliação de redes neurais
- **Wavelet Toolbox**: Para geração de escalogramas usando CWT

### Toolboxes Opcionais
- **Computer Vision Toolbox**: Para pré-processamento avançado de imagens
- **Parallel Computing Toolbox**: Para treinamento mais rápido em GPU

## Solução de Problemas

### Problemas Comuns

1. **Funções envspectrum/kurtogram ausentes**
   - Solução: Use implementações manuais fornecidas nos scripts
   - Instale o Predictive Maintenance Toolbox para funcionalidade completa

2. **Modelo de aprendizado profundo não carrega**
   - Solução: Instale o Deep Learning Toolbox Model para SqueezeNet
   - Alternativa: Use arquitetura CNN personalizada

3. **Problemas de memória com grandes conjuntos de dados**
   - Solução: Processe dados em lotes usando `fileEnsembleDatastore`
   - Reduza a resolução das imagens para escalogramas

4. **Baixa precisão de classificação**
   - Verifique a precisão dos parâmetros do rolamento (valores BPFI, BPFO)
   - Verifique a frequência de amostragem e qualidade dos dados
   - Ajuste a tolerância de frequência na extração de características

## Interpretação dos Resultados

### Saídas da Abordagem Clássica
- **Razão logarítmica**: Característica diagnóstica primária para classificação de falhas
- **Espectro envoltório**: Identificação visual das frequências de falha
- **Matriz de características**: Entrada para algoritmos avançados de ML

### Saídas do Aprendizado Profundo
- **Matriz de confusão**: Desempenho de classificação por tipo de falha
- **Grad-CAM**: Explicação visual das decisões da rede
- **Curvas de treinamento**: Progresso do aprendizado e convergência

## Extensões e Personalização

### Adicionando Novos Tipos de Falhas
1. Modificar limiares de classificação na abordagem baseada em regras
2. Adicionar novas categorias de pastas para abordagem de aprendizado profundo
3. Atualizar cálculos de parâmetros do rolamento para diferentes tipos de rolamentos

### Abordagens Alternativas
- **Análise Espectral**: Densidade espectral de potência, análise de cepstrum
- **Tempo-Frequência**: Transformada de Fourier de tempo curto, análise de espectrograma
- **Aprendizado de Máquina**: SVM, Random Forest, métodos de ensemble
- **AL Avançado**: LSTM para dados sequenciais, autoencoders para detecção de anomalias

## Referências
- [MathWorks: Diagnóstico de Falhas em Rolamentos de Elementos Rolantes](https://www.mathworks.com/help/predmaint/ug/Rolling-Element-Bearing-Fault-Diagnosis.html)
- [MathWorks: Aprendizado Profundo para Diagnóstico de Falhas em Rolamentos](https://www.mathworks.com/help/predmaint/ug/rolling-element-bearing-fault-diagnosis-using-deep-learning.html)
- Conjunto de Dados MFPT Challenge: https://www.mfpt.org/fault-data-sets/