classdef load_config
    properties
        fileLocation        % Location of the config file
        fileName            % Name of the config file
        
        detectorConfig      % Detector config
        linkConfig          % Link config
        signalConfig        % Signal config
        midlinkConfig       % Midlink data config
    end
    
    methods ( Access = public )
        
        function [this]=load_config(name, location)
            %% This function is to load the config files
            
            this.fileName = name; % Get the file name
            if nargin>1 % Has location input
                this.fileLocation=location;
            else
                % Use default location
                this.fileLocation=findFolder.config;
            end        
        end
        
        function [tmpConfig]=detector_property(this,subFileName)
            % This function is used to read detector properties

            file = fullfile(this.fileLocation,this.fileName);
            
            % The file format is excel
            [num,txt,raw]=xlsread(file,subFileName);
            % num stores all the numbers
            % txt stores all the text information
            
            numDetector=size(num,1); % Get the number of detectors in the subfile
            
            % Create a structural matrix to store the data
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,... % String
                'IntersectionID',       nan,... % Number
                'County',               nan,... % String
                'City',                 nan,... % String
                'RoadName',             nan,... % String
                'Direction',            nan,... % String
                'SensorID',             nan,... % Number
                'Movement',             nan,... % String
                'Status',               nan,... % String
                'DetourRoute',          nan,... % String
                'DetectorLength',       nan,... % Number
                'DistanceToStopbar',    nan,... % Number
                'NumberOfLanes',        nan...  % Number
                ),numDetector,1); % Number
            
            [~,col]=size(num);
            for i=1:numDetector
                % Get the numbers
                tmpConfig(i).IntersectionID=num(i,1);
                tmpConfig(i).SensorID=num(i,6);
                if(col>=10)
                    tmpConfig(i).DetectorLength=num(i,10);
                end
                if(col>=11)
                    tmpConfig(i).DistanceToStopbar=num(i,11);
                end
                if(col>=12)
                    tmpConfig(i).NumberOfLanes=num(i,12);
                end
                                
                % Get the strings
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).City=char(txt(i+1,4));
                tmpConfig(i).RoadName=char(txt(i+1,5));
                tmpConfig(i).Direction=char(txt(i+1,6));
                tmpConfig(i).Movement=char(txt(i+1,8));
                tmpConfig(i).Status=char(txt(i+1,9));
                tmpConfig(i).DetourRoute=char(txt(i+1,10));
                
            end
        end
        
        function [tmpConfig]=link_property(this,subFileName)
            % This function is used to read link properties
            
            file = fullfile(this.fileLocation,this.fileName);            
            
            % The file format is excel
            [num,txt,raw]=xlsread(file,subFileName);
            % num stores all the numbers
            % txt stores all the text information
            
            numApproach=size(num,1); % Get the number of approaches
            
            tmpConfig=repmat(struct(...
                'IntersectionName',         nan,... % String
                'IntersectionID',           nan,... % Number
                'County',                   nan,... % String
                'City',                     nan,... % String
                'RoadName',                 nan,... % String
                'Direction',                nan,... % String
                'LinkLength',               nan,... % Number
                'NumberOfLanes',            nan,... % Number
                'NumberOfLanesDownstream',  nan,... % Number
                'ExclusiveLeftTurnLane',    nan,... % Number
                'LeftTurnPocket',           nan,... % Number
                'ExclusiveRightTurnLane',   nan,... %Number
                'RightTurnPocket',          nan, ...% Number
                'Capacity',                 nan,... % Number
                'MaxSpeed',                 nan),numApproach,1); % Number
            
            [~,col]=size(num);
            for i=1:numApproach
                % Get all the numbers
                tmpConfig(i).IntersectionID=num(i,1);
                if(col>=6)
                    tmpConfig(i).LinkLength=num(i,6);
                end
                if(col>=7)
                    tmpConfig(i).NumberOfLanes=num(i,7);
                end
                if(col>=8)
                    tmpConfig(i).NumberOfLanesDownstream=num(i,8);
                end
                if(col>=9)
                    tmpConfig(i).ExclusiveLeftTurnLane=num(i,9);
                end
                if(col>=10)
                    tmpConfig(i).LeftTurnPocket=num(i,10);
                end
                if(col>=11)
                    tmpConfig(i).ExclusiveRightTurnLane=num(i,11);
                end
                if(col>=12)
                    tmpConfig(i).RightTurnPocket=num(i,12);
                end
                if(col>=13)
                    tmpConfig(i).Capacity=num(i,13);
                end
                if(col>=14)
                    tmpConfig(i).MaxSpeed=num(i,14);
                end
                
                % Get all the strings
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).City=char(txt(i+1,4));
                tmpConfig(i).RoadName=char(txt(i+1,5));
                tmpConfig(i).Direction=char(txt(i+1,6));
                
            end
        end
        
        function [tmpConfig]=signal_property(this,subFileName)
            % This function is used to read the signal settings
            
            file = fullfile(this.fileLocation,this.fileName);
            
            % The file format is excel
            [num,txt,raw]=xlsread(file,subFileName);
            % num stores all the numbers
            % txt stores all the text information
            
            numApproach=size(num,1); % Get the number of approaches
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,... % String
                'IntersectionID',       nan,... % Number
                'County',               nan,... % String 
                'City',                 nan,... % String
                'RoadName',             nan,... % String
                'Direction',            nan,... % String
                'CycleLength',          nan,... % Number
                'LeftTurnGreen',        nan,... % Number
                'ThroughGreen',         nan,... % Number
                'RightTurnGreen',       nan,... % Number
                'LeftTurnSetting',      nan),numApproach,1); % String
            
            [~,col]=size(num);
            for i=1:numApproach
                % Get all numbers
                tmpConfig(i).IntersectionID=num(i,1);
                if(col>=6)
                    tmpConfig(i).CycleLength=num(i,6);
                end
                if(col>=7)
                    tmpConfig(i).LeftTurnGreen=num(i,7);
                end
                if(col>=8)
                    tmpConfig(i).ThroughGreen=num(i,8);
                end
                if(col>=9)
                    tmpConfig(i).RightTurnGreen=num(i,9);
                end
                
                % Get all strings
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).City=char(txt(i+1,4));
                tmpConfig(i).RoadName=char(txt(i+1,5));
                tmpConfig(i).Direction=char(txt(i+1,6));
                tmpConfig(i).LeftTurnSetting=char(txt(i+1,11));
            end
        end
        
        function [tmpConfig]=midlink_config(this,subFileName)
            % This function is used to read the configuration of midlink
            % counts. Need to use this config file since the location of the
            % midlink count is not at the corresponding
            % approach/intersection.
            
            file = fullfile(this.fileLocation,this.fileName);
            
            % The file format is excel
            [num,txt,raw]=xlsread(file,subFileName);
            % num stores all the numbers
            % txt stores all the text information
            
            numApproach=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,... % String
                'IntersectionID',       nan,... % Number
                'County',               nan,... % String
                'City',                 nan,... % String
                'RoadName',             nan,... % String
                'Direction',            nan,... % String
                'Location',             nan,... % String
                'Approach',             nan),numApproach,1); % String
            
            [~,col]=size(num);
            for i=1:numApproach
                % Get all numbers
                tmpConfig(i).IntersectionID=num(i,1);
                
                % Get all strings
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).City=char(txt(i+1,4));
                tmpConfig(i).RoadName=char(txt(i+1,5));
                tmpConfig(i).Direction=char(txt(i+1,6));
                tmpConfig(i).Location=char(txt(i+1,7));
                tmpConfig(i).Approach=char(txt(i+1,8));
            end
        end

    end
    
end

