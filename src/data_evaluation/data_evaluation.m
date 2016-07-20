classdef data_evaluation
    properties

        approachConfig              % Approach-based configuration
        
        dataProvider_sensor         % Data provider: sensor
        dataProvider_midlink        % Data provider: sensor
        dataProvider_turningCount   % Data provider: sensor

    end
    
    methods ( Access = public )
        
        function [this]=data_evaluation(approachConfig,dataProvider_sensor, dataProvider_midlink, dataProvider_turningCount)
            % This function is to do the state estimation
            if(nargin<4)
                error('Not enough inputs!')
            end
            
            if(isempty(approachConfig)||isempty(dataProvider_sensor))
                error('Wrong inputs');
            end
            
            this.approachConfig=approachConfig;
            this.dataProvider_sensor=dataProvider_sensor;
            
            if(nargin>2)
                this.dataProvider_midlink=dataProvider_midlink;
            end
            if(nargin>3)
                this.dataProvider_turningCount=dataProvider_turningCount;
            end
        end
           
        %% ***************Functions to get data*****************
        function [approach_out]=get_turning_count_for_approach(this,approach_in)
            
            approach_out=approach_in;
            fileName=sprintf('TP_%s_%s_%s.mat',approach_in.intersection_name,...
                strrep(approach_in.road_name,' ', '_'),approach_in.direction);
            
            approach_out.data_evaluation.approach_volume.turning_count=[];
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            for i=0:9
                queryMeasures=struct(...
                    'year',     nan,...
                    'month',    nan,...
                    'day',      nan,...
                    'dayOfWeek',i,...
                    'median', 1,...
                    'timeOfDay', nan);
                
                [data_out]=this.dataProvider_turningCount.clustering(fileName, queryMeasures);
                if(isempty(data_out))
                    data=struct(...
                        'dayofweek',i,...
                        'data', []);
                else
                    data=struct(...
                        'dayofweek',i,...
                        'data', struct(...
                        'time',data_out.time,...
                        'data',sum(data_out.volume,2)));
                end
                approach_out.data_evaluation.approach_volume.turning_count=[...
                        approach_out.data_evaluation.approach_volume.turning_count;data];
            end

        end
        
        function [approach_out]=get_midlink_data_for_approach(this,approach_in)
            
            approach_out=approach_in;
            fileName=sprintf('Midlink_%s_%s.mat',approach_in.midlink_properties.Location,...
                approach_in.midlink_properties.Approach);
            
            approach_out.data_evaluation.approach_volume.midlink_count=[];
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            for i=0:9
                queryMeasures=struct(...
                    'year',     nan,...
                    'month',    nan,...
                    'day',      nan,...
                    'dayOfWeek',i,...
                    'median', 1,...
                    'timeOfDay', nan);
                
                [data_out]=this.dataProvider_midlink.clustering(fileName, queryMeasures);
                if(isempty(data_out))
                    data=struct(...
                        'dayofweek',i,...
                        'data', []);
                else
                    data=struct(...
                        'dayofweek',i,...
                        'data', struct(...
                        'time',data_out.time,...
                        'data',sum(data_out.volume,2)));
                end
                approach_out.data_evaluation.approach_volume.midlink_count=[...
                        approach_out.data_evaluation.approach_volume.midlink_count;data];
            end
        end
        
        function [approach_out]=get_stopbar_data_for_approach(this,approach_in)
            % This function is to get stopbar data for a given approach
            
            % NOTE: This procedure do not work for those approaches with only
            % exclusive left/right-turn movements
            
            approach_out=approach_in;
            approach_out.data_evaluation.approach_volume.stopbar_count=[];
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            for i=0:9
                queryMeasures=struct(...
                    'year',     nan,...
                    'month',    nan,...
                    'day',      nan,...
                    'dayOfWeek',i,...
                    'median', 1,...
                    'timeOfDay', nan);
                
                % Check whether the general stopbar detectors exist
                tmp=[];
                tmp_general=[];
                if(~isempty(approach_out.general_stopline_detectors))
                    for j=1:size(approach_out.general_stopline_detectors,1) % Check the types of stop-line detectors: n-by-1
                        tmp_general=[tmp_general;...
                            this.get_average_data_for_movement(approach_out.general_stopline_detectors(j),queryMeasures)];
                    end  
                    % Check whether the data is good or not
                    for j=1: size(tmp_general,1) % For each detector type, there may be multiple detectors inside
                        symbol_general=all(ismember([tmp_general(j).status],{'Good Data'}));
                        if(symbol_general==0) % If one detector is bad, then quit
                            break;
                        end
                    end
                    
                    if(symbol_general==0) % Not all good data
                        data=struct(...
                            'dayofweek',i,...
                            'data', []);
                    else % Good data from general stopbar detectors
                        tmp=[tmp;tmp_general];
                        
                        % Exclusive left-turn detectors exist
                        tmp_exclusive_left=[];
                        symbol_exclusive_left=1;
                        if(~isempty(approach_out.exclusive_left_turn)) 
                            for j=1:size(approach_out.exclusive_left_turn,1) % Check the types of exclusive left-turn detectors: n-by-1
                                if(strcmp(approach_out.exclusive_left_turn(j).Movement,'Left Turn')) % Do not consider 'Left Turn Queue'
                                    tmp_exclusive_left=[tmp_exclusive_left;...
                                        this.get_average_data_for_movement(approach_out.exclusive_left_turn(j),queryMeasures)];
                                end
                            end
                            
                            % Check whether the data is good or not
                            for j=1: size(tmp_exclusive_left,1) % For each detector type, there may be multiple detectors inside
                                symbol_exclusive_left=all(ismember([tmp_exclusive_left(j).status],{'Good Data'}));
                                if(symbol_exclusive_left==0) % If one detector is bad, then quit
                                    break;
                                end
                            end
                            
                        end
                        
                        if(symbol_exclusive_left==1) % Exclusive left-turn detectors are good or do not exist
                            tmp=[tmp;tmp_exclusive_left];
                            
                            % Exclusive right-turn detectors exist
                            tmp_exclusive_right=[];
                            symbol_exclusive_right=1;
                            if(~isempty(approach_out.exclusive_right_turn))
                                for j=1:size(approach_out.exclusive_right_turn,1) % Check the types of exclusive right-turn detectors: n-by-1
                                    if(strcmp(approach_out.exclusive_right_turn(j).Movement,'Right Turn')) % Do not consider 'Right Turn Queue'
                                        tmp_exclusive_right=[tmp_exclusive_right;...
                                            this.get_average_data_for_movement(approach_out.exclusive_right_turn(j),queryMeasures)];
                                    end
                                end

                                % Check whether the data is good or not
                                for j=1: size(tmp_exclusive_right,1) % For each detector type, there may be multiple detectors inside
                                    symbol_exclusive_right=all(ismember([tmp_exclusive_right(j).status],{'Good Data'}));
                                    if(symbol_exclusive_right==0) % If one detector is bad, then quit
                                        break;
                                    end
                                end
                                
                            end     
                            
                            if(symbol_exclusive_right==1) % Exclusive right-turn detectors are good or do not exist
                                tmp=[tmp;tmp_exclusive_right];
                                
                                time=tmp(1).data.time;
                                volume=zeros(size(time));
                                for j=1:size(tmp,1)
                                    for k=1:size(tmp(j).data,1)
                                        tmp_volume=tmp(j).data(k).s_volume*tmp(j).NumberOfLanes(k);
                                        volume=volume+tmp_volume;
                                    end
                                end
                                
                                data=struct(...
                                    'dayofweek',i,...
                                    'data', struct(...
                                    'time',time,...
                                    'data',volume));

                            else % Exclusive right-turn detectors are not good
                                data=struct(...
                                    'dayofweek',i,...
                                    'data', []);
                            end

                        else % Exclusive left-turn detectors are not good
                            data=struct(...
                                'dayofweek',i,...
                                'data', []);
                        end                        
                                                
                    end
                else % Do not have general stopbar detectors
                    data=struct(...
                        'dayofweek',i,...
                        'data', []);
                end

                approach_out.data_evaluation.approach_volume.stopbar_count=[...
                        approach_out.data_evaluation.approach_volume.stopbar_count;data];
            end
        end
        
        function [approach_out]=get_advanced_data_for_approach(this,approach_in)
            % This function is to get advanced data for a given approach
            
            approach_out=approach_in;
            approach_out.data_evaluation.approach_volume.advanced_count=[];
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            for i=0:9
                queryMeasures=struct(...
                    'year',     nan,...
                    'month',    nan,...
                    'day',      nan,...
                    'dayOfWeek',i,...
                    'median', 1,...
                    'timeOfDay', nan);
                
                % Check whether the advanced detectors exist
                tmp=[];
                if(~isempty(approach_out.advanced_detectors))
                    for j=1:size(approach_out.advanced_detectors,1) % Check the types of advanced detectors: n-by-1
                        tmp=[tmp;...
                            this.get_average_data_for_movement(approach_out.advanced_detectors(j),queryMeasures)];
                    end  
                    % Check whether the data is good or not
                    for j=1: size(tmp,1) % For each detector type, there may be multiple detectors inside
                        symbol_advanced=all(ismember([tmp(j).status],{'Good Data'}));
                        if(symbol_advanced==0) % If one detector is bad, then quit
                            break;
                        end
                    end
                    
                    if(symbol_advanced==0) % Not all good data
                        data=struct(...
                            'dayofweek',i,...
                            'data', []);
                    else % Good data from general stopbar detectors
                        time=tmp(1).data.time;
                        volume=zeros(size(time));
                        for j=1:size(tmp,1)
                            for k=1:size(tmp(j).data,1)
                                tmp_volume=tmp(j).data(k).s_volume*tmp(j).NumberOfLanes(k);
                                volume=volume+tmp_volume;
                            end                            
                        end
                        
                        data=struct(...
                            'dayofweek',i,...
                            'data', struct(...
                            'time',time,...
                            'data',volume));
                    end
                else % Do not have general stopbar detectors
                    data=struct(...
                        'dayofweek',i,...
                        'data', []);
                end

                approach_out.data_evaluation.approach_volume.advanced_count=[...
                        approach_out.data_evaluation.approach_volume.advanced_count;data];
            end
        end
        
        function [movementData_Out]=get_average_data_for_movement(this,movementData_In,queryMeasures)
            % This function is used to get the flow and occ data for
            % detectors belonging to the same detector type
            
            movementData_Out=movementData_In;
            
            movementData_Out.data=[];
            movementData_Out.status=[];
            for i=1: size(movementData_Out.IDs,1) % Get the number of detectors beloning to the same detector type
                
                tmp_data=this.dataProvider_sensor.clustering(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                
                % Save the status of the returned data: for each detector
                movementData_Out.status=[movementData_Out.status;{tmp_data.status}];
                movementData_Out.data=[movementData_Out.data;tmp_data.data];
                
            end
        end
        
        
    end
  
end

