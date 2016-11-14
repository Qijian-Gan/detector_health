classdef load_simVehicle_data
    properties
        folderLocation          % Location of the folder that stores the simVehicle data files
        outputFolderLocation    % Location of the output folder

        fileList                % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_simVehicle_data(folder,outputFolder)
            % This function is to load the bluetooth data file
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
            else
                % Default folder location
                this.folderLocation=findFolder.simVehicle_data;
                this.outputFolderLocation=findFolder.temp;
            end   
            
            tmp=dir(this.folderLocation);
            this.fileList=tmp(3:end);
            
        end
        
        function [data]=parse_csv(this,file, location)
            % This function is to parse the csv file with only number
            % inputs
            
            % Open the file
            tmp_data=csvread(fullfile(location,file),1,0); % Skip the header
            
            % Get wrong simulated vehicles
            idx=(tmp_data(:,6)<0 | tmp_data(:,9)==0 |tmp_data(:,10)==0 ); % Lane ID not negative, OD ID greater than zero
            wrong_veh=unique(tmp_data(idx,2)); % Get the set of wrong simulated vehicles
            clear idx
            
            % Remove wrong vehicles
            idx=ismember(tmp_data(:,2),wrong_veh);
            data=tmp_data(~idx,:);

        end
        
         
        function save_data(this,data)
            
            sections=unique(data(:,4));
            numSections=length(sections);
            
            
            for i=1:numSections
                idx=(data(:,4)==sections(i));
                dataSection=data(idx,:);
                
                % Get the file name
                fileName=fullfile(this.outputFolderLocation,sprintf('SimVeh_Section_%d.mat',sections(i)));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);    
                    vehSectionAll=[vehSectionAll;dataSection];
                    vehSectionAll=unique(vehSectionAll,'rows');
                else    
                    % If it is the first time
                    vehSectionAll=dataSection;                    
                end
                
                % Save the health report
                save(fileName,'vehSectionAll');                
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
                'Time',                 nan,...
                'VehicleID',            nan,...
                'Type',                 nan,...
                'SectionID',            nan,...
                'SegmentID',            nan,...
                'LaneID',               nan,...
                'Distance2End',         nan,...
                'CurrentSpeed',         nan,...
                'CentroidOrigin',       nan,...
                'CentriodDestination',  nan,...
                'StatusLeft',           nan,...
                'StatusRight',          nan,...
                'StatusStop',           nan);
         end
         
     end
end

