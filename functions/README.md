# Funções Reutilizáveis

Este diretório contém funções MATLAB modulares que podem ser reutilizadas em diferentes análises de diagnóstico de falhas em rolamentos.

## Função Principal

### `bearing_fault_analysis.m`

Função abrangente que integra todas as técnicas de análise disponíveis no projeto.

#### Sintaxe
```matlab
results = bearing_fault_analysis(signal, fs, bearing_params, method)
```

#### Parâmetros de Entrada
- **signal**: Sinal de vibração 1D (vetor)
- **fs**: Frequência de amostragem em Hz
- **bearing_params**: Estrutura com parâmetros críticos do rolamento
  ```matlab
  bearing_params.BPFI = 297.0;  % Ball Pass Frequency Inner
  bearing_params.BPFO = 236.4;  % Ball Pass Frequency Outer  
  bearing_params.FTF = 15.9;    % Fundamental Train Frequency
  bearing_params.BSF = 139.1;   % Ball Spin Frequency
  ```
- **method**: Método de análise ('envelope', 'kurtogram', 'features', 'all')

#### Métodos Disponíveis

##### 'envelope'
- Análise do espectro envoltório
- Extração de amplitudes nas frequências críticas
- Cálculo da razão logarítmica BPFI/BPFO
- Classificação baseada em limiar

##### 'kurtogram'
- Análise de kurtograma
- Identificação da banda de frequência ótima
- Design de filtro passa-banda otimizado
- Análise do sinal filtrado

##### 'features'
- Extração abrangente de características
- Características do domínio do tempo (RMS, curtose, etc.)
- Características do domínio da frequência
- Matriz de características para ML avançado

##### 'all'
- Executa todos os métodos acima
- Fornece análise completa e comparativa
- Recomendado para análise exploratória

#### Estrutura de Saída

```matlab
results = struct(
    'envelope_analysis', struct(...),
    'kurtogram_analysis', struct(...),
    'feature_extraction', struct(...),
    'classification', struct(...)
);
```

#### Exemplo de Uso

```matlab
% Carregar dados
load('bearing_vibration_data.mat');

% Definir parâmetros do rolamento
bearing_params.BPFI = 297.0;
bearing_params.BPFO = 236.4;
bearing_params.FTF = 15.9;
bearing_params.BSF = 139.1;

% Executar análise completa
results = bearing_fault_analysis(signal, 25600, bearing_params, 'all');

% Verificar classificação
fprintf('Estado do rolamento: %s\n', results.classification.predicted_fault);
fprintf('Razão log BPFI/BPFO: %.3f\n', results.envelope_analysis.log_ratio);
```

## Funções Auxiliares

### Processamento de Sinais
- **highpass_filter()**: Filtragem passa-alta para remoção de ruído
- **envelope_computation()**: Cálculo do envoltório usando transformada de Hilbert
- **frequency_extraction()**: Extração de amplitudes em frequências específicas

### Análise de Características
- **time_domain_features()**: Características no domínio do tempo
- **frequency_domain_features()**: Características no domínio da frequência
- **statistical_features()**: Medidas estatísticas do sinal

### Visualização
- **plot_envelope_spectrum()**: Plotagem do espectro envoltório
- **plot_kurtogram()**: Visualização do kurtograma
- **plot_time_frequency()**: Análise tempo-frequência

## Requisitos

- MATLAB R2019b ou superior
- Signal Processing Toolbox
- Predictive Maintenance Toolbox (recomendado)

## Notas de Implementação

1. **Robustez**: Todas as funções incluem verificação de entrada e tratamento de erros
2. **Eficiência**: Algoritmos otimizados para processamento em tempo real
3. **Modularidade**: Cada função pode ser usada independentemente
4. **Documentação**: Cada função inclui help completo accessível via `help nome_funcao`

## Personalização

Para adaptar as funções a diferentes tipos de rolamentos:

1. **Atualize os parâmetros críticos** nas estruturas `bearing_params`
2. **Ajuste os limiares de classificação** na lógica de decisão
3. **Modifique as frequências de filtro** conforme necessário
4. **Adicione novos métodos de análise** seguindo a estrutura modular existente