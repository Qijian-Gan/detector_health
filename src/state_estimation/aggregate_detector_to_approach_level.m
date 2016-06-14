classdef aggregate_detector_to_approach_level 
    properties
        
        fileLocation                    % Location of the configuration file
        fileName                        % File name
        city                            % Name of the city
        
        detectorConfig                  % Detector-based configuration file   
        approachConfig                  % Approach-based configuration file
        
        
    end
    
    methods ( Access = public )
        
        function [this]=aggregate_detector_to_approach_level(config)
            % This function is to do the data clustering
            
            % Obtain inputs
            if nargin==0
                error('No inputs!')
            end 
            
            this.city=config.city;
            this.fileLocation=config.fileLocation;
            this.fileName=config.fileName;
            
            this.detectorConfig=config.detectorConfig; 
            this.approachConfig=aggregate_detector_to_approach_level.detector_to_approach(this.detectorConfig);
            
        end
                
    end
    
    methods (Static)
        
        function [approachConfig]=detector_to_approach(detectorConfig)
            
            % First, get the number of approaches
            [int_app_dir_pair,numPair]=aggregate_detector_to_approach_level.get_unique_int_app_dir_pair(...
                {detectorConfig.IntersectionName}',{detectorConfig.RoadName}',{detectorConfig.Direction}');
            
            approachConfig=[];
            % Second, start to get the detector information for each
            % approach
            for i=1:numPair
                idx=(sum(ismember([{detectorConfig.IntersectionName}',{detectorConfig.RoadName}',{detectorConfig.Direction}'],...
                    int_app_dir_pair(i,:),'rows'),2)==3);
                tmp_data=detectorConfig(idx,:);
                
                exclusive_left_turn=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Left');
                exclusive_right_turn=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Right');
                advanced_detectors=aggregate_detector_to_approach_level.find_detectors(tmp_data,'Advanced');
                general_stopline_detectors=aggregate_detector_to_approach_level.find_detectors(tmp_data,'General');
                
                approachConfig=[approachConfig;struct(...
                    'intersection_name',            int_app_dir_pair(i,1),...
                    'road_name',                    int_app_dir_pair(i,2),...
                    'direction',                    int_app_dir_pair(i,3),...
                    'exclusive_left_turn',          exclusive_left_turn,...
                    'exclusive_right_turn',         exclusive_right_turn,...
                    'advanced_detectors',           advanced_detectors,...
                    'general_stopline_detectors',   general_stopline_detectors)];
            end          
        end
        
        function [detectorList]=find_detectors(data,movement)

            % Get all possible combinations
            possibleMovements=aggregate_detector_to_approach_level.traffic_movement_library(movement);
            
            numCase=length(possibleMovements);
            detectorList=[];
            for i=1:numCase
                idx=ismember({data.Movement}',possibleMovements(i));

                if(sum(idx)>0)
                    tmp_data=data(idx,:);
                    tmpID=aggregate_detector_to_approach_level.get_detector_ids(tmp_data);
                    detectorList=[detectorList;struct(...
                        'Movement',                     possibleMovements(i),...
                        'IDs',                          tmpID,...
                        'AfterLeftTurnPocket',          tmp_data(1).AfterLeftTurnPocket,...
                        'AfterRightTurnPocket',         tmp_data(1).AfterRightTurnPocket)];
                end
            end
        end
        
        function [possibleMovements]=traffic_movement_library(type)
            
            switch(type)
                case 'Left'
                    possibleMovements={'Left Turn','Left Turn Queue'};
                case 'Right'
                    possibleMovements={'Right Turn','Right Turn Queue'};
                case 'Advanced'
                    possibleMovements={'Advanced','Advanced Left Turn', 'Advanced Right Turn','Advanced Through',...
                       'Advanced Through and Right', 'Advanced Left and Through', 'Advanced Left and Right' };
                case 'General'
                    possibleMovements={'All Movements','Through','Left and Right', 'Left and Through', 'Through and Right' }; 
                otherwise
                    error('Wrong input of movements!')
            end
        end
        
        function [detectorIDs]=get_detector_ids(data)
            detectorIDs=[];
            for i=1:size(data,1)
                if(data(i).SensorID<10)
                    detectorID=sprintf('%d0%d',data(i).IntersectionID,data(i).SensorID);
                else
                    detectorID=sprintf('%d%d',data(i).IntersectionID,data(i).SensorID);
                end
                detectorIDs=[detectorIDs;detectorID];
            end
        end
        
        function [int_app_dir_pair,numPair]=get_unique_int_app_dir_pair(int,app, dir)
            if(length(int)~=length(app) || length(int)~=length(dir) || length(int)~=length(dir))
                error('Wrong inputs: the lengths are not matched!')
            end
            
            numRow=size(int,1);
            
            int_app_dir_pair=[int(1),app(1),dir(1)];
            numPair=1;
            
            for r=2:numRow
                % Search
                for i=1:numPair
                    symbol=0;
                    if(strcmp(int(r),int_app_dir_pair(i,1)) && strcmp(app(r),int_app_dir_pair(i,2)) &&...
                            strcmp(dir(r),int_app_dir_pair(i,3)))
                        symbol=1;
                        break;
                    end
                end
                if(symbol==0) % A new one
                    int_app_dir_pair=[int_app_dir_pair;[int(r),app(r),dir(r)]];
                    numPair=numPair+1;
                end
            end
        end
    end

end

