classdef sensor_count_provider 
    properties
        
        inputFolderLocation             % Folder that stores the processed data files
        outputFolderLocation            % Folder that outputs the clustered files
        
        listOfDetectors                 % List of detectors
        queryMeasures                   % Measures of the query:
                                        % year, month, day, day of week, time of
                                        % day, average/median
    end
    
    methods ( Access = public )

        function [this]=sensor_count_provider(inputFolderLocation, outputFolderLocation,listOfDetectors, queryMeasures)
            %% This function is to obtain the sensor data
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.temp;
            this.outputFolderLocation=findFolder.outputs;
            
            if(nargin>=1)
                this.inputFolderLocation=inputFolderLocation; % Get the input folder
            elseif(nargin>=2)
                this.outputFolderLocation=outputFolderLocation; % Get the output folder
            elseif(nargin>=3)
                this.listOfDetectors=listOfDetectors; % Get the list detectors
            elseif(nargin==4)
                this.queryMeasures=queryMeasures; % Get the query measures
            elseif(nargin>4)
                error('Too many inputs!')
            end
        end
         
        function [data_out]=get_data_for_a_date(this,listOfDetectors, queryMeasures)
            % This function is to get data for a particular date
            
            % Get all parameters
            if(isempty(listOfDetectors))
                error('No detector list!')
            end
                 
            % Get the number of detectors
            numOfDetectors=length(listOfDetectors);
            data_out=[];
            % First read the data file
            for i=1:numOfDetectors
                detectorID=char(listOfDetectors(i));
                
                % Load data file and health report
                dataFile=fullfile(this.inputFolderLocation,sprintf('Processed_data_%s.mat',detectorID));
                healthReport=fullfile(this.inputFolderLocation,sprintf('Health_Report_%s.mat',detectorID));
                if(exist(dataFile,'file')&& exist(healthReport,'file'))
                    load(dataFile); % Inside: processed_data
                    load(healthReport); % Inside: dataAll
                    
                    dateID=datenum(sprintf('%d-%d-%d',queryMeasures.year,queryMeasures.month,queryMeasures.day));
                    tmp_data=processed_data(([processed_data.day]==dateID),:);
                    tmp_health=dataAll(dataAll(:,5)==dateID,end);
                    if(isempty(tmp_data)) % Data for that day not found
                        data_out=[data_out;struct(...
                            'detectorID', detectorID,...
                            'data',DetectorDataProfile,...
                            'status',{'No Data'})];
                    else
                        if(tmp_health==1) % Health status
                            status={'Good Data'};
                        else
                            status={'Bad Data'};
                        end
                        
                        if(queryMeasures.timeOfDay(end)>0) % Return time of day's data
                            startTime=queryMeasures.timeOfDay(1);
                            endTime=queryMeasures.timeOfDay(2);
                            
                            tmp_time=tmp_data.data.time;
                            idx1=(tmp_time>=startTime);
                            idx2=(tmp_time<endTime);
                            idx=(idx1+idx2==2);
                            
                            tmp_data.data.time=tmp_data.data.time(idx);
                            tmp_data.data.s_volume=tmp_data.data.s_volume(idx);
                            tmp_data.data.s_occupancy=tmp_data.data.s_occupancy(idx);
                            tmp_data.data.s_speed=tmp_data.data.s_speed(idx);
                            tmp_data.data.s_delay=tmp_data.data.s_delay(idx);
                            tmp_data.data.s_stops=tmp_data.data.s_stops(idx);
                        end
                        data_out=[data_out;struct(...
                        'detectorID', detectorID,...
                        'data',tmp_data.data,...
                        'status',status)];
                    end
                else
                    disp(sprintf('Missing either the data file or the health report for detector ID:%s\n',(detectorID)));  
                    data_out=[data_out;struct(...
                        'detectorID', detectorID,...
                        'data',DetectorDataProfile,...
                        'status',{'No Data'})];
                end
            end            
        end
        
        function [data_out]=clustering(this,listOfDetectors, queryMeasures)
            % This function is for data clustering
            
            % Get all parameters
            if(isempty(listOfDetectors))
                error('No detector list!')
            end
                 
            % Get the number of detectors
            numOfDetectors=length(listOfDetectors);
            data_out=[];
            % First read the data file
            for i=1:numOfDetectors
                detectorID=char(listOfDetectors(i));
                
                % Load data file and health report
                dataFile=fullfile(this.inputFolderLocation,sprintf('Processed_data_%s.mat',detectorID));
                healthReport=fullfile(this.inputFolderLocation,sprintf('Health_Report_%s.mat',detectorID));
                if(exist(dataFile,'file')&& exist(healthReport,'file'))
                    load(dataFile); % Inside: processed_data
                    load(healthReport); % Inside: dataAll
                    [tmp_data,status]=sensor_count_provider.cluster_data_by_query_measures(processed_data,dataAll,queryMeasures);
                    data_out=[data_out;struct(...
                        'detectorID', detectorID,...
                        'data',tmp_data,...
                        'status',status)];
                else
                    disp(sprintf('Missing either the data file or the health report for detector ID:%s\n',(detectorID)));  
                    data_out=[data_out;struct(...
                        'detectorID', detectorID,...
                        'data',DetectorDataProfile,...
                        'status',{'No Data'})];
                end
            end            
        end
        
    end
   
    methods(Static)
        function [data_out, status]=cluster_data_by_query_measures(dataFile,healthReport,queryMeasures)
            % This function is to cluster the data by query measures
            
            if(~isnan(queryMeasures.year))
                byYear=queryMeasures.year; % Get the year
            else
                byYear=0; % False
            end
            if(~isnan(queryMeasures.month))
                byMonth=queryMeasures.month; % Get the Month
            else
                byMonth=0; % False
            end
            
            if(~isnan(queryMeasures.dayOfWeek))
                dayOfWeek=queryMeasures.dayOfWeek; % Get the number of day: Sunday=1; ... Saturday=7
            else
                dayOfWeek=0; % False
            end
            
            if(~isnan(queryMeasures.timeOfDay))
                % Get the time of day interval in seconds: [beginTime, endTime]
                timeOfDay=queryMeasures.timeOfDay;
            else
                timeOfDay=0; % False
            end
            
            days=[dataFile.day]';
            
            % Find the health report for the available days
            [tf,idx]=ismember(days,healthReport(:,5));
            report=healthReport(idx,:); % Re-organize the health report according to the sequence of days in the data file
            
            % By year?
            if (byYear>0)
                idx=(report(:,2)==byYear);
                dataFile=dataFile(idx,:);
                report=report(idx,:);
                clear idx
            end
            
            % By month?
            if (byMonth>0)
                idx=(report(:,3)==byMonth);
                dataFile=dataFile(idx,:);
                report=report(idx,:);
                clear idx
            end
            
            % By day of week? Weekday? Weekend?
            if (dayOfWeek>0)
                if(dayOfWeek==8) % Weekday
                    idx=(weekday(report(:,5))==1 | weekday(report(:,5))==7);
                    idx=(idx==0);
                elseif(dayOfWeek==9) % Weekend
                    idx=(weekday(report(:,5))==1 | weekday(report(:,5))==7);
                else % day of week
                    idx=(weekday(report(:,5))==dayOfWeek);
                end
                dataFile=dataFile(idx,:);
                report=report(idx,:);
                clear idx
            end
            
            % Using median values
            if(queryMeasures.median)
                useMedian=1;
            else
                useMedian=0;
            end
            
            %% There may be more than 288 points
            idx=[];
            for i=1:size(dataFile,1)
                if(size(dataFile(i).data.time,2)~=288)
                    idx=[idx;false];
                else
                    idx=[idx;true];
                end
            end   
            dataFile=dataFile(logical(idx),:);
            report=report(logical(idx),:);
            
            if (isempty(report)) % No corresponding data
                data_out=DetectorDataProfile;
                status={'No Data'};
            else
                % Only use healthy data
                idx=(report(:,end)==1);
                
                if (sum(idx)==0) % No good data                    
                    data=vertcat(dataFile(1:end).data);
                    
                    data_out=sensor_count_provider.get_time_of_day_data(data,timeOfDay,useMedian);                    
                    status={'Bad Data'};
                else % Have good data
                    dataFile=dataFile(idx,:);
                    report=report(idx,:);
                    
                    data=vertcat(dataFile(1:end).data);
                    
                    data_out=sensor_count_provider.get_time_of_day_data(data,timeOfDay,useMedian);                    
                    status={'Good Data'};
                end
            end
            
        end

        function [data_out]=get_time_of_day_data(dataIn,timeOfDay,useMedian)
            % This function is to get the data for time of day
            
            % Due to the small bug in detector health, there exist some
            % days with duplicated observations (more than 288 observations)
            data=[];
            for i=1:size(dataIn,1)
                if(length(dataIn(i,1).time)==288)
                    data=[data;dataIn(i)];
                end
            end
            
            if(size(data,1)==1) % Only one day
                tmp_time=data(1).time;
                tmp_volume=(vertcat(data.s_volume));
                tmp_occupancy=(vertcat(data.s_occupancy));
                tmp_speed=(vertcat(data.s_speed));
                tmp_delay=(vertcat(data.s_delay));
                tmp_stops=(vertcat(data.s_stops));
            else % Have multiple days
                tmp_time=data(1).time;
                if(useMedian) % Use the median values
                    volume=vertcat(data.s_volume);
                    occupancy=vertcat(data.s_occupancy);
                    speed=vertcat(data.s_speed);
                    delay=vertcat(data.s_delay);
                    stops=vertcat(data.s_stops);
                    
                    tmp_volume=median(volume,'omitnan'); % Get the median values for volume
                    tmp_occupancy=[];
                    tmp_speed=[];
                    tmp_delay=[];
                    tmp_stops=[];
                    
                                       
                    for i=1:size(tmp_volume,2) % Loop for each timestamp  
                        first_val=nan;
                        second_val=nan; 
                        idx=(volume(:,i)==tmp_volume(i)); % Find the index that has the same volume
                        if(sum(idx)==0)                            
                            tmp=sort(volume(:,i));
                            symbol1=0;
                            symbol2=0;
                            
                            for t=1:length(tmp)
                                if(tmp(t)>=tmp_volume(i) && symbol2==0)
                                    second_val=tmp(t);
                                    symbol2=1;
                                end
                                if(tmp(end-t+1)<=tmp_volume(i) && symbol1==0)
                                    first_val=tmp(end-t+1);
                                    symbol1=1;
                                end
                            end
                            idx1=(volume(:,i)==first_val);
                            idx2=(volume(:,i)==second_val);                            
                            idx=(idx1+idx2>0);
                        end
                                    
                        % Take the mean value of occupancy, speed, delay,
                        % and stops
                        if(sum(idx)==0 &&(isnan(first_val)||isnan(second_val)))
                            tmp_occupancy=[tmp_occupancy,nan];
                            tmp_speed=[tmp_speed,nan];
                            tmp_delay=[tmp_delay,nan];
                            tmp_stops=[tmp_stops,nan];
                        else
                            tmp_occupancy=[tmp_occupancy,mean(occupancy(idx,i),'omitnan')];
                            tmp_speed=[tmp_speed,mean(speed(idx,i),'omitnan')];
                            tmp_delay=[tmp_delay,mean(delay(idx,i),'omitnan')];
                            tmp_stops=[tmp_stops,mean(stops(idx,i),'omitnan')];
                        end
                    end
                else
                    tmp_volume=mean(vertcat(data.s_volume),'omitnan');
                    tmp_occupancy=mean(vertcat(data.s_occupancy),'omitnan');
                    tmp_speed=mean(vertcat(data.s_speed),'omitnan');
                    tmp_delay=mean(vertcat(data.s_delay),'omitnan');
                    tmp_stops=mean(vertcat(data.s_stops),'omitnan');
                end
            end
            
            if(timeOfDay(end)>0) % Return time of day's data
                startTime=timeOfDay(1);
                endTime=timeOfDay(2);

                idx=(tmp_time>=startTime & tmp_time<endTime);
%                 idx1=(tmp_time>=startTime);
%                 idx2=(tmp_time<endTime);
%                 idx=(idx1+idx2==2);
                
                time=tmp_time(idx);
                s_volume=tmp_volume(idx);
                s_occupancy=tmp_occupancy(idx);
                s_speed=tmp_speed(idx);
                s_delay=tmp_delay(idx);
                s_stops=tmp_stops(idx);
                
                data_out=DetectorDataProfile(time,s_volume,s_occupancy,s_speed, s_delay, s_stops);
                
            else % Return a whole day's data               
                data_out=DetectorDataProfile(tmp_time,tmp_volume,tmp_occupancy,tmp_speed, tmp_delay, tmp_stops);
            end
        end
    
    end
end

