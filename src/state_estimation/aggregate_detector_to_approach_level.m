classdef aggregate_detector_to_approach_level 
    properties
        
        fileLocation                    % Location of the configuration file
        fileName                        % File name
        
        detectorConfig                  % Detector-based configuration file  
        linkConfig                      % Link config
        signalConfig                    % Signal config
        midlinkConfig                   % Midlink config
        
        approachConfig                  % Approach-based configuration file
        
        
    end
    
    methods ( Access = public )
        
        function [this]=aggregate_detector_to_approach_level(config)
            %% This function is to aggregate detector to approach level
            
            % Obtain inputs
            if nargin==0
                error('No inputs!')
            end 

            % Copy all information
            this.fileLocation=config.fileLocation;
            this.fileName=config.fileName;            
            this.detectorConfig=config.detectorConfig; 
            this.linkConfig=config.linkConfig;
            this.signalConfig=config.signalConfig;
            this.midlinkConfig=config.midlinkConfig;
            
        end
                  
        function [approachConfig]=detector_to_approach(this)
            % This function is: from detector level to approach level (left-turn, through, and right)
             
            % First, get the number of approaches
            % Get unique pairs of [intersection, approach, direction]
            [int_app_dir_pair,numPair]=aggregate_detector_to_approach_level.get_unique_int_app_dir_pair(...
                {this.detectorConfig.IntersectionName}',{this.detectorConfig.IntersectionID}',{this.detectorConfig.RoadName}',...
                {this.detectorConfig.Direction}',{this.detectorConfig.City}');
            
            approachConfig=[];
            % Second, start to get the detector information for each
            % approach
            for i=1:numPair % Loop for each pair
                % Get the rows with the same [int, app, dir]
                idx=(sum(ismember([{this.detectorConfig.IntersectionName}',{this.detectorConfig.RoadName}',{this.detectorConfig.Direction}'],...
                    int_app_dir_pair(i,1:3),'rows'),2)==3);
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
                    int_app_dir_pair(i,1:3),'rows'),2)==3);
                if(sum(idx))
                    link_properties=struct(...
                        'LinkLength',                       this.linkConfig(idx).LinkLength,...
                        'NumberOfLanes',                    this.linkConfig(idx).NumberOfLanes,...
                        'NumberOfLanesDownstream',          this.linkConfig(idx).NumberOfLanesDownstream,...
                        'ExclusiveLeftTurnLane',            this.linkConfig(idx).ExclusiveLeftTurnLane,...              
                        'LeftTurnPocket',                   this.linkConfig(idx).LeftTurnPocket,...
                        'ExclusiveRightTurnLane',           this.linkConfig(idx).ExclusiveRightTurnLane,...
                        'RightTurnPocket',                  this.linkConfig(idx).RightTurnPocket,...
                        'Capacity',                         this.linkConfig(idx).Capacity,...
                        'MaxSpeed',                         this.linkConfig(idx).MaxSpeed);
                else
                    link_properties=[];
                end
                
                % Find signal settings
                clear idx;
                idx=(sum(ismember([{this.signalConfig.IntersectionName}',{this.signalConfig.RoadName}',{this.signalConfig.Direction}'],...
                    int_app_dir_pair(i,1:3),'rows'),2)==3);
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
                
                % Find midlink properties
                clear idx;
                idx=(sum(ismember([{this.midlinkConfig.IntersectionName}',{this.midlinkConfig.RoadName}',{this.midlinkConfig.Direction}'],...
                    int_app_dir_pair(i,1:3),'rows'),2)==3);
                if(sum(idx))
                    midlink_properties=struct(...
                        'Location',              this.midlinkConfig(idx).Location,...
                        'Approach',              this.midlinkConfig(idx).Approach);
                else
                    midlink_properties=[];
                end
                
                approachConfig=[approachConfig;struct(...
                    'intersection_name',            int_app_dir_pair(i,1),...       % Int. Name
                    'intersection_id',              int_app_dir_pair{i,4},...       % Int. ID
                    'city',                         int_app_dir_pair(i,5),...       % City
                    'road_name',                    int_app_dir_pair(i,2),...       % Road Name
                    'direction',                    int_app_dir_pair(i,3),...       % Direction
                    'exclusive_left_turn',          exclusive_left_turn,...         % Exclu. left
                    'exclusive_right_turn',         exclusive_right_turn,...        % Exclu. right
                    'advanced_detectors',           advanced_detectors,...          % Advanced
                    'general_stopline_detectors',   general_stopline_detectors,...  % General
                    'link_properties',              link_properties,...             % Link properties
                    'signal_properties',            signal_properties,...           % Signal properties
                    'midlink_properties',           midlink_properties,...          % Midlink properties
                    'turning_count_properties',     [])];                           % Turning count
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

                if(sum(idx)>0) % Has detectors belonging to the current type?
                    tmp_data=data(idx,:);
                    [tmpID,distanceToStopbar,detectorLength,numberOfLanes]=...
                        aggregate_detector_to_approach_level.get_detector_ids(tmp_data);
                    detectorList=[detectorList;struct(...
                        'Movement',                     possibleMovements(i),...    % Movement Type
                        'IDs',                          tmpID,...                   % Detector IDs belonging to the same movement type
                        'DetectorLength',               detectorLength,...          % Length of the detector
                        'DistanceToStopbar',            distanceToStopbar,...       % Distance to Stopbar
                        'NumberOfLanes',                numberOfLanes...           % Number of lanes
                        )];          % Right-turn pocket
                end
            end
        end
        
        function [possibleMovements]=traffic_movement_library(type)
            % This function returns all possible detectors belonging to
            % the same type: exclusive left/exclusive
            % right/advanced/general stopbar
            
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
        
        function [detectorIDs, distanceToStopbar,detectorLength,numberOfLanes]=get_detector_ids(data)
            % This function returns detector IDs and their distances to the
            % stopbar
            
            detectorIDs=[];
            distanceToStopbar=[];
            detectorLength=[];
            numberOfLanes=[];
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
            end
        end
        
        function [int_app_dir_pair,numPair]=get_unique_int_app_dir_pair(int,intID,app,dir,city)
            % This function is to get unique pairs of [intersection, approach, direction]
            
            % Check the length of inputs
            if(length(int)~=length(app) || length(int)~=length(dir) || length(int)~=length(dir))
                error('Wrong inputs: the lengths do not match!')
            end
            
            % Get the number of detectors/rows
            numRow=size(int,1);
            
            % Get the first row
            int_app_dir_pair=[int(1),app(1),dir(1),intID(1),city(1)];
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
                    int_app_dir_pair=[int_app_dir_pair;[int(r),app(r),dir(r),intID(r),city(r)]];
                    numPair=numPair+1;
                end
            end
        end
    end

end

