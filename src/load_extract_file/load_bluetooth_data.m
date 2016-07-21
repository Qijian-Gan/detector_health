classdef load_bluetooth_data
    properties
        folderLocation          % Location of the folder that stores the bluetooth data files
        outputFolderLocation    % Location of the output folder

        fileList                % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_bluetooth_data(folder,outputFolder)
            % This function is to load the bluetooth data file
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
            else
                % Default folder location
                this.folderLocation=findFolder.bluetooth_travel_time;
                this.outputFolderLocation=findFolder.temp;
            end   
            
            tmp=dir(this.folderLocation);
            this.fileList=tmp(3:end);
            
        end
        
        function [data]=parse_txt(this,file, location)
            % This function is to parse the txt file with both string and number inputs
            
            dataFormat=load_bluetooth_data.dataFormat;

            % Open the file
            fileID = fopen(fullfile(location,file));
                                  
            data=struct(dataFormat);
            
            tline=fgetl(fileID); % Starting from the first line
            count=0;
            while ischar(tline)
                
                % Example: ac2dc03908aef0cf00ea2f426aec8aa9	Huntington_Gateway	Huntington_SantaClara	
                % 12/31/2015 23:59	1/1/2016 0:00	102	25	valid	125

                tmp = textscan(tline,'%s %s %s %s %s %f %f %s %f','Delimiter',',','EmptyValue',-Inf);
                
                % Get the bluetooth ID
                dataFormat.BluetoothID=char(tmp{1});
                
                % Get the location A and B
                dataFormat.Location_A=char(tmp{2});
                dataFormat.Location_B=char(tmp{3});
                
                % Get the date and time
                [dataFormat.Date_At_A, dataFormat.Time_At_A]=load_bluetooth_data.unpack(char(tmp{4}));
                [dataFormat.Date_At_B, dataFormat.Time_At_B]=load_bluetooth_data.unpack(char(tmp{5}));
                
                % Get the travel time
                dataFormat.Travel_Time=tmp{6};
                
                % Get other fields
                dataFormat.C1=tmp{7};
                dataFormat.C2=char(tmp{8});
                dataFormat.C3=tmp{9};
                               
                count=count+1;
                data(count,:)=dataFormat;
                tline=fgetl(fileID);
            end
            
            % Close the file
            fclose(fileID);
        end
        
         
        function save_data(this,data)
            
            [loc_pair,numPair]=load_bluetooth_data.get_unique_loc_pair({data.Location_A}',{data.Location_B}');
            
            for i=1:numPair
                idx=(ismember({data.Location_A}',loc_pair(i,1)) & ismember({data.Location_B}',loc_pair(i,2)));

                data_loc=data(idx,:);
                
                % Get the file name
                fileName=fullfile(this.outputFolderLocation,sprintf('Bluetooth_%s_%s.mat',loc_pair{i,1},loc_pair{i,2}));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);    
                    bluetoothAll=[bluetoothAll;data_loc];   
                else    
                    % If it is the first time
                    bluetoothAll=data_loc;                    
                end
                
                % Save the health report
                save(fileName,'bluetoothAll');                
            end
            
        end
        
    end
    
     methods ( Static)
         function [loc_pair,numPair]=get_unique_loc_pair(loc_A,loc_B)
            % This function is to get unique pairs of [location_A, Location_B]
            
            % Check the length of inputs
            if(length(loc_A)~=length(loc_B))
                error('Wrong inputs: the lengths are not matched!')
            end
            
            % Get the number of rows
            numRow=size(loc_A,1);
            
            % Get the first row
            loc_pair=[loc_A(1),loc_B(1)];
            numPair=1;
            
            for r=2:numRow % Loop from Row 2 to the end
                % Search
                
                symbol=(ismember(loc_A(r),loc_pair(:,1)) & ismember(loc_B(r),loc_pair(:,2)));
                
%                 for i=1:numPair
%                     symbol=0; % Initially, set to zero
%                     % Compare cell strings
%                     if(strcmp(loc_A(r),loc_pair(i,1)) && strcmp(loc_B(r),loc_pair(i,2)))
%                         symbol=1; % Find duplicated rows
%                         break;
%                     end
%                 end
                if(symbol==0) % Find a new one
                    loc_pair=[loc_pair;[loc_A(r),loc_B(r)]];
                    numPair=numPair+1;
                end
            end
         end
        
         
         function [dataFormat]=dataFormat
             % This function is used to return the structure of data format
             
             dataFormat=struct(...
                'BluetoothID',           nan,...
                'Location_A',            nan,...
                'Location_B',            nan,...
                'Date_At_A',             nan,...
                'Time_At_A',             nan,...
                'Date_At_B',             nan,...
                'Time_At_B',             nan,...
                'Travel_Time',           nan,...
                'C1',                    nan,...
                'C2',                    nan,...
                'C3',                    nan);
         end
         
         function [date, time]= unpack(str)
             % This function is used to unpack the datetime string
             
             % Example: 12/31/2015  11:59:08 PM
             tmp = strsplit(str);
                
             date=tmp{1};
             
             timestr=[tmp{2} tmp{3}];
             time=hour(timestr)*3600+minute(timestr)*60+second(timestr);
           
         end
     end
end

