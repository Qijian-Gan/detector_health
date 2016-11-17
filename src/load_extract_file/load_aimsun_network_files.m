classdef load_aimsun_network_files
    properties
        folderLocation          % Location of the folder that stores the simVehicle data files
        outputFolderLocation    % Location of the output folder

        junctionInfFile         % File name for junction information
        sectionInfFile          % File name for section information
        
    end
    
    methods ( Access = public )
        
        function [this]=load_aimsun_network_files(folder,outputFolder)
            % This function is to load the aimsun network files
            
            if nargin>0
                this.folderLocation=folder;
                this.outputFolderLocation=outputFolder;
            else
                % Default folder location
                this.folderLocation=findFolder.aimsunNetwork_data;
                this.outputFolderLocation=findFolder.temp_aimsun;
            end   
            
        end
        
        function [data]=parse_junctionInf_txt(this,junctionInfFile)
            % This function is to parse the txt file of junction
            % information
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,junctionInfFile));
                      
            tline=fgetl(fileID); % Ignore the first line
            tline=fgetl(fileID); % Get the second line: number of junctions
            tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
            numJunction=str2double(tmp{1,1});
            tline=fgetl(fileID); % Get the blank line
            
            data=repmat(load_aimsun_network_files.dataFormatJunction,numJunction,1);
            
            
            for i=1:numJunction
                tline=fgetl(fileID); % Ignore the first line 
                tline=fgetl(fileID); % Get the junction information
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                data(i).JunctionID=str2double(tmp{1,1}{1,1});
                data(i).Name=tmp{1,1}{2,1};
                data(i).ExternalID=tmp{1,1}{3,1};
                data(i).Signalized=str2double(tmp{1,1}{4,1});
                data(i).NumEntranceSection=str2double(tmp{1,1}{5,1});
                data(i).NumExitSection=str2double(tmp{1,1}{6,1});
                data(i).NumTurn=str2double(tmp{1,1}{7,1});

                tline=fgetl(fileID); % Get the entrance sections
                tline=fgetl(fileID);
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                data(i).EntranceSections=nan(data(i).NumEntranceSection,1);
                for j=1:data(i).NumEntranceSection
                    data(i).EntranceSections(j)=str2double(tmp{1,1}{j,1});
                end

                tline=fgetl(fileID); % Get the exit sections
                tline=fgetl(fileID);
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                data(i).ExitSections=nan(data(i).NumExitSection,1);
                for j=1:data(i).NumExitSection
                    data(i).ExitSections(j)=str2double(tmp{1,1}{j,1});
                end
                
                tline=fgetl(fileID); % Get the turnings    
                data(i).Turnings=[];
                data(i).Turnings.TurningInf=repmat(load_aimsun_network_files.dataFormatTurning,data(i).NumTurn,1);
                for j=1:data(i).NumTurn
                    tline=fgetl(fileID);
                    tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                    data(i).Turnings.TurningInf(j)=struct(...
                        'TurnID',           str2double(tmp{1,1}{1,1}),...
                        'OrigSectionID',    str2double(tmp{1,1}{2,1}),...
                        'DestSectionID',    str2double(tmp{1,1}{3,1}),...
                        'OrigFromLane',     str2double(tmp{1,1}{4,1}),...
                        'OrigToLane',       str2double(tmp{1,1}{5,1}),...
                        'DestFromLane',     str2double(tmp{1,1}{6,1}),...
                        'DestToLane',       str2double(tmp{1,1}{7,1}));
                end
                
                tline=fgetl(fileID); % Get the orders of turnings                
                data(i).Turnings.TurnsFromLeftToRight=repmat(load_aimsun_network_files.dataFormatTurningOrder,data(i).NumEntranceSection,1);
                for j=1:data(i).NumEntranceSection
                    tline=fgetl(fileID);
                    tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                    data(i).Turnings.TurnsFromLeftToRight(j).SectionID=str2double(tmp{1,1}{1,1});
                    data(i).Turnings.TurnsFromLeftToRight(j).NumTurns=str2double(tmp{1,1}{2,1});
                    data(i).Turnings.TurnsFromLeftToRight(j).TurnIDsFromLeftToRight=...
                        zeros(data(i).Turnings.TurnsFromLeftToRight(j).NumTurns,1);
                    for k=1:data(i).Turnings.TurnsFromLeftToRight(j).NumTurns
                        data(i).Turnings.TurnsFromLeftToRight(j).TurnIDsFromLeftToRight(k)=str2double(tmp{1,1}{2+k,1});
                    end
                end                                
                tline=fgetl(fileID); % Get the blank line
            end
        end
        
        function [data]=parse_sectionInf_txt(this,sectionInfFile)
            % This function is to parse the txt file of section
            % information
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,sectionInfFile));
                      
            tline=fgetl(fileID); % Ignore the first line
            tline=fgetl(fileID); % Get the second line: number of sections
            tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
            numSection=str2double(tmp{1,1});
            tline=fgetl(fileID); % Get the blank line
            
            data=repmat(load_aimsun_network_files.dataFormatSection,numSection,1);
            
            
            for i=1:numSection
                tline=fgetl(fileID); % Ignore the first line 
                tline=fgetl(fileID); % Get the section information
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                data(i).SectionID=str2double(tmp{1,1}{1,1});
                data(i).Name=tmp{1,1}{2,1};
                data(i).ExternalID=tmp{1,1}{3,1};
                data(i).NumLanes=str2double(tmp{1,1}{4,1});
            
                tline=fgetl(fileID); % Get the lane lengths
                tline=fgetl(fileID);
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                data(i).LaneLengths=nan(data(i).NumLanes,1);
                for j=1:data(i).NumLanes
                    data(i).LaneLengths(j)=str2double(tmp{1,1}{j,1});
                end

                tline=fgetl(fileID); % Get the lane information: Is full lane?
                tline=fgetl(fileID);
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                data(i).IsFullLane=nan(data(i).NumLanes,1);
                for j=1:data(i).NumLanes
                    data(i).IsFullLane(j)=str2double(tmp{1,1}{j,1});
                end
                                                
                tline=fgetl(fileID); % Get the blank line
            end
        end 
    end
    
     methods ( Static)
                  
         function [dataFormat]=dataFormatJunction
             % This function is used to return the structure of data
             % format: Junction
             
             dataFormat=struct(...
                'JunctionID',               nan,...
                'Name',                     nan,...
                'ExternalID',               nan,...
                'Signalized',               nan,...
                'NumEntranceSection',       nan,...
                'NumExitSection',           nan,...
                'NumTurn',                  nan,...
                'EntranceSections',         nan,...
                'ExitSections',             nan,...
                'Turnings',                 nan);
         end
         
         function [dataFormat]=dataFormatSection
             % This function is used to return the structure of data
             % format: Section
             
             dataFormat=struct(...
                'SectionID',                nan,...
                'Name',                     nan,...
                'ExternalID',               nan,...
                'NumLanes',                 nan,...
                'LaneLengths',              nan,...
                'IsFullLane',               nan);
         end
         
         function [dataFormat]=dataFormatTurning
             dataFormat=struct(...
                 'TurnID',           nan,...
                 'OrigSectionID',    nan,...
                 'DestSectionID',    nan,...
                 'OrigFromLane',     nan,...
                 'OrigToLane',       nan,...
                 'DestFromLane',     nan,...
                 'DestToLane',       nan);
         end
         
         function [dataFormat]=dataFormatTurningOrder
             dataFormat=struct(...
                 'SectionID',                   nan,...
                 'NumTurns',                    nan,...
                 'TurnIDsFromLeftToRight',      nan);
         end
     end
end

