classdef simBEATS_data_provider 
    properties
        
        inputFolderLocation             % Folder that stores the BEATS simulation file
        outputFolderLocation            % Folder that outputs the processed files
        
        listSections                 % List of sections
        timePeriod                   % Time period: [start_time, end_time] in seconds
    end
    
    methods ( Access = public )

        function [this]=simBEATS_data_provider(inputFolderLocation, outputFolderLocation,listSections, timePeriod)
            %% This function is to obtain the BEATS simulation data
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.BEATS_temp;
            this.outputFolderLocation=findFolder.outputs;
            
            if(nargin>=1)
                this.inputFolderLocation=inputFolderLocation; % Get the input folder
            elseif(nargin>=2)
                this.outputFolderLocation=outputFolderLocation; % Get the output folder
            elseif(nargin>=3)
                this.listSections=listSections; % Get the list of sections
            elseif(nargin==4)
                this.timePeriod=timePeriod; % Get the time period
            elseif(nargin>4)
                error('Too many inputs!')
            end
        end
         
        function [data_out]=get_data_for_a_date(this,listOfLinks, queryMeasures)
            %% This function is to get data for a particular date and time
            
            % Get all parameters
            if(isempty(listOfLinks))
                error('No link list!')
            end
                 
            % Get the data format for the BEATS link
            dataFormat=simBEATS_data_provider.dataFormatBEATSLink;
            
            % Get the number of links
            numOfLinks=length(listOfLinks);
            data_out=[];
            % First read the data file
            for i=1:numOfLinks
                linkID=char(listOfLinks(i));
                
                % Load data file
                dataFile=fullfile(this.inputFolderLocation,sprintf('BEATS_simulation_link_%s.mat',linkID));
                if(exist(dataFile,'file')) % If found
                    load(dataFile); % Inside: dataBEATSLinkResult
                    
                    dateID=sprintf('%d-%d-%d',queryMeasures.day,queryMeasures.month,queryMeasures.year); % DD-MM-YY
                    tmp_data=dataBEATSLinkResult(ismember([dataBEATSLinkResult.Date]',dateID),:);
                    if(isempty(tmp_data)) % Data for that day not found
                        data_out=[data_out;struct(...
                            'linkID', linkID,...
                            'data',dataFormat,...
                            'status',{'No Data'})];
                    else
                        if(queryMeasures.timeOfDay(end)>0) % Return time of day's data
                            startTime=queryMeasures.timeOfDay(1);
                            endTime=queryMeasures.timeOfDay(2);
                            
                            tmp_time=hour({tmp_data.Time}')*3600+minute({tmp_data.Time}')*60+second({tmp_data.Time}');
                            idx=(tmp_time>=startTime & tmp_time<endTime);
                            
                            time=tmp_time(idx);
                            data=vertcat(tmp_data.Result);
                            densityMean=[data.DensityMean]';
                            densityStdDev=[data.DensityStdDev]';
                            velocityMean=[data.VelocityMean]';
                            velocityStdDev=[data.VelocityStdDev]';
                            inflowMean=[data.InflowMean]';
                            inflowStdDev=[data.InflowStdDev]';
                            outflowMean=[data.OutflowMean]';
                            outflowStdDev=[data.OutflowStdDev]';                            
                            data=simBEATS_data_provider.dataFormatBEATSLink...
                                (time,densityMean(idx),densityStdDev(idx),velocityMean(idx),...
                                velocityStdDev(idx),inflowMean(idx),inflowStdDev(idx),outflowMean(idx), outflowStdDev(idx));
                            
                        end
                        data_out=[data_out;struct(...
                            'linkID', linkID,...
                            'data',data,...
                            'status',{'Good Data'})];
                    end
                else
                    disp(sprintf('Missing the data file for link ID:%s\n',(linkID)));  
                    data_out=[data_out;struct(...
                            'linkID', linkID,...
                            'data',dataFormat,...
                            'status',{'No Data'})];
                end
            end            
        end
        
        function [data_out]=clustering(this,listOfLinks, queryMeasures)
            %% This function is for data clustering
            
            % Get all parameters
            if(isempty(listOfLinks))
                error('No link list!')
            end
                 
            % Get the data format for the BEATS link
            dataFormat=simBEATS_data_provider.dataFormatBEATSLink;
            
            % Get the number of links
            numOfLinks=length(listOfLinks);
            data_out=[];
            
            % First read the data file
            for i=1:numOfLinks
                linkID=char(listOfLinks(i));
                
                % Load data file
                dataFile=fullfile(this.inputFolderLocation,sprintf('BEATS_simulation_link_%s.mat',linkID));
                if(exist(dataFile,'file')) % If found
                    load(dataFile); % Inside: dataBEATSLinkResult
                    
                    [tmp_data,status]=simBEATS_data_provider.cluster_data_by_query_measures(dataBEATSLinkResult,queryMeasures);
                    data_out=[data_out;struct(...
                        'linkID', linkID,...
                        'data',tmp_data,...
                        'status',status)];
                else
                    disp(sprintf('Missing the data file for link ID:%s\n',(linkID)));
                    data_out=[data_out;struct(...
                        'linkID', linkID,...
                        'data',dataFormat,...
                        'status',{'No Data'})];
                end
            end            
        end
        
    end
   
    methods(Static)
        
        function [dataFormat]=dataFormatBEATSLink(time,densityMean,densityStdDev,velocityMean,velocityStdDev,inflowMean,inflowStdDev,outflowMean, outflowStdDev)
            %% This function is used to return the structure of data
            
            if(nargin==0)
                dataFormat=struct(...
                    'Time',                    nan,...
                    'DensityMean',             nan,...
                    'DensityStdDev',           nan,...
                    'VelocityMean',            nan,...
                    'VelocityStdDev',          nan,...
                    'InflowMean',              nan,...
                    'InflowStdDev',            nan,...
                    'OutflowMean',             nan,...
                    'OutflowStdDev',           nan);
            else
                dataFormat=struct(...
                    'Time',                    time,...
                    'DensityMean',             densityMean,...
                    'DensityStdDev',           densityStdDev,...
                    'VelocityMean',            velocityMean,...
                    'VelocityStdDev',          velocityStdDev,...
                    'InflowMean',              inflowMean,...
                    'InflowStdDev',            inflowStdDev,...
                    'OutflowMean',             outflowMean,...
                    'OutflowStdDev',           outflowStdDev);
            end
        end
        
        
        function [data_out, status]=cluster_data_by_query_measures(dataFile,queryMeasures)
            %% This function is to cluster the data by query measures
            
            % Get the data format for the BEATS link
            dataFormat=simBEATS_data_provider.dataFormatBEATSLink;
            
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
            
            dates=datenum({dataFile.Date}');
            years=year({dataFile.Date}');
            months=month({dataFile.Date}'); 
            times=hour({dataFile.Time}')*3600+minute({dataFile.Time}')*60+second({dataFile.Time}');

            % By year?
            if (byYear>0)
                idx=(years==byYear);
                dataFile=dataFile(idx,:);
                months=months(idx);
                days=days(idx);
                times=times(idx);
                clear idx
            end
            
            % By month?
            if (byMonth>0)
                idx=(months==byMonth);
                dataFile=dataFile(idx,:);
                times=times(idx);
                clear idx
            end
            
            % By day of week? Weekday? Weekend?
            if (dayOfWeek>0)
                if(dayOfWeek==8) % Weekday
                    idx=(weekday(dates)==1 | weekday(dates)==7);
                    idx=(idx==0);
                elseif(dayOfWeek==9) % Weekend
                    idx=(weekday(dates)==1 | weekday(dates)==7);
                else % day of week
                    idx=(weekday(dates)==dayOfWeek);
                end
                dataFile=dataFile(idx,:);
                times=times(idx);
                clear idx
            end
            
            % Using median values
            if(queryMeasures.median)
                useMedian=1;
            else
                useMedian=0;
            end
                        
            if (isempty(dataFile)) % No corresponding data
                data_out=dataFormat;
                status={'No Data'};
            else               
                data=vertcat(dataFile.Result);
                densityMean=[data.DensityMean]';
                densityStdDev=[data.DensityStdDev]';
                velocityMean=[data.VelocityMean]';
                velocityStdDev=[data.VelocityStdDev]';
                inflowMean=[data.InflowMean]';
                inflowStdDev=[data.InflowStdDev]';
                outflowMean=[data.OutflowMean]';
                outflowStdDev=[data.OutflowStdDev]';
                
                data_out=simBEATS_data_provider.get_time_of_day_data(times,densityMean,densityStdDev,velocityMean,...
                    velocityStdDev,inflowMean,inflowStdDev,outflowMean, outflowStdDev,timeOfDay,useMedian);
                if(isnan(data_out.Time))
                    status={'No Data'};
                else
                    status={'Good Data'};
                end
            end
            
        end

        function [data_out]=get_time_of_day_data(time,densityMean,densityStdDev,velocityMean,...
                    velocityStdDev,inflowMean,inflowStdDev,outflowMean, outflowStdDev,timeOfDay,useMedian)
            %% This function is to get the data for time of day
             
            if(size(data,1)==1) % Only one day
                if(timeOfDay(end)>0) % Return time of day's data
                    startTime=timeOfDay(1);
                    endTime=timeOfDay(2);
                    
                    idx=(time>=startTime & time<endTime);
                    time=time(idx);
                end
                
                if(isempty(time))
                    data_out=simBEATS_data_provider.dataFormatBEATSLink;
                else
                    data_out=simBEATS_data_provider.dataFormatBEATSLink(time,densityMean,densityStdDev,velocityMean,...
                        velocityStdDev,inflowMean,inflowStdDev,outflowMean, outflowStdDev);
                end
                
            else % Have multiple days
                tmp_time=sort(unique(time));                
                tmp_densityMean=zeros(size(time));
                tmp_densityStdDev=zeros(size(time));
                tmp_velocityMean=zeros(size(time));
                tmp_velocityStdDev=zeros(size(time));
                tmp_inflowMean=zeros(size(time));
                tmp_inflowStdDev=zeros(size(time));
                tmp_outflowMean=zeros(size(time));
                tmp_outflowStdDev=zeros(size(time));
            
                if(useMedian) % Use the median values
                    for i=1:length(time)
                        idx=(time==tmp_time(i));
                        tmp_densityMean(i)=median(densityMean(idx));
                        tmp_densityStdDev(i)=median(densityStdDev(idx));
                        tmp_velocityMean(i)=median(velocityMean(idx));
                        tmp_velocityStdDev(i)=median(velocityStdDev(idx));
                        tmp_inflowMean(i)=median(inflowMean(idx));
                        tmp_inflowStdDev(i)=median(inflowStdDev(idx));
                        tmp_outflowMean(i)=median(outflowMean(idx));
                        tmp_outflowStdDev(i)=median(outflowStdDev(idx));                     
                    end
                  
                else
                    for i=1:length(time)
                        idx=(time==tmp_time(i));
                        tmp_densityMean(i)=mean(densityMean(idx));
                        tmp_densityStdDev(i)=mean(densityStdDev(idx));
                        tmp_velocityMean(i)=mean(velocityMean(idx));
                        tmp_velocityStdDev(i)=mean(velocityStdDev(idx));
                        tmp_inflowMean(i)=mean(inflowMean(idx));
                        tmp_inflowStdDev(i)=mean(inflowStdDev(idx));
                        tmp_outflowMean(i)=mean(outflowMean(idx));
                        tmp_outflowStdDev(i)=mean(outflowStdDev(idx));                     
                    end
                end
                
                if(timeOfDay(end)>0) % Return time of day's data
                    startTime=timeOfDay(1);
                    endTime=timeOfDay(2);
                    
                    idx=(tmp_time>=startTime & tmp_time<endTime);
                    tmp_time=tmp_time(idx);
                    tmp_densityMean=tmp_densityMean(idx);
                    tmp_densityStdDev=tmp_densityStdDev(idx);
                    tmp_velocityMean=tmp_velocityMean(idx);
                    tmp_velocityStdDev=tmp_velocityStdDev(idx);
                    tmp_inflowMean=tmp_inflowMean(idx);
                    tmp_inflowStdDev=tmp_inflowStdDev(idx);
                    tmp_outflowMean=tmp_outflowMean(idx);
                    tmp_outflowStdDev=tmp_outflowStdDev(idx);
                end
                
                if(isempty(tmp_time))
                    data_out=simBEATS_data_provider.dataFormatBEATSLink;
                else
                    data_out=simBEATS_data_provider.dataFormatBEATSLink(tmp_time,tmp_densityMean,tmp_densityStdDev,tmp_velocityMean,...
                        tmp_velocityStdDev,tmp_inflowMean,tmp_inflowStdDev,tmp_outflowMean, tmp_outflowStdDev);
                end
            end
        end
    
    end

end

