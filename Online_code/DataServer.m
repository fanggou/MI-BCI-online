classdef DataServer < handle
%
% Syntax:  
%     
%
% Inputs:
%     
%
% Outputs:
%     
%
% Example:
%     
%
% Other m-files required: none
% Subfunctions: none
% MAT-files required: none
%
% Author: Xiaoshan Huang, hxs@neuracle.cn
%
% Versions:
%    v0.1: 2016-11-02, orignal
%
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    properties (Constant)
        updateInterval = 0.08; % 40ms
    end
    
    properties
        nChan;
        sampleRate;
        TCPIP;
        dataParser;
        ringBuffer;
    end
    
    methods
        
        function obj = DataServer(device, nChan, ipAddress, serverPort, sampleRate, saveData_flag,bufferSize)
%             obj.pkgCount=0;
            if nargin < 7
                bufferSize = 5;
            end
            
            obj.nChan = nChan;
            obj.sampleRate = sampleRate;
            
            obj.ringBuffer = RingBuffer(bufferSize, 0);
            obj.dataParser = DataParser(device, obj.nChan,saveData_flag);
            obj.TCPIP = tcpip(ipAddress, serverPort);
            

            obj.TCPIP.InputBufferSize = obj.updateInterval*4*30*1000*10;
            obj.TCPIP.TimerPeriod = obj.updateInterval;
            obj.TCPIP.TimerFcn = {@timerCallBack,obj.TCPIP, obj.dataParser, obj.ringBuffer};
        end
        
        function Open(obj)
            fopen(obj.TCPIP);
        end
        
        function Close(obj)
            fclose(obj.TCPIP);

        end
        
        function [data,Trigger,TS_Out,TS_Out_Trigger] = GetBufferData(obj)
            [data,Trigger,TS_Out,TS_Out_Trigger] = obj.ringBuffer.GetRingbuffer;
        end

        function [data,Trigger,TS_Out,TS_Out_Trigger] = GetLatestData(obj)
            [data,Trigger,TS_Out,TS_Out_Trigger] = obj.ringBuffer.GetLatestRingbuffer;
        end
        function ResetnUpdate(obj)
            obj.ringBuffer.ResetnUpdate;
        end
        
        function [nUpdate]=GetnUpdate(obj)
            nUpdate=obj.ringBuffer.nUpdate;
        end
        function ClearTrigger(obj, idxSensor)
            obj.ringBuffer.ClearTrigger(idxSensor);%��ɾ����һ�������е�trigger
        end
        
        function [Metadata] = GetMetaData(obj)
            Metadata = obj.dataParser.MetaData_MSG_Jellyfish;
        end
        function [DataMessage] = GetDataMessage(obj)
            %�ṩ�û�ʹ�õļ򻯺����Ϣ
            Metadata = obj.dataParser.MetaData_MSG_Jellyfish;
            subject_unique=Metadata(1).SubjectUnique;
            for idx_subject=1:length(subject_unique)
                subject_loc=find(strcmp({Metadata.PersonName},subject_unique{idx_subject})==1);
                sensorName_all=Metadata(subject_loc(1)).SensorName_sort(1,:);
                sensorSrate_all=Metadata(subject_loc(1)).SensorName_sort(2,:);
                sensorChannelName_all=Metadata(subject_loc(1)).ChannelName_sort(1,:);
                
                DataMessage(idx_subject).SubjectName=subject_unique{idx_subject};
                DataMessage(idx_subject).SensorName=sensorName_all;
                DataMessage(idx_subject).SensorSrate=sensorSrate_all;
                DataMessage(idx_subject).SensorChannelName=sensorChannelName_all;
            end
        end
        
        
        
    end
    
end

function timerCallBack(obj, event,TCPIP_in, dataParser, ringBuffer)
    if obj.BytesAvailable > 0
        raw = fread(obj, obj.BytesAvailable, 'uint8');
        dataParser.WriteData(raw,TCPIP_in, ringBuffer); 
    end
end

