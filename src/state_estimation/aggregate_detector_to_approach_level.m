classdef aggregate_detector_to_approach_level 
    properties
        
        fileLocation                    % Location of the configuration file
        fileName                        % File name
        
        detectorConfig                  % Detector-based configuration file  
        linkConfig                      % Link config
        signalConfig                    % Signal config
        
        approachConfig                  % Approach-based configuration file
        
        
    end
    
    methods ( Access = public )
        
        function [this]=aggregate_detector_to_approach_level(config)
            % This function is to aggregate detector to approach level
            
            % Obtain inputs
            if nargin==0
                error('No inputs!')
            end 

            this.fileLocation=config.fileLocation;
            this.fileName=config.fileName;            
            this.detectorConfig=config.detectorConfig; 
            this.linkConfig=config.linkConfig;
            this.signalConfig=config.signalConfig;
            
        end
                
         
        function [approachConfig]=detector_to_approach(this)
            % From detector level to approach level (left-turn, through, and right)
             
            % First, get the number of approaches
            % Get unique pairs of [intersection, approach, direction]
            [int_app_dir_pair,numPair]=aggregate_detector_to_approach_level.get_unique_int_app_dir_pair(...
                {this.detectorConfig.IntersectionName}',{this.detectorConfig.RoadName}',{this.detectorConfig.Direction}');
            
            approachConfig=[];
            % Second, start to get the detector information for each
            % approach
            for i=1:numPair % Loop for each pair
                % Get the rows with the same [int, app, dir]
                idx=(sum(ismember([{this.detectorConfig.IntersectionName}',{this.detectorConfig.RoadName}',{this.detectorConfig.Direction}'],...
                    int_app_dir_pair(i,:),'rows'),2)==3);
                tmp_data=this.detectorConfig(idx,:);
                
                % Find different categories of detectors: exclusive left,
                % exclusive right, general stopline, and advanded detectors
                exclusive_left_turn=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Left');
                exclusive_right_turn=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Right');
                advanced_detectors=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Advanced');
                general_stopline_detectors=aggregate_detector_to_approach_level.find_detectors(tmp_data,'General');
                
                % Find link properties
                clear idx;
                idx=(sum(ismember([{this.linkConfig.IntersectionName}',{this.linkConfig.RoadName}',{this.linkConfig.Direction}'],...
                    int_app_dir_pair(i,:),'rows'),2)==3);
                if(sum(idx))
                    link_properties=struct(...
                        'LinkLength',            this.linkConfig(idx).LinkLength,...
                        'NumberOfLanes',         this.linkConfig(idx).NumberOfLanes,...
                        'Capacity',              this.linkConfig(idx).Capacity,...
                        'MaxSpeed',              this.linkConfig(idx).MaxSpeed);
                else
                    link_properties=[];
                end
                
                % Find signal settings
                clear idx;
                idx=(sum(ismember([{this.signalConfig.IntersectionName}',{this.signalConfig.RoadName}',{this.signalConfig.Direction}'],...
                    int_app_dir_pair(i,:),'rows'),2)==3);
                if(sum(idx))
                    signal_properties=struct(...
                        'CycleLength',              this.signalConfig(idx).CycleLength,...
                        'LeftTurnGreen',            this.signalConfig(idx).LeftTurnGreen,...
                        'ThroughGreen',             this.signalConfig(idx).ThroughGreen,...
                        'RightTurnGreen',           this.signalConfig(idx).RightTurnGreen,...
                        'LeftTurnSetting',          this.signalConfig(idx).LeftTurnSetting);
                else
                    signal_properties=[];
                end
                
                approachConfig=[approachConfig;struct(...
                    'intersection_name',            int_app_dir_pair(i,1),...
                    'road_name',                    int_app_dir_pair(i,2),...
                    'direction',                    int_app_dir_pair(i,3),...
                    'exclusive_left_turn',          exclusive_left_turn,...
                    'exclusive_right_turn',         exclusive_right_turn,...
                    'advanced_detectors',           advanced_detectors,...
                    'general_stopline_detectors',   general_stopline_detectors,...
                    'link_properties',              link_properties,...
                    'signal_properties',            signal_properties)];
            end          
        end
        
    end
    
    methods(Static)
        function [detectorList]=find_detectors(data,movement)
            % This function is to find the detectors belonging to the same
            % type: exclusive left, exclusive right, general stopline, and
            % advanced detectors

            % Get all possible combinations
            possibleMovements=aggregate_detector_to_approach_level.traffic_movement_library(movement);
            
            numCase=length(possibleMovements);
            detectorList=[];
            for i=1:numCase
                idx=ismember({data.Movement}',possibleMovements(i));

                if(sum(idx)>0)
                    tmp_data=data(idx,:);
                    [tmpID,distanceToStopbar,detectorLength,numberOfLanes,leftTurnPocket,rightTurnPocket]=...
                        aggregate_detector_to_approach_level.get_detector_ids(tmp_data);
                    detectorList=[detectorList;struct(...
                        'Movement',                     possibleMovements(i),...
                        'IDs',                          tmpID,...
                        'DetectorLength',               detectorLength,...
                        'DistanceToStopbar',            distanceToStopbar,...
                        'NumberOfLanes',                numberOfLanes,...
                        'LeftTurnPocket',               leftTurnPocket,...
                        'RightTurnPocket',              rightTurnPocket)];
                end
            end
        end
        
        function [possibleMovements]=traffic_movement_library(type)
            % This function returns all possible detectors belonging to
            % the same type
            
            switch(type)
                case 'Left' % Exclusive left-turn detectors
                    possibleMovements={'Left Turn','Left Turn Queue'};
                case 'Right' % Exclusive right-turn detectors
                    possibleMovements={'Right Turn','Right Turn Queue'};
                case 'Advanced' % Advanced detectors: "Advanced" means for all movements
                    possibleMovements={'Advanced','Advanced Left Turn', 'Advanced Right Turn','Advanced Through',...
                       'Advanced Through and Right', 'Advanced Left and Through', 'Advanced Left and Right' };
                case 'General' % General stopline detectors
                    possibleMovements={'All Movements','Through','Left and Right', 'Left and Through', 'Through and Right' }; 
                otherwise
                    error('Wrong input of movements!')
            end
        end
        
        function [detectorIDs, distanceToStopbar,detectorLength,numberOfLanes,leftTurnPocket,rightTurnPocket]=get_detector_ids(data)
            % This function returns detector IDs and their distances to the
            % stopbar
            
            detectorIDs=[];
            distanceToStopbar=[];
            detectorLength=[];
            numberOfLanes=[];
            leftTurnPocket=[];
            rightTurnPocket=[];
            for i=1:size(data,1)
                if(data(i).SensorID<10)
                    detectorID=sprintf('%d0%d',data(i).IntersectionID,data(i).SensorID);
                else
                    detectorID=sprintf('%d%d',data(i).IntersectionID,data(i).SensorID);
                end
                detectorIDs=[detectorIDs;detectorID];
                distanceToStopbar=[distanceToStopbar;data(i).DistanceToStopbar];
                detectorLength=[detectorLength;data(i).DetectorLength];
                numberOfLanes=[numberOfLanes;data(i).NumberOfLanes];
                leftTurnPocket=[leftTurnPocket;data(i).LeftTurnPocket];
                rightTurnPocket=[rightTurnPocket;data(i).RightTurnPocket];
            end
        end
        
        function [int_app_dir_pair,numPair]=get_unique_int_app_dir_pair(int,app, dir)
            % This function is to get unique pairs of [intersection, approach, direction]
            
            % Check the length of inputs
            if(length(int)~=length(app) || length(int)~=length(dir) || length(int)~=length(dir))
                error('Wrong inputs: the lengths are not matched!')
            end
            
            % Get the number of detectors/rows
            numRow=size(int,1);
            
            % Get the first row
            int_app_dir_pair=[int(1),app(1),dir(1)];
            numPair=1;
            
            for r=2:numRow % Loop from Row 2 to the end
                % Search
                for i=1:numPair
                    symbol=0; % Initially, set to zero
                    % Compare cell strings
                    if(strcmp(int(r),int_app_dir_pair(i,1)) && strcmp(app(r),int_app_dir_pair(i,2)) &&...
                            strcmp(dir(r),int_app_dir_pair(i,3)))
                        symbol=1; % Find duplicated rows
                        break;
                    end
                end
                if(symbol==0) % Find a new one
                    int_app_dir_pair=[int_app_dir_pair;[int(r),app(r),dir(r)]];
                    numPair=numPair+1;
                end
            end
        end
    end

end

