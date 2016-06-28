classdef data_clustering 
    properties
        
        inputFolderLocation             % Folder that stores the processed data files
        outputFolderLocation            % Folder that outputs the clustered files
        
        listOfDetectors                 % List of detectors
        queryMeasures                   % Measures of the query:
                                        % year, month, day of week, time of
                                        % day, average/distribution
    end
    
    methods ( Access = public )

        function [this]=data_clustering(inputFolderLocation, outputFolderLocation,listOfDetectors, queryMeasures)
            % This function is to do the data clustering
            
            % Obtain inputs
            if nargin==0 % Default input and output folders
                this.inputFolderLocation=findFolder.temp;
                this.outputFolderLocation=findFolder.outputs;
            else
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
                    [tmp_data,status]=data_clustering.cluster_data_by_query_measures(processed_data,dataAll,queryMeasures);
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
                byYear=quaryMeasures.year; % Get the year
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
            
            % By day of week?
            if (dayOfWeek>0)
                idx=(weekday(report(:,5))==dayOfWeek);
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
            
            if (isempty(report)) % No corresponding data
                data_out=DetectorDataProfile;
                status={'No Data'};
            else
                % Only use healthy data
                idx=(report(:,end)==1);
                
                if (sum(idx)==0) % No good data
                    data=vertcat(dataFile(1:end).data);
                    
                    data_out=data_clustering.get_time_of_day_data(data,timeOfDay,useMedian);                    
                    status={'Bad Data'};
                else % Have good data
                    dataFile=dataFile(idx,:);
                    report=report(idx,:);
                    
                    data=vertcat(dataFile(1:end).data);
                    
                    data_out=data_clustering.get_time_of_day_data(data,timeOfDay,useMedian);                    
                    status={'Good Data'};
                end
            end
            
        end

        function [data_out]=get_time_of_day_data(data,timeOfDay,useMedian)
            % This function is to get the data for time of day
            
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
                        tmp_occupancy=[tmp_occupancy,mean(occupancy(idx,i),'omitnan')]; 
                        tmp_speed=[tmp_speed,mean(speed(idx,i),'omitnan')];
                        tmp_delay=[tmp_delay,mean(delay(idx,i),'omitnan')];
                        tmp_stops=[tmp_stops,mean(stops(idx,i),'omitnan')];
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

                idx1=(tmp_time>=startTime);
                idx2=(tmp_time<endTime);
                idx=(idx1+idx2==2);
                
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

