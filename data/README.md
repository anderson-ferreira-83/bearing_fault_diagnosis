# Conjunto de Dados

Este diretório contém os dados utilizados para o diagnóstico de falhas em rolamentos.

## 🚀 Início Rápido - Extração de Dados

### 1. Executar Extração Automática
```matlab
% No MATLAB, execute:
run('scripts/00_setup/extract_data.m');
```

Este script irá:
- ✅ Extrair automaticamente o arquivo zip
- 📁 Organizar dados por tipo de falha
- 📊 Criar índice para acesso otimizado
- ✔️ Validar integridade dos dados

### 2. Verificar Estrutura Criada
Após a extração, a estrutura será:
```
data/
├── RollingElementBearingFaultDiagnosis-Data-master.zip  # Arquivo original
├── raw/                                                 # Dados extraídos
├── organized/                                          # Dados organizados
│   ├── normal/           # train_normal_baseline_*.mat, test_normal_baseline_*.mat
│   ├── inner_fault/      # train_inner_fault_*.mat, test_inner_fault_*.mat
│   └── outer_fault/      # train_outer_fault_*.mat, test_outer_fault_*.mat
└── processed/                                          # Para dados processados
```

## Fonte dos Dados

O projeto utiliza o **conjunto de dados MFPT (Machinery Failure Prevention Technology)** do repositório GitHub da MathWorks.

### Sobre o MFPT Dataset

- **Origem**: Society for Machinery Failure Prevention Technology
- **Repositório**: https://github.com/mathworks/RollingElementBearingFaultDiagnosis-Data
- **Tipo**: Dados de vibração de rolamentos com diferentes tipos de falhas
- **Formato**: Arquivos .mat (MATLAB)
- **Frequência de Amostragem**: 97,656 Hz (downsample para 25,600 Hz)
- **Total de Arquivos**: 20 arquivos .mat organizados em treino/teste

## 📋 Inventário de Dados

### Dados de Treinamento (15 arquivos)
- **Normal (Baseline)**: 2 arquivos
  - `train_normal_baseline_1.mat`
  - `train_normal_baseline_2.mat`
  
- **Falha Pista Interna**: 5 arquivos
  - `train_inner_fault_InnerRaceFault_vload_1.mat` até `vload_5.mat`
  
- **Falha Pista Externa**: 8 arquivos
  - `train_outer_fault_OuterRaceFault_1.mat`, `OuterRaceFault_2.mat`
  - `train_outer_fault_OuterRaceFault_vload_1.mat` até `vload_5.mat`

### Dados de Teste (5 arquivos)
- **Normal (Baseline)**: 1 arquivo
  - `test_normal_baseline_3.mat`
  
- **Falha Pista Interna**: 2 arquivos
  - `test_inner_fault_InnerRaceFault_vload_6.mat`
  - `test_inner_fault_InnerRaceFault_vload_7.mat`
  
- **Falha Pista Externa**: 2 arquivos
  - `test_outer_fault_OuterRaceFault_3.mat`
  - `test_outer_fault_OuterRaceFault_vload_6.mat`
  - `test_outer_fault_OuterRaceFault_vload_7.mat`

## 🔧 Acesso Otimizado aos Dados

### Usando o Índice de Dados
```matlab
% Carregar índice de dados
load('data/organized/data_index.mat', 'data_index');

% Listar arquivos por categoria
normal_files = data_index.normal.files;
inner_fault_files = data_index.inner_fault.files;
outer_fault_files = data_index.outer_fault.files;

% Estatísticas
fprintf('Total de arquivos: %d\n', data_index.total_files);
fprintf('Normal: %d, Inner: %d, Outer: %d\n', ...
    data_index.normal.count, ...
    data_index.inner_fault.count, ...
    data_index.outer_fault.count);
```

## Tipos de Condições

### 1. Normal (Baseline)
- **Descrição**: Rolamentos em condição normal de operação
- **Arquivos**: Dados de vibração sem defeitos
- **Uso**: Estabelecer linha de base para comparação

### 2. Falha na Pista Interna (Inner Race Fault)
- **Descrição**: Defeitos na superfície interna do rolamento
- **Características**: Frequência predominante BPFI (297.0 Hz)
- **Sintomas**: Impulsos periódicos no sinal de vibração

### 3. Falha na Pista Externa (Outer Race Fault)
- **Descrição**: Defeitos na superfície externa do rolamento
- **Características**: Frequência predominante BPFO (236.4 Hz)
- **Sintomas**: Modulação da amplitude em frequências específicas

## Parâmetros do Rolamento

Os dados MFPT são baseados em rolamentos com as seguintes especificações:

```matlab
% Frequências características calculadas
bearing_params.BPFI = 297.0;  % Hz - Ball Pass Frequency Inner
bearing_params.BPFO = 236.4;  % Hz - Ball Pass Frequency Outer
bearing_params.FTF = 15.9;    % Hz - Fundamental Train Frequency
bearing_params.BSF = 139.1;   % Hz - Ball Spin Frequency

% Parâmetros físicos do rolamento
bearing_specs.inner_diameter = 25;    % mm
bearing_specs.outer_diameter = 52;    % mm
bearing_specs.pitch_diameter = 39;    % mm
bearing_specs.ball_diameter = 7.94;   % mm
bearing_specs.num_balls = 9;          % quantidade
bearing_specs.contact_angle = 0;      % graus
```

## Formato dos Arquivos

### Arquivos de Entrada (.mat)
```matlab
% Estrutura típica de um arquivo MFPT
data_struct = load('bearing_data.mat');
signal = data_struct.bearing;  % Sinal de vibração
fs = 25600;                    % Frequência de amostragem
```

### Arquivos Processados
```matlab
% Características extraídas
features = struct(
    'time_domain',      [...],  % RMS, curtose, etc.
    'frequency_domain', [...],  % Centroide, rolloff, etc.
    'envelope_features',[...]   % BPFI, BPFO amplitudes
);

% Escalogramas para deep learning
scalogram_data = struct(
    'images',    [...],  % Imagens 227x227x3
    'labels',    [...],  % Rótulos das classes
    'filenames', [...]   % Nomes dos arquivos
);
```

## Preparação dos Dados

### Para Análise Clássica
1. **Carregamento**: Use `load_bearing_data.m`
2. **Filtragem**: Aplicar filtros passa-alta (>1000 Hz)
3. **Segmentação**: Dividir em janelas de análise
4. **Normalização**: Ajustar amplitude se necessário

### Para Deep Learning
1. **Carregamento**: Use `load_bearing_data.m`
2. **Conversão CWT**: Gerar escalogramas com `prepare_scalogram_data.m`
3. **Redimensionamento**: 227x227x3 pixels para SqueezeNet
4. **Organização**: Separar por classes em diretórios

## Qualidade dos Dados

### Características Positivas
- ✅ Dados reais de rolamentos industriais
- ✅ Múltiplas condições de falha bem documentadas
- ✅ Alta frequência de amostragem
- ✅ Padrão reconhecido na comunidade científica

### Limitações
- ⚠️ Conjunto limitado de tipos de falhas
- ⚠️ Condições controladas de laboratório
- ⚠️ Apenas um tipo/tamanho de rolamento
- ⚠️ Dados sem ruído excessivo

## Uso Recomendado

### Para Iniciantes
1. Comece com dados normais vs. uma falha
2. Use análise visual (espectros, kurtogramas)
3. Implemente classificação simples (limiar)

### Para Pesquisa Avançada
1. Combine todas as condições
2. Implemente validação cruzada
3. Compare múltiplos algoritmos
4. Teste robustez com ruído adicionado

## 📥 Download e Instalação

### Método 1: Automático (Recomendado)
```matlab
% 1. Execute a extração automática
run('scripts/00_setup/extract_data.m');

% 2. Verifique a instalação
load('data/organized/data_index.mat', 'data_index');
fprintf('Dados extraídos: %d arquivos\n', data_index.total_files);
```

### Método 2: Manual
1. **Baixar dados**:
   - Acesse: https://github.com/mathworks/RollingElementBearingFaultDiagnosis-Data
   - Baixe como ZIP e coloque em `data/`

2. **Extrair manualmente**:
   ```matlab
   % Execute a função de extração
   extract_data();
   ```

### Verificação da Instalação
```matlab
% Verificar se todos os dados estão disponíveis
organized_dir = 'data/organized';
categories = {'normal', 'inner_fault', 'outer_fault'};

for i = 1:length(categories)
    cat_dir = fullfile(organized_dir, categories{i});
    files = dir(fullfile(cat_dir, '*.mat'));
    fprintf('%s: %d arquivos\n', categories{i}, length(files));
end
```

## Citação

Se você usar este conjunto de dados em pesquisa, cite:
```
MFPT Bearing Data Set, Society for Machinery Failure Prevention Technology, 
Available: https://www.mfpt.org/fault-data-sets/
```