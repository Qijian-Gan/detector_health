classdef data_evaluation
    properties
        
        approachConfig              % Approach-based configuration
        
        dataProvider_sensor         % Data provider: sensor
        dataProvider_midlink        % Data provider: sensor
        dataProvider_turningCount   % Data provider: sensor
        
        excludeMovement             % Excluded detector types for the diagnostic analysis of left-turn, through and right-turn movements
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
            
            % When such detector types exist, do not perform the diagnostic
            % analysis since it is impossible to do that
            this.excludeMovement.Through={'All Movements','Left and Through','Through and Right'};
            this.excludeMovement.Left={'All Movements','Left and Right', 'Left and Through'};
            this.excludeMovement.Right={'All Movements','Left and Right', 'Through and Right'};
            
        end
        
        %% ***************Functions to get data for traffic movement*****************
        function [approach_out]=get_turning_count_for_movement(this,approach_in,movement)
            
            if(isempty(this.dataProvider_turningCount))
                error('The data provider for turning counts is empty!')
            end
            
            approach_out=approach_in;
            fileName=sprintf('TP_%s_%s_%s.mat',approach_in.intersection_name,...
                strrep(approach_in.road_name,' ', '_'),approach_in.direction);
            
            switch movement
                case 'Left Turn'
                    idx=1;
                case 'Through'
                    idx=2;
                case 'Right Turn'
                    idx=3;
                otherwise
                    error('Wrong input of traffic movements!')
            end
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            tmp=[];
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
                        'data',data_out.volume(:,idx)));
                end
                tmp=[tmp;data];
            end
            
            switch movement
                case 'Left Turn'
                    approach_out.data_evaluation.left_turn_volume.turning_count=tmp;
                case 'Through'
                    approach_out.data_evaluation.through_volume.turning_count=tmp;
                case 'Right Turn'
                    approach_out.data_evaluation.right_turn_volume.turning_count=tmp;
                otherwise
                    error('Wrong input of traffic movements!')
            end
            
        end
        
        function [approach_out]=get_stopbar_data_for_movement(this,approach_in,movement)
            % This function is to get stopbar data for a given movement
            
            if(isempty(this.dataProvider_sensor))
                error('The data provider for sensor counts is empty!')
            end
            
            approach_out=approach_in;
            
            [result]=this.check_validity_of_test_for_movement(approach_in,movement);
            
            % Get daily data:0: all, 1-7: sunday to saturday, 8: weekday, 9: weekend
            tmp=[];
            for i=0:9
                queryMeasures=struct(...
                    'year',     nan,...
                    'month',    nan,...
                    'day',      nan,...
                    'dayOfWeek',i,...
                    'median', 1,...
                    'timeOfDay', nan);
                
                if(result==1)
                    switch movement
                        case 'Left Turn'
                            [tmp_data]=this.get_turning_data_for_movement(approach_out.exclusive_left_turn,queryMeasures);
                        case 'Through'
                            [tmp_data]=this.get_turning_data_for_movement(approach_out.general_stopline_detectors,queryMeasures);
                        case 'Right Turn'
                            [tmp_data]=this.get_turning_data_for_movement(approach_out.exclusive_right_turn,queryMeasures);
                        otherwise
                            error('Wrong input of traffic movements!')
                    end
                    data=struct(...
                        'dayofweek',i,...
                        'data', tmp_data);
                else % Do not have general stopbar detectors
                    data=struct(...
                        'dayofweek',i,...
                        'data', []);
                end
                
                tmp=[tmp;data];
            end
            
            switch movement
                case 'Left Turn'
                    approach_out.data_evaluation.left_turn_volume.stopbar_count=tmp;
                case 'Through'
                    approach_out.data_evaluation.through_volume.stopbar_count=tmp;
                case 'Right Turn'
                    approach_out.data_evaluation.right_turn_volume.stopbar_count=tmp;
                otherwise
                    error('Wrong input of traffic movements!')
            end
            
        end
        
        function [data]=get_turning_data_for_movement(this,detectors,queryMeasures)
            tmp=[];
            if(~isempty(detectors)) % Detectors not empty
                for j=1:size(detectors,1) % Check the types of stop-line detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(detectors(j),queryMeasures)];
                end
                
                % Check whether the data is good or not
                for j=1: size(tmp,1) % For each detector type, there may be multiple detectors inside
                    symbol_general=all(ismember([tmp(j).status],{'Good Data'}));
                    if(symbol_general==0) % If one detector is bad, then quit
                        break;
                    end
                end
                
                if(symbol_general>0) % Have good data
                    time=tmp(1).data.time;
                    volume=zeros(size(tmp));
                    for j=1:size(tmp,1)
                        for k=1:size(tmp(j).data,1)
                            tmp_volume=tmp(j).data(k).s_volume*tmp(j).NumberOfLanes(k);
                            volume=volume+tmp_volume;
                        end
                    end
                    data=struct(...
                        'time',time,...
                        'data',volume);
                else % No good data
                    data=[];
                end
            else
                data=[];
            end
        end
        
        function [result]=check_validity_of_test_for_movement(this,approach_in,movement)
            
            result=1; % Set it to be valid first
            switch movement
                case 'Left Turn'
                    if(~isempty(approach_in.general_stopline_detectors)) % Other general stopbar detectors exist
                        for i=1:length(approach_in.general_stopline_detectors)
                            idx=ismember({approach_in.general_stopline_detectors(i).Movement},this.excludeMovement.Left);
                            if(idx==1)
                                result=0;
                                break;
                            end
                        end
                    end
                case 'Through'
                    if(~isempty(approach_in.general_stopline_detectors)) % Other general stopbar detectors exist
                        for i=1:length(approach_in.general_stopline_detectors)
                            idx=ismember({approach_in.general_stopline_detectors(i).Movement},this.excludeMovement.Through);
                            if(idx==1)
                                result=0;
                                break;
                            end
                        end
                    end
                case 'Right Turn'
                    if(~isempty(approach_in.general_stopline_detectors)) % Other general stopbar detectors exist
                        for i=1:length(approach_in.general_stopline_detectors)
                            idx=ismember({approach_in.general_stopline_detectors(i).Movement},this.excludeMovement.Right);
                            if(idx==1)
                                result=0;
                                break;
                            end
                        end
                    end
                otherwise
                    error('Wrong input of traffic movements!')
            end
            
        end
        %% ***************Functions to get data for approach*****************
        
        function [approach_out]=get_turning_count_for_approach(this,approach_in)
            
            if(isempty(this.dataProvider_turningCount))
                error('The data provider for turning counts is empty!')
            end
            
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
            
            if(isempty(this.dataProvider_midlink))
                error('The data provider for midlink counts is empty!')
            end
            
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
            
            if(isempty(this.dataProvider_sensor))
                error('The data provider for sensor counts is empty!')
            end
            
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
            
            if(isempty(this.dataProvider_sensor))
                error('The data provider for sensor counts is empty!')
            end
            
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
        
        %% ***************Functions to get diagnostic results*****************
        
        function [approach_out]=diagnose_approach_flow(this, approach_in,interval)
            
            approach_out=approach_in;
            
            approach_out.data_evaluation.approach_volume.diagnostic_result=[];
            
            for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend
                % Check turning counts and midlink counts
                if(~isempty(approach_in.data_evaluation.approach_volume.turning_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.midlink_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.turning_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.midlink_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Turning_Count_VS_Midlink_Count',...
                    'result',result)];
                
                % Check turning counts and stopbar counts
                if(~isempty(approach_in.data_evaluation.approach_volume.turning_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.stopbar_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.turning_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.stopbar_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Turning_Count_VS_Stopbar_Count',...
                    'result',result)];
                
                % Check turning counts and advanced counts
                if(~isempty(approach_in.data_evaluation.approach_volume.turning_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.advanced_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.turning_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.advanced_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Turning_Count_VS_Advanced_Count',...
                    'result',result)];
                
                % Check midlink counts and stopbar counts
                if(~isempty(approach_in.data_evaluation.approach_volume.midlink_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.stopbar_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.midlink_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.stopbar_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Midlink_Count_VS_Stopbar_Count',...
                    'result',result)];
                
                % Check midlink counts and advanced counts
                if(~isempty(approach_in.data_evaluation.approach_volume.midlink_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.advanced_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.midlink_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.advanced_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Midlink_Count_VS_Advanced_Count',...
                    'result',result)];
                
                
                % Check stopbar counts and advanced counts
                if(~isempty(approach_in.data_evaluation.approach_volume.stopbar_count(i).data) && ...
                        ~isempty(approach_in.data_evaluation.approach_volume.advanced_count(i).data))
                    data1=approach_in.data_evaluation.approach_volume.stopbar_count(i).data;
                    data2=approach_in.data_evaluation.approach_volume.advanced_count(i).data;
                    
                    [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                else
                    result=[];
                end
                approach_out.data_evaluation.approach_volume.diagnostic_result=...
                    [approach_out.data_evaluation.approach_volume.diagnostic_result;struct(...
                    'dayofweek',i-1,...
                    'type', 'Stopbar_Count_VS_Advanced_Count',...
                    'result',result)];
                
            end
        end
        
        function [approach_out]=get_rescaled_approach_flow(this,approach_in)
            
            approach_out=approach_in;
            
            approach_out.data_evaluation.approach_volume.rescaled_flow=[];
            
            if(isempty(approach_in.data_evaluation.approach_volume.diagnostic_result))
                error('The diagnostic test result is missing!');
            else
                result=approach_in.data_evaluation.approach_volume.diagnostic_result;
            end
            
            for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend
         
                % Check the existence of stopbar counts
                exist_stopbar_count=(~isempty(approach_out.data_evaluation.approach_volume.stopbar_count(i).data));
                if(exist_stopbar_count) % If yes
                    stopbar_data=approach_out.data_evaluation.approach_volume.stopbar_count(i).data;
                else
                    stopbar_data=[];
                end
                
                exist_advanced_count=(~isempty(approach_out.data_evaluation.approach_volume.advanced_count(i).data));
                if(exist_advanced_count) % If yes
                    advanced_data=approach_out.data_evaluation.approach_volume.advanced_count(i).data;
                else
                    advanced_data=[];
                end
                
                if(~isempty(advanced_data)) % Advanced data has the highest priority
                    data=advanced_data;
                    type_A='Advanced_Count';
                else % Do not have advanced data
                    if(~isempty(stopbar_data)) % Check stopbar data
                        data=stopbar_data;
                        type_A='Stopbar_Count';
                    else % have none of them
                        data=[];
                    end
                end
                
                if(isempty(data)) % No sensor (advanced or stopbar) data available
                    approach_out.data_evaluation.approach_volume.rescaled_flow=...
                        [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                        'dayofweek',i-1,...
                        'scaled_ratio', [],...
                        'ratio_from_test',[],...
                        'scaled_data',[],...
                        'raw_data',[])];
                else % Have sensor data available
                    % Check the existence of midlink data
                    exist_midlink=(~isempty(approach_out.data_evaluation.approach_volume.midlink_count(i).data));
                    if(exist_midlink) % If yes, check the length of the data
                        length_midlink=length(approach_out.data_evaluation.approach_volume.midlink_count(i).data.data);
                    else
                        length_midlink=0;
                    end
                    
                    % Check the existence of turning count data
                    exist_turning_count=(~isempty(approach_out.data_evaluation.approach_volume.turning_count(i).data));
                    if(exist_turning_count) % If yes, check the length of the data
                        length_turning_count=length(approach_out.data_evaluation.approach_volume.turning_count(i).data.data);
                    else
                        length_turning_count=0;
                    end
                    
                    % Priorities: (i) advanced count > stopbar count; (ii) the one (turning count or midlink count) with more
                    % observed data points has a higher priority (regression result is more reliable)
                    idx=([result.dayofweek]'==i-1);
                    tmp_result=result(idx,:);
                    
                    if(length_midlink==0 && length_turning_count==0) % Not available
                        approach_out.data_evaluation.approach_volume.rescaled_flow=...
                            [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                            'dayofweek',i-1,...
                            'scaled_ratio', [],...
                            'ratio_from_test',[],...
                            'scaled_data',[],...
                            'raw_data',[])];
                    elseif((length_midlink>0 && length_turning_count==0) ||...% Midlink count available
                            (length_midlink>0 && length_turning_count>0 && length_midlink>=length_turning_count)) % Midlink count is better
                        
                        result_midlink=tmp_result(ismember({tmp_result.type}',{sprintf('Midlink_Count_VS_%s',type_A)})).result;
                        
                        if(~isempty(result_midlink) && result_midlink.test_result) % Succeed in the cointegration test
                            scaled_data=data.data*max(1,result_midlink.test_coefficient); % Rescale the data
                            
                            approach_out.data_evaluation.approach_volume.rescaled_flow=...
                                [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                                'dayofweek',i-1,...
                                'scaled_ratio', max(1,result_midlink.test_coefficient),...
                                'ratio_from_test',result_midlink.test_coefficient,...
                                'scaled_data',struct(...
                                'time',data.time,...
                                'data',scaled_data),...
                                'raw_data', data)];
                        else % Do not do the scaling
                            approach_out.data_evaluation.approach_volume.rescaled_flow=...
                                [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                                'dayofweek',i-1,...
                                'scaled_ratio', 1,...
                                'ratio_from_test',[],...
                                'scaled_data',data,...
                                'raw_data',data)];
                        end
                        
                    elseif((length_midlink==0 && length_turning_count>0)||... % Turning count available
                            (length_midlink>0 && length_turning_count>0 && length_midlink<length_turning_count)) % Turning count is better
                        result_turning=tmp_result(ismember({tmp_result.type}',{sprintf('Turning_Count_VS_%s',type_A)})).result;
                        
                        if(~isempty(result_turning) && result_turning.test_result) % Succeed in the cointegration test
                            scaled_data=data.data*max(1,result_turning.test_coefficient); % Rescale the data
                            
                            approach_out.data_evaluation.approach_volume.rescaled_flow=...
                                [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                                'dayofweek',i-1,...
                                'scaled_ratio', max(1,result_turning.test_coefficient),...
                                'ratio_from_test',result_turning.test_coefficient,...
                                'scaled_data',struct(...
                                'time',data.time,...
                                'data',scaled_data),...
                                'raw_data', data)];
                        else % Do not do the scaling
                            approach_out.data_evaluation.approach_volume.rescaled_flow=...
                                [approach_out.data_evaluation.approach_volume.rescaled_flow;struct(...
                                'dayofweek',i-1,...
                                'scaled_ratio', 1,...
                                'ratio_from_test',[],...
                                'scaled_data', data,...
                                'raw_data', data)];
                        end
                    else
                        error('Wrong inputs of turning count and midlink count data!')
                    end
                end
            end
        end
        
        function [approach_out]=diagnose_movement_flow(this, approach_in, movement, interval)
            approach_out=approach_in;
            
            switch movement
                case 'Left Turn'
                    tmp=[];
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend
                        % Check turning counts and stopbar counts
                        if(~isempty(approach_in.data_evaluation.left_turn_volume.turning_count(i).data) && ...
                                ~isempty(approach_in.data_evaluation.left_turn_volume.stopbar_count(i).data))
                            data1=approach_in.data_evaluation.left_turn_volume.turning_count(i).data;
                            data2=approach_in.data_evaluation.left_turn_volume.stopbar_count(i).data;
                            
                            [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                        else
                            result=[];
                        end
                        tmp=[tmp;struct(...
                            'dayofweek',i-1,...
                            'type', 'Turning_Count_VS_Stopbar_Count',...
                            'result',result)];
                    end
                    approach_out.data_evaluation.left_turn_volume.diagnostic_result=tmp;
                    
                case 'Through'
                    tmp=[];
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend
                        % Check turning counts and stopbar counts
                        if(~isempty(approach_in.data_evaluation.through_volume.turning_count(i).data) && ...
                                ~isempty(approach_in.data_evaluation.through_volume.stopbar_count(i).data))
                            data1=approach_in.data_evaluation.through_volume.turning_count(i).data;
                            data2=approach_in.data_evaluation.through_volume.stopbar_count(i).data;
                            
                            [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                        else
                            result=[];
                        end
                        tmp=[tmp;struct(...
                            'dayofweek',i-1,...
                            'type', 'Turning_Count_VS_Stopbar_Count',...
                            'result',result)];
                    end
                    approach_out.data_evaluation.through_volume.diagnostic_result=tmp;
                    
                case 'Right Turn'
                    tmp=[];
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend
                        % Check turning counts and stopbar counts
                        if(~isempty(approach_in.data_evaluation.right_turn_volume.turning_count(i).data) && ...
                                ~isempty(approach_in.data_evaluation.right_turn_volume.stopbar_count(i).data))
                            data1=approach_in.data_evaluation.right_turn_volume.turning_count(i).data;
                            data2=approach_in.data_evaluation.right_turn_volume.stopbar_count(i).data;
                            
                            [result]=this.compare_traffic_flow_between_two_data_sources(data1,data2,interval);
                        else
                            result=[];
                        end
                        tmp=[tmp;struct(...
                            'dayofweek',i-1,...
                            'type', 'Turning_Count_VS_Stopbar_Count',...
                            'result',result)];
                    end
                    approach_out.data_evaluation.right_turn_volume.diagnostic_result=tmp;
                    
                otherwise
                    error('Wrong input of traffic movements!')
            end
        end
        
        function [approach_out]=get_scaled_movement_flow(this, approach_in,movement)
            
            approach_out=approach_in;
            
            switch movement
                case 'Left Turn'
                    approach_out.data_evaluation.left_turn_volume.rescaled_flow=[];
                    
                    % Left turns
                    if(isempty(approach_in.data_evaluation.left_turn_volume.diagnostic_result))
                        error('The diagnostic test result for left turns is missing!');
                    end                  
                    
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend                        
                        % For left-turn movements
                        [scaled_ratio_left,scaled_data_left,raw_data_left]=this.rescale_data_for_movement...
                            (approach_out.data_evaluation.left_turn_volume.turning_count(i).data,...
                            approach_out.data_evaluation.left_turn_volume.stopbar_count(i).data,...
                            approach_out.data_evaluation.left_turn_volume.diagnostic_result(i).result);
                        
                        approach_out.data_evaluation.left_turn_volume.rescaled_flow=...
                            [approach_out.data_evaluation.left_turn_volume.rescaled_flow;struct(...
                            'dayofweek',i-1,...
                            'scaled_ratio', scaled_ratio_left,...
                            'scaled_data',scaled_data_left,...
                            'raw_data', raw_data_left)];
                        
                    end
                    
                case 'Through'
                    approach_out.data_evaluation.through_volume.rescaled_flow=[];
                    
                    % Through
                    if(isempty(approach_in.data_evaluation.through_volume.diagnostic_result))
                        error('The diagnostic test result for through movements is missing!');
                    end
                    
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend                        
                        % For through movements
                        [scaled_ratio_through,scaled_data_through,raw_data_through]=this.rescale_data_for_movement...
                            (approach_out.data_evaluation.through_volume.turning_count(i).data,...
                            approach_out.data_evaluation.through_volume.stopbar_count(i).data,...
                            approach_out.data_evaluation.through_volume.diagnostic_result(i).result);
                        
                        approach_out.data_evaluation.through_volume.rescaled_flow=...
                            [approach_out.data_evaluation.through_volume.rescaled_flow;struct(...
                            'dayofweek',i-1,...
                            'scaled_ratio', scaled_ratio_through,...
                            'scaled_data',scaled_data_through,...
                            'raw_data', raw_data_through)];                        
                    end
                    
                case 'Right Turn'
                    approach_out.data_evaluation.right_turn_volume.rescaled_flow=[];
                    
                    % Right turns
                    if(isempty(approach_in.data_evaluation.right_turn_volume.diagnostic_result))
                        error('The diagnostic test result for right turns is missing!');
                    end
                    
                    for i=1:10 % Case from 0: 9, where 0=all, 1:7=Sunday: Satursday, 8=weekday, 9=weekend                        
                        % For through movements
                        [scaled_ratio_right,scaled_data_right,raw_data_right]=this.rescale_data_for_movement...
                            (approach_out.data_evaluation.right_turn_volume.turning_count(i).data,...
                            approach_out.data_evaluation.right_turn_volume.stopbar_count(i).data,...
                            approach_out.data_evaluation.right_turn_volume.diagnostic_result(i).result);
                        
                        approach_out.data_evaluation.right_turn_volume.rescaled_flow=...
                            [approach_out.data_evaluation.right_turn_volume.rescaled_flow;struct(...
                            'dayofweek',i-1,...
                            'scaled_ratio', scaled_ratio_right,...
                            'scaled_data',scaled_data_right,...
                            'raw_data', raw_data_right)];                        
                    end
            end
        end
        
        function [scaled_ratio,scaled_data,raw_data]=rescale_data_for_movement(this,turning_count,stopbar_count,result)
            
            % Check the existence of stopbar counts and turning counts
            exist_stopbar_count=(~isempty(stopbar_count));            
            exist_turning_count=(~isempty(turning_count));
            if(exist_stopbar_count && exist_turning_count) % If both yes
                if(~isempty(result) && result.test_result) % Pass the test
                    scaled_ratio=max(1,result.test_coefficient);
                    scaled_data.time=stopbar_count.time;
                    scaled_data.data=stopbar_count.data*scaled_ratio;
                    raw_data=stopbar_count;
                else
                    scaled_ratio=1;
                    scaled_data=stopbar_count;
                    raw_data=stopbar_count;
                end
                
            else % No stopbar counts
                scaled_ratio=[];
                raw_data=[];
                scaled_data=[];
            end
            
        end
            
        function [result]=compare_traffic_flow_between_two_data_sources(this,data1,data2,interval)
            % This function is to compare the approach flows between two
            % data sources: Compare data1 with data2.
            
            % Aggregated to the same time interval
            data_agg1=data_evaluation.data_aggregation(data1,interval);
            data_agg2=data_evaluation.data_aggregation(data2,interval);
            
            % Call the function: Engle-Granger cointegration test
            idx=(isnan(data_agg1.data) +isnan(data_agg2.data)==0); % Do not use the nan values
            
            time_in=data_agg1.time(idx)';
            data_in=[data_agg1.data(idx);data_agg2.data(idx)]';
            
            if(sum(idx)<10)
                result=[];
            else
                test_name='ADF';
                test_statistic='t1';
                [h,pValue,stat,cValue,reg1,reg2] = egcitest(data_in,'creg','nc','rreg',test_name,'test',test_statistic);
                
                result=struct(...
                    'test','Engle-Granger cointegration test',...
                    'residual_regression',test_name,...
                    'test_statistic',test_statistic,...
                    'test_result',h,...
                    'test_data',struct(...
                    'time',time_in,...
                    'data',data_in),...
                    'test_coefficient',reg1.coeff);
            end
        end
        
    end
    
    methods(Static)
        
        function [data_agg]=data_aggregation(data_in,interval)
            % This function is aggregate the data into larger time
            % intervals. Each data point should have been converted into
            % hourly flows.
            
            % Sort the data
            time=data_in.time;
            data=data_in.data;
            
            numInterval=3600*24/interval;
            time_out=(interval:interval:3600*24);
            data_out=nan(size(time_out));
            
            for i=1:numInterval
                minTime=interval*(i-1);
                maxTime=interval*i;
                
                % Get the data points belonging to the same time interval
                idx=(time>=minTime & time < maxTime);
                
                if(sum(idx)>0)
                    tmp_data=data(idx);
                    data_out(i)=mean(tmp_data);
                end
            end
            
            data_agg.time=time_out;
            data_agg.data=data_out;
            
        end
    end
end

