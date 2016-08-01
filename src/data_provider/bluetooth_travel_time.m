classdef bluetooth_travel_time 
    properties
        
        inputFolderLocation             % Folder that stores the midblock counts

    end
    
    methods ( Access = public )

        function [this]=bluetooth_travel_time(inputFolderLocation)
            % This function is to obtain the bluetooth travel times
            
            % Obtain inputs
            if nargin==0 % Default input folder
                this.inputFolderLocation=findFolder.temp;
            else
                this.inputFolderLocation=inputFolderLocation; % Get the input folder
                if(nargin>1)
                    error('Too many inputs!')
                end
            end             
        end
         
        function [data_out]=get_data_for_a_date(this,fileName, queryMeasures, interval)
            % This function is to get data for a particular date
          
            % Load data file
            dataFile=fullfile(this.inputFolderLocation,fileName);
            
            data_out=[];
            if(exist(dataFile,'file'))
                load(dataFile); % Inside: dataAll
                dateID=datenum(sprintf('%d-%d-%d',queryMeasures.year,queryMeasures.month,queryMeasures.day));
                
                % Get data for that date
                dateID_A=datenum({bluetoothAll.Date_At_A}');
                dateID_B=datenum({bluetoothAll.Date_At_B}');
                
                idx=(dateID_A==dateID & dateID_B==dateID);
                data=bluetoothAll(idx,:);

                if(~isempty(data)) % Have data
                    time=(interval:interval:3600*24)';
                    travel_time=bluetooth_travel_time.aggregate_travel_time_by_interval(data,time);
                    
                    if(queryMeasures.timeOfDay(end)>0) % Return time of day's data
                        startTime=queryMeasures.timeOfDay(1);
                        endTime=queryMeasures.timeOfDay(2);
                        
                        idx=(time>=startTime & time <endTime);
                        
                        data_out.time=time(idx);
                        data_out.travel_time=travel_time(idx,:);
                    end
                end
            else
                fprintf('No such a data file:%s\n',fileName);
            end
        end
        
        function [data_out]=clustering(this,fileName, queryMeasures, interval)
            % This function is for data clustering
            
            % Load data file
            dataFile=fullfile(this.inputFolderLocation,fileName);
            
            data_out=[];
            if(exist(dataFile,'file'))
                load(dataFile); % Inside: dataAll                
                [data_out]=bluetooth_travel_time.cluster_data_by_query_measures(bluetoothAll,queryMeasures,interval);
            else
                fprintf('No such a data file:%s\n',fileName);
            end  
        end
        
    end
   
    methods(Static)
        function [travel_time]=aggregate_travel_time_by_interval(data,time)
            
            % Looking at time_at_B
            time_at_B=[data.Time_At_B]';
            
            interval=time(end)-time(end-1);
            
            travel_time=[];
            for i=1:length(time)
                endTime=time(i);
                startTime=endTime-interval;
                
                idx=(time_at_B>=startTime & time_at_B <endTime);
                
                tmp_travel_time=[data(idx).Travel_Time]';               

                if(~isempty(tmp_travel_time))
                    travel_time_mean=mean(tmp_travel_time,'omitnan');
                    travel_time_median=median(tmp_travel_time,'omitnan');
                else
                    travel_time_mean=[];
                    travel_time_median=[];                  
                end
                
                travel_time=[travel_time, struct(...
                    'travel_time_all', tmp_travel_time,...
                    'travel_time_mean', travel_time_mean,...
                    'travel_time_median', travel_time_median)];
            end      
        end
        
        function [data_out]=cluster_data_by_query_measures(dataFile,queryMeasures,interval)
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

            % By year?
            years=year({dataFile.Date_At_B})'; 
            if (byYear>0)
                idx=(years==byYear);
                dataFile=dataFile(idx,:);
                clear idx
            end
            
            % By month?
            months=month({dataFile.Date_At_B})';            
            if (byMonth>0)
                idx=(months==byMonth);
                dataFile=dataFile(idx,:);
                clear idx
            end
            
            % By day of week? Weekday? Weekend?
            days=weekday({dataFile.Date_At_B})';
            if (dayOfWeek>0)
                if(dayOfWeek==8) % Weekday
                    idx=(days==1 | days==7);
                    idx=(idx==0);
                elseif(dayOfWeek==9) % Weekend
                    idx=(days==1 | days==7);
                else % day of week
                    idx=(days==dayOfWeek);
                end
                dataFile=dataFile(idx,:);
                clear idx
            end

            if (isempty(dataFile)) % No corresponding data
                data_out=[];
            else
                time=(interval:interval:3600*24)';
                travel_time=bluetooth_travel_time.aggregate_travel_time_by_interval(dataFile,time);
                
                if(queryMeasures.timeOfDay(end)>0) % Return time of day's data
                    startTime=queryMeasures.timeOfDay(1);
                    endTime=queryMeasures.timeOfDay(2);
                    
                    idx=(time>=startTime & time <endTime);
                    
                    data_out.time=time(idx);
                    data_out.travel_time=travel_time(idx,:);
                end
            end            
        end
        
    end
end
