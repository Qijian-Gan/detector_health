classdef load_config
    properties
        fileLocation        % Location of the detector config file
        fileName            % Name of the detector config file
        
        detectorConfig      % Detector config
        linkConfig          % Link config
        signalConfig        % Signal config
        midlinkConfig       % Midlink data config
    end
    
    methods ( Access = public )
        
        function [this]=load_config(name, location)
            % This function is to load the detector config file
            
            if nargin>1
                this.fileLocation=location;
            else
                % Default location for the network configuration file
                this.fileLocation=findFolder.config;
            end
            
            this.fileName = name;
        end
        
        function [tmpConfig]=detector_property(this,subFileName)
            % This function is used to read detector properties
            
            file = fullfile(this.fileLocation,this.fileName);
            
            [num,txt,raw]=xlsread(file,subFileName);
            
            numDetector=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,...
                'IntersectionID',       nan,...
                'County',               nan,...
                'City',                 nan,...
                'RoadName',             nan,...
                'Direction',            nan,...
                'SensorID',             nan,...
                'Movement',             nan,...
                'Status',               nan,...
                'DetourRoute',          nan,...
                'DetectorLength',       nan,...
                'DistanceToStopbar',    nan,...
                'NumberOfLanes',        nan,...
                'LeftTurnPocket',       nan,...
                'RightTurnPocket',      nan),numDetector,1);
            
            [~,col]=size(num);
            for i=1:numDetector
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
                if(col>=13)
                    tmpConfig(i).LeftTurnPocket=num(i,13);
                end
                if(col>=14)
                    tmpConfig(i).RightTurnPocket=num(i,14);
                end
                
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
            
            [num,txt,raw]=xlsread(file,subFileName);
            
            numApproach=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,...
                'IntersectionID',       nan,...
                'County',               nan,...
                'City',                 nan,...
                'RoadName',             nan,...
                'Direction',            nan,...
                'LinkLength',           nan,...
                'NumberOfLanes',        nan,...
                'Capacity',             nan,...
                'MaxSpeed',             nan),numApproach,1);
            
            [~,col]=size(num);
            for i=1:numApproach
                tmpConfig(i).IntersectionID=num(i,1);
                if(col>=6)
                    tmpConfig(i).LinkLength=num(i,6);
                end
                if(col>=7)
                    tmpConfig(i).NumberOfLanes=num(i,7);
                end
                if(col>=8)
                    tmpConfig(i).Capacity=num(i,8);
                end
                if(col>=9)
                    tmpConfig(i).MaxSpeed=num(i,9);
                end
                
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
            
            [num,txt,raw]=xlsread(file,subFileName);
            
            numApproach=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,...
                'IntersectionID',       nan,...
                'County',               nan,...
                'City',                 nan,...
                'RoadName',             nan,...
                'Direction',            nan,...
                'CycleLength',          nan,...
                'LeftTurnGreen',        nan,...
                'ThroughGreen',         nan,...
                'RightTurnGreen',       nan,...
                'LeftTurnSetting',      nan),numApproach,1);
            
            [~,col]=size(num);
            for i=1:numApproach
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
            % counts
            
            file = fullfile(this.fileLocation,this.fileName);
            
            [num,txt,raw]=xlsread(file,subFileName);
            
            numApproach=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,...
                'IntersectionID',       nan,...
                'County',               nan,...
                'City',                 nan,...
                'RoadName',             nan,...
                'Direction',            nan,...
                'Location',             nan,...
                'Approach',             nan),numApproach,1);
            
            [~,col]=size(num);
            for i=1:numApproach
                tmpConfig(i).IntersectionID=num(i,1);
                                
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

