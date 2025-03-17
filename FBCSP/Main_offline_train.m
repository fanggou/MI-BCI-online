tic

% 加载数据
% 获取当前脚本所在目录（假设脚本在offline文件夹）
scriptDir = 'E:\桌面\BCI_Project\EEG_Data\pre_for_mat_data\fangfang';
% 构建到上级Data目录的路径
% dataPath = fullfile(scriptDir, 'merged_data.mat'); 
dataPath = fullfile(scriptDir, 'fang_merged_data.mat'); 
load(dataPath);
X_train = double(data); % 训练集pre_A01.mat
Y_train = labels - 2;        % 训练集标签

dataPath = fullfile(scriptDir, 'fang_pre_test.mat'); 
% dataPath = fullfile(scriptDir, 'Q_V5.mat'); 
load(dataPath);
X_test = double(data);  % 测试集
Y_test = labels - 2;         % 测试集标签


disp('离线训练通道数:');
disp(size(data, 2)); % 必须输出59

% 参数设置
CSPm = 2;        % 定义 CSP-m 参数
sampleRate = 250;
k = 30;           % 定义 Mutual Select K 值
freq = [4 10 16 22 28 34 40]; % 子频带频率

disp('检查训练数据是否有NaN/Inf:');
disp(['数据中NaN数量: ', num2str(sum(isnan(X_train(:))))]);
disp(['数据中Inf数量: ', num2str(sum(isinf(X_train(:))))]);
disp(['标签范围: ', num2str(unique(Y_train)')]); % 应为 [1 2] 或 [0 1]

% FBCSP 特征提取
[FBtrainf, proj, classNum] = FBCSP(X_train(:,:,:), Y_train, sampleRate, CSPm, freq);
kmax = size(FBtrainf, 2); % k 不能超过 kmax

%% 特征选择 
rank = all_MuI(FBtrainf, Y_train);
selFeaTrain = FBtrainf(:, rank(1:k, 2)); % 选取前 k 个特征

%% 训练模型（多类分类）
% svmTemplate = templateSVM(...
%     'KernelFunction', 'rbf', ...
%     'BoxConstraint', 2, ...
%     'KernelScale', 8);
% 
% model = fitcecoc(selFeaTrain, Y_train, 'Learners', svmTemplate);

model = fitcsvm(selFeaTrain, Y_train, ...
    'KernelFunction', 'rbf', 'BoxConstraint', 2, 'KernelScale', 8);

% 测试集处理
fbtestf = FBCSPOnline(X_test(:,:,:), proj, classNum, sampleRate, CSPm, freq);
selFeaTest = fbtestf(:, rank(1:k, 2)); 

% 保存模型

saveDir = 'E:\桌面\BCI_Project\formal_project\Offline_model_data';
save(fullfile(saveDir, 'MI_BCI_TWO_model.mat'), 'model');
save(fullfile(saveDir, 'FBCSP_ProcessData.mat'), 'rank', 'proj', 'classNum');

%% 预测并输出结果
predictlabel = predict(model, selFeaTest);
ac_1 = sum(predictlabel == Y_test) / numel(Y_test) * 100;
fprintf('分类准确率是%6.2f%%\n', ac_1);
toc