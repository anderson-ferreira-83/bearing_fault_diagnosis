# 🛠️ Scripts de Configuração

Este diretório contém scripts essenciais para configurar o ambiente e preparar os dados antes de executar as análises de diagnóstico de falhas em rolamentos.

## 📦 extract_data.m

### Funcionalidade
Script principal para extração e organização automática dos dados MFPT.

### Características
- ✅ **Extração automática** do arquivo ZIP
- 📁 **Organização inteligente** por tipo de falha
- 📊 **Criação de índice** para acesso otimizado
- ✔️ **Validação de integridade** dos dados
- 🚀 **Otimização de performance** para carregamento

### Como Usar
```matlab
% Método 1: Executar diretamente
extract_data();

% Método 2: Executar via path relativo
run('scripts/00_setup/extract_data.m');
```

### Estrutura de Saída
```
data/
├── RollingElementBearingFaultDiagnosis-Data-master.zip  # Original
├── raw/                                                 # Extraído
│   └── RollingElementBearingFaultDiagnosis-Data-master/
│       ├── train_data/
│       └── test_data/
├── organized/                                          # Organizado
│   ├── data_index.mat                                 # Índice otimizado
│   ├── normal/                                        # Baseline
│   │   ├── train_normal_baseline_1.mat
│   │   ├── train_normal_baseline_2.mat
│   │   └── test_normal_baseline_3.mat
│   ├── inner_fault/                                   # Falhas internas
│   │   ├── train_inner_fault_InnerRaceFault_vload_1.mat
│   │   ├── ...
│   │   ├── test_inner_fault_InnerRaceFault_vload_6.mat
│   │   └── test_inner_fault_InnerRaceFault_vload_7.mat
│   └── outer_fault/                                   # Falhas externas
│       ├── train_outer_fault_OuterRaceFault_1.mat
│       ├── ...
│       ├── test_outer_fault_OuterRaceFault_vload_6.mat
│       └── test_outer_fault_OuterRaceFault_vload_7.mat
└── processed/                                         # Para análises
```

## 🔧 Funcionalidades Detalhadas

### 1. Extração de Arquivo ZIP
```matlab
% Localiza automaticamente o arquivo ZIP
% Extrai para diretório 'raw/'
% Tratamento de erros robusto
```

### 2. Organização por Tipo de Falha
```matlab
% Analisa nomes dos arquivos
% Classifica automaticamente:
%   - baseline → normal/
%   - InnerRaceFault → inner_fault/
%   - OuterRaceFault → outer_fault/
% Renomeia com padrão consistente
```

### 3. Criação de Índice de Dados
```matlab
% Gera data_index.mat com:
%   - Lista de todos os arquivos
%   - Separação treino/teste
%   - Metadados (tamanho, data)
%   - Estatísticas por categoria
```

### 4. Validação de Integridade
```matlab
% Verifica se arquivos carregam corretamente
% Identifica sinais de vibração válidos
% Reporta estatísticas de sucesso
% Alerta sobre problemas
```

## 📊 Saída do Script

### Console Output Típico
```
=== Extração de Dados MFPT ===
Criado diretório: /path/to/data/raw
Criado diretório: /path/to/data/organized
Criado diretório: /path/to/data/processed
Extraindo arquivo zip...
✅ Arquivo extraído para: /path/to/data/raw
Organizando dados por tipo de falha...
📁 baseline_1.mat → train_normal_baseline_1.mat
📁 InnerRaceFault_vload_1.mat → train_inner_fault_InnerRaceFault_vload_1.mat
...
Criando índice de dados...
📊 normal: 3 arquivos
📊 inner_fault: 7 arquivos
📊 outer_fault: 10 arquivos
💾 Índice salvo em: /path/to/data/organized/data_index.mat
Validando integridade dos dados...
✅ normal: 3/3 arquivos válidos
✅ inner_fault: 7/7 arquivos válidos  
✅ outer_fault: 10/10 arquivos válidos

📈 Resumo da validação:
   Total de arquivos: 20
   Arquivos válidos: 20
   Taxa de sucesso: 100.0%
🎉 Todos os dados foram validados com sucesso!
✅ Extração concluída com sucesso!
📊 Dados organizados em: /path/to/data/organized
```

## ⚠️ Solução de Problemas

### Arquivo ZIP não encontrado
```matlab
Error: Arquivo zip não encontrado: /path/to/file.zip
```
**Solução**: Certifique-se de que o arquivo ZIP está em `data/RollingElementBearingFaultDiagnosis-Data-master.zip`

### Erro de permissão
```matlab
Error: Erro ao extrair arquivo zip: permission denied
```
**Solução**: Verifique permissões de escrita no diretório `data/`

### Dados suspeitos detectados
```matlab
⚠️ Dados suspeitos em: arquivo.mat
```
**Solução**: Arquivo pode estar corrompido, baixe novamente o conjunto de dados

### Baixa taxa de sucesso na validação
```matlab
Taxa de sucesso: 75.0%
```
**Solução**: Alguns arquivos podem estar corrompidos, verifique logs detalhados

## 🚀 Otimizações Implementadas

### Performance
- **Processamento em lote** para múltiplos arquivos
- **Cache de metadados** para acesso rápido
- **Validação eficiente** sem carregamento completo

### Robustez
- **Tratamento de erros** abrangente
- **Verificação de integridade** automática
- **Logs detalhados** para debug

### Usabilidade
- **Interface amigável** com emojis e cores
- **Progresso em tempo real** durante execução
- **Instruções claras** para próximos passos

## 📝 Próximos Passos

Após executar `extract_data.m`, execute:
```matlab
% 1. Carregar dados organizados
run('scripts/01_data_preprocessing/load_bearing_data.m');

% 2. Processar sinais
run('scripts/02_signal_processing/envelope_spectrum_analysis.m');
```