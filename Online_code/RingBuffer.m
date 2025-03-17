classdef RingBuffer < handle
%RingBuffer Dummy 2D ring buffer for multichannel data
% updates along 2st dimension
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
%    v0.1: 2016-11-22, orignal
%
% Copyright (c) 2016 Neuracle, Inc. All Rights Reserved. http://neuracle.cn/
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties
        currentPtr;
        buffer;
        nPoint;
        nChan;
        nUpdate;
        SampleRate
        
        bufferbuffer;
        Enable_flag;
        timelength;
        
        MetaData_MSG;
        SensorNum;
        SubjectNum;
        
        Type_Flag;
        bufferTS;
        bufferTS_Fast;
        bufferTS_Pakage;
        TriggerLoc;
        TS_TrgOut
        
        currentReadPtr;
    end
    
    methods

        function obj = RingBuffer(timelength, Enable_flag)

            obj.timelength=timelength;
            obj.bufferbuffer= [];
            obj.Enable_flag=Enable_flag;    
            obj.buffer={};
        end
        
        

        function BufferContruct(obj,MetaData_MSG,Flag_Meta) %

            try
                obj.MetaData_MSG=MetaData_MSG;
                nChanMid=[];
                nPoint_mid=[];
                idxTriggerSensor={};
                SubjectIdx_old=0;
                
                isTrigger=[];
                for idx_Module=1:length(MetaData_MSG)
                    for idx_sensor=1:size(MetaData_MSG(idx_Module).SensorDataLoc,1)
                        nChanMid(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx)=...
                            MetaData_MSG(idx_Module).SensorDataLoc(idx_sensor,3);
                        nPoint_mid(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx)=obj.timelength*MetaData_MSG(idx_Module).SensorDataLoc(idx_sensor,5);
                        
                        obj.buffer{MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx}=...
                            zeros(nChanMid(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx),...
                            nPoint_mid(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx));
                        
                        obj.SampleRate(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx)=...
                            MetaData_MSG(idx_Module).SensorDataLoc(idx_sensor,5);
                    
                        obj.bufferTS{MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx}=...
                            zeros(1,nPoint_mid(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx));
                     
                        if strcmp(MetaData_MSG(idx_Module).SensorName_sort(1,idx_sensor),'Trigger')
                            isTrigger(MetaData_MSG(idx_Module).SensorIdx(idx_sensor),MetaData_MSG(idx_Module).SubjectIdx)=1;
                        end
                        
                    end

                end
                
                obj.nChan = nChanMid;
                obj.nPoint = nPoint_mid;
                
                obj.currentPtr = ones(size(obj.buffer));
                obj.currentReadPtr = ones(size(obj.buffer));
                obj.nUpdate = zeros(size(obj.buffer));
                
                obj.SensorNum=size(obj.buffer,1);
                obj.SubjectNum=size(obj.buffer,2);
                
                obj.Enable_flag=1;
                obj.Type_Flag=Flag_Meta;
                TriggerLoc=[];
                [TriggerLoc(:,1),TriggerLoc(:,2)]=find(isTrigger==1);
                obj.TriggerLoc=TriggerLoc;
           
                obj.bufferTS_Pakage=cell(size(obj.buffer));
            catch
                
            end
            
        end
        function AppendData(obj, data,Timestamp_all)
            switch obj.Type_Flag
                case 0
                    obj.Append( data,Timestamp_all);
                case 1
                    obj.Append_Indep( data_all,Timestamp_all);
            end
        end
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=GetRingbuffer(obj)
            switch obj.Type_Flag
                case 0
                    [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=obj.GetData();
                case 1
                    [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=obj.GetData_Indep();
            end
        end
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=GetLatestRingbuffer(obj)
            switch obj.Type_Flag
                case 0
                    [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=obj.GetLatestData();
                case 1
                    [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger]=obj.GetLatestData_Indep();
            end
        end
%         function Append(obj, data,Timestamp_all)
% 
%             switch obj.Enable_flag
%                 case 0
%                     obj.bufferbuffer=data;
%                 case 1  
%                     buffer_mid=obj.buffer; 
%                     currentPtr_mid=obj.currentPtr;
%                     nUpdate_mid=obj.nUpdate;
%                     for idx_subject=1:size(data,2)  
%                         for idx_sensor=1:size(data,1)
%                             data_nowsensor=data{idx_sensor,idx_subject};
%                             
%                             n = size(data_nowsensor,2);
%                             buffer_mid{idx_sensor,idx_subject}(:, mod((obj.currentPtr(idx_sensor,idx_subject) : ...
%                                 obj.currentPtr(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
%                             currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
%                             nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;
%                         end
%                     end
%                     obj.buffer=buffer_mid; 
%                     obj.currentPtr=currentPtr_mid;
%                     obj.nUpdate=nUpdate_mid;
%                     %% ����TS�������ݰ���֧��������ȡʱ��TS���
%                     
%             end
%         end
        function Append(obj, data,Timestamp_all)

            switch obj.Enable_flag
                case 0
                    obj.bufferbuffer=data;
                case 1
                    if ~isempty(data)
                        buffer_mid=obj.buffer;
                        currentPtr_mid=obj.currentPtr;
                        nUpdate_mid=obj.nUpdate;
                        
                        bufferTS_mid=obj.bufferTS;
                        bufferTS_Pakage_mid=obj.bufferTS_Pakage;%����ʱ���
                        Timestamp=Timestamp_all(1);
                        Timestamp=double(Timestamp);
%                         disp(['TS:' num2str(Timestamp)])
                        for idx_subject=1:size(data,2)
                            for idx_sensor=1:size(data,1)
                                data_nowsensor=data{idx_sensor,idx_subject};
                                %����ʱ���
                                bufferTS_Pakage_mid{idx_sensor,idx_subject}=[bufferTS_Pakage_mid{idx_sensor,idx_subject} Timestamp];
                                %���ݳ���
                                n = size(data_nowsensor,2);
                                
                                if all(obj.bufferTS{idx_sensor,idx_subject}==0)
                                    %��һ�θ���
                                    buffer_mid{idx_sensor,idx_subject}(:, mod((obj.currentPtr(idx_sensor,idx_subject) : ...
                                        obj.currentPtr(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                    currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                    nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;
                                    %����ʱ���
                                    Timestamp_new=obj.Refresh_TS(Timestamp,n,obj.SampleRate(idx_sensor,idx_subject));
                                    bufferTS_mid{idx_sensor,idx_subject}=Timestamp_new;
                                else
                                    %�ǵ�һ�θ���
                                    %��֮���ʱ�����Ҷ�Ӧʱ���
                                    Loc_nowTS=find((obj.bufferTS{idx_sensor,idx_subject}+obj.timelength*1000)==Timestamp);
                                    
                                    Loc_last=currentPtr_mid(idx_sensor,idx_subject);%��ǰдָ��
                                    %��ǰдָ�������
                                    currentPtr_mid(idx_sensor,idx_subject) = mod(Loc_last+Loc_nowTS(1)-1-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                    
                                    if Loc_nowTS(1)>1
                                        %���Ƚ���ǰдָ��ʱ���������Ҫд���ʱ���֮�������ȫ������
                                        buffer_mid{idx_sensor,idx_subject}(:, mod((Loc_last : Loc_last+Loc_nowTS(1)-1)-1,...
                                            obj.nPoint(idx_sensor,idx_subject)) + 1) = 0;
                                    end
                                    %ʹ�þ������дָ��д������
                                    buffer_mid{idx_sensor,idx_subject}(:, mod((currentPtr_mid(idx_sensor,idx_subject) : ...
                                        currentPtr_mid(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                    %д�����ݺ󣬸���дָ��
                                    currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                    %����ͳ�Ƹ���
                                    nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;
                                    %���ݸ����������������TS
                                    Timestamp_new=obj.Refresh_TS(Timestamp,n,obj.SampleRate(idx_sensor,idx_subject));
                                    %             Timestamp_new=obj.Refresh_TS(Timestamp,n+Loc_nowTS(1)-1,obj.SampleRate(idx_sensor,idx_subject));
                                    bufferTS_mid{idx_sensor,idx_subject}=Timestamp_new;
                                end
                                
                            end
                        end
                        
                        obj.buffer=buffer_mid;
                        obj.currentPtr=currentPtr_mid;
                        obj.nUpdate=nUpdate_mid;
                        obj.bufferTS=bufferTS_mid;
                        obj.bufferTS_Pakage=bufferTS_Pakage_mid;
                    end
                    
                    

            end
        end
        function Append_Indep(obj, data_all,Timestamp_all)
            switch obj.Enable_flag
                case 0
                    obj.bufferbuffer=data_all;
                case 1
                    buffer_mid=obj.buffer; 
                    currentPtr_mid=obj.currentPtr;
                    nUpdate_mid=obj.nUpdate;
                    bufferTS_mid=obj.bufferTS;
                    bufferTS_Pakage_mid=obj.bufferTS_Pakage;
                    %% ÿ��block����ʱ���ѹ�룬
                    for idx_package=1:length(data_all)
                        data=data_all{idx_package};
                        Timestamp=Timestamp_all(idx_package);    
                        
                        for idx_subject=1:size(data,2)    
                            for idx_sensor=1:size(data,1)
                                data_nowsensor=data{idx_sensor,idx_subject};
                                
                                if ~isempty(data_nowsensor)
                                    if ismember([idx_sensor,idx_subject],obj.TriggerLoc,'rows')
                                        %����Trigger
                                        Timestamp=double(Timestamp);
%                                         Trigger_Now = buffer_mid{1,end};
%                                         TriggerTS_Now = bufferTS_mid{1,end};
                                        Trigger_Now = buffer_mid{1,obj.TriggerLoc(2)};
                                        TriggerTS_Now = bufferTS_mid{1,obj.TriggerLoc(2)};
                                        Timestamp_new=Timestamp-obj.timelength*1000+1:Timestamp;
                                        
                                        [~, index_old] = ismember(intersect(TriggerTS_Now,Timestamp_new),TriggerTS_Now);
                                        [~, index_new] = ismember(intersect(TriggerTS_Now,Timestamp_new),Timestamp_new);
                                        data_nowsensor_save=zeros(size(Trigger_Now));
                                        data_nowsensor_save(index_new)=Trigger_Now(index_old);
                                        data_nowsensor_save(end)=data_nowsensor;
                                        
%                                         buffer_mid{1,end}= data_nowsensor_save;
%                                         bufferTS_mid{1,end}= Timestamp_new;
                                        buffer_mid{1,obj.TriggerLoc(2)}= data_nowsensor_save;
                                        bufferTS_mid{1,obj.TriggerLoc(2)}= Timestamp_new;
                                        obj.buffer=buffer_mid;
                                        obj.bufferTS=bufferTS_mid;
                                    else
                                        %����sensor
                                        bufferTS_Pakage_mid{idx_sensor,idx_subject}=[bufferTS_Pakage_mid{idx_sensor,idx_subject} Timestamp];
                                        
                                        n = size(data_nowsensor,2);
                                        
                                        Timestamp=double(Timestamp);
                                        
                                        if all(obj.bufferTS{idx_sensor,idx_subject}==0)
                                            %��һ�θ���ringbuffer
                                            buffer_mid{idx_sensor,idx_subject}(:, mod((obj.currentPtr(idx_sensor,idx_subject) : ...
                                                obj.currentPtr(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                            currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                            nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;
                                            
                                            Timestamp_new=obj.Refresh_TS(Timestamp,n,obj.SampleRate(idx_sensor,idx_subject));
                                            bufferTS_mid{idx_sensor,idx_subject}=Timestamp_new;
                                            
                                            obj.bufferTS_Fast=Timestamp_new(1);
                                            
                                            
                                        elseif any((obj.bufferTS{idx_sensor,idx_subject}+obj.timelength*1000)==Timestamp)
                                    
                                            Loc_nowTS=find((obj.bufferTS{idx_sensor,idx_subject}+obj.timelength*1000)==Timestamp);
                                            
                                            Loc_last=currentPtr_mid(idx_sensor,idx_subject);%��ǰдָ��
                                            %��ǰдָ�������
                                            currentPtr_mid(idx_sensor,idx_subject) = mod(Loc_last+Loc_nowTS(1)-1-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                            
                                            if Loc_nowTS(1)>1 
                                                %���Ƚ���ǰдָ��ʱ���������Ҫд���ʱ���֮�������ȫ������
                                                buffer_mid{idx_sensor,idx_subject}(:, mod((Loc_last : Loc_last+Loc_nowTS(1)-1)-1,...
                                                    obj.nPoint(idx_sensor,idx_subject)) + 1) = 0;
%                                                 obj.currentPtr(idx_sensor,idx_subject)=mod(obj.currentPtr(idx_sensor,idx_subject)+Loc_nowTS(1)-3,...
%                                                     obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                            end
                                            % д��λ�ó����ˣ�
%                                             buffer_mid{idx_sensor,idx_subject}(:, mod((obj.currentPtr(idx_sensor,idx_subject) : ...
%                                                 obj.currentPtr(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                            buffer_mid{idx_sensor,idx_subject}(:, mod((currentPtr_mid(idx_sensor,idx_subject) : ...
                                                currentPtr_mid(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                            currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                            nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;

                                            %
                                            Timestamp_new=obj.Refresh_TS(Timestamp,n,obj.SampleRate(idx_sensor,idx_subject));
%                                             Timestamp_new=obj.Refresh_TS(Timestamp,n+Loc_nowTS(1)-1,obj.SampleRate(idx_sensor,idx_subject));
                                            bufferTS_mid{idx_sensor,idx_subject}=Timestamp_new;
                                            
                                            if obj.bufferTS_Fast<Timestamp_new(1)
                                                obj.bufferTS_Fast=Timestamp_new(1);
                                            end
                                            
                                            
                                            
                                        elseif (obj.bufferTS{idx_sensor,idx_subject}(end)+obj.timelength*1000)<Timestamp
                                            %��Զ�������
                                            obj.Reset();
                                            
                                            buffer_mid{idx_sensor,idx_subject}(:, mod((obj.currentPtr(idx_sensor,idx_subject) : ...
                                                obj.currentPtr(idx_sensor,idx_subject)+n-1)-1, obj.nPoint(idx_sensor,idx_subject)) + 1) = data_nowsensor;
                                            currentPtr_mid(idx_sensor,idx_subject) = mod(obj.currentPtr(idx_sensor,idx_subject)+n-2, obj.nPoint(idx_sensor,idx_subject)) + 1 + 1;
                                            nUpdate_mid(idx_sensor,idx_subject) =obj.nUpdate(idx_sensor,idx_subject) + n;
                                            
                                            Timestamp_new=obj.Refresh_TS(Timestamp,n,obj.SampleRate(idx_sensor,idx_subject));
                                            bufferTS_mid{idx_sensor,idx_subject}=Timestamp_new;
                                            
                                            obj.bufferTS_Fast=Timestamp_new(1);
                                            
                                            
                                        end
                                        
                                        bufferTS_Pakage_mid{idx_sensor,idx_subject}(bufferTS_Pakage_mid{idx_sensor,idx_subject}<Timestamp_new(1))=[];
                                        
                                        obj.buffer=buffer_mid;
                                        obj.currentPtr=currentPtr_mid;
                                        obj.nUpdate=nUpdate_mid;
                                        obj.bufferTS=bufferTS_mid;
                                        obj.bufferTS_Pakage=bufferTS_Pakage_mid;%
                                    end
                                    
                                end
                            end
                        end
                        

                    end
                    

            end

        end

        function Timestamp_new=Refresh_TS(obj, Timestamp,n,fs )

            length=fs*obj.timelength;
            Timestamp=cast(Timestamp,'double');
            if fs<1000
                Spacing=1000/fs;
                
                Timestamp_new=[0:length-1]*Spacing;
                Diff=Timestamp-Timestamp_new(end-n+1);
                Timestamp_new=Timestamp_new+Diff;
            elseif fs>1000
                Times=fs/1000;
                n_fix=n/Times;
                length_fix=length/Times;
%                 Timestamp_new=[Timestamp-length+n:Timestamp-1 Timestamp Timestamp+1:Timestamp+n-1];
                Timestamp_new=[Timestamp-length_fix+n_fix:Timestamp-1 Timestamp Timestamp+1:Timestamp+n_fix-1];
                Timestamp_new=repmat(Timestamp_new,Times,1);
                Timestamp_new=Timestamp_new(:);
                Timestamp_new=Timestamp_new';
            else
                Timestamp_new=[Timestamp-length+n:Timestamp-1 Timestamp Timestamp+1:Timestamp+n-1];
            end
        end
        
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger] = GetData(obj)
            
            data_out={};
            buffer_now=obj.buffer;
            currentPtr_now=obj.currentPtr;
            TS_Out=obj.bufferTS;
            for idx_subject=1:obj.SubjectNum  
                for idx_sensor=1:obj.SensorNum
                    data_out{idx_sensor,idx_subject} = [buffer_now{idx_sensor,idx_subject}(:, currentPtr_now(idx_sensor,idx_subject):end),...
                        buffer_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                end
            end
            
            data_out_Trigger=data_out{obj.TriggerLoc(1,1),obj.TriggerLoc(1,2)};
            TS_Out_Trigger=TS_Out{obj.TriggerLoc(1,1),obj.TriggerLoc(1,2)};
        end
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger] = GetData_Indep(obj)

            data_out={};
            buffer_now=obj.buffer;
            currentPtr_now=obj.currentPtr;
            TS_Out=obj.bufferTS;
            
            bufferTS_Pakage_mid=obj.bufferTS_Pakage;
            
            TimestampFast_now=obj.bufferTS_Fast;
            TimestampFast_now=obj.findOutputTS(bufferTS_Pakage_mid,TimestampFast_now);

            idx_subject_all=1:obj.SubjectNum;
            idx_subject_all=setdiff(idx_subject_all,obj.TriggerLoc(:,2));
            for idx_subject=idx_subject_all
                for idx_sensor=1:obj.SensorNum 
                    
                    Timestamp_now=obj.bufferTS{idx_sensor,idx_subject};
                    data_sensor_now= [buffer_now{idx_sensor,idx_subject}(:, currentPtr_now(idx_sensor,idx_subject):end),...
                        buffer_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                    data_out_now=zeros(size(data_sensor_now));
                    data_sensor_now=data_sensor_now(:,Timestamp_now>=TimestampFast_now(1));
                    data_out_now(:,1:size(data_sensor_now,2))=data_sensor_now;
                    data_out{idx_sensor,idx_subject} =data_out_now;

                end
                
            end
            for idx_trigger=1:size(obj.TriggerLoc,1)
                Timestamp_now=obj.bufferTS{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};
                data_sensor_now= buffer_now{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};
                data_out_now=zeros(size(data_sensor_now));
                data_sensor_now=data_sensor_now(:,Timestamp_now>=TimestampFast_now(1));
                data_out_now(:,1:size(data_sensor_now,2))=data_sensor_now;
                
                %�����������
                data_out{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)} =data_out_now;
                
%                 data_out_Trigger=data_sensor_now;
                data_out_Trigger=data_out_now;
                %������ݵ�ʱ�������ȡȫ������ʱ����Ȼ����ȳ���ʱ���
                TS_Out_Trigger=TimestampFast_now(1):TimestampFast_now(1)+size(data_out_now,2)-1;
            end
            
        end
        function TimestampFast_out=findOutputTS(obj,bufferTS_Pakage,TimestampFast_now)
            bufferTS_Pakage_Step=zeros(size(bufferTS_Pakage));
            for idx_subject=1:size(bufferTS_Pakage,2)
                for idx_sensor=1:size(bufferTS_Pakage,1)
                    bufferTS_Pakage_now=bufferTS_Pakage{idx_sensor,idx_subject};
                    bufferTS_Pakage_now(bufferTS_Pakage_now<TimestampFast_now)=[];
                    
                    if ~isempty(bufferTS_Pakage_now)
                        bufferTS_Pakage_Diff=diff(bufferTS_Pakage_now);
                        bufferTS_Pakage_Step(idx_sensor,idx_subject)=min(unique(bufferTS_Pakage_Diff));
                    end
                end
            end
            [~,loc_maxSensor]=max(bufferTS_Pakage_Step,[],'all', 'linear');
            TimestampFast_out=bufferTS_Pakage{loc_maxSensor};
            TimestampFast_out(TimestampFast_out<TimestampFast_now)=[];
            TimestampFast_out=TimestampFast_out(1);
        end
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger] = GetLatestData(obj)
            data_out={};
            TS_Out={};
            buffer_now=obj.buffer;
            currentPtr_now=obj.currentPtr;
            TS_now=obj.bufferTS;
            currentReadPtr_now=obj.currentReadPtr;
            obj.currentReadPtr=obj.currentPtr;
            for idx_subject=1:obj.SubjectNum
                for idx_sensor=1:obj.SensorNum
                    
                    if currentReadPtr_now(idx_sensor,idx_subject)<=currentPtr_now(idx_sensor,idx_subject)
                        data_out{idx_sensor,idx_subject} = [buffer_now{idx_sensor,idx_subject}(:,currentReadPtr_now(idx_sensor,idx_subject):(currentPtr_now(idx_sensor,idx_subject)-1))];
                        TS_Out{idx_sensor,idx_subject} = [TS_now{idx_sensor,idx_subject}(:,currentReadPtr_now(idx_sensor,idx_subject):(currentPtr_now(idx_sensor,idx_subject)-1))];
                    else
                        data_out{idx_sensor,idx_subject} = [buffer_now{idx_sensor,idx_subject}(:, currentReadPtr_now(idx_sensor,idx_subject):end),...
                            buffer_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                        TS_Out{idx_sensor,idx_subject} = [TS_now{idx_sensor,idx_subject}(:, currentReadPtr_now(idx_sensor,idx_subject):end),...
                            TS_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                    end
                    
                end
            end
            data_out_Trigger=data_out{obj.TriggerLoc(1,1),obj.TriggerLoc(1,2)};
            TS_Out_Trigger=TS_Out{obj.TriggerLoc(1,1),obj.TriggerLoc(1,2)};
        end
        
        function [data_out,data_out_Trigger,TS_Out,TS_Out_Trigger] = GetLatestData_Indep(obj)
            %% ������� ���� �� trigger
            data_out={};
            TS_Out={};
            buffer_now=obj.buffer;
            currentPtr_now=obj.currentPtr;
            TS_now=obj.bufferTS;
            currentReadPtr_now=obj.currentReadPtr;
            
            idx_subject_all=1:obj.SubjectNum;
            idx_subject_all=setdiff(idx_subject_all,obj.TriggerLoc(:,2));
            for idx_subject=idx_subject_all
                for idx_sensor=1:obj.SensorNum
                    %���ٶ��룬�ж�����ȡ����
                    if currentReadPtr_now(idx_sensor,idx_subject)<=currentPtr_now(idx_sensor,idx_subject)
                        data_out{idx_sensor,idx_subject} = [buffer_now{idx_sensor,idx_subject}(:,currentReadPtr_now(idx_sensor,idx_subject):(currentPtr_now(idx_sensor,idx_subject)-1))];
                        TS_Out{idx_sensor,idx_subject} = [TS_now{idx_sensor,idx_subject}(:,currentReadPtr_now(idx_sensor,idx_subject):(currentPtr_now(idx_sensor,idx_subject)-1))];
                    else
                        data_out{idx_sensor,idx_subject} = [buffer_now{idx_sensor,idx_subject}(:, currentReadPtr_now(idx_sensor,idx_subject):end),...
                            buffer_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                        TS_Out{idx_sensor,idx_subject} = [TS_now{idx_sensor,idx_subject}(:, currentReadPtr_now(idx_sensor,idx_subject):end),...
                            TS_now{idx_sensor,idx_subject}(:,1:(currentPtr_now(idx_sensor,idx_subject)-1))];
                    end
                    obj.currentReadPtr(idx_sensor,idx_subject)=currentPtr_now(idx_sensor,idx_subject);
                end
                
            end
            for idx_trigger=1:size(obj.TriggerLoc,1)
                %����trg���ݣ�Ҫô�����������trg������ʱ��������
                TS_Out_Trigger=[];
                data_out_Trigger=[];%Trgͨ�������
                
                TS_Trg_now=obj.bufferTS{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};%��ǰtrg��ʱ���
                TS_TrgOut_now=obj.TS_TrgOut;
                if TS_Trg_now(end)~=0
                    if TS_TrgOut_now==0
                        %trgʱ����Ѿ����£����Ƕ�ָ���ʱ�����û�н��е�һ�ζ�ȡ������ȫ0
                        %��ô�����ǰbuffer�е�ȫ�����ݣ��Լ���Ӧ��ʱ���
                        data_out_Trigger=obj.buffer{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};
                        obj.TS_TrgOut=TS_Trg_now(end);
                        TS_Out_Trigger=obj.bufferTS{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};
                    elseif TS_TrgOut_now>0&&TS_TrgOut_now<TS_Trg_now(1)
                        %��ָ�����0��С��tiggerʱ�������Сֵ����Ҫ�������
                        data_out_Trigger=obj.buffer{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)};
                        data_out_Trigger=[zeros(1,TS_Trg_now(1)-TS_TrgOut_now-1) data_out_Trigger];
                        obj.TS_TrgOut=TS_Trg_now(end);
                        TS_Out_Trigger=TS_TrgOut_now+1:TS_Trg_now(end);
                    elseif TS_TrgOut_now>TS_Trg_now(1)&&TS_TrgOut_now<TS_Trg_now(end)
                        loc_TS_TrgOut=find(TS_Trg_now==TS_TrgOut_now);
                        data_out_Trigger=obj.buffer{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)}(loc_TS_TrgOut+1:end);
                        obj.TS_TrgOut=TS_Trg_now(end);
                        TS_Out_Trigger=TS_TrgOut_now+1:TS_Trg_now(end);
                    end
                end
                
                data_out{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)}=data_out_Trigger;
                TS_Out{obj.TriggerLoc(idx_trigger,1),obj.TriggerLoc(idx_trigger,2)}=TS_Out_Trigger;
            end
            %}
        end
        
        function Reset(obj)
            bufferMid=obj.buffer;
            for idx_subject=1:obj.SubjectNum 
                for idx_sensor=1:obj.SensorNum
                    bufferMid{idx_sensor,idx_subject} = zeros(size(bufferMid{idx_sensor,idx_subject})); 
                end
            end
            obj.buffer = bufferMid;
            
            obj.currentPtr = ones(size(obj.currentPtr));
            obj.nUpdate = zeros(size(obj.nUpdate));

        end
        function ResetnUpdate(obj)
            obj.nUpdate = zeros(size(obj.nUpdate));
        end
        function ClearTrigger100(obj, idxSensor,idxSubject,idxTrigger)

%             idx = find(obj.buffer{idxSensor,1} >=100);
            idx = find(obj.buffer{idxSensor,idxSubject} >=100);
%             disp(['��ǰ����100λ��' num2str(idx) '����ֵΪ��' num2str(obj.buffer{idxSensor,idxSubject}(idx))])
            if length(idx)>idxTrigger||(length(idx)==idxTrigger&&idx(1)<obj.nPoint/3)
                idxNew = [idx(idx>=obj.currentPtr(idxSensor,idxSubject)) idx(idx<obj.currentPtr(idxSensor,idxSubject))] ;
%                 disp(['��ǰ����100λ�ã�����' num2str(idxNew)])
                obj.buffer{idxSensor,idxSubject}(end,idxNew(idxTrigger))=0 ;
                
            end
            idx = find(obj.buffer{idxSensor,idxSubject} >=100);
%             disp(['��ǰ����100λ�ã�ɾ����' num2str(idx)  '����ֵΪ��' num2str(obj.buffer{idxSensor,idxSubject}(idx))])
        end

        function ClearTrigger(obj, idxSensor)
            obj.buffer{idxSensor,1}(end,:)=zeros(1,length(obj.buffer{idxSensor,1})) ;
        end
        
    end
    
end