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
                        fprintf(fileID,sprintf('%s,%s,%.2f,%.2f,%.2f,%.2f,%.2f,%.2f\n',data_good(j).detectorID,timestring,data_good(j).data.s_volume(i)/12,...
                            data_good(j).data.s_volume(i),data_good(j).data.s_occupancy(i),...
                            data_good(j).data.s_speed(i),data_good(j).data.s_delay(i),data_good(j).data.s_stops(i)));
                    end                    
                end

                fclose(fileID);
            else
                error('No sucha a file!')
            end
            
        end
        
    end
  
end

