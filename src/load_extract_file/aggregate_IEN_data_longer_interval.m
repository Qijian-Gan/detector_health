classdef aggregate_IEN_data_longer_interval
    properties
        InputFolder                 % Location of the folder that stores the IEN raw data files
        OutputFolder                % Location of the output folder that stores the IEN processed data files
        
        FileList                    % File list of IEN raw data
        
        Interval                    % Aggregation interval
        StartDate                   % Starting time
        EndDate                     % Ending time
        Method                      % Method
    end
    
    methods ( Access = public )
        
        function [this]=aggregate_IEN_data_longer_interval(params)
            %% This function is to load the parameters that are used to aggregate the raw data
            
            this.Interval=params.Interval;
            this.StartDate=params.StartDate;
            this.EndDate=params.EndDate;
            this.Method=params.Method;
            
            switch params.InputFolder
                case 'Default'                    
                    this.InputFolder=fullfile(findFolder.IEN_temp(),'device_data');
                otherwise
                    this.InputFolder=params.InputFolder;
            end
            
            switch params.OutputFolder
                case 'Default'                    
                    this.OutputFolder=fullfile(findFolder.IEN_temp(),'device_data_aggregated');
                otherwise
                    this.OutputFolder=params.OutputFolder;
            end
            
            % Get the file list for IEN data
            tmpData=dir(this.InputFolder);
            idx=strmatch('Detector_Data',{tmpData.name});
            this.FileList=tmpData(idx,:);
            
        end
        
        function [this]=aggregation_by_default_interval(this)
            
            StartDateNum=datenum(this.StartDate);
            EndDateNum=datenum(this.EndDate);
            
            Dates=(StartDateNum:EndDateNum);
            
            YearMonths=num2str((year(Dates)*100+month(Dates))');       
            UniqueYearMonths=unique(YearMonths,'rows');
            
            for i=1:size(UniqueYearMonths,1) % Loop for each unique year-month
                
                % Get the selected dates
                idx=strmatch(UniqueYearMonths(i,:),YearMonths);                
                SelectedDates=Dates(idx);
                
                Year=year(SelectedDates(1));
                Month=month(SelectedDates(1));
                
                % Get the corresponding raw data files
                idxData=strmatch(sprintf('Detector_Data_%s',UniqueYearMonths(i,:)),({this.FileList.name}));
                SelectedDataFiles=this.FileList(idxData);

                for j=1:length(SelectedDataFiles)
                    % Loop for each data file: each file contains monthly data for a detector
                    disp(SelectedDataFiles(j).name);
                    
                    % Load the data file
                    load(SelectedDataFiles(j).name);
                    
                    % Find the dates inside the data file
                    formatIn='yyyy.mm.dd';
                    DateAll={dataDevData.Date}';
                    DateInData=datenum(DateAll(1:end,:),formatIn);
                    
                    % Get the Org and Detector IDs
                    StrList=strsplit(SelectedDataFiles(j).name,'_');                    
                    Org=StrList{1,4};                                            
                    StrList=strsplit(StrList{1,end},'.');
                    DetectorID=str2double(StrList{1,1});
                    
                    % Get the file name
                    fileName=fullfile(this.OutputFolder,...
                        sprintf('Data_By_%dSecond_%s_%d.mat',this.Interval,Org,DetectorID));
                    if(exist(fileName,'file'))
                        load(fileName);      
                    else
                        aggregatedData=[];
                    end
                   
                    [DataFormat]=aggregate_IEN_data_longer_interval.process_by_SelectedDates...
                        (dataDevData,DateInData,SelectedDates,this.Interval,this.Method,DetectorID,Year,Month);
                    
                    if(~isempty(DataFormat)) % If it is not empty                       
                        if(~isempty(aggregatedData)) % If aggregatedData is not empty
                            for t=1:size(DataFormat,1)
                                % Get the date
                                date=sprintf('%d-%d-%d',DataFormat(t).Year(1),DataFormat(t).Month(1),...
                                    DataFormat(t).Day(1));                                
                                
                                idx=ismember([aggregatedData.DateNum]',datenum(date));
                                
                                if(sum(idx)) % Find the corresponding date
                                    aggregatedData(idx).Data=DataFormat(t,:);
                                else % If not
                                    aggregatedData=[aggregatedData;struct(...
                                        'DetectorID',DetectorID,...
                                        'Date',date,...
                                        'DateNum', datenum(date),...
                                        'Data',DataFormat(t,:))];
                                end
                            end                         
                        else % If it is not empty
                            for t=1:size(DataFormat,1)
                                date=sprintf('%d-%d-%d',DataFormat(t).Year(1),DataFormat(t).Month(1),...
                                    DataFormat(t).Day(1));
                                aggregatedData=[aggregatedData;struct(...
                                    'DetectorID',DetectorID,...
                                    'Date',date,...
                                    'DateNum', datenum(date),...
                                    'Data',DataFormat(t,:))];
                            end                            
                        end
                    end  
                    save(fileName,'aggregatedData');                    
                end
            end
            
        end
        
       
    end
    
    methods (Static)
        
        function [DataFormat]=process_by_SelectedDates...
                (dataDevData,DateInData,SelectedDates,Interval,Method,DetectorID,Year,Month)
            %% This function is used to perform aggregation by SelectedDates
            
            DataFormat=[];
            parfor k=1:length(SelectedDates) % Loop for each selected day
                idx=(DateInData==SelectedDates(k));
                
                if(sum(idx)) % If find the corresponding date
                    Day=day(SelectedDates(k));
                    
                    RawData=dataDevData(idx).Data;
                    
                    [Time,Volume,Occupancy,Speed]=aggregate_IEN_data_longer_interval.from_raw_to_fixed_interval...
                        (Interval,Method,RawData);
                    
                    tmpDataFormat=aggregate_IEN_data_longer_interval.IENDataProfile...
                        (DetectorID,Year,Month,Day,Time,Speed,Occupancy,Volume);
                else
                    tmpDataFormat=[];
                end
                DataFormat=[DataFormat;tmpDataFormat];
            end     
        end
        
        function [Time,Volume,Occupancy,Speed]=from_raw_to_fixed_interval(Interval,Method,RawData)
            %% This function is used to convert raw data to fixed intervals
            
            if(Interval<60)
                disp('Too small aggregation interval! Return Nan values!')
                Time=nan;
                Volume=nan;
                Occupancy=nan;
                Speed=nan;
            elseif(isempty(RawData))
                disp('Empty raw data! Return Nan values!')
                Time=nan;
                Volume=nan;
                Occupancy=nan;
                Speed=nan;
            else
                SampleTime=(0:Interval:24*3600);
                SampleTime=SampleTime(1:end-1);
                
                % Get the raw time
                RawTimeString=char(strrep({RawData.Time}','.',':'));
                RawTimeSplit=datevec(RawTimeString(1:end,:),'HH:MM:SS');
                RawTime=RawTimeSplit(:,4)*3600+RawTimeSplit(:,5)*60+RawTimeSplit(:,6);
                
                [~,I]=unique(RawTime);
                RawData=RawData(I,:);
                RawTime=RawTime(I);
                RawSpeed=str2double({RawData.Speed}');
                RawOccupancy=str2double({RawData.Occupancy}');
                RawVolume=str2double({RawData.Volume}');

                switch Method
                    case 'Interpolation'
                        Time=[];
                        Volume=[];
                        Occupancy=[];
                        Speed=[];
                        
                        for i=1:length(SampleTime)
                            StartTime=SampleTime(i);
                            EndTime=SampleTime(i)+Interval;
                            
                            idx=(RawTime>=StartTime & RawTime<EndTime);
                            if(sum(idx)) % Sample exists
                                RawTimeSelected=RawTime(idx);
                                RawVolumeSelected=RawVolume(idx);
                                RawOccupancySelected=RawOccupancy(idx);
                                RawSpeedSelected=RawSpeed(idx);
                                
                                tmpTime=SampleTime(i);
                                if(sum(idx)==1) % Only one sample                                    
                                    tmpVolume=RawVolumeSelected;
                                    tmpOccupancy=RawOccupancySelected;
                                    tmpSpeed=RawSpeedSelected;                                    
                                else
                                    % Add one more point in the end
                                    RawTimeSelected=[StartTime;RawTimeSelected;EndTime];
                                    RawVolumeSelected=[0;RawVolumeSelected;RawVolumeSelected(end)];
                                    RawOccupancySelected=[0;RawOccupancySelected;RawOccupancySelected(end)];
                                    RawSpeedSelected=[0;RawSpeedSelected;RawSpeedSelected(end)];
                                    
                                    tmpVolume=0;
                                    tmpOccupancy=0;
                                    tmpSpeed=0;
                                    for j=2:length(RawTimeSelected)
                                        tmpVolume=tmpVolume+RawVolumeSelected(j)...
                                            *(RawTimeSelected(j)-RawTimeSelected(j-1))/Interval;
                                        tmpOccupancy=tmpOccupancy+RawOccupancySelected(j)...
                                            *(RawTimeSelected(j)-RawTimeSelected(j-1))/Interval;
                                        tmpSpeed=tmpSpeed+RawSpeedSelected(j)...
                                            *(RawTimeSelected(j)-RawTimeSelected(j-1))/Interval;
                                    end                                    
                                end
                                
                                Time=[Time,tmpTime];
                                Volume=[Volume,tmpVolume];
                                Occupancy=[Occupancy,tmpOccupancy];
                                Speed=[Speed,tmpSpeed];
                            end
                        end
                        
                    otherwise
                        disp('Undefined aggregation method! Return Nan values!')
                        
                        Time=nan;
                        Volume=nan;
                        Occupancy=nan;
                        Speed=nan;
                end
                
                
            end
            
            
                        
                        
        end
        function [DataFormat]=IENDataProfile(DetectorID,Year,Month,Day,Time,Speed,Occupancy,Volume)
            %% This function is to return the IEN data format
      
            if(nargin==0)
                DataFormat=struct(...
                    'DetectorID',   nan,...
                    'Year',         nan,...
                    'Month',        nan,...
                    'Day',          nan,...
                    ...
                    'Time',         nan,...
                    'Volume',       nan,...
                    'Occupancy',    nan,...
                    'Speed',        nan,... 
                    ...
                    'Delay',        nan,...
                    'Stops',        nan,...
                    'S_Volume',     nan,...
                    'S_Occupancy',  nan,...
                    'S_Speed',      nan,...
                    'S_Delay',      nan,...
                    'S_Stops',      nan);
            else
                DataFormat=struct(...
                    'DetectorID',   DetectorID*ones(size(Time)),...
                    'Year',         Year*ones(size(Time)),...
                    'Month',        Month*ones(size(Time)),...
                    'Day',          Day*ones(size(Time)),...
                    ...
                    'Time',         Time,...
                    'Volume',       Volume,...
                    'Occupancy',    Occupancy,...
                    'Speed',        Speed,... 
                    ...
                    'Delay',        nan(size(Time)),...
                    'Stops',        nan(size(Time)),...
                    'S_Volume',     nan(size(Time)),...
                    'S_Occupancy',  nan(size(Time)),...
                    'S_Speed',      nan(size(Time)),...
                    'S_Delay',      nan(size(Time)),...
                    'S_Stops',      nan(size(Time)));
            end
            
            
        end
    end
end

