classdef load_config
    properties
        fileLocation        % Location of the detector config file
        fileName            % Name of the detector config file
        city                % Name of the targeted city
        
        detectorConfig      % Detector config
        
    end
    
    methods ( Access = public )
        
        function [this]=load_config(name, city, location)
            % This function is to load the detector config file
            if nargin>2
                this.fileLocation=location;
            else
                this.fileLocation=findFolder.config;
            end
            
            this.fileName = name;
            this.city = city;
            
            file = fullfile(this.fileLocation,this.fileName);
            this.detectorConfig=this.parse_excel(file,city);
            
        end
        
        function [tmpConfig]=parse_excel(this,file,city)
            % This function is to parse the excel file with both string and number inputs
            
            [num,txt,raw]=xlsread(file,city);
            
            numDetector=size(num,1);
            
            tmpConfig=repmat(struct(...
                'IntersectionName',     nan,...
                'IntersectionID',       nan,...
                'County',               nan,...
                'City',                 nan,...
                'RoadName',             nan,...
                'Direction',            nan,...
                'SensorID',             nan,...
                'Location',             nan),numDetector,1);
            
            for i=1:numDetector
                tmpConfig(i).IntersectionID=num(i,1);
                tmpConfig(i).SensorID=num(i,6);
                
                tmpConfig(i).IntersectionName=char(txt(i+1,1));
                tmpConfig(i).County=char(txt(i+1,3));
                tmpConfig(i).City=char(txt(i+1,4));
                tmpConfig(i).RoadName=char(txt(i+1,5));
                tmpConfig(i).Direction=char(txt(i+1,6));
                tmpConfig(i).Location=char(txt(i+1,8));              
            end
        end
    end
    
end

