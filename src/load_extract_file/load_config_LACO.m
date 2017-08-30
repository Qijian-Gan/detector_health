classdef load_config_LACO
    properties
        fileLocation        % Location of the config file
        fileName            % Name of the config file
        
        detectorConfig      % Detector config
    end
    
    methods ( Access = public )
        
        function [this]=load_config_LACO(name, location)
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
                'NumberOfLanes',        nan,... % Number
                'Notes',                nan...  % String
                ),numDetector,1); % Number
            
            [~,col]=size(num);
            for i=1:numDetector
                % Get the numbers
                tmpConfig(i).IntersectionID=num(i,1);
                tmpConfig(i).SensorID=num(i,5);
                if(col>=7)
                    tmpConfig(i).DetectorLength=num(i,7);
                end
                if(col>=8)
                    tmpConfig(i).DistanceToStopbar=num(i,8);
                end
                if(col>=9)
                    tmpConfig(i).NumberOfLanes=num(i,9);
                end
                                
                % Get the strings
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).RoadName=char(txt(i+1,4));
                tmpConfig(i).Direction=char(txt(i+1,5));
                tmpConfig(i).Movement=char(txt(i+1,7));
                tmpConfig(i).Notes=char(txt(i+1,11));
                
            end
        end
    end
    
end

