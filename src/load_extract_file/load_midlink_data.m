classdef load_midlink_data
    properties
        folderLocation          % Location of the folder that stores the midlink data files
        outputFolderLocation    % Location of the output folder
        
        interval                % Time interval inside the data
        
        fileList                % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_midlink_data(folder,outputFolder,interval)
            % This function is to load the midlink data files
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
                this.interval=interval;
            else
                % Default folder location
                this.folderLocation=findFolder.midlink_count;
                this.outputFolderLocation=findFolder.temp;
                this.interval=900; % in seconds
            end   
            
            tmp=dir(this.folderLocation);
            this.fileList=tmp(3:end);

        end
        
        function [data]=parse_txt(this,file)
            % This function is to parse the txt file with both string and number inputs
            % The data has a specific format
            
            location=this.folderLocation;
            
            % Get the location
            address=strfind(file,'_');
            link_location=file(1:address(end)-1);
            
            % Open the file
            fileID = fopen(fullfile(location,file));

            tline=fgetl(fileID); % Ignore the first line
            
            % Get the date
            tline=fgetl(fileID); % Get the second line
            str=strsplit(tline); % Split strings
            date=datestr(str{end});
            
            % Ignore the third line
            tline=fgetl(fileID);
            
            % Get the approach
            tline=fgetl(fileID); % Get the fourth line
            str=strsplit(tline); % Split strings
            approach_A=str{2};
            approach_B=str{3};
            
            % Get the AM and PM setting
            tline=fgetl(fileID); % Get the fifth line
            str=strsplit(tline); % Split strings
            period_A=str{2};
            period_B=str{3};
            
            data=load_midlink_data.dataFormat;            
            tline=fgetl(fileID); % Starting from the sixth line
            count=1;
            while ischar(tline)
                
                % Example: 
                %                 12:00 5 11 46 153 5 13 61 275 10 24 107 428
                %                 12:15 1 41 1 74 2 115
                %                 12:30 5 35 5 64 10 99
                %                 12:45 0 31 2 76 2 107
                %                 01:00 1 3 46 183 2 4 67 319 3 7 113 502
                symbol=mod(count,4);
                
                str=strsplit(tline,' '); % Split strings
                
                % Get the time in seconds
                hr_A=hour(strcat(str{1},period_A));
                mm_A=minute(strcat(str{1},period_A));
                time_A=hr_A*3600+mm_A*60;
                
                hr_B=hour(strcat(str{1},period_B));
                mm_B=minute(strcat(str{1},period_B));
                time_B=hr_B*3600+mm_B*60;
                
                
                if(symbol==1) % The first time step of each hour
                    volume_app_A_time_A=str{2};
                    volume_app_A_time_B=str{4};
                    volume_app_B_time_A=str{6};
                    volume_app_B_time_B=str{8};    
                else
                    volume_app_A_time_A=str{2};
                    volume_app_A_time_B=str{3};
                    volume_app_B_time_A=str{4};
                    volume_app_B_time_B=str{5};   
                end
                
                data((count-1)*4+1,1)=load_midlink_data.dataFormat(link_location,approach_A,date,time_A,volume_app_A_time_A);
                data((count-1)*4+2,1)=load_midlink_data.dataFormat(link_location,approach_A,date,time_B,volume_app_A_time_B);
                data((count-1)*4+3,1)=load_midlink_data.dataFormat(link_location,approach_B,date,time_A,volume_app_B_time_A);
                data((count-1)*4+4,1)=load_midlink_data.dataFormat(link_location,approach_B,date,time_B,volume_app_B_time_B);
                
                count=count+1;
                tline=fgetl(fileID);
            end
            
            % Close the file
            fclose(fileID);
        end
        
        function save_data(this,data)
            
            [loc_app_pair,numPair]=load_midlink_data.get_unique_loc_app_pair({data.Location}',{data.Approach}');
            
            for i=1:numPair
                idx=(sum(ismember([{data.Location}',{data.Approach}'],loc_app_pair(i,:)),2)==2);
                
                % Change the volume from 15 minutes to houly
                data_loc_app=[[data(idx).DateNum]',[data(idx).Time]',[data(idx).Volume]'*3600/this.interval];
                
                % Get the file name
                fileName=fullfile(this.outputFolderLocation,sprintf('Midlink_%s_%s.mat',loc_app_pair{i,1},loc_app_pair{i,2}));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);    
                    dataAll=[dataAll;data_loc_app];                    
                    dataAll=unique(dataAll,'rows');
                else    
                    % If it is the first time
                    dataAll=data_loc_app;                    
                end
                
                % Save the health report
                save(fileName,'dataAll');
                
            end
            
        end
    end
    
     methods ( Static)
         function [loc_app_pair,numPair]=get_unique_loc_app_pair(loc,app)
            % This function is to get unique pairs of [location, approach]
            
            % Check the length of inputs
            if(length(loc)~=length(app))
                error('Wrong inputs: the lengths are not matched!')
            end
            
            % Get the number of rows
            numRow=size(loc,1);
            
            % Get the first row
            loc_app_pair=[loc(1),app(1)];
            numPair=1;
            
            for r=2:numRow % Loop from Row 2 to the end
                % Search
                for i=1:numPair
                    symbol=0; % Initially, set to zero
                    % Compare cell strings
                    if(strcmp(loc(r),loc_app_pair(i,1)) && strcmp(app(r),loc_app_pair(i,2)))
                        symbol=1; % Find duplicated rows
                        break;
                    end
                end
                if(symbol==0) % Find a new one
                    loc_app_pair=[loc_app_pair;[loc(r),app(r)]];
                    numPair=numPair+1;
                end
            end
         end
        
         function [dataFormat]=dataFormat(link_location,approach_A,date,time_A,volume_app_A_time_A)
             % This function is used to return the structure of data format
             if(nargin==0)
                 dataFormat=struct(...
                     'Location',           nan,...
                     'Approach',           nan,...
                     'Date',               nan,...
                     'DateNum',            nan,...
                     'Time',               nan,...
                     'Volume',             str2double(nan));
             else                 
                 dataFormat=struct(...
                     'Location',           link_location,...
                     'Approach',           approach_A,...
                     'Date',               date,...
                     'DateNum',            datenum(date),...
                     'Time',               time_A,...
                     'Volume',             str2double(volume_app_A_time_A));
             end
         end
         
     end
end

