function extract_data()
    % EXTRACT_DATA Extrai e organiza os dados do conjunto MFPT
    %
    % Esta função:
    % 1. Extrai o arquivo zip com dados de rolamentos
    % 2. Organiza os dados em estrutura otimizada
    % 3. Cria índices para acesso rápido
    % 4. Valida a integridade dos dados
    %
    % Uso:
    %   extract_data()
    %
    % Estrutura de saída:
    %   data/
    %   ├── raw/                    # Dados extraídos do zip
    %   ├── organized/              # Dados organizados por tipo
    %   │   ├── normal/            # Dados baseline
    %   │   ├── inner_fault/       # Falhas na pista interna
    %   │   └── outer_fault/       # Falhas na pista externa
    %   └── processed/             # Dados processados para ML
    
    fprintf('=== Extração de Dados MFPT ===\n');
    
    % Configurar caminhos
    current_dir = fileparts(mfilename('fullpath'));
    project_root = fileparts(fileparts(current_dir));
    data_dir = fullfile(project_root, 'data');
    zip_file = fullfile(data_dir, 'RollingElementBearingFaultDiagnosis-Data-master.zip');
    
    % Verificar se o arquivo zip existe
    if ~exist(zip_file, 'file')
        error('Arquivo zip não encontrado: %s', zip_file);
    end
    
    % Criar diretórios de destino
    raw_dir = fullfile(data_dir, 'raw');
    organized_dir = fullfile(data_dir, 'organized');
    processed_dir = fullfile(data_dir, 'processed');
    
    create_directories({raw_dir, organized_dir, processed_dir});
    
    % Extrair arquivo zip
    fprintf('Extraindo arquivo zip...\n');
    extract_zip_file(zip_file, raw_dir);
    
    % Organizar dados por tipo de falha
    fprintf('Organizando dados por tipo de falha...\n');
    organize_data_by_fault_type(raw_dir, organized_dir);
    
    % Criar índice de dados
    fprintf('Criando índice de dados...\n');
    create_data_index(organized_dir);
    
    % Validar dados extraídos
    fprintf('Validando integridade dos dados...\n');
    validate_extracted_data(organized_dir);
    
    fprintf('✅ Extração concluída com sucesso!\n');
    fprintf('📊 Dados organizados em: %s\n', organized_dir);
end

function create_directories(dirs)
    % Criar diretórios se não existirem
    for i = 1:length(dirs)
        if ~exist(dirs{i}, 'dir')
            mkdir(dirs{i});
            fprintf('Criado diretório: %s\n', dirs{i});
        end
    end
end

function extract_zip_file(zip_file, extract_dir)
    % Extrair arquivo zip
    try
        unzip(zip_file, extract_dir);
        fprintf('✅ Arquivo extraído para: %s\n', extract_dir);
    catch ME
        error('Erro ao extrair arquivo zip: %s', ME.message);
    end
end

function organize_data_by_fault_type(raw_dir, organized_dir)
    % Organizar dados por tipo de falha
    
    % Encontrar diretório extraído
    extracted_dir = fullfile(raw_dir, 'RollingElementBearingFaultDiagnosis-Data-master');
    train_dir = fullfile(extracted_dir, 'train_data');
    test_dir = fullfile(extracted_dir, 'test_data');
    
    % Criar subdiretórios organizados
    normal_dir = fullfile(organized_dir, 'normal');
    inner_fault_dir = fullfile(organized_dir, 'inner_fault');
    outer_fault_dir = fullfile(organized_dir, 'outer_fault');
    
    create_directories({normal_dir, inner_fault_dir, outer_fault_dir});
    
    % Organizar dados de treinamento
    organize_files(train_dir, normal_dir, inner_fault_dir, outer_fault_dir, 'train');
    
    % Organizar dados de teste
    organize_files(test_dir, normal_dir, inner_fault_dir, outer_fault_dir, 'test');
end

function organize_files(source_dir, normal_dir, inner_fault_dir, outer_fault_dir, prefix)
    % Organizar arquivos por tipo de falha
    
    if ~exist(source_dir, 'dir')
        fprintf('⚠️  Diretório não encontrado: %s\n', source_dir);
        return;
    end
    
    % Listar arquivos .mat
    mat_files = dir(fullfile(source_dir, '*.mat'));
    
    for i = 1:length(mat_files)
        filename = mat_files(i).name;
        source_path = fullfile(source_dir, filename);
        
        % Determinar tipo de falha baseado no nome do arquivo
        if contains(filename, 'baseline', 'IgnoreCase', true)
            dest_dir = normal_dir;
            fault_type = 'normal';
        elseif contains(filename, 'InnerRaceFault', 'IgnoreCase', true)
            dest_dir = inner_fault_dir;
            fault_type = 'inner_fault';
        elseif contains(filename, 'OuterRaceFault', 'IgnoreCase', true)
            dest_dir = outer_fault_dir;
            fault_type = 'outer_fault';
        else
            fprintf('⚠️  Tipo de falha não reconhecido: %s\n', filename);
            continue;
        end
        
        % Criar nome de arquivo organizado
        [~, name, ext] = fileparts(filename);
        organized_filename = sprintf('%s_%s_%s%s', prefix, fault_type, name, ext);
        dest_path = fullfile(dest_dir, organized_filename);
        
        % Copiar arquivo
        copyfile(source_path, dest_path);
        fprintf('📁 %s → %s\n', filename, organized_filename);
    end
end

function create_data_index(organized_dir)
    % Criar índice de dados para acesso rápido
    
    data_index = struct();
    data_index.created = datetime('now');
    data_index.total_files = 0;
    
    % Categorias de dados
    categories = {'normal', 'inner_fault', 'outer_fault'};
    
    for i = 1:length(categories)
        category = categories{i};
        category_dir = fullfile(organized_dir, category);
        
        % Listar arquivos da categoria
        mat_files = dir(fullfile(category_dir, '*.mat'));
        
        % Criar estrutura de índice para categoria
        category_data = struct();
        category_data.count = length(mat_files);
        category_data.files = {};
        category_data.train_files = {};
        category_data.test_files = {};
        
        for j = 1:length(mat_files)
            filename = mat_files(j).name;
            filepath = fullfile(category_dir, filename);
            
            % Informações do arquivo
            file_info = struct();
            file_info.filename = filename;
            file_info.filepath = filepath;
            file_info.size = mat_files(j).bytes;
            file_info.date = mat_files(j).date;
            
            % Categorizar como treino ou teste
            if contains(filename, 'train')
                category_data.train_files{end+1} = file_info;
            elseif contains(filename, 'test')
                category_data.test_files{end+1} = file_info;
            else
                category_data.files{end+1} = file_info;
            end
        end
        
        data_index.(category) = category_data;
        data_index.total_files = data_index.total_files + category_data.count;
        
        fprintf('📊 %s: %d arquivos\n', category, category_data.count);
    end
    
    % Salvar índice
    index_file = fullfile(organized_dir, 'data_index.mat');
    save(index_file, 'data_index');
    fprintf('💾 Índice salvo em: %s\n', index_file);
end

function validate_extracted_data(organized_dir)
    % Validar integridade dos dados extraídos
    
    categories = {'normal', 'inner_fault', 'outer_fault'};
    total_valid = 0;
    total_files = 0;
    
    for i = 1:length(categories)
        category = categories{i};
        category_dir = fullfile(organized_dir, category);
        
        % Listar arquivos .mat
        mat_files = dir(fullfile(category_dir, '*.mat'));
        category_valid = 0;
        
        for j = 1:length(mat_files)
            filepath = fullfile(category_dir, mat_files(j).name);
            
            try
                % Tentar carregar arquivo
                data = load(filepath);
                
                % Verificar se contém dados de vibração
                fields = fieldnames(data);
                has_vibration_data = false;
                
                for k = 1:length(fields)
                    if isnumeric(data.(fields{k})) && length(data.(fields{k})) > 1000
                        has_vibration_data = true;
                        break;
                    end
                end
                
                if has_vibration_data
                    category_valid = category_valid + 1;
                else
                    fprintf('⚠️  Dados suspeitos em: %s\n', mat_files(j).name);
                end
                
            catch ME
                fprintf('❌ Erro ao carregar: %s - %s\n', mat_files(j).name, ME.message);
            end
        end
        
        total_valid = total_valid + category_valid;
        total_files = total_files + length(mat_files);
        
        fprintf('✅ %s: %d/%d arquivos válidos\n', category, category_valid, length(mat_files));
    end
    
    fprintf('\n📈 Resumo da validação:\n');
    fprintf('   Total de arquivos: %d\n', total_files);
    fprintf('   Arquivos válidos: %d\n', total_valid);
    fprintf('   Taxa de sucesso: %.1f%%\n', (total_valid/total_files)*100);
    
    if total_valid == total_files
        fprintf('🎉 Todos os dados foram validados com sucesso!\n');
    else
        fprintf('⚠️  Alguns arquivos podem ter problemas. Verifique os logs acima.\n');
    end
end