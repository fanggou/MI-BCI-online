

%ʹ�÷���
%��118�����öϵ㣬
%׼����jellyfish����ת�������ڵ�������
%�� jellyfish ���ݼ�¼�����б�����
%������figure����ʵʱ���ݺ󣬿������ڵ������ֵ��ظ����ͣ�����һ��ʱ���ȡ���ظ�����
    %��ǰ�ű�ѭ����¼10s��10s���Ͽ����ӡ���10s��ֹͣ����trigger�����ܱ�֤NDF��¼��TCPIP��¼��trigger����һ��
    %����������trigger���������ڲ��죬������˶���������
%��ǰ�ű����е��ϵ������ֹͣjellyfish ���ݼ�¼������¼������ת��Ϊbdf��ʽ
    %NDF��ȡ������ܻ������⣬�����Ŷ�����trigger��������ʱ��bdf��ʽ
%��bdf����·�����浽BDFdatapath��ѡ�в����жϵ�֮��Ľű�

%% ����������Jellyfish����Э����º󣬶� ���ߴ������� �� ���ߴ洢���ݣ�NDF�� ��������һ���ԶԱ�
clear all;
clc;
close all;
instrreset;

deviceName = 'JellyFish';       % deviceName must be 'JellyFish'
nChan = 0;                      % default
srate = 0;                      % default

% Modify subject, sensor, and channel info in DataMesssage: required fields
subject_toshow='1';             % type the real subject name        
sensor_toshow='EEG';          
channel_toshow='T8';   

nDevice= 1;                     % type the number of device, default

ipData = '127.0.0.1';        % type IP address of the DataServer in JellyFish
portData = 8712;   

bufferSize = 7;                 % length of ringbuffer: 5s
datasaveflag=1;                 % whether save data to bin file or not

flag_cmpModuleSandC=1;
flag_cmpJellyfishSandC=1;

%% open data server
dataServer = DataServer(deviceName,nChan, ipData, portData, srate,datasaveflag,bufferSize);
dataServer.Open();

pause(1.5);                    % waiting 1.5s for creating inner buffer
DataMessage = dataServer.GetDataMessage();
MetaMessage = dataServer.GetMetaData();
%% save data online ȷ�����ݱ����ļ���
if datasaveflag==1
    timenow=datestr(now,'yyyymmdd-HHMMSS');
    filename={};
    datapath=['.\Data\' timenow];
    figurepath=['.\ResultFigure\' timenow];
    if ~isfolder(datapath)
        mkdir(datapath);
    end
    if ~isfolder(figurepath)
        mkdir(figurepath);
    end
    for idx_subject=1:length(DataMessage)
        for idx_senor=1:length(DataMessage(idx_subject).SensorName)
            Chan_num_now=length(DataMessage(idx_subject).SensorChannelName{1,idx_senor});
            filename{idx_senor,idx_subject} = [datapath '\' strcat('nbChan-',num2str(Chan_num_now,'%02d'),...
                '-','Subject',num2str(idx_subject,'%02d'),'-','Sensor',num2str(idx_senor,'%02d'),'-',timenow , '.txt')];
            filename_TS{idx_senor,idx_subject} = [datapath '\' strcat('TSnbChan-',num2str(1,'%02d'),...
                '-','Subject',num2str(idx_subject,'%02d'),'-','Sensor',num2str(idx_senor,'%02d'),'.txt')];
            fileID{idx_senor,idx_subject}= fopen(filename{idx_senor,idx_subject},'w');%����Ҫд����ļ��ṹ�崫�䵽dataParser
            fileTSID{idx_senor,idx_subject}= fopen(filename_TS{idx_senor,idx_subject},'w');
        end
    end
end


%% only obtain the latest data, without overlap signal
%ֻ�����������ݣ���������ȡringbuffer�е�ȫ�����ݣ�
idx_subject_toshow=find(contains({DataMessage(:).SubjectName},subject_toshow)==1);
idx_sensor_toshow=find(strcmp([DataMessage(idx_subject_toshow).SensorName],sensor_toshow)==1);
idx_sensor_toshow=idx_sensor_toshow(1);
idx_chan_toshow=find(strcmp([DataMessage(idx_subject_toshow).SensorChannelName{1,idx_sensor_toshow(1)}],channel_toshow)==1);

dataServer.ResetnUpdate;
pause(0.2);
rawdata_all=[];
figure;
for i = 1:100 %ѭ��
%     [raw_latest,data_out_Trigger] = dataServer.GetLatestData();%just the latest data  
    [raw_latest,~,raw_latest_TS,~] = dataServer.GetLatestData();%just the latest data  
%     raw_latest = dataServer.GetLatestRingbuffer();%just the latest data
    rawdata_plot=raw_latest{idx_sensor_toshow,idx_subject_toshow};
    
    if ~isempty(rawdata_plot)
        rawdata_all=[rawdata_all,rawdata_plot];
        plot(rawdata_plot(idx_chan_toshow,:))
        title(['Subject: ' subject_toshow '; Sensor: ' sensor_toshow '; Channel: ' channel_toshow])
        
    else
        disp('��ѭ��Ϊ��')
    end
    
    
    %Save the data to the corresponding file ѭ���ڼ䱣���Ӧ����
    if datasaveflag==1
        for idx_subject=1:size(raw_latest,2)
            for idx_senor=1:size(raw_latest,1)
                if ~isempty(fileID{idx_senor,idx_subject})
%                     fwrite(fileID{idx_senor,idx_subject},raw_latest{idx_senor,idx_subject},'float32',0,'ieee-le'); 
%                     fwrite(fileTSID{idx_senor,idx_subject},raw_latest_TS{idx_senor,idx_subject},'float32',0,'ieee-le'); 
                    fwrite(fileID{idx_senor,idx_subject},raw_latest{idx_senor,idx_subject},'double',0,'ieee-le'); 
                    fwrite(fileTSID{idx_senor,idx_subject},raw_latest_TS{idx_senor,idx_subject},'double',0,'ieee-le'); 

                end
            end
        end
    end
    pause(0.2);
end
close gcf
figure,plot(rawdata_all(idx_chan_toshow,:))

%close file
if datasaveflag==1
    for idx_subject=1:size(fileID,2)
        for idx_senor=1:size(fileID,1)
            if ~isempty(fileID{idx_senor,idx_subject})
                status = fclose(fileID{idx_senor,idx_subject});
                if status == -1
                    fprintf('failed to colse file .......\n');
                end
                status = fclose(fileTSID{idx_senor,idx_subject});
                if status == -1
                    fprintf('failed to colse file .......\n');
                end
            end
            
        end
    end
end


%% close data server
dataServer.Close();


%% �Ƿ���Ҫ�Ա�̽ͷ������������ݵ��ȶ���
if flag_cmpModuleSandC
    if ~isfolder([figurepath '\ת���ٶ��ȶ���'])
        mkdir([figurepath '\ת���ٶ��ȶ���']);
    end
    %FileName='G:\�������ά��\JellyFish_20230627_Dumpԭʼ���ݰ�ʱ���\Log-501\DumpAlertTimestamp_22053130_20230703_115744.csv';
    [FileName,PathName]=uigetfile('*.csv','�� DumpAlertTimestamp_ ��ͷ��CSV�ļ�');%     
    ModuleTS_client = readmatrix([PathName FileName],'Range','B:B');%���ն�ʱ�������msΪ��λ
    ModuleTS_server=readmatrix([PathName FileName],'Range','D:D');%���Ͷ�ʱ�������msΪ��λ
%     ModuleTS_client = Milliseconds(2:end);
%     ModuleTS_server=TimestampFPO(2:end);

    ModuleTS_server=ModuleTS_server-ModuleTS_server(1);
    ModuleTS_client=ModuleTS_client-ModuleTS_client(1);
    figure,plot(ModuleTS_client-ModuleTS_server)
    xlabel('���ݰ����')
    ylabel('���շ���ʱ��ms��')
    title('̽ͷ�ӷ�ʱ�����')
    saveas(gca,[figurepath '\ת���ٶ��ȶ���\̽ͷ�ӷ�ʱ�����.tiff'])
end

%% �Ƿ���Ҫ�Ա� Jellyfish ������ C# ���ݵ��ȶ���
if flag_cmpJellyfishSandC
    if ~isfolder([figurepath '\ת���ٶ��ȶ���'])
        mkdir([figurepath '\ת���ٶ��ȶ���']);
    end
    %% ��ȡJellyfish���Ͷ�����
    [FileName,PathName]=uigetfile('*.csv','�� DataTransferTimeStamp_SN ��ͷ��CSV�ļ�');%   �� DataTransferTimeStamp_SN ��ͷ���ļ�
    DateTime_server = readmatrix([PathName FileName],'Range','A:A', 'OutputType', 'string');%���ն�ʱ�������msΪ��λ
    pkgTS_server = readmatrix([PathName FileName],'Range','C:C');%���ն�ʱ�������msΪ��λ
    
    %ת��Ϊs
    JellyfishTS_server=[];
    for idx_time=2:size(DateTime_server,1)%���Ͷ˵�ʱ�䣬��Ҫת����ms
        DateTime_now=DateTime_server(idx_time,1);
        DateTime_now=char(DateTime_now);
        loc_colon=strfind(DateTime_now,':');
        DateTime_now_hour=str2num(DateTime_now(1:loc_colon(1)-1));
        DateTime_now_minute=str2num(DateTime_now(loc_colon(1)+1:loc_colon(2)-1));
        DateTime_now_second=str2num(DateTime_now(loc_colon(2)+1:loc_colon(3)-1));
        DateTime_now_msecond=str2num(DateTime_now(loc_colon(3)+1:end));
        JellyfishTS_server(idx_time)=3600*DateTime_now_hour+60*DateTime_now_minute+DateTime_now_second+DateTime_now_msecond/1000;
    end
    JellyfishTS_server(1)=[];%���Ͷ˵�ʱ��
    
    % Ҫ��¼���ݰ���ʱ���
    JellyfishPkgTS_server=pkgTS_server;
    JellyfishPkgTS_server(1,:)=[];
    
   
    %% matlab/C# ���ն�
    %������DataTransferTimeStamp_**client��ͷ��csv�ļ�����������֮��ʱ���
    %�ָ������е����⣬��Ҫ�ֶ��޸ı�������
    [FileName,PathName]=uigetfile('*.csv','����DataTransferTimeStamp_**client��csv�ļ�');%   
    DateTime_client = readmatrix([PathName FileName],'Range','A:A', 'OutputType', 'string');%���ն�ʱ�������msΪ��λ
    pkgTS_client = readmatrix([PathName FileName],'Range','C:C');%���ն�ʱ�������msΪ��λ
    
    JellyfishTS_client=[];
    for idx_time=2:size(DateTime_client,1)%���Ͷ˵�ʱ�䣬��Ҫת����ms
        DateTime_now=DateTime_client(idx_time,1);
        DateTime_now=char(DateTime_now);
        loc_colon=strfind(DateTime_now,':');
        DateTime_now_hour=str2num(DateTime_now(1:loc_colon(1)-1));
        DateTime_now_minute=str2num(DateTime_now(loc_colon(1)+1:loc_colon(2)-1));
        DateTime_now_second=str2num(DateTime_now(loc_colon(2)+1:loc_colon(3)-1));
        DateTime_now_msecond=str2num(DateTime_now(loc_colon(3)+1:end));
        JellyfishTS_client(idx_time)=3600*DateTime_now_hour+60*DateTime_now_minute+DateTime_now_second+DateTime_now_msecond/1000;
    end
    JellyfishTS_client(1)=[];%���Ͷ˵�ʱ��
    
    % Ҫ��¼���ݰ���ʱ���
    JellyfishPkgTS_client=pkgTS_client;
    JellyfishPkgTS_client(1,:)=[];
    


    %% ����ͼ��
    %����ʱ������ж���
    loc_cut=find(JellyfishPkgTS_server==JellyfishPkgTS_client(1));
    
    diff_Jellyfish=JellyfishTS_client-JellyfishTS_server(loc_cut:loc_cut+length(JellyfishTS_client)-1);
    diff_Jellyfish_mean=mean(diff_Jellyfish*1000);
    diff_Jellyfish_std=std(diff_Jellyfish*1000);
    
    figure,plot(diff_Jellyfish*1000)
    xlabel('���ݰ����')
    ylabel('���ݰ�������Ӧ�ý��յ�ʱ�䣨ms��')
    title(['Jellyfish��Ӧ��֮���ʱ��' num2str(diff_Jellyfish_mean) '��' num2str(diff_Jellyfish_std)])
    saveas(gca,[figurepath '\ת���ٶ��ȶ���\Jellyfish��Ӧ�ýӷ�ʱ���.tiff'])
end

%% �����������������ݵ�Triggerһ���ԶԱ�
close all
% ����NDF���������û��trigger��eventsΪ��
%����(д��BDF���ݵ�ַ)
BDFdatapath=uigetdir('D:\','ת��ΪBDF֮�������·��');
% BDFdatapath='G:\�������ά��\JellyFish_20230627_Dumpԭʼ���ݰ�ʱ���\Data\20230704093441_����601\20230704093441_����601';
EEG =  pop_importNeuracle([],BDFdatapath);

addpath('.\LibNDF4EEGLab')
% EEG = pop_importNDF;  
% [ChannelData,events] = ReadOneChannel('E:\�����ļ���\2023-01-13 JellyfishЭ�����\JellyFish-develop-20230427-bc96ec72\Data\20230515152314_0515_005',...
%     '���¾�ʿ',"TP8",0,20);    

Data_cmp_all={};
for idx_subject=1:size(filename,2)  % triggersubjectλ��δ֪�����ж�Ҫ�ԱȶԱ�
    subject_loc=find([MetaMessage(:).SubjectIdx]==idx_subject);
    for idx_senor=1:size(filename,1)
        if ~isempty(filename{idx_senor,idx_subject})
            filename_now =filename{idx_senor,idx_subject};
            
            channame_nowsensor=MetaMessage(subject_loc(1)).ChannelName_sort  {1, idx_senor} ;
            if ~strcmp(channame_nowsensor,'Trigger')
                continue
            end
            data_nowsensor_TCPIP= readSavedFile(filename_now);
            dataTS_nowsensor_TCPIP= readSavedFile(filename_TS{idx_senor,idx_subject});
%             data_nowsensor_TCPIP= readSavedFile('.\Data\20230628-131815\nbChan-01-Subject01-Sensor02-20230628-131815.txt');
%             dataTS_nowsensor_TCPIP= readSavedFile('.\Data\20230628-131815\TSnbChan-01-Subject01-Sensor02.txt');
            
            loc_trigger=find(data_nowsensor_TCPIP>0); % Trigger��
            loc_trigger_diff=diff(loc_trigger);%����trigger֮���ʱ����
            
            figure,histogram(loc_trigger_diff),
            title('TCPIP triggerʱ������ͳ��')
            loc_trigger_diff_mean=mean(loc_trigger_diff);
            loc_trigger_diff_std=std(loc_trigger_diff);
            disp(['TCPIP��ʱ����ֵΪ��' num2str(loc_trigger_diff_mean) 'ms������Ϊ��' num2str(loc_trigger_diff_std) 'ms'])
            
            
            loc_trigger2=[EEG.event(:).latency];
            loc_trigger_diff2=diff(loc_trigger2);%����trigger֮���ʱ����
            figure,histogram(loc_trigger_diff2)
            title('BDF triggerʱ������ͳ��')
            loc_trigger_diff_mean2=mean(loc_trigger_diff2);
            loc_trigger_diff_std2=std(loc_trigger_diff2);
            disp(['NDF��ʱ����ֵΪ��' num2str(loc_trigger_diff_mean) 'ms������Ϊ��' num2str(loc_trigger_diff_std) 'ms'])

            
            data_trigger1=zeros(1,loc_trigger(end)-loc_trigger(1));
            data_trigger1(loc_trigger-loc_trigger(1)+1)=2;
            TS_trigger1=dataTS_nowsensor_TCPIP(loc_trigger(1):loc_trigger(end));
            data_trigger2=zeros(1,loc_trigger2(end)-loc_trigger2(1)); 
            data_trigger2(loc_trigger2-loc_trigger2(1)+1)=1;
            
            %���������ݵȳ�
            Length_min=min(length(data_trigger1),length(data_trigger2));
            data_trigger1_cut=data_trigger1(1:Length_min);%���롢����������
            data_trigger2_cut=data_trigger2(1:Length_min);
%             Count_min=min(length(loc_trigger),length(loc_trigger2));
            try
%                 Time_diff=(loc_trigger(end)-loc_trigger(1))-(loc_trigger2(end)-loc_trigger2(1));
%                 Time_diff=(loc_trigger(1:Count_min)-loc_trigger(1))-...
%                     (loc_trigger2(1:Count_min)-loc_trigger2(1));%����ȫ�����룬���ĳ������trgȱʧ���򲻶���
                Time_diff=data_trigger1_cut./2-data_trigger2_cut;
                
                figure,plot(data_trigger1_cut),hold on,
                plot(data_trigger2_cut),plot(Time_diff*3)
                title(['TCPIP��NDF triggerʱ������ֵ��' num2str(mean(Time_diff)) '�����' num2str(std(Time_diff))])
                ylim([-3 3])
                legend('TCPIP','BDF','��������λ��')%,'Error Location'
                saveas(gca,[figurepath '\TCPIP��NDF��Triggerһ����.fig'])
                saveas(gca,[figurepath '\TCPIP��NDF��Triggerһ����.tiff'])
            catch
                disp('TCPIP��NDF��trigger������һ��')
            end
            
            break
        end
        
        
    end
end

%% �����������������ݵ�����һ���ԶԱ�
addpath('.\DataCmp')

%����ÿ��
folder =  uigetdir('*.*', 'ѡ��Jellyfish NDF�����ļ�����·��');
if isequal(folder,0)
    error('Cancel choosing a folder...');
end

Data_cmp_all={};
for idx_subject=1:size(filename,2)% triggersubjectλ��δ֪�����ж�Ҫ�ԱȶԱ�
    
    
    subject_loc=find([MetaMessage(:).SubjectIdx]==idx_subject);%��ǰ������ӵ�е�̽ͷ���
    for idx_senor=1:size(filename,1)
        
        SensorIdx_all={MetaMessage(:).SensorIdx};
        for idx_sensor2=1:length(SensorIdx_all)
            idx_senor_cell{1,idx_sensor2}=idx_senor;
        end
        sensor_loc1=cellfun(@ismember,idx_senor_cell,SensorIdx_all,'UniformOutput',false);
        sensor_loc2=find(cell2mat(sensor_loc1(subject_loc))==1);
        sensor_loc3=subject_loc(sensor_loc2);
        ModuleName_nowSensor=MetaMessage(sensor_loc3).ModuleName';
        ModuleName_nowSensor=strrep(ModuleName_nowSensor,native2unicode(0,'UTF-8'),'');
        
        if ~isempty(filename{idx_senor,idx_subject})
            filename_now =filename{idx_senor,idx_subject};
            
            channame_nowsensor=MetaMessage(subject_loc(1)).ChannelName_sort  {1, idx_senor} ;
            
            if strcmp(channame_nowsensor,'Trigger')
                continue
            end
            data_nowsensor_TCPIP= readSavedFile(filename_now);
            
            fs_nowsensor=MetaMessage(subject_loc(1)).SampleRates  (1, idx_senor) ;
            fs_nowsensor=double(fs_nowsensor);
            
            %���ڸ�sensor��ÿ��ͨ��
            if iscell(channame_nowsensor)
                channum=length(channame_nowsensor);
            else
                channum=1;
            end
            
            for idx_chan=1:channum
                if iscell(channame_nowsensor)
                    channame_nowsensor_now=channame_nowsensor{idx_chan};
                else
                    channame_nowsensor_now=channame_nowsensor;
                end
                
                channame_nowsensor_nowModule=[ModuleName_nowSensor '_' channame_nowsensor_now];
                [~,data_nowchan_NDF]=pop_importNDF(folder, ...
                    channame_nowsensor_now,idx_subject);
                [~,data_nowchan_NDFModule]=pop_importNDF(folder, ...
                    channame_nowsensor_nowModule,idx_subject);

                %����trigger�õ��Ĳο�λ�ã��ҵ����Ķ����
                % ����1000Hz������ʶ�𵽵Ķ����
                % loc_trigger(1)��TCPIP��loc_trigger2(1)��NDF
                loc_ref=loc_trigger(1)-loc_trigger2(1);
                loc_ref_time=loc_ref*fs_nowsensor/1000;

                if (~isempty(data_nowchan_NDF))&&(~isempty(data_nowchan_NDFModule))
                    [startPoint1,Data_epoch1,Diff_epoch1,Mean_Diff1,Var_diff1]=...
                        data_equal_cmp(data_nowsensor_TCPIP(idx_chan,:),data_nowchan_NDF,loc_ref_time);
                    [startPoint2,Data_epoch2,Diff_epoch2,Mean_Diff2,Var_diff2]=...
                        data_equal_cmp(data_nowsensor_TCPIP(idx_chan,:),data_nowchan_NDFModule,loc_ref_time);
                    
                    if abs(Mean_Diff1)<abs(Mean_Diff2)
                        startPoint=startPoint1;Data_epoch=Data_epoch1;Diff_epoch=Diff_epoch1;Mean_Diff=Mean_Diff1;Var_diff=Var_diff1;
                        Data_cmp_all{1,end+1}=Data_epoch;
                        Data_cmp_all{2,end}=channame_nowsensor_now;
                        Data_cmp_all{3,end}=startPoint;
                    else
                        startPoint=startPoint2;Data_epoch=Data_epoch2;Diff_epoch=Diff_epoch2;Mean_Diff=Mean_Diff2;Var_diff=Var_diff2;
                        Data_cmp_all{1,end+1}=Data_epoch;
                        Data_cmp_all{2,end}=channame_nowsensor_now;
                        Data_cmp_all{3,end}=startPoint;
                    end
                else
                    
                    % ���ɺ��������жԱ�
                    [startPoint,Data_epoch,Diff_epoch,Mean_Diff,Var_diff]=...
                        data_equal_cmp(data_nowsensor_TCPIP(idx_chan,:),data_nowchan_NDF,loc_ref_time);
                    Data_cmp_all{1,end+1}=Data_epoch;
                    Data_cmp_all{2,end}=channame_nowsensor_now;
                    Data_cmp_all{3,end}=startPoint;
                    
                end
                
                figure,plot(Data_epoch(1,:)),hold on,
                    plot(Data_epoch(2,:)),
                    legend('NDF','TCPIP')
                    xlabel('Data Point'),
                    ylabel('Amplitude(��V)')
                    title(['ͨ����' channame_nowsensor_now '������ֵ��' num2str(Mean_Diff) '�����' num2str(Var_diff)])
                
                saveas(gca,['.\ResultFigure\ResultFigure-Subject_' num2str(idx_subject) '-Sensor_' num2str(idx_senor) ...
                    '-Chan_' num2str(idx_chan) '.tiff'])
            end
        end
        
        
    end
end


%{
%% ����ʱ���ͳ�ƣ�ȫ̽ͷת��

TS_segment=unique(100*floor(TS_trigger1/100));
TriggerCount_TCPIP=[];
TriggerCount_Jellyfish=[];
for idx_TS_segment=1:length(TS_segment)
    Loc_segment=find(TS_trigger1>=TS_segment(idx_TS_segment)&TS_trigger1<(TS_segment(idx_TS_segment)+100));
    Num_trigger=find(data_trigger1(Loc_segment)>0);
    TriggerCount_TCPIP(idx_TS_segment)=length(Num_trigger);
    
    Num_trigger=find(data_trigger2_cut(Loc_segment)>0);
    TriggerCount_Jellyfish(idx_TS_segment)=length(Num_trigger);
end
%��C#ͳ�Ƶ� Trigger ���ݶ���
Loc_start=find(VarName3==TS_segment(1));
TriggerCount_C=Trigger(Loc_start:end);

% figure,plot(TriggerCount_TCPIP),hold on,
% plot(TriggerCount_C)
% plot(TriggerCount_Jellyfish)
% legend('TCPIP','C','Jellyfish')

figure,plot(TriggerCount_TCPIP),hold on,
plot(TriggerCount_Jellyfish)
legend('TCPIP','Jellyfish')

figure,plot(TriggerCount_C),hold on,
plot(TriggerCount_Jellyfish)
legend('C','Jellyfish')

%% ����ʱ���ͳ�ƣ���̽ͷת��
    %C#�Ľ���ͳ�������⣬���Բ�����Ϊ�ο�

%% ���ݴ����ٶȵ��ȶ���
%��ȡʱ�� DateTime
DateTime_seconds=[];
for idx_time=2:size(DateTime,1)
    DateTime_now=DateTime(idx_time,1);
    DateTime_now=char(DateTime_now);
    loc_colon=strfind(DateTime_now,':');
    DateTime_now_hour=str2num(DateTime_now(1:loc_colon(1)-1));
    DateTime_now_minute=str2num(DateTime_now(loc_colon(1)+1:loc_colon(2)-1));
    DateTime_now_second=str2num(DateTime_now(loc_colon(2)+1:loc_colon(3)-1));
    DateTime_now_msecond=str2num(DateTime_now(loc_colon(3)+1:end));
    DateTime_seconds(idx_time)=3600*DateTime_now_hour+60*DateTime_now_minute+DateTime_now_second+DateTime_now_msecond/1000;
end
DateTime_seconds(1)=[];
figure,plot(DateTime_seconds)

%}












