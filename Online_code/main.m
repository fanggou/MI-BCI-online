%% 系统初始化
clear; clc; close all; instrreset;

%% 串口初始化
% 串口编号，需要从设备管理器中的COM号获知
HC_ClearCOM;
serPort = 'COM16';
% 通讯的波特率，固定值
baudrate = 9600;
% 新建一个串口对象
serConn = serial(serPort,'BaudRate',baudrate,'Timeout',5,'DataBits',8,...
    'StopBits',1,'Parity','none','OutputBufferSize',1024,'InputBufferSize',1024);

% 打开串口
try
    fopen(serConn);
catch e
    msgbox('串口打开失败');
    return;
end
disp('串口连接完成。。。。。。。');
disp('TCP连接ing。。。。。。');



%%
current_script_path = mfilename('fullpath'); % 自动获取当前脚本的完整路径
current_folder = fileparts(current_script_path); % 提取所在目录
project_root = fileparts(current_folder);
% 添加必要的子目录
addpath(fullfile(project_root, 'FBCSP'));
addpath(fullfile(project_root, 'Offline_Process'));

%% 脑机设备配置
deviceName = 'JellyFish';          
nChan = 0;                         % 通道数自动获取
srate = 0;                         % 采样率自动获取
subject_toshow = 'FangYunMeng';     % 受试者名称
sensor_toshow = 'EEG';              % 目标传感器类型
nDevice = 1;                       % 设备编号
ipData = '127.0.0.1';               % 数据服务器IP
portData = 8712;                    % 数据服务器端口

%% 用户定义的通道列表（需验证是否存在于实际数据流中）
channel_toshow = {'Fpz', 'Fp1', 'Fp2', 'AF3', 'AF4', 'AF7', 'AF8', 'Fz', 'F1', ...
             'F2', 'F3', 'F4', 'F5', 'F6', 'F7', 'F8', 'FCz', 'FC1', ...
             'FC2', 'FC3', 'FC4', 'FC5', 'FC6', 'FT7', 'FT8', 'Cz', ...
             'C1', 'C2', 'C3', 'C4', 'C5', 'C6', 'T7', 'T8', 'CP1', ...
             'CP2', 'CP3', 'CP4', 'CP5', 'CP6', 'TP7', 'TP8', 'Pz', ...
             'P3', 'P4', 'P5', 'P6', 'P7', 'P8', 'POz', 'PO3', 'PO4', ...
             'PO5', 'PO6', 'PO7', 'PO8', 'Oz', 'O1', 'O2'};

%% 初始化数据服务器
try
    dataServer = DataServer(deviceName, nChan, ipData, portData, srate, 0, 5); % 保留5秒缓冲区（仅用于数据接收）
    dataServer.Open();
    pause(2); % 等待连接稳定
    
    % 获取通道信息
    DataMessage = dataServer.GetDataMessage();
    
    % 找到目标受试者
    idx_subject = find(contains({DataMessage.SubjectName}, subject_toshow));
    if isempty(idx_subject)
        error('未找到受试者: %s', subject_toshow);
    end
    
    % 找到目标传感器 (EEG)
    sensor_list = DataMessage(idx_subject).SensorName;
    idx_sensor = find(strcmp(sensor_list, sensor_toshow));
    if isempty(idx_sensor)
        error('未找到传感器: %s', sensor_toshow);
    end
    
    % 提取实际通道列表
    all_channels = DataMessage(idx_subject).SensorChannelName{1, idx_sensor};
    disp('=======================');
    disp('【实际通道列表】');
    disp(all_channels);
    
    %验证用户配置的通道是否存在
    [~, idx_chan] = ismember(channel_toshow, all_channels);
    missing_channels = channel_toshow(idx_chan == 0);
    
    if ~isempty(missing_channels)
        disp('=======================');
        disp('【错误】以下通道未找到:');
        disp(missing_channels);
    else
        disp('=======================');
        disp('【成功】所有配置通道均存在!');
    end
    
catch ME
    disp('程序终止:');
    disp(ME.message);
    
    % 确保关闭连接
    if exist('dataServer', 'var')
        dataServer.Close();
    end
    return;
end

%% 调用离线保存的model和参数

loadDir =   'E:\桌面\BCI_Project\formal_project\Offline_model_data';
load(fullfile(loadDir,'MI_BCI_TWO_model.mat'), 'model');          % 加载分类模型
load(fullfile(loadDir, 'FBCSP_ProcessData.mat'), 'rank', 'proj', 'classNum'); 

% 算法参数
k = 30;       % 特征选择数量
freq = [4 10 16 22 28 34 40]; % 子频带划分
m = 2;     % CSP参数
% classNum = 4;   % 类别数 (来自离线训练中的classNum)
%% 实时处理参数初始化
srate_actual = DataMessage(idx_subject).SensorSrate{idx_sensor}; % 实际采样率
assert(srate_actual == 1000, '【错误】实际采样率异常: %d Hz', srate_actual); % 验证采样率必须为1000Hz
fprintf('实际采样率验证通过: %d Hz\n', srate_actual); % 调试输出

nChannels = length(idx_chan);    % 通道数
fprintf('实际采样率: %d Hz, 使用通道数: %d\n', srate_actual, nChannels);

% 初始化滤波器状态（维护滤波连续性）
filter_states = struct(); 
buffer_size = 4 * srate_actual;  % 4秒数据
persistent_data_buffer = [];     % 动态缓冲区初始化

%发送信号相关
buffer = struct('labels', [], 'confidences', []);
loopCounter = 0;
sendInterval = 3;  % 4秒 / 0.2秒 = 20次循环

disp('连接完成！实验开始。。。。。。。。');
try
    dataServer.ResetnUpdate(); % 重置数据流
    while true
        t_start = tic; % 计时开始
        
        %% ==== 核心处理流程 ====
        % 1. 获取最新数据块
        [raw_data, ~, ~] = dataServer.GetLatestData();

        valid_data_cell = raw_data{idx_sensor, idx_subject}; 
        if ~isempty(valid_data_cell)
            % 提取目标通道数据 [nChannels × nSamples]
%             disp(['有效数据块维度: ', num2str(size(valid_data_cell))]); % 应为 [nChan × nSamples]
            new_block = valid_data_cell(idx_chan, :); 
            
            persistent_data_buffer = [persistent_data_buffer, new_block];
            
            % 裁切超出4秒的旧数据
            if size(persistent_data_buffer,2) > buffer_size
                persistent_data_buffer = persistent_data_buffer(:, end-buffer_size+1:end);
            end            

             % 检查数据是否足够
            if size(persistent_data_buffer,2) >= buffer_size
            
                %% 2. 实时预处理
                [processed_data, filter_states] = pre_process_eeg_online( ...
                    persistent_data_buffer(:, end-buffer_size+1:end), 1000, filter_states);
%                 disp(['预处理后数据维度: ', num2str(size(processed_data))]); % 应为 [59通道 × 降采样后时间点]
                
                % 转置数据为 [时间点 × 通道]
                processed_data_transposed = processed_data'; % [425×59]
%                 disp(['预处理通过，转置之后的数据维度', size(processed_data_transposed)]);%调试输出代码           
                
                %% 3. 特征提取
                features = FBCSPOnline(...
                    processed_data_transposed, proj, classNum, 250, m, freq); % 注意srate_new=250
%                 disp(features);
                
                % 检查输出维度
                expected_features = (length(freq)-1) * 2 * m * classNum; % 总特征数 = 子频带数 × 每频带特征数
                assert(size(features,2) == expected_features, ...
                        '特征数异常: 预期 %d, 实际 %d', expected_features, size(features,2));
                
                selFeaTest = features(:, rank(1:k, 2));    
                
                %% 4. 分类与反馈
                [predictlabel, scores] = predict(model, selFeaTest);
                confidence = max(scores, [], 2);
                fprintf('[结果] 类别: %d | 置信度: %.2f\n', predictlabel, confidence);
				
				[buffer, loopCounter] = update_buffer_and_send(...
                    buffer, loopCounter, predictlabel, confidence, serConn, sendInterval);
            
			end

            %% 5. 延迟控制
            elapsed = toc(t_start); % 计算处理耗时
            target_interval = 0.4;  % 目标处理间隔200ms（根据实际调整）
            if elapsed < target_interval
                pause(target_interval - elapsed); 
            else
                warning('处理超时: %.2fs > %.2fs', elapsed, target_interval);
            end
        end
    end

catch ME
    disp('程序终止:');
    disp(ME.message);
    dataServer.Close();
    return;
end

%% 清理
dataServer.Close();
disp('=======================');
disp('测试完成，连接已关闭.');