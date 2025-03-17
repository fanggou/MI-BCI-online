function [buffer, loopCounter] = update_buffer_and_send(...
    buffer, loopCounter, predictlabel, confidence, serConn, sendInterval)
% 功能: 更新缓冲区并每指定次数发送最高置信度结果
% 输入:
%   - buffer: 结构体，包含 labels 和 confidences 字段
%   - loopCounter: 当前循环计数器
%   - predictlabel: 本次预测标签
%   - confidence: 本次置信度
%   - serConn: 串口对象
%   - sendInterval: 发送间隔次数（如20次）
% 输出:
%   - buffer: 更新后的缓冲区
%   - loopCounter: 更新后的计数器

%% 更新缓冲区
buffer.labels = [buffer.labels, predictlabel];
buffer.confidences = [buffer.confidences, confidence];
loopCounter = loopCounter + 1;

%% 判断是否到达发送间隔
if loopCounter >= sendInterval
    % 提取最高置信度结果
    [max_confidence, idx] = max(buffer.confidences);
    best_label = buffer.labels(idx);
    
    % 发送指令
    send_cmd(best_label, serConn);
    fprintf('[发送] 4秒内最高置信度: 类别 %d (置信度 %.2f)\n', best_label, max_confidence);
    
    % 重置缓冲区和计数器
    buffer.labels = [];
    buffer.confidences = [];
    loopCounter = 0;
end
end