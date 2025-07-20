# Conjunto de Dados

Este diretório contém os dados utilizados para o diagnóstico de falhas em rolamentos.

## Fonte dos Dados

O projeto utiliza o **conjunto de dados MFPT (Machinery Failure Prevention Technology)**, que é um padrão na área de diagnóstico de falhas em maquinário rotativo.

### Sobre o MFPT Dataset

- **Origem**: Society for Machinery Failure Prevention Technology
- **Tipo**: Dados de vibração de rolamentos com diferentes tipos de falhas
- **Formato**: Arquivos .mat (MATLAB)
- **Frequência de Amostragem**: 97,656 Hz (downsample para 25,600 Hz)
- **Website**: https://www.mfpt.org/fault-data-sets/

## Estrutura dos Dados

```
data/
├── mfpt_bearing_data/          # Dados originais MFPT
│   ├── normal/                 # Rolamentos sem falhas
│   ├── inner_fault/           # Falhas na pista interna
│   └── outer_fault/           # Falhas na pista externa
├── processed/                  # Dados processados
│   ├── features/              # Características extraídas
│   └── scalograms/            # Imagens de escalogramas
└── results/                    # Resultados das análises
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

## Download e Instalação

1. **Baixar dados MFPT**:
   ```bash
   # Visite: https://www.mfpt.org/fault-data-sets/
   # Baixe "Bearing Data Set"
   ```

2. **Organizar arquivos**:
   ```matlab
   % Coloque os arquivos .mat em:
   data/mfpt_bearing_data/normal/
   data/mfpt_bearing_data/inner_fault/
   data/mfpt_bearing_data/outer_fault/
   ```

3. **Verificar instalação**:
   ```matlab
   % Execute o script de verificação
   run('scripts/01_data_preprocessing/load_bearing_data.m');
   ```

## Citação

Se você usar este conjunto de dados em pesquisa, cite:
```
MFPT Bearing Data Set, Society for Machinery Failure Prevention Technology, 
Available: https://www.mfpt.org/fault-data-sets/
```