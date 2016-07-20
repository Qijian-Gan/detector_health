classdef load_turning_count_data
    properties
        folderLocation          % Location of the folder that stores the turning counts
        outputFolderLocation    % Location of the output folder
        
        interval                % Time interval inside the data
        
        fileList                % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_turning_count_data(folder,outputFolder,interval)
            % This function is to load the turning count data files
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
                this.interval=interval;
            else
                % Default folder location
                this.folderLocation=findFolder.turning_count;
                this.outputFolderLocation=findFolder.temp;
                this.interval=900; % in seconds
            end
            
            tmp=dir(this.folderLocation);
            this.fileList=tmp(3:end);
            
        end
        
        function [data]=parse_csv(this,file)
            % This function is to parse the csv file with both string and number inputs
            % The data has a specific format
            
            location=this.folderLocation;
            
            % Get the intersection name: the intersection name should be
            % the same as the one in the detector configuration file
            address=strfind(file,'.');
            intersectionName=file(1:address(end)-1);
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            % Get the approach links
            tline=fgetl(fileID); % Get the first line
            str=strsplit(tline,','); % Split strings
            link_A=strrep(str(1),' ', '_');
            link_B=strrep(str(2),' ', '_');
            
            % Get the direction
            tline=fgetl(fileID); % Get the second line
            str=strsplit(tline,','); % Split strings
            direction_A_for_link_A=str(1);
            direction_B_for_link_A=str(2);
            direction_A_for_link_B=str(3);
            direction_B_for_link_B=str(4);
            
            tline=fgetl(fileID); % Ignore the third line
            
            data=load_turning_count_data.dataFormat;
            tline=fgetl(fileID); % Starting from the fourth line
            count=1;
            while ischar(tline)
                
                % Example:
                % 4/13/2006	7:00	AM	25	53	29	13	22	6	2	59	2	8	215	12	446
                
                str=strsplit(tline,','); % Split strings
                
                % Date
                date=str(1);
                % Time
                hr=hour(strcat(str{2},str{3}));
                mm=minute(strcat(str{2},str{3}));
                time=hr*3600+mm*60;
                
                data((count-1)*4+1,1)=load_turning_count_data.dataFormat...
                    (intersectionName,link_A,direction_A_for_link_A,date,time,str(4),str(5),str(6));
                data((count-1)*4+2,1)=load_turning_count_data.dataFormat...
                    (intersectionName,link_A,direction_B_for_link_A,date,time,str(7),str(8),str(9));
                data((count-1)*4+3,1)=load_turning_count_data.dataFormat...
                    (intersectionName,link_B,direction_A_for_link_B,date,time,str(10),str(11),str(12));
                data((count-1)*4+4,1)=load_turning_count_data.dataFormat...
                    (intersectionName,link_B,direction_B_for_link_B,date,time,str(13),str(14),str(15));
                
                count=count+1;
                tline=fgetl(fileID);
            end
            
            % Close the file
            fclose(fileID);
        end
        
        function save_data(this,data)
            
            [int_app_dir_pair,numPair]=load_turning_count_data.get_unique_int_app_dir_pair...
                ({data.IntersectionName}',{data.RoadName}',{data.Direction}');
            
            for i=1:numPair
                idx=(sum(ismember([{data.IntersectionName}',{data.RoadName}',{data.Direction}'],...
                    int_app_dir_pair(i,:),'rows'),2)==3);
                
                % Change the volume from 15 minutes to houly
                data_loc_app_dir=[[data(idx).DateNum]',[data(idx).Time]',[data(idx).VolumeLeft]'*3600/this.interval,...
                    [data(idx).VolumeThrough]'*3600/this.interval,[data(idx).VolumeRight]'*3600/this.interval];
                
                % Get the file name
                fileName=fullfile(this.outputFolderLocation,sprintf('TP_%s_%s_%s.mat',...
                    int_app_dir_pair{i,1},int_app_dir_pair{i,2},int_app_dir_pair{i,3}));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);
                    dataAll=[dataAll;data_loc_app_dir];
                    dataAll=unique(dataAll,'rows');
                else
                    % If it is the first time
                    dataAll=data_loc_app_dir;
                end
                
                % Save the health report
                save(fileName,'dataAll');
                
            end
            
        end
    end
    
    methods ( Static)
        function [int_app_dir_pair,numPair]=get_unique_int_app_dir_pair(int,app, dir)
            % This function is to get unique pairs of [intersection, approach, direction]
            
            % Check the length of inputs
            if(length(int)~=length(app) || length(int)~=length(dir) || length(int)~=length(dir))
                error('Wrong inputs: the lengths are not matched!')
            end
            
            % Get the number of detectors/rows
            numRow=size(int,1);
            
            % Get the first row
            int_app_dir_pair=[int(1),app(1),dir(1)];
            numPair=1;
            
            for r=2:numRow % Loop from Row 2 to the end
                % Search
                for i=1:numPair
                    symbol=0; % Initially, set to zero
                    % Compare cell strings
                    if(strcmp(int(r),int_app_dir_pair(i,1)) && strcmp(app(r),int_app_dir_pair(i,2)) &&...
                            strcmp(dir(r),int_app_dir_pair(i,3)))
                        symbol=1; % Find duplicated rows
                        break;
                    end
                end
                if(symbol==0) % Find a new one
                    int_app_dir_pair=[int_app_dir_pair;[int(r),app(r),dir(r)]];
                    numPair=numPair+1;
                end
            end
        end
        
        function [dataFormat]=dataFormat(intersectionName,link,direction,date,time,volume_left,volume_through,volume_right)
            % This function is used to return the structure of data format
            if(nargin==0)
                dataFormat=struct(...
                    'IntersectionName',   nan,...
                    'RoadName',           nan,...
                    'Direction',          nan,...
                    'Date',               nan,...
                    'DateNum',            nan,...
                    'Time',               nan,...
                    'VolumeLeft',         str2double(nan),...
                    'VolumeThrough',      str2double(nan),...
                    'VolumeRight',        str2double(nan));
            else
                dataFormat=struct(...
                    'IntersectionName',   intersectionName,...
                    'RoadName',           link,...
                    'Direction',          direction,...
                    'Date',               date,...
                    'DateNum',            datenum(date),...
                    'Time',               time,...
                    'VolumeLeft',         str2double(volume_left),...
                    'VolumeThrough',      str2double(volume_through),...
                    'VolumeRight',        str2double(volume_right));
            end
        end
        
    end
end

