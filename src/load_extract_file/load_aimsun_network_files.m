classdef load_aimsun_network_files
    properties
        folderLocation          % Location of the folder that stores the simVehicle data files
        outputFolderLocation    % Location of the output folder
        
        junctionInfFile         % File name for junction information
        sectionInfFile          % File name for section information
        detectorInfFile         % File name for detector information
        defaultSigSettingFile   % File name for default signal settings
        midlinkCountConfigFile  % File name for the configuration of midlink count
        
    end
    
    methods ( Access = public )
        
        function [this]=load_aimsun_network_files(folder,outputFolder)
            % This function is to load the aimsun network files
            
            if nargin>2
                error('Too many input variables!')
            end
            
            if(nargin==0)
                % Default folder location
                this.folderLocation=findFolder.aimsunNetwork_data;
                this.outputFolderLocation=findFolder.temp_aimsun;
            end
            
            if nargin>=1
                this.folderLocation=folder;
                this.outputFolderLocation=findFolder.temp_aimsun;
            end
            
            if nargin==2
                this.outputFolderLocation=outputFolder;
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
                        'DestToLane',       str2double(tmp{1,1}{7,1}),...
                        'Description',      [],...
                        'TurningSpeed',     []);
                    if(length(tmp{1,1})>=8)
                        data(i).Turnings.TurningInf(j).Description=tmp{1,1}{8,1};
                    end
                    if(length(tmp{1,1})>=9)
                        data(i).Turnings.TurningInf(j).TurningSpeed=tmp{1,1}{9,1};
                    end
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
        
        function [data]=parse_detectorInf_csv(this,detectorInfFile)
            % This function is to parse the csv file of section
            % information
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,detectorInfFile));
            
            tline=fgetl(fileID); % Ignore the first line
            data=[];
            
            tline=fgetl(fileID);
            while(tline>0)
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                tmpData=struct(...
                    'DetectorID',                       str2num(tmp{1,1}{1,1}),...
                    'ExternalID',                       str2num(tmp{1,1}{2,1}),...
                    'SectionID',                        str2num(tmp{1,1}{3,1}),...
                    'Description',                      tmp{1,1}{4,1},...
                    'FirstLane',                        str2num(tmp{1,1}{5,1}),...
                    'LastLane',                         str2num(tmp{1,1}{6,1}),...
                    'InitialPosition',                  str2double(tmp{1,1}{7,1}),...
                    'FinalPosition',                    str2double(tmp{1,1}{8,1}));
                tmpData.NumOfLanesCovered=tmpData.LastLane-tmpData.FirstLane+1;
                tmpData.Length=tmpData.FinalPosition-tmpData.InitialPosition;
                
                data=[data;tmpData];
                tline=fgetl(fileID);
            end
            
        end
        
        function [data]=parse_defaultSigSetting_csv(this,sigInfFile)
            % This function is to parse the csv file of default signal
            % settings
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,sigInfFile));
            
            tline=fgetl(fileID); % Ignore the first line
            data=[];
            
            tline=fgetl(fileID);
            while(tline>0)
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                tmpData=struct(...
                    'IntersectionName',             tmp{1,1}{1,1},...
                    'IntersectionID',               str2num(tmp{1,1}{2,1}),...
                    'IntersectionExtID',            str2num(tmp{1,1}{3,1}),...
                    'County',                       tmp{1,1}{4,1},...
                    'City',                         tmp{1,1}{5,1},...
                    'FirstSectionName',             tmp{1,1}{6,1},...
                    'FirstSectionID',               str2num(tmp{1,1}{7,1}),...
                    'CycleLength',                  str2double(tmp{1,1}{8,1}),...
                    'LeftTurnGreen',                str2double(tmp{1,1}{9,1}),...
                    'ThroughGreen',                 str2double(tmp{1,1}{10,1}),...
                    'RightTurnGreen',               str2double(tmp{1,1}{11,1}),...
                    'LeftTurnSetting',              tmp{1,1}{12,1});
                
                data=[data;tmpData];
                tline=fgetl(fileID);
            end
            
        end
        
        function [data]=parse_midlinkCountConfig_csv(this,midlinkInfFile)
            % This function is to parse the csv file of midlink count
            % configuration files
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,midlinkInfFile));
            
            tline=fgetl(fileID); % Ignore the first line
            data=[];
            
            tline=fgetl(fileID);
            while(tline>0)
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                tmpData=struct(...
                    'IntersectionName',             tmp{1,1}{1,1},...
                    'IntersectionID',               str2num(tmp{1,1}{2,1}),...
                    'IntersectionExtID',            str2num(tmp{1,1}{3,1}),...
                    'County',                       tmp{1,1}{4,1},...
                    'City',                         tmp{1,1}{5,1},...
                    'FirstSectionName',             tmp{1,1}{6,1},...
                    'FirstSectionID',               str2num(tmp{1,1}{7,1}),...
                    'Location',                     tmp{1,1}{8,1},...
                    'Approach',                     tmp{1,1}{9,1});
                
                data=[data;tmpData];
                tline=fgetl(fileID);
            end
            
        end
        
        function [data]=parse_controlPlanInf_txt(this,controlPlanFile)            
            % This function is to parse the txt file of control plan information
            
            % Open the file
            fileID = fopen(fullfile(this.folderLocation,controlPlanFile));
            
            tline=fgetl(fileID); % Ignore the first line
            tline=fgetl(fileID); % Get the second line: number of sections
            tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
            numControlPlan=str2double(tmp{1,1});
            tline=fgetl(fileID); % Get the blank line
            
            data=[];            
            
            for i=1:numControlPlan
                tline=fgetl(fileID); % Ignore the first line
                tline=fgetl(fileID); % Get the control plan information
                tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                
                PlanID=str2double(tmp{1,1}{1,1});
                PlanExtID=tmp{1,1}{2,1};
                PlanName=tmp{1,1}{3,1};
                NumOfControlJunction=str2double(tmp{1,1}{4,1});
                
                dataControlJunction=load_aimsun_network_files.dataFormatControlPlanJunction();
                for j=1:NumOfControlJunction
                    tline=fgetl(fileID); % Ignore the first line
                    tline=fgetl(fileID);
                    tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                    dataControlJunction.PlanID=PlanID;
                    dataControlJunction.PlanExtID=PlanExtID;
                    dataControlJunction.PlanName=PlanName;
                    dataControlJunction.JunctionID=str2double(tmp{1,1}{1,1});
                    dataControlJunction.JunctionName=(tmp{1,1}{2,1});
                    dataControlJunction.ControlType=(tmp{1,1}{3,1});
                    dataControlJunction.Offset=str2double(tmp{1,1}{4,1});
                    dataControlJunction.NumBarriers=str2double(tmp{1,1}{5,1});
                    dataControlJunction.Cycle=str2double(tmp{1,1}{6,1});
                    dataControlJunction.NumRings=str2double(tmp{1,1}{7,1});
                    dataControlJunction.NumPhases=str2double(tmp{1,1}{8,1});
                    dataControlJunction.NumSignals=str2double(tmp{1,1}{9,1});
                    
                    % Loop for all phases                    
                    tline=fgetl(fileID); % Ignore the first line
                    for k=1:dataControlJunction.NumPhases                        
                        tline=fgetl(fileID);
                        tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                        
                        phaseSetting.PhaseID=str2double(tmp{1,1}{1,1});
                        phaseSetting.RingID=str2double(tmp{1,1}{2,1});
                        phaseSetting.StartTime=str2double(tmp{1,1}{3,1});
                        phaseSetting.Duration=str2double(tmp{1,1}{4,1});
                        phaseSetting.IsInterphase=(tmp{1,1}{5,1});
                        phaseSetting.PermissiveStartTime=str2double(tmp{1,1}{6,1});
                        phaseSetting.PermissiveEndTime=str2double(tmp{1,1}{7,1});
                        phaseSetting.NumSignalInPhase=str2double(tmp{1,1}{8,1});
                        phaseSetting.SignalInPhase=[];
                        for t=1:phaseSetting.NumSignalInPhase
                            phaseSetting.SignalInPhase=[phaseSetting.SignalInPhase,str2double(tmp{1,1}{8+t,1})];
                        end
                        
                        dataControlJunction.Phases=[dataControlJunction.Phases;phaseSetting];
                    end
                    
                    % Loop for all signal-turnings                    
                    tline=fgetl(fileID); % Ignore the first line
                    for k=1:dataControlJunction.NumSignals                        
                        tline=fgetl(fileID);
                        tmp = textscan(tline,'%s','Delimiter',',','EmptyValue',-Inf);
                        
                        signalSetting.SignalID=str2double(tmp{1,1}{1,1});
                        signalSetting.NumTurnings=str2double(tmp{1,1}{2,1});                        
                        signalSetting.TurningInSignal=[];
                        for t=1:signalSetting.NumTurnings
                            signalSetting.TurningInSignal=[signalSetting.TurningInSignal,str2double(tmp{1,1}{2+t,1})];
                        end
                        
                        dataControlJunction.Signals=[dataControlJunction.Signals;signalSetting];
                    end                    
                   
                    data=[data;dataControlJunction];
                end
                
                tline=fgetl(fileID); % Get the blank line
            end
            
        end
    end
    
    methods ( Static)
        
        function [dataFormat]=dataFormatControlPlanJunction
            % This function is used to return the structure of the control
            % plan
            
            dataFormat=struct(...
                'PlanID',               nan,...
                'PlanExtID',            nan,...
                'PlanName',             nan,...
                'JunctionID',           nan,...
                'JunctionName',         nan,...
                'ControlType',          nan,...
                'Offset',               nan,...
                'NumBarriers',          nan,...
                'Cycle',                nan,...
                'NumRings',             nan,...
                'NumPhases',            nan,...
                'NumSignals',           nan,...
                'Phases',               [],...
                'Signals',              []);
        end
        
        function [dataFormat]=dataFormatDetector
            % This function is used to return the structure of data
            % format: Detector
            
            dataFormat=struct(...
                'DetectorID',                       nan,...
                'ExternalID',                       nan,...
                'SectionID',                        nan,...
                'Description',                      nan,...
                'NumOfLanesCovered',                nan,...
                'FirstLane',                        nan,...
                'LastLane',                         nan,...
                'InitialPosition',                  nan,...
                'FinalPosition',                    nan,...
                'Length',                           nan);
        end
        
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
                'DestToLane',       nan,...
                'Description',      nan,...
                'TurningSpeed',     nan);
        end
        
        function [dataFormat]=dataFormatTurningOrder
            dataFormat=struct(...
                'SectionID',                   nan,...
                'NumTurns',                    nan,...
                'TurnIDsFromLeftToRight',      nan);
        end
    end
end

