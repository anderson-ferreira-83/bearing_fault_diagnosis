%% Load Bearing Data - MFPT Dataset (Versão Otimizada)
% Este script carrega o conjunto de dados MFPT usando a estrutura otimizada
% criada pelo script de extração extract_data.m
%
% Funcionalidades:
% - Carregamento automático dos dados organizados
% - Acesso otimizado através do índice de dados
% - Validação da integridade dos dados
% - Preparação para análises subsequentes

%% Limpar workspace
clear; clc; close all;

fprintf('=== Carregamento de Dados MFPT ===\n');

%% Verificar se dados foram extraídos
organized_dir = '../../data/organized';
index_file = fullfile(organized_dir, 'data_index.mat');

if ~exist(index_file, 'file')
    fprintf('❌ Dados não encontrados! Execute primeiro a extração:\n');
    fprintf('   >> run(''scripts/00_setup/extract_data.m'')\n');
    return;
end

%% Parâmetros do Rolamento MFPT
% Frequências críticas calculadas para o conjunto MFPT
bearing_params.BPFO = 236.4;  % Ball Pass Frequency Outer race (Hz)
bearing_params.BPFI = 297.0;  % Ball Pass Frequency Inner race (Hz)
bearing_params.FTF = 15.9;    % Fundamental Train Frequency (Hz)
bearing_params.BSF = 139.1;   % Ball Spin Frequency (Hz)

% Parâmetros de amostragem
bearing_params.fs_original = 97656;  % Frequência original (Hz)
bearing_params.fs_target = 25600;    % Frequência de trabalho (Hz)

%% Carregar Índice de Dados
fprintf('📊 Carregando índice de dados...\n');
load(index_file, 'data_index');

% Exibir estatísticas
fprintf('   Total de arquivos: %d\n', data_index.total_files);
fprintf('   Normal: %d arquivos\n', data_index.normal.count);
fprintf('   Falha Interna: %d arquivos\n', data_index.inner_fault.count);
fprintf('   Falha Externa: %d arquivos\n', data_index.outer_fault.count);

%% Criar Datastores por Categoria
fprintf('🔧 Criando datastores otimizados...\n');

% Datastore para dados normais
normal_dir = fullfile(organized_dir, 'normal');
if exist(normal_dir, 'dir')
    ds_normal = fileDatastore(normal_dir, 'ReadFcn', @load_mat_file, ...
        'FileExtensions', '.mat', 'IncludeSubfolders', false);
    fprintf('   ✅ Normal: %d arquivos\n', length(ds_normal.Files));
else
    ds_normal = [];
    fprintf('   ⚠️  Normal: diretório não encontrado\n');
end

% Datastore para falhas internas
inner_dir = fullfile(organized_dir, 'inner_fault');
if exist(inner_dir, 'dir')
    ds_inner = fileDatastore(inner_dir, 'ReadFcn', @load_mat_file, ...
        'FileExtensions', '.mat', 'IncludeSubfolders', false);
    fprintf('   ✅ Falha Interna: %d arquivos\n', length(ds_inner.Files));
else
    ds_inner = [];
    fprintf('   ⚠️  Falha Interna: diretório não encontrado\n');
end

% Datastore para falhas externas
outer_dir = fullfile(organized_dir, 'outer_fault');
if exist(outer_dir, 'dir')
    ds_outer = fileDatastore(outer_dir, 'ReadFcn', @load_mat_file, ...
        'FileExtensions', '.mat', 'IncludeSubfolders', false);
    fprintf('   ✅ Falha Externa: %d arquivos\n', length(ds_outer.Files));
else
    ds_outer = [];
    fprintf('   ⚠️  Falha Externa: diretório não encontrado\n');
end

%% Exemplo de Carregamento de Dados
fprintf('🔍 Testando carregamento de dados...\n');

try
    % Testar carregamento de cada categoria
    if ~isempty(ds_normal)
        normal_sample = read(ds_normal);
        fprintf('   ✅ Normal: %d amostras\n', length(normal_sample.data));
        reset(ds_normal);
    end
    
    if ~isempty(ds_inner)
        inner_sample = read(ds_inner);
        fprintf('   ✅ Falha Interna: %d amostras\n', length(inner_sample.data));
        reset(ds_inner);
    end
    
    if ~isempty(ds_outer)
        outer_sample = read(ds_outer);
        fprintf('   ✅ Falha Externa: %d amostras\n', length(outer_sample.data));
        reset(ds_outer);
    end
    
catch ME
    fprintf('   ❌ Erro no carregamento: %s\n', ME.message);
end

%% Salvar Parâmetros e Datastores
output_dir = '../../data/processed';
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

% Salvar parâmetros do rolamento
params_file = fullfile(output_dir, 'bearing_parameters.mat');
save(params_file, 'bearing_params');
fprintf('💾 Parâmetros salvos em: %s\n', params_file);

% Salvar datastores
datastores_file = fullfile(output_dir, 'datastores.mat');
save(datastores_file, 'ds_normal', 'ds_inner', 'ds_outer', 'data_index');
fprintf('💾 Datastores salvos em: %s\n', datastores_file);

%% Exibir Parâmetros
fprintf('\n📋 Parâmetros do Rolamento (Hz):\n');
fprintf('   BPFO (Pista Externa): %.1f Hz\n', bearing_params.BPFO);
fprintf('   BPFI (Pista Interna): %.1f Hz\n', bearing_params.BPFI);
fprintf('   FTF (Gaiola): %.1f Hz\n', bearing_params.FTF);
fprintf('   BSF (Rotação Esfera): %.1f Hz\n', bearing_params.BSF);
fprintf('   Freq. Amostragem: %.0f Hz\n', bearing_params.fs_target);

fprintf('\n🎉 Carregamento concluído com sucesso!\n');
fprintf('📝 Próximos passos: Execute os scripts de processamento em 02_signal_processing/\n');

%% Função auxiliar para carregar arquivos .mat
function data = load_mat_file(filename)
    % Carregar arquivo .mat e extrair dados de vibração
    loaded = load(filename);
    
    % Encontrar campo com dados numéricos (sinal de vibração)
    fields = fieldnames(loaded);
    data.filename = filename;
    data.data = [];
    
    for i = 1:length(fields)
        field_data = loaded.(fields{i});
        if isnumeric(field_data) && length(field_data) > 1000
            data.data = field_data(:);  % Garantir vetor coluna
            data.field_name = fields{i};
            break;
        end
    end
    
    if isempty(data.data)
        warning('Nenhum sinal de vibração encontrado em: %s', filename);
    end
end