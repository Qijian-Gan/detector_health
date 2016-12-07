classdef load_estStateQueue_data
    properties
        folderLocation          % Location of the folder that stores the estStateQueue data files
        outputFolderLocation    % Location of the output folder

    end
    
    methods ( Access = public )
        
        function [this]=load_estStateQueue_data(folder,outputFolder)
            % This function is to load the estStateQueue data file
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
            else
                % Default folder location
                this.folderLocation=findFolder.estStateQueue_data;
                this.outputFolderLocation=findFolder.temp_aimsun;
            end               
        end
        
        function [data]=parse_csv(this,file, location)
            % This function is to parse the excel file of estimated queue
            % and traffic state
            
            dataFormat=load_estStateQueue_data.dataFormat;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
                      
            tline=fgetl(fileID); % Ignore the first line
            
            data=[];
            
            tline=fgetl(fileID); % Starting from the second line
            while ischar(tline)
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
            
                dataFormat.JunctionID=str2double(tmp{1,1}{1,1});
                dataFormat.JunctionName=(tmp{1,1}{2,1});
                dataFormat.JunctionExtID=(tmp{1,1}{3,1});
                dataFormat.Signalized=str2double(tmp{1,1}{4,1});
                dataFormat.SectionID=str2double(tmp{1,1}{5,1});
                dataFormat.SectionName=(tmp{1,1}{6,1});
                dataFormat.SectionExtID=(tmp{1,1}{7,1});
                dataFormat.Time=str2double(tmp{1,1}{8,1});
                
                tmpNumTurns=(length(tmp{1,1})-8)/2;              
                % Get the status and queue
                dataFormat.Status=[];
                dataFormat.Queue=[];
                for i=1:tmpNumTurns
                    if(str2double(tmp{1,1}{8+tmpNumTurns+i,1})>=-1)
                        dataFormat.Status=[dataFormat.Status;tmp{1,1}(8+i,1)];
                        dataFormat.Queue=[dataFormat.Queue;str2double(tmp{1,1}{8+tmpNumTurns+i,1})];
                    end
                end
                
                data=[data;dataFormat];
                tline=fgetl(fileID);
            end

        end
        
    end
    
     methods ( Static)
                  
         function [dataFormat]=dataFormat
             % This function is used to return the structure of data format
             
             dataFormat=struct(...
                'JunctionID',                   nan,...
                'JunctionName',                 nan,...
                'JunctionExtID',                nan,...
                'Signalized',                   nan,...
                'SectionID',                    nan,...
                'SectionName',                  nan,...
                'SectionExtID',                 nan,...
                'Time',                         nan,...
                'Status',                       nan,...
                'Queue',                        nan);
         end
         
     end
end

