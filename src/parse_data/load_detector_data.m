classdef load_detector_data
    properties
        folderLocation      % Location of the folder that stores the data files
        
        fileList            % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_detector_data(folder)
            % This function is to load the detector config file
            
            if nargin>0
                this.folderLocation=folder;
            else
                this.folderLocation=findFolder.data;
            end            
        end
        
        function [fileList]=obtain_file_list(this,folder)
            % This function is to obtain the list of files
            
            tmp=dir(folder);
            fileList=tmp(3:end);
        end
        
        function [data]=parse_csv(this,file, location)
            % This function is to parse the excel file with both string and number inputs
            dataFormat=load_detector_data.dataFormat;
            
            fileID = fopen(fullfile(location,file));
                      
            tline=fgetl(fileID); % Ignore the first line
            
            data=struct(dataFormat);
            
            tline=fgetl(fileID); % Starting from the second line
            count=0;
            while ischar(tline)
%                 disp(tline)
                tmp = textscan(tline,'%d %s %s %f %f %f %f %f %f %f %f %f %f','Delimiter',',','EmptyValue',-Inf);
                
                dataFormat.DetectorID=tmp{1};
                
                [dataFormat.Year,dataFormat.Month, dataFormat.Day, dataFormat.Time]...
                    =load_detector_data.unpack(char(tmp{2}));
                
                dataFormat.Volume=tmp{4};
                dataFormat.Occupancy=tmp{5};
                dataFormat.Speed=tmp{6};
                dataFormat.Delay=tmp{7};
                dataFormat.Stops=tmp{8};
                
                dataFormat.S_Volume=tmp{9};
                dataFormat.S_Occupancy=tmp{10};
                dataFormat.S_Speed=tmp{11};
                dataFormat.S_Delay=tmp{12};
                dataFormat.S_Stops=tmp{13};
                
                count=count+1;
                data(count)=dataFormat;
                tline=fgetl(fileID);
            end
            fclose(fileID);
        end
        
    end
    
     methods ( Static)
         function [dataFormat]=dataFormat
             dataFormat=struct(...
                'DetectorID',           nan,...
                'Year',                 nan,...
                'Month',                nan,...
                'Day',                  nan,...
                'Time',                 nan,...
                'Volume',               nan,...
                'Occupancy',            nan,...
                'Speed',                nan,...
                'Delay',                nan,...
                'Stops',                nan,...
                'S_Volume',             nan,...
                'S_Occupancy',          nan,...
                'S_Speed',              nan,...
                'S_Delay',              nan,...
                'S_Stops',              nan);
         end
         
         function [year, month, day, time]= unpack(str)
             
             tmp = textscan(str,'%s %s %d %s %s %d','Delimiter',' ','EmptyValue',-Inf);
             
             year=tmp{6};
             day=tmp{3};
             
             month_abbre={'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',...
                 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
             month=find(ismember(month_abbre,tmp{2}),1);
             
             tmp1 = textscan(char(tmp{4}),'%d %d %d','Delimiter',':','EmptyValue',-Inf);             
             time=tmp1{1}*3600+tmp1{2}*60+tmp1{3}; % In seconds
         end
     end
end

