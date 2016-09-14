classdef extract_clustered_data 
    properties
        
        inputFolderLocation             % Folder that stores the processed data files
        outputFolderLocation            % Folder that outputs the clustered files

    end
    
    methods ( Access = public )

        function [this]=extract_clustered_data(inputFolderLocation, outputFolderLocation)
            % This function is to extract the clustered data into a particular
            % model input
            
            % Obtain inputs
            if nargin==0 % Default input and output folders
                this.inputFolderLocation=findFolder.outputs;
                this.outputFolderLocation=findFolder.outputs;
            else
                if(nargin>=1)
                    this.inputFolderLocation=inputFolderLocation; % Get the input folder
                elseif(nargin>=2)
                    this.outputFolderLocation=outputFolderLocation; % Get the output folder
                elseif(nargin>2)
                    error('Too many inputs!')
                end                    
            end             
        end
         
        function extract_to_aimsun_by_day_of_week(this,daynum)
            % This function is to extract to aimsun
            
            day={'Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'};
            
            inputFileName=fullfile(this.inputFolderLocation,sprintf('Clustered_data_%s.mat',day{daynum}));
            outputFileName=fullfile(this.inputFolderLocation,sprintf('Aimsun_data_%s.csv',day{daynum}));
            
            if(exist(inputFileName,'file'))
                load(inputFileName);
                
                data_status={clustered_data.status}';
                
                idx=ismember(data_status,{'Good Data'});                
                data_good=clustered_data(idx,:);
                
                % Start to write data to a csv file
                fileID = fopen(outputFileName,'w');
                
                fprintf(fileID,'Detector ID,Time,count (#/5min),volume(vph),occupancy (sec/hr),speed,delay,stops\n');
                time=data_good(1).data.time;
                interval=time(end)-time(end-1);
                
                for i=1:length(time)
                    % Get the time String
                    t=time(i)+interval;
                    hour=floor(t/3600);
                    if(hour<10)
                        hour_str=strcat('0',num2str(hour));
                    else
                        hour_str=num2str(hour);
                    end
                    minute=floor(mod(t,3600)/60);                   
                    if(minute<10)
                        minute_str=strcat('0',num2str(minute));
                    else
                        minute_str=num2str(minute);
                    end
                    second=t-hour*3600-minute*60;
                    if(second<10)
                        second_str=strcat('0',num2str(second));
                    else
                        second_str=num2str(second);
                    end
                    timestring=sprintf('%s:%s:%s',hour_str,minute_str,second_str);
                    
                    for j=1:size(data_good,1)                        
                        fprintf(fileID,sprintf('%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n',data_good(j).detectorID,timestring,data_good(j).data.s_volume(i)/(3600/interval),...
                            data_good(j).data.s_volume(i),data_good(j).data.s_occupancy(i),...
                            data_good(j).data.s_speed(i),data_good(j).data.s_delay(i),data_good(j).data.s_stops(i)));
                    end                    
                end

                fclose(fileID);
            else
                error('No such a file!')
            end
            
        end
        
        function extract_scaled_approach_flow_to_aimsun_by_day_of_week(this,fileName,daynum,interval,type)
            % This function is to extract the scaled approach flow to aimsun
            
            day={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
            
            inputFileName=fullfile(this.inputFolderLocation,fileName);                     

            if(exist(inputFileName,'file'))
                load(inputFileName); % Inside 'appDataEvl'
                
                dayType=day{daynum};
                switch type
                    case 'Approach'
                        dataType='scaled_approach_flow';
                        movement=[];
                    case 'Left Turn'
                        dataType='scaled_left_turn_flow';
                        movement='L';
                    case 'Through'
                        dataType='scaled_through_flow';
                        movement='T';
                    case 'Right Turn'
                        dataType='scaled_right_turn_flow';
                        movement='R';
                end
            
                outputFileName=fullfile(this.inputFolderLocation,sprintf('Aimsun_data_%s_%s.csv',dataType,dayType));
                
                % Start to write data to a csv file
                fileID = fopen(outputFileName,'w');
                
                fprintf(fileID,'ID, Time, Scaled count (#/5min), Scaled volume(vph), Original volume (vph)\n');
                
                time=(interval:interval:24*3600);
                
                for i=1:length(time)
                    % Get the time String
                    t=time(i);
                    hour=floor(t/3600);
                    if(hour<10)
                        hour_str=strcat('0',num2str(hour));
                    else
                        hour_str=num2str(hour);
                    end
                    minute=floor(mod(t,3600)/60);                   
                    if(minute<10)
                        minute_str=strcat('0',num2str(minute));
                    else
                        minute_str=num2str(minute);
                    end
                    second=t-hour*3600-minute*60;
                    if(second<10)
                        second_str=strcat('0',num2str(second));
                    else
                        second_str=num2str(second);
                    end
                    timestring=sprintf('%s:%s:%s',hour_str,minute_str,second_str);
                    
                    for j=1:size(appDataEvl,1)  % Loop for all approaches
                        switch type
                            case 'Approach'
                                scaled_data=appDataEvl(j).data_evaluation.approach_volume.rescaled_flow(daynum).scaled_data;
                                raw_data=appDataEvl(j).data_evaluation.approach_volume.rescaled_flow(daynum).raw_data;                                
                            case 'Left Turn'
                                scaled_data=appDataEvl(j).data_evaluation.left_turn_volume.rescaled_flow(daynum).scaled_data;
                                raw_data=appDataEvl(j).data_evaluation.left_turn_volume.rescaled_flow(daynum).raw_data;
                            case 'Through'
                                scaled_data=appDataEvl(j).data_evaluation.through_volume.rescaled_flow(daynum).scaled_data;
                                raw_data=appDataEvl(j).data_evaluation.through_volume.rescaled_flow(daynum).raw_data;
                            case 'Right Turn'
                                scaled_data=appDataEvl(j).data_evaluation.right_turn_volume.rescaled_flow(daynum).scaled_data;
                                raw_data=appDataEvl(j).data_evaluation.right_turn_volume.rescaled_flow(daynum).raw_data;
                        end
                        
                        if(~isempty(scaled_data)) % If data is available
                            switch appDataEvl(j).city
                                case 'Arcadia'
                                    cityName='AR';
                                case 'Pasadena'
                                    cityName='PA';
                                otherwise
                                    error('Unknown city name!')
                            end
                            if(isempty(movement))
                                ID=sprintf('%s-%d-%s',cityName,appDataEvl(j).intersection_id,appDataEvl(j).direction);
                            else
                                ID=sprintf('%s_%d_%s_%s',cityName,appDataEvl(j).intersection_id,appDataEvl(j).direction,movement);
                            end
                            
                            idx=(scaled_data.time==t-interval);
                            scaled_flow=scaled_data.data(idx);
                            clear idx
                            idx=(raw_data.time==t-interval);
                            raw_flow=raw_data.data(idx);
                            clear idx
                            
                            fprintf(fileID,sprintf('%s,%s,%.2f,%.2f,%.2f\n',ID,timestring,scaled_flow/(3600/interval),...
                                scaled_flow,raw_flow));
                        end
                    end
                end

                fclose(fileID);
            else
                error('No such a file!')
            end
            
        end
    end
  
end

