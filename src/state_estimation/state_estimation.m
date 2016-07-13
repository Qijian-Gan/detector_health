classdef state_estimation
    properties

        approachConfig              % Approach-based configuration
        
        dataProvider                % Data provider
        
        default_params              % Default parameters
        params                      % Current parameters
        
        default_proportions         % Default proportions of left-turn, through, and right-turn vehicles
    end
    
    methods ( Access = public )
        
        function [this]=state_estimation(approachConfig,dataProvider)
            % This function is to do the state estimation
            
            if(isempty(approachConfig)||isempty(dataProvider))
                error('Wrong inputs');
            end
            
            this.approachConfig=approachConfig;
            this.dataProvider=dataProvider;

            % Default values
            this.default_params=struct(...
                'cycle',                                     120,...        % Cycle length
                'green_left',                                0.2,...        % Green ratio for left turns
                'green_through',                             0.35,...       % Green ratio for through movements
                'green_right',                               0.35,...       % Green ratio for right turns
                'vehicle_length',                            17,...         % Vehicle length
                'speed_threshold_for_advanced_detector',     5,...          % Speed scale to determine levels of congestion
                'speed_freeflow_for_advanced_detector',      35,...         % Speed scale to determine free-flow speed
                'flow_threshold_for_stopline_detector',      0.5,...        % Threshold to indicate low flow for stopbar detectors
                'saturation_headway',                        2.0,...        % Saturation headway
                'saturation_speed_left',                     15,...         % Left-turn speed at saturation
                'saturation_speed_right',                    15,...         % Right-turn speed at saturation
                'saturation_speed_through',                  25,...         % Speed of through movements at saturation
                'start_up_lost_time',                        3,...
                'jam_spacing',                               24,...
                'distance_advanced_detector',                200,...
                'left_turn_pocket',                          150,...
                'right_turn_pocket',                         100);           
            
            % Default proportions for left-turn, through, and right-turn
            % movements for each type of detectors
            this.default_proportions=struct(...
                'Left_Turn',                        [1, 0, 0],...           % Exclusive left turn: no through and right-turn movements
                'Left_Turn_Queue',                  [0, 0, 0],...           % Currently tends not to use this value
                'Right_Turn',                       [0, 0, 1],...           % Exclusive right turn: no through and left-turn movements
                'Right_Turn_Queue',                 [0, 0, 0],...           % Currently tends not to use this value
                'Advanced',                         [0.15, 0.8, 0.05],...   % Advanced detectors for all movements
                'Advanced_Left_Turn',               [1, 0, 0],...           % Advanced detectors for left turns only
                'Advanced_Right_Turn',              [0, 0, 1],...           % Advanced detectors for right turns only
                'Advanced_Through',                 [0, 1, 0],...           % Advanced detectors for through movements only
                'Advanced_Through_and_Right',       [0, 0.85, 0.15],...     % Advanced detectors for through and right-turn movements
                'Advanced_Left_and_Through',        [0.3, 0.7, 0],...       % Advanced detectors for left-turn and through movements
                'Advanced_Left_and_Right',          [0.5, 0, 0.5],...       % Advanced detectors for left-turn and right-turn movements
                'All_Movements',                    [0.15, 0.8, 0.05],...   % Stop-line detectors for all movements
                'Through',                          [0, 1, 0],...           % Stop-line detectors for through movements
                'Left_and_Right',                   [0.5, 0, 0.5],...       % Stop-line detectors for left-turn and right-turn movements
                'Left_and_Through',                 [0.3, 0.7, 0],...       % Stop-line detectors for left-turn and through movements
                'Through_and_Right',                [0, 0.85, 0.15]);       % Stop-line detectors for through and right-turn movements
        end
        
        %% ***************Functions to get data*****************
        
        function [approachData]=get_data_for_approach(this,approach,queryMeasures)
            % This function is to get data for a given approach with specific query measures
            
            % First, get the flow and occ data for exclusive left-turn detectors if exist
            tmp=[];
            if(~isempty(approach.exclusive_left_turn)) % Exclusive left-turn detectors exist
                for i=1:size(approach.exclusive_left_turn,1) % Check the types of exclusive left-turn detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.exclusive_left_turn(i),queryMeasures)];
                end
                approach.exclusive_left_turn=tmp;
            end
            
            % Second, get the flow and occ data for exclusive right-turn detectors if exist
            tmp=[];
            if(~isempty(approach.exclusive_right_turn))  % Exclusive right-turn detectors exist
                for i=1:size(approach.exclusive_right_turn,1) % Check the types of exclusive right-turn detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.exclusive_right_turn(i),queryMeasures)];
                end
                approach.exclusive_right_turn=tmp;
            end
            
            % Third, get the flow and occ data for advanced detectors if exist
            tmp=[];
            if(~isempty(approach.advanced_detectors)) % Advanced detectors exist
                for i=1:size(approach.advanced_detectors,1) % Check the types of advanced detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.advanced_detectors(i),queryMeasures)];
                end
                approach.advanced_detectors=tmp;
            end
            
            % Fourth, get the flow and occ data for general stopline detectors if exist
            tmp=[];
            if(~isempty(approach.general_stopline_detectors)) % General stop-line detectors exist
                for i=1:size(approach.general_stopline_detectors,1) % Check the types of stop-line detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.general_stopline_detectors(i),queryMeasures)];
                end
                approach.general_stopline_detectors=tmp;
            end
            
            % Return the average flow and occ data
            approachData=approach;
        end
        
        function [movementData_Out]=get_average_data_for_movement(this,movementData_In,queryMeasures)
            % This function is used to get the flow and occ data for
            % detectors belonging to the same detector type
            
            movementData_Out=movementData_In;
            
            movementData_Out.data=[];
            movementData_Out.avg_data=[];
            movementData_Out.status=[];
            for i=1: size(movementData_Out.IDs,1) % Get the number of detectors beloning to the same detector type
                if(~isnan(queryMeasures.year)&&~isnan(queryMeasures.month) && ~isnan(queryMeasures.day)) % For a particular date
                    tmp_data=this.dataProvider.get_data_for_a_date(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                else % For historical data
                    tmp_data=this.dataProvider.clustering(cellstr(movementData_Out.IDs(i,:)), queryMeasures);

                    if(~strcmp(tmp_data.status,'Good Data'))
                        % Not good data, try historical averages
                        tmp_data_hist=this.get_historical_average(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                        
                        if(strcmp(tmp_data_hist.status,'Good Data'))
                            % Only when it returns good historical averages
                            tmp_data=tmp_data_hist;
                        end
                    end
                end
                % Save the status of the returned data: for each detector
                movementData_Out.status=[movementData_Out.status;{tmp_data.status}];
                movementData_Out.data=[movementData_Out.data;tmp_data.data];
                
                % For the same detector type, there may be a couple of detectors. Therefore, we need to
                % get the aggregated data for the same detector type
                aggData=state_estimation.get_aggregated_data(tmp_data.data);
                movementData_Out.avg_data=[movementData_Out.avg_data;aggData];
            end
        end
        
        function [data]=get_historical_average(this,id,queryMeasures)
            % This function returns the historical average
            
            % Do not specify year, month, and day of week
            queryMeasures.year=nan;
            queryMeasures.month=nan;
            queryMeasures.dayOfWeek=nan;
            
            % Get the clustered data
            data=this.dataProvider.clustering(id, queryMeasures);
        end
        
        
        %% ***************Functions to get traffic states and estimate vehicle queues*****************
        
        function [approachData]=get_traffic_condition_by_approach(this,approach)
            % This function is to get traffic conditions by approach:
            % exclusive left turns, exclusive right turns, stop-line
            % detectors, and advanced detectors. Rates are assigned
            % according to the relation between the current occupancy and the
            % occupancy scales
            
            % Update parameter settings
            this.params=this.update_signal_setting(approach.signal_properties);
            
            % Check exclusive left turn
            approach.decision_making.exclusive_left_turn.rates=[];
            approach.decision_making.exclusive_left_turn.speeds=[];
            if(~isempty(approach.exclusive_left_turn)) % Exclusive left-turn movement exists
                for i=1:size(approach.exclusive_left_turn,1) % Check the state for each type of exclusive left-turn movments
                    % Return rates and the corresponding occupancy scales
                    [rates,speeds]=this.check_detector_status...
                        (approach.exclusive_left_turn(i).avg_data,approach.exclusive_left_turn(i).status,...
                        approach.exclusive_left_turn(i).DetectorLength, approach.exclusive_left_turn(i).NumberOfLanes,...
                        approach.exclusive_left_turn(i).Movement,'exclusive_left_turn');
                    
                    approach.decision_making.exclusive_left_turn.rates=...
                        [approach.decision_making.exclusive_left_turn.rates;rates];
                    approach.decision_making.exclusive_left_turn.speeds=...
                        [approach.decision_making.exclusive_left_turn.speeds;speeds];
                end
            end
            
            % Check exclusive right turn
            approach.decision_making.exclusive_right_turn.rates=[];
            approach.decision_making.exclusive_right_turn.speeds=[];
            if(~isempty(approach.exclusive_right_turn)) % Exclusive left-turn movement exists
                for i=1:size(approach.exclusive_right_turn,1) % Check the state for each type of exclusive right-turn movments
                    % Return rates and the corresponding occupancy scales
                    [rates,speeds]=this.check_detector_status...
                        (approach.exclusive_right_turn(i).avg_data,approach.exclusive_right_turn(i).status,...
                        approach.exclusive_right_turn(i).DetectorLength, approach.exclusive_right_turn(i).NumberOfLanes,...
                        approach.exclusive_right_turn(i).Movement,'exclusive_right_turn');
                    
                    approach.decision_making.exclusive_right_turn.rates=...
                        [approach.decision_making.exclusive_right_turn.rates;rates];
                    approach.decision_making.exclusive_right_turn.speeds=...
                        [approach.decision_making.exclusive_right_turn.speeds;speeds];
                end
            end
            
            % Check advanced detectors
            approach.decision_making.advanced_detectors.rates=[];
            approach.decision_making.advanced_detectors.speeds=[];
            if(~isempty(approach.advanced_detectors)) % Advanced detectors exist
                for i=1:size(approach.advanced_detectors,1) % Check the state for each type of advanced detectors
                    % Return rates and the corresponding occupancy scales
                    [rates,speeds]=this.check_detector_status...
                        (approach.advanced_detectors(i).avg_data,approach.advanced_detectors(i).status,...
                        approach.advanced_detectors(i).DetectorLength,approach.advanced_detectors(i).NumberOfLanes,...
                        approach.advanced_detectors(i).Movement,'advanced_detectors');
                    
                    approach.decision_making.advanced_detectors.rates=...
                        [approach.decision_making.advanced_detectors.rates;rates];
                    approach.decision_making.advanced_detectors.speeds=...
                        [approach.decision_making.advanced_detectors.speeds;speeds];
                end
            end
            
            % Check general stopline detectors
            approach.decision_making.general_stopline_detectors.rates=[];
            approach.decision_making.general_stopline_detectors.speeds=[];
            if(~isempty(approach.general_stopline_detectors)) % Stop-line detectors exist
                for i=1:size(approach.general_stopline_detectors,1) % Check the state for each type of stop-line detectors
                    % Return rates and the corresponding occupancy scales
                    [rates,speeds]=this.check_detector_status...
                        (approach.general_stopline_detectors(i).avg_data,approach.general_stopline_detectors(i).status,...
                        approach.general_stopline_detectors(i).DetectorLength, approach.general_stopline_detectors(i).NumberOfLanes,...
                        approach.general_stopline_detectors(i).Movement,'general_stopline_detectors');
                    
                    approach.decision_making.general_stopline_detectors.rates=...
                        [approach.decision_making.general_stopline_detectors.rates;rates];
                    approach.decision_making.general_stopline_detectors.speeds=...
                        [approach.decision_making.general_stopline_detectors.speeds;speeds];
                end
            end
            
            % Provide assessment according to the rates from exclusive
            % left turns, exclusive right turns, stop-line detectors, and
            % advanced detectors
            [status_assessment,queue_assessment]=this.traffic_state_and_queue_assessment(approach);
            
            approach.decision_making.status_assessment.left_turn=status_assessment(1);
            approach.decision_making.status_assessment.through=status_assessment(2);
            approach.decision_making.status_assessment.right_turn=status_assessment(3);
            
            approach.decision_making.queue_assessment.left_turn=queue_assessment(1);
            approach.decision_making.queue_assessment.through=queue_assessment(2);
            approach.decision_making.queue_assessment.right_turn=queue_assessment(3);
            
            % Return the decision making results
            approachData=approach;
        end
        
        function [rates,speeds]=check_detector_status(this,data,status,detector_length,numberOfLanes,movement,type)
            % This function is to check the status of each detector
            % belonging to the same detector type, e.g., exclusive left
            % turns
            
            numDetector=size(data,1); % Get the number of detectors
            rates=[];
            speeds=[];
            switch type
                % For stop-line detectors
                case {'exclusive_left_turn','exclusive_right_turn','general_stopline_detectors'}
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow and occupancy
                            [rate,speed]=this.get_occupancy_scale_and_rate_stopline_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,detector_length(i),numberOfLanes(i),movement,type);
                            rates=[rates;rate];
                            speeds=[speeds;speed];
                        else % Otherwise, say "Unknown"
                            rates=[rates;{'Unknown'}];
                            speeds=[speeds;0];
                        end
                    end
                    % For advanced detectors
                case 'advanced_detectors'
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow, occupancy, and
                            % detector length
                            [rate,speed]=this.get_occupancy_scale_and_rate_advanced_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,detector_length(i),numberOfLanes(i));
                            rates=[rates;rate];
                            speeds=[speeds;speed];
                        else % Otherwise, say "Unknown"
                            rates=[rates;{'Unknown'}];
                            speeds=[speeds;0];
                        end
                    end
                otherwise
                    error('Wrong input of detector type!')
            end
            
        end
        
        function [rate,speed]=get_occupancy_scale_and_rate_advanced_detector(this,flow,occ,detector_length,numberOfLanes)
            % This function is to get the rate and speed for advanced detectors. In this case, we consider advanced
            % detectors are different from other stop-line detectors since
            % traffic flow is less impacted by traffic signals
            
            % Get effective length that will occupy the advanced detectors
            effectiveLength=detector_length+this.params.vehicle_length;
            
            % Get the occupancy threshold to divide the state into low and
            % high occupancies
            occThreshold=min(flow/numberOfLanes*effectiveLength/5280/this.params.speed_threshold_for_advanced_detector,1);
            
            % Determine the rating based on the average occupancy
            if(occ>=occThreshold)
                rate={'High Occupancy'};
            else
                rate={'Low Occupancy'};
            end
            
            speed=flow/numberOfLanes*effectiveLength/5280/min(occ,1);
            
        end
        
        function [rate,speed]=get_occupancy_scale_and_rate_stopline_detector(this,flow,occ,detector_length,numberOfLanes,detectorMovement,type)
            % This function is to get the rate and speed for stop-line detectors. In this case, we consider stop-line
            % detectors (exclusive left, exclusive right, and other general stop-line detectors)
            % are different from advanced detectors since traffic flow is
            % mostly impacted by traffic signals.
            
            % Get the green ratio
            switch type
                case 'exclusive_left_turn'
                    green_ratio=this.params.green_left;
                case 'exclusive_right_turn'
                    green_ratio=this.params.green_right;
                case 'general_stopline_detectors'
                    green_ratio=this.params.green_through;
                otherwise
                    error('Wrong input of detector type!')
            end
            
            % Get the saturation speed, startup lost time, and saturation
            % headway
            % May not need to use this value if we consider the start-up
            % lost time is the same as the yellow and all-red time
            start_up_lost_time=this.params.start_up_lost_time;  
            
            saturation_headway=this.params.saturation_headway;
            
            saturation_speed_left=this.params.saturation_speed_left;
            saturation_speed_right=this.params.saturation_speed_right;
            saturation_speed_through=this.params.saturation_speed_through;
            
            time_to_pass_left=(detector_length+this.params.vehicle_length)*3600/saturation_speed_left/5280;
            time_to_pass_right=(detector_length+this.params.vehicle_length)*3600/saturation_speed_right/5280;
            time_to_pass_through=(detector_length+this.params.vehicle_length)*3600/saturation_speed_through/5280;
            
            % Get proportions of vehicles for left-turn, through, and right-turn
            % movements
            proportion_left=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Left');
            proportion_through=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Through');
            proportion_right=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Right');
            
            numVeh=flow*this.params.cycle/3600;
            numVehLeft=numVeh*proportion_left;
            numVehThrough=numVeh*proportion_through;
            numVehRight=numVeh*proportion_right;
            
            % Get the discharging time given the current flow-rate
            dischargingTime=start_up_lost_time+(time_to_pass_left*numVehLeft+...
                time_to_pass_right*numVehRight+time_to_pass_through*numVehThrough)/numberOfLanes; % Divided by number of lanes
            occ_threshold=min(1,dischargingTime/this.params.cycle+(1-green_ratio)); % Get the threshold for occupancy
            
            capacity=numberOfLanes*(3600/saturation_headway)*green_ratio; % Need to time the number of lanes
            
            if(occ<occ_threshold) % Under-saturated
                rate={'Under Saturated'};
            else
                if(flow>capacity*this.params.flow_threshold_for_stopline_detector) % Oversaturated with high flow
                    rate={'Over Saturated With No Spillback'};
                else
                    rate={'Over Saturated With Spillback'}; % Oversaturated with low flow
                end
            end
            
            speed=0; % For stopline detectors, no need to use speed information
        end
        
        function [params]=update_signal_setting(this, signal_properties)
            % This function is to update signal setttings
            
            % First, reset all values to default ones
            params=this.default_params;
            
            % Update signal settings
            if(~isempty(signal_properties))
                if(~isnan(signal_properties.CycleLength))
                    params.cycle=signal_properties.CycleLength;
                end
                if(~isnan(signal_properties.LeftTurnGreen))
                    params.green_left=signal_properties.LeftTurnGreen/params.cycle;
                end
                if(~isnan(signal_properties.ThroughGreen))
                    params.green_through=signal_properties.ThroughGreen/params.cycle;
                end
                if(~isnan(signal_properties.RightTurnGreen))
                    params.green_right=signal_properties.RightTurnGreen/params.cycle;
                end
                if(~isnan(signal_properties.LeftTurnSetting))
                    if(strcmp(signal_properties.LeftTurnSetting,'Permitted'))
                        params.saturation_speed_left=5;                        
                    elseif(strcmp(signal_properties.LeftTurnSetting,'Protected_Permitted'))
                        params.saturation_speed_left=10;
                    else
                        params.saturation_speed_left=15;
                    end
                end
            end
            
        end
        
        
        function [status_assessment,queue_assessment]=traffic_state_and_queue_assessment(this,approach)
            % This function is for traffic state and queue assessment
            
            if(isempty(approach.exclusive_left_turn)&& isempty(approach.exclusive_right_turn)...
                    && isempty(approach.general_stopline_detectors) && isempty(approach.advanced_detectors)) % No Detector
                status_assessment={'No Detector','No Detector','No Detector'};
                queue_assessment=[NaN, NaN, NaN];
                
            else              
                
                % Get the aggregated states and speeds for left-turn, through,
                % and right-turn movements for different types of detectors                 
                if(~isempty(approach.advanced_detectors))% Check advanced detectors
                    
                    % Get the states of left-turn, through, and right-turn
                    % from advanded detectors
                    possibleAdvanced.Through={'Advanced','Advanced Through','Advanced Through and Right','Advanced Left and Through'};
                    possibleAdvanced.Left={'Advanced','Advanced Left Turn', 'Advanced Left and Through', 'Advanced Left and Right' };
                    possibleAdvanced.Right={'Advanced','Advanced Right Turn','Advanced Through and Right','Advanced Left and Right' };
                    
                    [advanced_status,avg_speed]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.advanced_detectors, possibleAdvanced, approach.decision_making.advanced_detectors,'advanced detectors');
                else
                    advanced_status=[0, 0, 0];
                    avg_speed=[0, 0, 0];
                end
                                
                if(~isempty(approach.general_stopline_detectors)) % Check general stopline detectors
                    
                    % Get the states of left-turn, through, and right-turn
                    % from stopline detectors
                    possibleGeneral.Through={'All Movements','Through', 'Left and Through', 'Through and Right'};
                    possibleGeneral.Left={'All Movements','Left and Right', 'Left and Through'};
                    possibleGeneral.Right={'All Movements','Left and Right', 'Through and Right' };
                    [stopline_status,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.general_stopline_detectors, possibleGeneral,approach.decision_making.general_stopline_detectors,'stopline detectors');
                else
                    stopline_status=[0, 0, 0];
                end                
                
                if(~isempty(approach.exclusive_right_turn)) % Check exclusive right turn detectors
                    
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive right-turn detectors
                    possibleExclusiveRight.Through=[];
                    possibleExclusiveRight.Left=[];
                    possibleExclusiveRight.Right={'Right Turn','Right Turn Queue'};
                    [exc_right_status,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_right_turn,possibleExclusiveRight,approach.decision_making.exclusive_right_turn,'stopline detectors');
                else
                    exc_right_status=[0, 0, 0];
                end                
                
                if(~isempty(approach.exclusive_left_turn)) % Check exclusive left turn detectors
                    
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive left-turn detectors
                    possibleExclusiveLeft.Through=[];
                    possibleExclusiveLeft.Left={'Left Turn','Left Turn Queue'};
                    possibleExclusiveLeft.Right=[];
                    [exc_left_status,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_left_turn,possibleExclusiveLeft,approach.decision_making.exclusive_left_turn,'stopline detectors');
                else
                    exc_left_status=[0, 0, 0];
                end
                
                % Get the queue thresholds for different traffic movements
                [queue_threshold]=state_estimation.calculation_of_queue_thresholds(approach,this.default_proportions,this.params);
                
                % Get the assessment of states and queues
                [status_assessment,queue_assessment]=state_estimation.make_a_decision...
                    (this.default_params,queue_threshold,advanced_status,stopline_status,exc_right_status,exc_left_status,avg_speed);
            end
        end
        
        
    end
    
    methods(Static)
        
        %% *************** Functions to get traffic states and estimate vehicle queues *****************
        
        function [status,avg_speed]=check_aggregate_rate_by_movement_type(movement, possibleMovement, decision_making,type)
            % This function is to get the aggreagated rate by movement (left-turn, through, and right-turn) and
            % type of detectors (exclusive left, exclusive right, general stopline, and advanced detectors)
            
            % Check the number of detector types
            numType=size(movement,1);
            
            possibleThrough=possibleMovement.Through;
            possibleLeft=possibleMovement.Left;
            possibleRight=possibleMovement.Right;
            
            % Check through movements
            rateSum_through=0;   
            speedSum_through=0;  
            count_through=0;
            for i=1:numType
                idx_through=ismember(movement(i).Movement,possibleThrough);
                if(sum(idx_through)) % Find the corresponding through movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates',type);                    
                    speeds=decision_making.speeds(i,:);
                    
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_through=count_through+1;
                            rateSum_through=rateSum_through+rateNum(j);
                            speedSum_through=speedSum_through+speeds(j);
                        end
                    end
                end
            end
            if(count_through)
                rateMean_through=rateSum_through/count_through;
                speedSum_through=speedSum_through/count_through;
            else
                rateMean_through=0;
                speedSum_through=0;
            end
            
            % Check left-turn movements
            rateSum_left=0;
            speedSum_left=0;
            count_left=0;
            for i=1:numType
                idx_left=ismember(movement(i).Movement,possibleLeft);
                if(sum(idx_left)) % Find the corresponding left-turn movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates',type);
                    speeds=decision_making.speeds(i,:);
                    
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_left=count_left+1;
                            rateSum_left=rateSum_left+rateNum(j);
                            speedSum_left=speedSum_left+speeds(j);
                        end
                    end
                end
            end
            if(count_left)
                rateMean_left=rateSum_left/count_left;
                speedSum_left=speedSum_left/count_through;
            else
                rateMean_left=0;
                speedSum_left=0;
            end
            
            
            % Check right-turn movements
            rateSum_right=0;
            speedSum_right=0;
            count_right=0;
            for i=1:numType
                idx_right=ismember(movement(i).Movement,possibleRight);
                if(sum(idx_right)) % Find the corresponding right-turn movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates',type);
                    speeds=decision_making.speeds(i,:);
                    
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_right=count_right+1;
                            rateSum_right=rateSum_right+rateNum(j);
                            speedSum_right=speedSum_right+speeds(j);
                        end
                    end
                end
            end
            if(count_right)
                rateMean_right=rateSum_right/count_right;
                speedSum_right=speedSum_right/count_through;
            else
                rateMean_right=0;
                speedSum_right=0;
            end
            
            % Return mean values for different movements
            status=[rateMean_left, rateMean_through, rateMean_right];
            avg_speed=[speedSum_left,speedSum_through,speedSum_right];
        end
        
        function [queue_threshold]=calculation_of_queue_thresholds(approach,default_proportions,params)
            % This function is used to calculate queue thresholds for
            % left-turn, through, and right-turn movements
            
            % Calculate the seperation lengths and number of lanes by exclusive left-/right-turn movements
            seperation_left=0; % If no exclusive left-turn lanes, this value is zero
            num_exclusive_left_lane=0;
            num_exclusive_left_lane_queue=0;
            if(~isempty(approach.exclusive_left_turn)) % Have exclusive left turns
                for i=1:size(approach.exclusive_left_turn,1) % Loop for different types of esclusive left-turn detectors
                    left_turn_pocket=approach.exclusive_left_turn(i).LeftTurnPocket;
                    seperation_left=max(seperation_left,max(left_turn_pocket)); % Get the maximum value of the left-turn pocket
                    
                    % For exclusive left turns, currently there are two
                    % cases: 'Left Turn' and 'Left Turn Queue'. 
                    idx=ismember(approach.exclusive_left_turn(i).Movement,{'Left Turn'});
                    if(idx) % If exists
                        num_exclusive_left_lane=num_exclusive_left_lane+sum(approach.exclusive_left_turn(i).NumberOfLanes);
                    end
                    clear idx
                    
                    % We may not have 'Left Turn' detectors, use 'Left Turn
                    % Queue' if exists
                    idx=ismember(approach.exclusive_left_turn(i).Movement,{'Left Turn Queue'});
                    if(idx) % If exists
                        num_exclusive_left_lane_queue=num_exclusive_left_lane_queue+sum(approach.exclusive_left_turn(i).NumberOfLanes);
                    end
                end
            end
            num_exclusive_left_lane=max(num_exclusive_left_lane,num_exclusive_left_lane_queue);
            
            seperation_right=0; % If no exclusive right-turn lanes, this value is zero
            num_exclusive_right_lane=0;
            num_exclusive_right_lane_queue=0;
            if(~isempty(approach.exclusive_right_turn)) % Have exclusive right turns
                for i=1:size(approach.exclusive_right_turn,1) % Loop for different types of esclusive right-turn detectors
                    right_turn_pocket=approach.exclusive_right_turn(i).RightTurnPocket;
                    seperation_right=max(seperation_right,max(right_turn_pocket)); % Get the maximum value
                    
                    % For exclusive right turns, currently there are two
                    % cases: 'Right Turn' and 'Right Turn Queue'. 
                    idx=ismember(approach.exclusive_right_turn(i).Movement,{'Right Turn'});
                    if(idx)
                        num_exclusive_right_lane=num_exclusive_right_lane+sum(approach.exclusive_right_turn(i).NumberOfLanes);
                    end
                    clear idx
                    
                    idx=ismember(approach.exclusive_right_turn(i).Movement,{'Right Turn Queue'});
                    if(idx)
                        num_exclusive_right_lane_queue=num_exclusive_right_lane_queue+sum(approach.exclusive_right_turn(i).NumberOfLanes);
                    end
                end
            end
            num_exclusive_right_lane=max(num_exclusive_right_lane,num_exclusive_right_lane_queue);
            
            % Calculate the lane numbers for left turn, through, and right turn movements at
            % general stopline detectors
            movement_lane_proportion_general=[0, 0, 0]; % Left, through, right
            if(~isempty(approach.general_stopline_detectors)) % Have stopline detectors
                for i=1:size(approach.general_stopline_detectors,1) % Loop for all types of general stopline detectors
                    for j=1: size(approach.general_stopline_detectors(i).Movement,1) % Loop for all detectors belonging to the same type
                        % Get the number of lanes
                        detectorMovement=approach.general_stopline_detectors(i).Movement(j,:);
                        num_of_lane=approach.general_stopline_detectors(i).NumberOfLanes(j);
                        
                        % Get the porportions of traffic movements
                        proportion_left=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Left');
                        proportion_through=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Through');
                        proportion_right=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Right');
                        
                        % Update the lane proportions
                        movement_lane_proportion_general=movement_lane_proportion_general+...
                            num_of_lane*[proportion_left,proportion_through,proportion_right];
                    end
                end
            end
            
            % Calculate the lane numbers for left turn, through, and right turn movements at
            % advanded detectors
            movement_lane_proportion_advanced=[0, 0, 0]; % Left, through, right
            distance_advanced_detector=0; % If no advanced detectors, this value is zero
            if(~isempty(approach.advanced_detectors)) % Have advanced detectors
                for i=1:size(approach.advanced_detectors,1) % Loop for all types of advanced detectors
                    for j=1: size(approach.advanced_detectors(i).Movement,1) % Loop for all detectors belonging to the same type
                        detectorMovement=approach.advanced_detectors(i).Movement(j,:);
                        num_of_lane=approach.advanced_detectors(i).NumberOfLanes(j);
                        
                        proportion_left=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Left');
                        proportion_through=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Through');
                        proportion_right=state_estimation.find_traffic_proportion(detectorMovement,default_proportions,'Right');
                        
                        movement_lane_proportion_advanced=movement_lane_proportion_advanced+...
                            num_of_lane*[proportion_left,proportion_through,proportion_right];
                    end
                    
                    distance_to_stopbar=approach.advanced_detectors(i).DistanceToStopbar;
                    distance_advanced_detector=max(distance_advanced_detector,max(distance_to_stopbar)); % Get the maximum distance of advanced detectors
                end
            end
            if(distance_advanced_detector==0) % No advanced detectors, use the default values
                distance_advanced_detector=params.distance_advanced_detector;
            end
            
            % Determine the queue thresholds for left-turn, through, and
            % right-turn movements
            num_jam_vehicle_per_lane=5280/params.jam_spacing; % Number of jammed vehicles for one mile
            
            % Check the completness of detector coverage
            % For left turns
            [queue_threshold.left]=state_estimation.get_queue_threshold_for_movement(num_exclusive_left_lane,movement_lane_proportion_advanced,...
                movement_lane_proportion_general,num_jam_vehicle_per_lane,seperation_left,...
                distance_advanced_detector,approach.link_properties.LinkLength,'Left');
            % For right-turn movements
            [queue_threshold.right]=state_estimation.get_queue_threshold_for_movement(num_exclusive_right_lane,movement_lane_proportion_advanced,...
                movement_lane_proportion_general,num_jam_vehicle_per_lane,seperation_right,...
                distance_advanced_detector,approach.link_properties.LinkLength,'Right');
            % For through movements
            [queue_threshold.through]=state_estimation.get_queue_threshold_for_movement(0,movement_lane_proportion_advanced,...
                movement_lane_proportion_general,num_jam_vehicle_per_lane,max(seperation_left,seperation_right),...
                distance_advanced_detector,approach.link_properties.LinkLength,'Through');
            
            
        end
        
        function [threshold]=get_queue_threshold_for_movement(num_exclusive_lane,movement_lane_proportion_advanded,movement_lane_proportion_general,...
                num_jam_vehicle_per_lane,seperation,distance_advanded_detector,link_length,type)
            % This function is used to calculate queue thresholds for a
            % particular traffic movenent (left, right, and through)
            
            switch type
                case 'Left'
                    idx=1;
                case 'Through'
                    idx=2;
                case 'Right'
                    idx=3;
                otherwise
                    error('Wrong input of movement type!');
            end
            
            if(movement_lane_proportion_advanded(idx)==0) % No information at advanced detectors
                if(movement_lane_proportion_general(idx)>0 || num_exclusive_lane >0) % But downstream has information
                    % Over-write the number of advanced lanes
                    if(idx==2) % For through movement
                        movement_lane_proportion_advanded(idx)=movement_lane_proportion_general(idx)/2;
                    else % For left and right turns: get the mean
                        movement_lane_proportion_advanded(idx)=(num_exclusive_lane+movement_lane_proportion_general(idx))/2;
                    end
                end
            else % Have information from advandec detectors
                if(movement_lane_proportion_general(idx)==0 && num_exclusive_lane ==0) % But downstream has no information
                    movement_lane_proportion_general(idx)=movement_lane_proportion_advanded(idx);
                end
            end
            
            % Calculate different component of queues
            if(movement_lane_proportion_advanded(idx)==0 && movement_lane_proportion_general(idx)==0 ...
                    && num_exclusive_lane ==0) % No detector
                queue_exclusive=nan;
                queue_general=nan;
                queue_advanced=nan;
            else
                queue_exclusive=num_exclusive_lane*num_jam_vehicle_per_lane*seperation/5280;
                queue_general=(movement_lane_proportion_general(idx)*seperation+...
                        movement_lane_proportion_advanded(idx)*(distance_advanded_detector-seperation))*num_jam_vehicle_per_lane/5280;
                    queue_advanced=movement_lane_proportion_advanded(idx)*num_jam_vehicle_per_lane...
                    *(link_length-distance_advanded_detector)/5280;
            end
            
            threshold.to_advanced=queue_exclusive+queue_general;
            threshold.to_link=queue_exclusive+queue_general+queue_advanced;
        end
        
        function [status,queue]=make_a_decision(default_params,queue_threshold,advanced_status,stopline_status,exc_right_status,exc_left_status,avg_speed)
            % This function is to make a final decision for left-turn,
            % through, and right-turn movements at the approach level

            
            % Get the states for left-turn, through, and right-turn
            % movements
            downstream_status_left=ceil(state_estimation.meanwithouzeros([exc_left_status(1),stopline_status(1)]));
            advanced_status_left=advanced_status(1);
            
            downstream_status_through=stopline_status(2);
            advanced_status_through=advanced_status(2);
            
            downstream_status_right=ceil(state_estimation.meanwithouzeros([exc_right_status(3),stopline_status(3)]));
            advanced_status_right=advanced_status(3);
            
            % Check the existence of lane blockage by other movements
            blockage=[0,0,0];
            % Check left turn
            if(downstream_status_left==3 && advanced_status_left==2) % Left turn congested
                if(advanced_status_through==2 && downstream_status_through==1) % Through is blocked
                    blockage(1)=1;
                end
            end
            % Check through
            if(downstream_status_through==3 && advanced_status_through==2) % Through congested
                if((downstream_status_right==1 && advanced_status_right==2)||...
                        (downstream_status_left==1 && advanced_status_left==2)) % Left or right is blocked
                    blockage(2)=1;
                end
            end
            % Check right turn
            if(downstream_status_right==3 && advanced_status_right==2) % Right turn congested
                if(advanced_status_through==2 && downstream_status_through==1) % Through is blocked
                    blockage(3)=1;
                end
            end
            
            status=cell(3,1);
            queue=zeros(3,1);
            speed_threshold=default_params.speed_threshold_for_advanced_detector;
            speed_freeflow=default_params.speed_freeflow_for_advanced_detector;
            
            [status(1,1), queue(1)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_left,advanced_status_left,avg_speed,speed_threshold,speed_freeflow,'Left');
            [status(2,1), queue(2)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_through,advanced_status_through,avg_speed,speed_threshold,speed_freeflow,'Through');
            [status(3,1), queue(3)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_right,advanced_status_right,avg_speed,speed_threshold,speed_freeflow,'Right');
            
            
        end
        
        function [status, queue]=decide_status_queue_for_movement(blockage,queue_threshold,downstream_status,advanced_status,avg_speed,speed_threshold,speed_freeflow,type)
            
            switch type
                case 'Left'
                    threshold=queue_threshold.left;
                    blockage(1)=0;
                    speed=avg_speed(1);
                case 'Through'
                    threshold=queue_threshold.through;
                    blockage(2)=0;
                    speed=avg_speed(2);
                case 'Right'
                    threshold=queue_threshold.right;
                    blockage(3)=0;
                    speed=avg_speed(3);
                otherwise
                    error('Wrong input of movements!')
            end
            
            
            if(advanced_status==2) % Upstream high occupancy
                if(downstream_status==0) % No downstream detector
                    if(sum(blockage)) % Lane blockage by other lanes
                        status={'Lane Blockage By Other Movements'};
                        queue=max(0,(speed_threshold-speed)/speed_threshold*(threshold.to_link-threshold.to_advanced));
                    else
                        status={'Long Queue'};
                        queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                            *(threshold.to_link-threshold.to_advanced));
                    end
                elseif(downstream_status==1)
                    status={'Lane Blockage By Other Movements'};
                    queue=max(0,(speed_threshold-speed)/speed_threshold...
                        *(threshold.to_link-threshold.to_advanced));
                elseif(downstream_status==2)
                    status={'Oversaturated With Long Queue'};
                    queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                        *(threshold.to_link-threshold.to_advanced));
                elseif(downstream_status==3)
                    status={'Downstream Spillback With Long Queue'};
                    queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                        *(threshold.to_link-threshold.to_advanced));
                end
            elseif(advanced_status==1) % Upstream low occupancy
                if(downstream_status==0) % No downstream detector
                    status={'Short Queue'};
                    queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                elseif(downstream_status==1)
                    status={'No Congestion'};
                    queue=0;
                elseif(downstream_status==2)
                    status={'Oversaturated With Short Queue'};
                    queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                elseif(downstream_status==3)
                    status={'Downstream Spillback With Short Queue'};
                    queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                end
             elseif(advanced_status==0) % No upstream information
                if(downstream_status==0) % No downstream detector
                    status={'Unknown'};
                    queue=-1;
                elseif(downstream_status==1)
                    if(sum(blockage))
                        status={'Lane Blockage By Other Movements'};
                        queue=max(0,(threshold.to_link-threshold.to_advanced)*rand); % Randomly pick a value
                    else
                        status={'No Congestion'};
                        queue=0;
                    end
                elseif(downstream_status==2)
                    status={'Oversaturated'};
                    queue=0.5*threshold.to_link*rand; % Randomly pick a value
                elseif(downstream_status==3)
                    status={'Downstream Spillback'};
                    queue=0.5*threshold.to_link+0.5*threshold.to_link*rand;
                end
            end
        end
        
        function [proportion]=find_traffic_proportion(detectorMovement,default_proportion,movement)
            switch movement
                case 'Left'
                    idx=1;
                case 'Through'
                    idx=2;
                case 'Right'
                    idx=3;
                otherwise
                    error('Wrong input of traffic movement!')
            end
            
            switch detectorMovement
                case 'Left Turn'
                    proportion=default_proportion.Left_Turn(idx);
                case 'Left Turn Queue'
                    proportion=default_proportion.Left_Turn_Queue(idx);
                case 'Right Turn'
                    proportion=default_proportion.Right_Turn(idx);
                case 'Right Turn Queue'
                    proportion=default_proportion.Right_Turn_Queue(idx);
                case 'Advanced'
                    proportion=default_proportion.Advanced(idx);
                case 'Advanced Left Turn'
                    proportion=default_proportion.Advanced_Left_Turn(idx);
                case 'Advanced Right Turn'
                    proportion=default_proportion.Advanced_Right_Turn(idx);
                case 'Advanced Through'
                    proportion=default_proportion.Advanced_Through(idx);
                case 'Advanced Through and Right'
                    proportion=default_proportion.Advanced_Through_and_Right(idx);
                case 'Advanced Left and Through'
                    proportion=default_proportion.Advanced_Left_and_Through(idx);
                case 'Advanced Left and Right'
                    proportion=default_proportion.Advanced_Left_and_Right(idx);
                case 'All Movements'
                    proportion=default_proportion.All_Movements(idx);
                case 'Through'
                    proportion=default_proportion.Through(idx);
                case 'Left and Right'
                    proportion=default_proportion.Left_and_Right(idx);
                case 'Left and Through'
                    proportion=default_proportion.Left_and_Through(idx);
                case 'Through and Right'
                    proportion=default_proportion.Through_and_Right(idx);
                otherwise
                    error('Corresponding movment not found!')
            end
            
        end
        
        function [output]=meanwithouzeros(input)
            % This function is to return the mean value of a column or row
            % vector excluding zeros
            
            if(sum(input)==0)
                output=0;
            else
                output=mean(input(input~=0));
            end
        end
        
        function [rateNum]=convert_rate_to_num(rates,type)
            % This function is to convert a rate to its corresponding
            % number
            
            rateNum=zeros(size(rates));
            
            switch type
                case 'advanced detectors'
                    for i=1:length(rates)
                        if(strcmp(rates(i),{'High Occupancy'})) % For advanded detectors
                            rateNum(i)=2;
                        elseif(strcmp(rates(i),{'Low Occupancy'})) % For advanded detectors
                            rateNum(i)=1;
                        elseif(strcmp(rates(i),{'Unknown'}))
                            rateNum(i)=0;
                        end
                    end
                case 'stopline detectors'
                    for i=1:length(rates)
                        if(strcmp(rates(i),{'Under Saturated'}))
                            rateNum(i)=1;
                        elseif(strcmp(rates(i),{'Over Saturated With No Spillback'}))
                            rateNum(i)=2;
                        elseif(strcmp(rates(i),{'Over Saturated With Spillback'}))
                            rateNum(i)=3;
                        elseif(strcmp(rates(i),{'Unknown'}))
                            rateNum(i)=0;
                        end
                    end
                otherwise
                    error('Wrong input of detector types!');
            end
        end
        
        function [rates]=convert_num_to_rate(rateNum,type)
            % This function is to convert a number to its corresponding
            % rate
            
            rateNum=round(rateNum);
            rates=cell(size(rateNum));
            
            switch type
                case 'advanced detectors'
                    for i=1:length(rateNum)
                        if(rateNum(i)==2)
                            rates(i)={'High Occupancy'};
                        elseif(rateNum(i)==1)
                            rates(i)={'Low Occupancy'};
                        else
                            rates(i)={'Unknown'};
                        end
                    end
                case 'stopline detectors'
                    for i=1:length(rateNum)
                        if(rateNum(i)==3)
                            rates(i)={'Over Saturated With Spillback'};
                        elseif(rateNum(i)==2)
                            rates(i)={'Over Saturated With No Spillback'};
                        elseif(rateNum(i)==1)
                            rates(i)={'Under Saturated'};
                        else
                            rates(i)={'Unknown'};
                        end
                    end
                otherwise
                    error('Wrong input of detector types!');
            end
        end
        
        
        %% *************** Functions to get data *****************
        function [aggData]=get_aggregated_data(data)
            % This function is to get the aggregated data for a given time
            % period
            
            if(isempty(data.time)) % If data is empty, return nan values
                aggData=struct(...
                    'startTime',nan,...
                    'endTime', nan,...
                    'avgFlow', nan,...
                    'avgOccupancy', nan,...
                    'medFlow', nan,...
                    'medOccupancy', nan,...
                    'maxFlow', nan,...
                    'maxOccupancy', nan,...
                    'minFlow', nan,...
                    'minOccupancy', nan);
            else % If not
                aggData=struct(...
                    'startTime',data.time(1),...                        % Start time
                    'endTime', data.time(end),...                       % End time
                    'avgFlow', mean(data.s_volume,'omitnan'),...                  % Average flow
                    'avgOccupancy', mean(data.s_occupancy,'omitnan')/3600,...     % Average occupancy
                    'medFlow', median(data.s_volume,'omitnan'),...                % Median of flow
                    'medOccupancy', median(data.s_occupancy,'omitnan')/3600,...   % Median of occupancy
                    'maxFlow', max(data.s_volume),...                   % Maximum value of flow
                    'maxOccupancy', max(data.s_occupancy)/3600,...      % Maximum value of occupancy
                    'minFlow', min(data.s_volume),...                   % Minimum value of flow
                    'minOccupancy', min(data.s_occupancy)/3600);        % Minimum value of occupancy
            end
        end
        
        
        %% *************** Functions to extract estimation performance *****************
        function extract_to_excel(appStateEst,outputFolder,outputFileName)
            % This function is extract the state estimation results to an
            % excel file
            
            outputFileName=fullfile(outputFolder,outputFileName);
            
            xlswrite(outputFileName,[{'Intersection Name'},{'Road Name'},{'Direction'},...
                {'Left Turn Status'},{'Through movement Status'},{'Right Turn Status'},...
                {'Left Turn Queue'},{'Through movement Queue'},{'Right Turn Queue'}]);
            
            % Write intersection and detector information
            data=vertcat(appStateEst.decision_making);
            assessment=vertcat(data.status_assessment);
            left_turn=[assessment.left_turn]';
            through=([assessment.through])';
            right_turn=([assessment.right_turn])';
            
            xlswrite(outputFileName,[...
                {appStateEst.intersection_name}',...
                {appStateEst.road_name}',...
                {appStateEst.direction}',...
                left_turn,...
                through,...
                right_turn],sprintf('A2:F%d',length(left_turn)+1));
            
            queue=vertcat(data.queue_assessment);
            left_turn_queue=ceil([queue.left_turn]');
            through_queue=ceil([queue.through]');
            right_turn_queue=ceil([queue.right_turn]');
            
            xlswrite(outputFileName,[...
                left_turn_queue,...
                through_queue,...
                right_turn_queue],sprintf('G2:I%d',length(left_turn_queue)+1));
            
            
        end
    end
end

