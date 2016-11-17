classdef load_simSignal_data
    properties
        folderLocation          % Location of the folder that stores the simVehicle data files
        outputFolderLocation    % Location of the output folder

        fileList                % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_simSignal_data(folder,outputFolder)
            % This function is to load the simVehicle data file
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
            else
                % Default folder location
                this.folderLocation=findFolder.aimsunSimSignal_data;
                this.outputFolderLocation=findFolder.temp_aimsun;
            end   
            
            tmp=dir(this.folderLocation);
            this.fileList=tmp(3:end);
            
        end
        
        function [data]=parse_txt(this,file, location)
            % This function is to parse the txt file of signal phasing
            % inputs
            
            dataFormat=load_simSignal_data.dataFormat;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
                      
            tline=fgetl(fileID); % Ignore the first line
            
            data=[];
            
            tline=fgetl(fileID); % Starting from the second line
            while ischar(tline)
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                simStartTime=str2double(tmp{1,1}{1,1});
                dataFormat.TimeStamp=str2double(tmp{1,1}{2,1});
                dataFormat.JunctionID=str2double(tmp{1,1}{3,1});
                dataFormat.ControlType=str2double(tmp{1,1}{4,1});
                dataFormat.CurrentPhase=str2double(tmp{1,1}{5,1});
                dataFormat.NumberOfRings=str2double(tmp{1,1}{6,1});
                
                StartTimeOfRings=[];
                for i=1:dataFormat.NumberOfRings
                    StartTimeOfRings=[StartTimeOfRings,dataFormat.TimeStamp+(str2double(tmp{1,1}{6+i,1})-simStartTime)];
                end
                dataFormat.StartTimeOfRings=StartTimeOfRings; 
                
                data=[data;dataFormat];
                tline=fgetl(fileID);
            end

        end
        
         
        function save_data(this,data)
            %This function is used to save the data based on the junction
            %IDs
            
            % Get the list of junctions
            junctions=unique([data.JunctionID]');
            numJunctions=length(junctions);
            
            % Loop for each junction
            for i=1:numJunctions
                junctionAll=[data.JunctionID]';
                
                idx=ismember(junctionAll,junctions(i));
                datajunction=data(idx,:); % Select data for a given section
                
                % Get the file name
                fileName=fullfile(this.outputFolderLocation,sprintf('SimSig_Junction_%d.mat',junctions(i)));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName); % Variable: 'vehSectionAll'   
                    sigJunctionAll=[sigJunctionAll;datajunction];
                    
                    sigMatrix=[[sigJunctionAll.TimeStamp]',[sigJunctionAll.JunctionID]',[sigJunctionAll.ControlType]',...
                        [sigJunctionAll.CurrentPhase]',[sigJunctionAll.NumberOfRings]'];
                    [~,ia,~]=unique(sigMatrix,'rows');
                    sigJunctionAll=sigJunctionAll(ia,:); % Get unique values
                else    
                    % If it is the first time
                    sigJunctionAll=datajunction;                    
                end
                
                % Save the health report
                save(fileName,'sigJunctionAll');                
            end
            
        end
        
%         function save_data_by_approach(this,data)
%             
%             [loc_pair,numPair]=load_bluetooth_data.get_unique_loc_pair({data.Location_A}',{data.Location_B}');
%             
%             for i=1:numPair
%                 idx=(ismember({data.Location_A}',loc_pair(i,1)) & ismember({data.Location_B}',loc_pair(i,2)));
% 
%                 data_loc=data(idx,:);
%                 
%                 % Get the file name
%                 fileName=fullfile(this.outputFolderLocation,sprintf('Bluetooth_%s_%s.mat',loc_pair{i,1},loc_pair{i,2}));
%                 
%                 if(exist(fileName,'file')) % If the file exists
%                     load(fileName);    
%                     bluetoothAll=[bluetoothAll;data_loc];   
%                 else    
%                     % If it is the first time
%                     bluetoothAll=data_loc;                    
%                 end
%                 
%                 % Save the health report
%                 save(fileName,'bluetoothAll');                
%             end
%             
%         end
%         
    end
    
     methods ( Static)
         
%          function [loc_pair,numPair]=get_unique_loc_pair(loc_A,loc_B)
%             % This function is to get unique pairs of [location_A, Location_B]
%             
%             % Check the length of inputs
%             if(length(loc_A)~=length(loc_B))
%                 error('Wrong inputs: the lengths are not matched!')
%             end
%             
%             % Get the number of rows
%             numRow=size(loc_A,1);
%             
%             % Get the first row
%             loc_pair=[loc_A(1),loc_B(1)];
%             numPair=1;
%             
%             for r=2:numRow % Loop from Row 2 to the end
%                 % Search
%                 
%                 symbol=(ismember(loc_A(r),loc_pair(:,1)) & ismember(loc_B(r),loc_pair(:,2)));
%                 
% %                 for i=1:numPair
% %                     symbol=0; % Initially, set to zero
% %                     % Compare cell strings
% %                     if(strcmp(loc_A(r),loc_pair(i,1)) && strcmp(loc_B(r),loc_pair(i,2)))
% %                         symbol=1; % Find duplicated rows
% %                         break;
% %                     end
% %                 end
%                 if(symbol==0) % Find a new one
%                     loc_pair=[loc_pair;[loc_A(r),loc_B(r)]];
%                     numPair=numPair+1;
%                 end
%             end
%          end
%         
         
         function [dataFormat]=dataFormat
             % This function is used to return the structure of data format
             
             dataFormat=struct(...
                'TimeStamp',                 nan,...
                'JunctionID',                nan,...
                'ControlType',               nan,...
                'CurrentPhase',              nan,...
                'NumberOfRings',             nan,...
                'StartTimeOfRings',          nan);
         end
         
     end
end

