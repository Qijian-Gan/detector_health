classdef state_estimation 
    properties
        
        detectorConfig              % Detector-based configuration
        
        approachConfig              % Approach-based configuration
        
        dataProvider                % Data provider
        
        default_params              % Default parameters
        params                      % Current parameters
        
        default_proportions         % Default proportions of left-turn, through, and right-turn vehicles
    end
    
    methods ( Access = public )
        
        function [this]=state_estimation(approachConfig,dataProvider,detectorConfig)
            % This function is to do the state estimation
            
            if(isempty(approachConfig)||isempty(dataProvider))
                error('Wrong inputs');
            end
            
            this.approachConfig=approachConfig;
            this.dataProvider=dataProvider;
            
            if(nargin==3)
                this.detectorConfig=detectorConfig;
            end          
            
            % Default values
            this.default_params=struct(...
                'cycle',                             120,...        % Cycle length
                'green_left',                        0.15,...       % Green ratio for left turns
                'green_through',                     0.35,...       % Green ratio for through movements
                'green_right',                       0.35,...       % Green ratio for right turns
                'detector_length_left_turn',         50,...         % Length for left-turn detectors
                'detector_length_advanced',          6,...          % Length for advanced detectors
                'detector_length',                   25,...         % Length for through and right-turn detectors
                'vehicle_length',                    17,...         % Vehicle length
                'speed_scales',                      [30 15 5],...  % Speed scales to determine levels of congestion
                'saturation_headway',                2.0,...        % Saturation headway
                'saturation_speed_left_and_right',   15,...         % Left-turn and right-turn speed at saturation
                'saturation_speed_through',          25,...         % Speed of through movements at saturation
                'start_up_lost_time',                3);            % Start-up lost time at the beginning of Green
            
            % Default proportions for left-turn, through, and right-turn
            % movements for each type of detectors
            this.default_proportions=struct(...
                'Left_Turn',                        [1, 0, 0],...           % Exclusive left turn: no through and right-turn movements
                'Left_Turn_Queue',                  [0, 0, 0],...           % Currently tends not to use this value
                'Right_Turn',                       [0, 0, 1],...           % Exclusive right turn: no through and left-turn movements
                'Right_Turn_Queue',                 [0, 0, 0],...           % Currently tends not to use this value
                'Advanced',                         [0.1, 0.85, 0.05],...   % Advanced detectors for all movements
                'Advanced_Left_Turn',               [1, 0, 0],...           % Advanced detectors for left turns only
                'Advanced_Right_Turn',              [0, 0, 1],...           % Advanced detectors for right turns only
                'Advanced_Through',                 [0, 1, 0],...           % Advanced detectors for through movements only
                'Advanced_Through_and_Right',       [0, 0.85, 0.15],...     % Advanced detectors for through and right-turn movements
                'Advanced_Left_and_Through',        [0.3, 0.7, 0],...       % Advanced detectors for left-turn and through movements
                'Advanced_Left_and_Right',          [0.5, 0, 0.5],...       % Advanced detectors for left-turn and right-turn movements
                'All_Movements',                    [0.1, 0.85, 0.05],...   % Stop-line detectors for all movements
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
                tmp_data=this.dataProvider.clustering(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                
                if(~strcmp(tmp_data.status,'Good Data')) 
                    % Not good data, try historical averages
                    tmp_data_hist=this.get_historical_average(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                    
                    if(strcmp(tmp_data_hist.status,'Good Data'))
                        % Only when it returns good historical averages
                        tmp_data=tmp_data_hist;
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
        
        
        %% ***************Functions to get traffic states*****************
        
        function [approachData]=get_traffic_condition_by_approach(this,approach,params)
            % This function is to get traffic conditions by approach:
            % exclusive left turns, exclusive right turns, stop-line
            % detectors, and advanced detectors. Rates are assigned
            % according to the relation between the current occupancy and the
            % occupancy scales
            
            % For each approach, we may need to update its parameter
            % settings. For example, signal settings
            if(nargin>=3) % Have new settings
                this=this.update_param_setting(params);
            else % Do not have param settings
                this=this.update_param_setting;
            end
            
            % Check exclusive left turn
            approach.decision_making.exclusive_left_turn.rates=[];
            approach.decision_making.exclusive_left_turn.scales=[];
            approach.decision_making.exclusive_left_turn.queues=[];
            
            if(~isempty(approach.exclusive_left_turn)) % Exclusive left-turn movement exists
                for i=1:size(approach.exclusive_left_turn,1) % Check the state for each type of exclusive left-turn movments
                    % Return rates and the corresponding occupancy scales
                    [rates,scales,queues]=this.check_detector_status...
                        (approach.exclusive_left_turn(i).avg_data,approach.exclusive_left_turn(i).status,...
                        approach.exclusive_left_turn(i).Movement,'exclusive_left_turn');
                    
                    approach.decision_making.exclusive_left_turn.rates=...
                        [approach.decision_making.exclusive_left_turn.rates;rates];
                    approach.decision_making.exclusive_left_turn.scales=...
                        [approach.decision_making.exclusive_left_turn.scales;scales];
                    approach.decision_making.exclusive_left_turn.queues=...
                        [approach.decision_making.exclusive_left_turn.queues;queues];
                end
            end
            
            % Check exclusive right turn
            approach.decision_making.exclusive_right_turn.rates=[];
            approach.decision_making.exclusive_right_turn.scales=[];
            approach.decision_making.exclusive_right_turn.queues=[];
            if(~isempty(approach.exclusive_right_turn)) % Exclusive left-turn movement exists
                for i=1:size(approach.exclusive_right_turn,1) % Check the state for each type of exclusive right-turn movments
                    % Return rates and the corresponding occupancy scales
                    [rates,scales,queues]=this.check_detector_status...
                        (approach.exclusive_right_turn(i).avg_data,approach.exclusive_right_turn(i).status,...
                        approach.exclusive_right_turn(i).Movement,'exclusive_right_turn');
                    
                    approach.decision_making.exclusive_right_turn.rates=...
                        [approach.decision_making.exclusive_right_turn.rates;rates];
                    approach.decision_making.exclusive_right_turn.scales=...
                        [approach.decision_making.exclusive_right_turn.scales;scales];
                    approach.decision_making.exclusive_right_turn.queues=...
                        [approach.decision_making.exclusive_right_turn.queues;queues];
                end
            end
            
            % Check advanced detectors
            approach.decision_making.advanced_detectors.rates=[];
            approach.decision_making.advanced_detectors.scales=[];
            approach.decision_making.advanced_detectors.queues=[];
            if(~isempty(approach.advanced_detectors)) % Advanced detectors exist
                for i=1:size(approach.advanced_detectors,1) % Check the state for each type of advanced detectors
                    % Return rates and the corresponding occupancy scales
                    [rates,scales,queues]=this.check_detector_status...
                        (approach.advanced_detectors(i).avg_data,approach.advanced_detectors(i).status,...
                        approach.advanced_detectors(i).Movement,'advanced_detectors');
                    
                    approach.decision_making.advanced_detectors.rates=...
                        [approach.decision_making.advanced_detectors.rates;rates];
                    approach.decision_making.advanced_detectors.scales=...
                        [approach.decision_making.advanced_detectors.scales;scales];
                    approach.decision_making.advanced_detectors.queues=...
                        [approach.decision_making.advanced_detectors.queues;queues];
                end
            end
            
            % Check general stopline detectors
            approach.decision_making.general_stopline_detectors.rates=[];
            approach.decision_making.general_stopline_detectors.scales=[];
            approach.decision_making.general_stopline_detectors.queues=[];
            if(~isempty(approach.general_stopline_detectors)) % Stop-line detectors exist
                for i=1:size(approach.general_stopline_detectors,1) % Check the state for each type of stop-line detectors 
                    % Return rates and the corresponding occupancy scales
                    [rates,scales,queues]=this.check_detector_status...
                        (approach.general_stopline_detectors(i).avg_data,approach.general_stopline_detectors(i).status,...
                        approach.general_stopline_detectors(i).Movement,'general_stopline_detectors');
                    
                    approach.decision_making.general_stopline_detectors.rates=...
                        [approach.decision_making.general_stopline_detectors.rates;rates];
                    approach.decision_making.general_stopline_detectors.scales=...
                        [approach.decision_making.general_stopline_detectors.scales;scales];
                    approach.decision_making.general_stopline_detectors.queues=...
                        [approach.decision_making.general_stopline_detectors.queues;queues];
                end
            end
            
            % Provide assessment according to the rates from exclusive
            % left turns, exclusive right turns, stop-line detectors, and
            % advanced detectors
            [status_assessment]=state_estimation.traffic_state_assessment(approach);
            approach.decision_making.assessment.left_turn=status_assessment(1);
            approach.decision_making.assessment.through=status_assessment(2);
            approach.decision_making.assessment.right_turn=status_assessment(3);
                
            % Return the decision making results
            approachData=approach;            
        end
        
        function [rates,scales,queues]=check_detector_status(this,data,status,movement,type)
            % This function is to check the status of each detector
            % belonging to the same detector type, e.g., exclusive left
            % turns
            
            numDetector=size(data,1); % Get the number of detectors
            rates=[];
            scales=[];
            queues=[];
            switch type
                % For stop-line detectors
                case {'exclusive_left_turn','exclusive_right_turn','general_stopline_detectors'}
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow and occupancy
                            [occ_rate,occ_scale,queue]=this.get_occupancy_scale_and_rate_stopline_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,movement,type);
                            rates=[rates;occ_rate];
                            scales=[scales;occ_scale];
                            queues=[queues;queue];
                        else % Otherwise, say "Unknown"
                            rates=[rates;{'Unknown'}];
                            scales=[scales;nan(1,3)];
                            queues=[];
                        end
                    end
                % For advanced detectors
                case 'advanced_detectors'
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow and occupancy, no
                            % need to use the movement information
                            [occ_rate,occ_scale,queue]=this.get_occupancy_scale_and_rate_advanced_detector...
                                (data(i).avgFlow,data(i).avgOccupancy);
                            rates=[rates;occ_rate];
                            scales=[scales;occ_scale];
                            queues=[queues;queue];
                        else % Otherwise, say "Unknown"
                            rates=[rates;{'Unknown'}];
                            scales=[scales;nan(1,3)];
                            queues=[];
                        end
                    end
                otherwise
                    error('Wrong input of detector type!')
            end
            
        end
        
        function [occ_rate,occ_scale,queue]=get_occupancy_scale_and_rate_advanced_detector(this,flow,occ)
            % This function is to get the rate and the corresponding scale
            % for advanced detectors. In this case, we consider advanced
            % detectors are different from other stop-line detectors since
            % traffic flow is less impacted by traffic signals
            
            % Get effective length that will occupy the advanced detectors
            effectiveLength=this.params.detector_length_advanced+this.params.vehicle_length;
            
            % Get low-level occupancy with a high speed
            lowOcc=min(flow*effectiveLength/5280/this.params.speed_scales(1),1);
            
            % Get mid-level occupancy with a moderate speed
            midOcc=min(flow*effectiveLength/5280/this.params.speed_scales(2),1);
            
            % Get high-level occupancy with a low speed
            highOcc=min(flow*effectiveLength/5280/this.params.speed_scales(3),1);
            
            % Get the corresponding scale
            occ_scale=[lowOcc, midOcc, highOcc];
            
            numVeh=this.params.cycle*flow/3600;
            % Determine the rating based on the average occupancy
            if(occ>=highOcc)
                occ_rate={'Heavy Congestion'};
                queue=1000; % Heavy congestion, assign a very large value to indicate queue spillback
            elseif(occ>=midOcc)
                occ_rate={'Moderate Congestion'};
                queue=numVeh;
            elseif(occ>=lowOcc)
                occ_rate={'Light Congestion'};
                queue=numVeh*0.5;
            else
                occ_rate={'No Congestion'};
                queue=0;
            end
        end
        
        function [occ_rate,occ_scale,queue]=get_occupancy_scale_and_rate_stopline_detector(this,flow,occ,detectorMovement,type)
            % This function is to get the rate and the corresponding scale
            % for stop-line detectors. In this case, we consider stop-line
            % detectors (exclusive left, exclusive right, and other general stop-line detectors)
            % are different from advanced detectors since traffic flow is
            % mostly impacted by traffic signals. In this case, we consider
            % platoon arrivals.

            % Get the green ratio and detector length
            switch type
                case 'exclusive_left_turn'
                    green_ratio=this.params.green_left;
                    detector_length=this.params.detector_length_left_turn; % left turn with a longer length
                case 'exclusive_right_turn'
                    green_ratio=this.params.green_right;
                    detector_length=this.params.detector_length;
                case 'general_stopline_detectors'
                    green_ratio=this.params.green_through;
                    detector_length=this.params.detector_length;
                otherwise
                    error('Wrong input of detector type!')
            end
            
            % Get the saturation speed, startup lost time, and saturation
            % headway
            start_up_lost_time=this.params.start_up_lost_time;
            saturation_headway=this.params.saturation_headway;
            
            saturation_speed_left_and_right=this.params.saturation_speed_left_and_right;
            saturation_speed_through=this.params.saturation_speed_through;
            
            time_to_pass_left_and_right=(detector_length+this.params.vehicle_length)*3600/saturation_speed_left_and_right/5280;
            time_to_pass_through=(detector_length+this.params.vehicle_length)*3600/saturation_speed_through/5280;            
            
            % Get number of vehicles for left-turn, through, and right-turn
            % movements
            proportion_left=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Left');
            proportion_through=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Through');
            proportion_right=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Right');
            
            numVeh=flow*this.params.cycle/3600;
            numVehLeft=numVeh*proportion_left;
            numVehThrough=numVeh*proportion_through;
            numVehRight=numVeh*proportion_right;

            % Get low-level occupancy: consider moving queue at saturation
            % flow-rate; discharging time            
            lowTime=time_to_pass_left_and_right*(numVehLeft+numVehRight)+time_to_pass_through*numVehThrough;
            lowOcc=min(lowTime/this.params.cycle,1);
            
            % Get mid-level occupancy: consider the case when the last
            % vehicle has to stop and then go            
            platoon_width=numVeh*saturation_headway;
            midTime=platoon_width+lowTime+start_up_lost_time;
            midOcc=min(midTime/this.params.cycle,1);
            
            % Get high-level occupancy: consider the worst case to wait
            % for the whole red time (use 90% to consider random errors inside the measurements)
            max_delay=this.params.cycle*(1-green_ratio)*0.9;
            highTime=max_delay+lowTime+start_up_lost_time;
            highOcc=min(highTime/this.params.cycle,1);
            
            occ_scale=[lowOcc, midOcc, highOcc];
            
            % Determine the rating based on the average occupancy
            if(occ>=highOcc)
                occ_rate={'Heavy Congestion'};
                if(lowTime>=this.params.cycle*green_ratio) % Green time is fully used
                    queue=1000; % Assign a very high value to indicate queue spillback
                else
                    queue=numVeh; % If not, use the vehicle number as a queue
                end
            elseif(occ>=midOcc)
                occ_rate={'Moderate Congestion'};
                queue=numVeh;
            elseif(occ>=lowOcc)
                occ_rate={'Light Congestion'};
                queue=min(1,(occ*this.params.cycle-lowTime)/platoon_width)*numVeh;
            else
                occ_rate={'No Congestion'};
                queue=0;
            end
        end
        
        function [this]=update_param_setting(this,params)
            % This function is to update parameter setttings
            
            % First, reset all values to default ones
            this.params=this.default_params;
            
            % Check possible inputs
            if (nargin>1)                 
                % Check cycle
                if(isfiled(params,'cycle'))
                    this.params.cycle=params.cycle;
                end
                % Check gree ratio for left turns
                if(isfiled(params,'green_left'))
                    this.params.green_left=params.green_left;
                end
                % Check green ratio for through vehicles
                if(isfiled(params,'green_through'))
                    this.params.green_through=params.green_through;
                end
                % Check green ratio for right turns
                if(isfiled(params,'green_right'))
                    this.params.green_right=params.green_right;
                end
                
                
                % Check detector length for exclusive left-turn detectors
                if(isfiled(params,'detector_length_left_turn'))
                    this.params.detector_length_left_turn=params.detector_length_left_turn;
                end
                % Check detector length for advanced detectors
                if(isfiled(params,'detector_length_advanced'))
                    this.params.detector_length_advanced=params.detector_length_advanced;
                end
                % Check detector length for through and right-turn
                % detectors
                if(isfiled(params,'detector_length'))
                    this.params.detector_length=params.detector_length;
                end
                % Check vehicle length
                if(isfiled(params,'vehicle_length'))
                    this.params.vehicle_length=params.vehicle_length;
                end
                
                
                % Check speed scales to identify congestion levels
                if(isfiled(params,'speed_scales'))
                    this.params.speed_scales=params.speed_scales;
                end
                
                
                % Check saturation headway
                if(isfiled(params,'saturation_headway'))
                    this.params.saturation_headway=params.saturation_headway;
                end
                % Check saturation speed for left-turn and right-turn
                % movements
                if(isfiled(params,'saturation_speed_left_and_right'))
                    this.params.saturation_speed_left_and_right=params.saturation_speed_left_and_right;
                end
                % Check saturation speed for through movements
                if(isfiled(params,'saturation_speed_through'))
                    this.params.saturation_speed_through=params.saturation_speed_through;
                end
                % Check startup lost time at the beginning of green
                if(isfiled(params,'start_up_lost_time'))
                    this.params.start_up_lost_time=params.start_up_lost_time;
                end
                
            end
            
        end
        
        
        %% ***************Functions to assign traffic: vehicle queues*****************
        function [approachData]=traffic_assignment_by_approach(this, approach,params)
            % This function is to estimate the number of queued vehicles
            % for the movements of left-turn, through, and right-turn at
            % the approach level
              
            % For each approach, we may need to update its parameter
            % settings
            if(nargin>=3) % Have new settings
                this=this.update_param_setting(params);
            else % Do not have param settings
                this=this.update_param_setting;
            end
            
            % Check for left-turn queues
            [left_turn_flow]=state_estimation.find_traffic_flow(this.default_proportion, approach,'Left');
            [approach.decision_making.vehicle_assignment.left_turn_queue]=...
                state_estimation.decide_vehicle_queue(left_turn_flow,this.params);
            
            % Check for right-turn queues
            [right_turn_flow]=state_estimation.find_traffic_flow(this.default_proportion, approach,'Right');
            [approach.decision_making.vehicle_assignment.right_turn_queue]=...
                state_estimation.decide_vehicle_queue(right_turn_flow,this.params);
            
            % Check for through queues
            [through_flow]=state_estimation.find_traffic_flow(this.default_proportion, approach,'Through');
            [approach.decision_making.vehicle_assignment.through_queue]=...
                state_estimation.decide_vehicle_queue(through_flow,this.params);
            
            
        end
        
    end
    
    methods(Static)
        
        function [vehQueue]=decide_vehicle_queue(flow,occ,params,movement)
            switch movement
                case 'Left'
                    green_ratio=params.green_left;
                    saturation_speed=params.saturation_speed_left_and_right;
                    detector_length=params.detector_length_left_turn;
                case 'Through'
                    green_ratio=params.green_through;
                    saturation_speed=params.saturation_speed_through;
                    detector_length=params.detector_length;
                case 'Right'
                    green_ratio=params.green_right;
                    saturation_speed=params.saturation_speed_left_and_right;
                    detector_length=params.detector_length;
            end

            vehicle_length=params.vehicle_length;
            saturation_headway=params.saturation_headway;
            cycle=params.cycle;
            start_up_lost_time=params.start_up_lost_time;
            
            discharging_time=(vehicle_length+detector_length)/saturation_speed*3600/5280;
            total_discharging_time=flow*cycle/3600*discharging_time;
            
            platoon_width=saturation_headway*flow*cycle/3600;
            
            occupied_time=cycle*occ;
            
            if(occupied_time<total_discharging_time)
                % If vehicle is travelling with a higher speed
                vehQueue=0; 
            else
                time_in_red=max(0,occupied_time-total_discharging_time-start_up_lost_time);
                
                vehQueue=min(time_in_red/platoon_width,1)*flow*cycle/3600;
            end

        end
        
        function [flow]=find_traffic_flow(default_proportion,approach,movement)
            switch movement
                case 'Left'
                    flow=0;
                    if(~isempty(approach.exclusive_left_turn)||~isempty(approach.general_stopline_detectors))
                        % Trust more on the stopline detectors
                        exclusive_Left={'Left Turn','Left Turn Queue'};
                        if(~isempty(approach.exclusive_left_turn))
                            for i=1:length(exclusive_left)
                                idx=ismember([approach.exclusive_left_turn.Movement],exclusive_left(i));
                                left_turn_proportion=state_estimation.find_traffic_proportion...
                                    (exclusive_left(i),default_proportion,movement);
                                flow=flow+approach.exclusive_left_turn(idx).avg_data.avgFlow * left_turn_proportion;
                            end
                        end
                        
                        if(~isempty(approach.general_stopline_detectors))                            
                            general_Left={'All Movements','Left and Right', 'Left and Through'};
                            for i=1:length(general_Left)
                                idx=ismember([approach.general_stopline_detectors.Movement],general_Left(i));
                                left_turn_proportion=state_estimation.find_traffic_proportion...
                                    (general_Left(i),default_proportion,movement);
                                flow=flow+approach.general_stopline_detectors(idx).avg_data.avgFlow * left_turn_proportion;
                            end
                        end
                    elseif(~isempty(approach.advanced_detectors))
                        advanced_Left={'Advanced','Advanced Left Turn', 'Advanced Left and Through', 'Advanced Left and Right' };
                        
                        for i=1:length(advanced_Left)
                            idx=ismember([approach.advanced_detectors.Movement],advanced_Left(i));
                            left_turn_proportion=state_estimation.find_traffic_proportion...
                                (advanced_Left(i),default_proportion,movement);
                            flow=flow+approach.advanced_detectors(idx).avg_data.avgFlow * left_turn_proportion;
                        end                        
                    end            
                case 'Right'
                    flow=0;
                    if(~isempty(approach.exclusive_right_turn)||~isempty(approach.general_stopline_detectors))
                        % Trust more on the stopline detectors
                        exclusive_Right={'Right Turn','Right Turn Queue'};
                        if(~isempty(approach.exclusive_right_turn))
                            for i=1:length(exclusive_Right)
                                idx=ismember([approach.exclusive_right_turn.Movement],exclusive_Right(i));
                                right_turn_proportion=state_estimation.find_traffic_proportion...
                                    (exclusive_Right(i),default_proportion,movement);
                                flow=flow+approach.exclusive_right_turn(idx).avg_data.avgFlow * right_turn_proportion;
                            end
                        end
                        
                        if(~isempty(approach.general_stopline_detectors))                            
                            general_Right={'All Movements','Left and Right', 'Through and Right' };
                            for i=1:length(general_Right)
                                idx=ismember([approach.general_stopline_detectors.Movement],general_Right(i));
                                right_turn_proportion=state_estimation.find_traffic_proportion...
                                    (general_Right(i),default_proportion,movement);
                                flow=flow+approach.general_stopline_detectors(idx).avg_data.avgFlow * right_turn_proportion;
                            end
                        end
                    elseif(~isempty(approach.advanced_detectors))
                        advanced_Right={'Advanced','Advanced Right Turn','Advanced Through and Right','Advanced Left and Right' };                        
                        for i=1:length(advanced_Right)
                            idx=ismember([approach.advanced_detectors.Movement],advanced_Right(i));
                            right_turn_proportion=state_estimation.find_traffic_proportion...
                                (advanced_Right(i),default_proportion,movement);
                            flow=flow+approach.advanced_detectors(idx).avg_data.avgFlow * right_turn_proportion;
                        end                        
                    end           
                    
                case 'Through'
                    flow=0;
                    if(~isempty(approach.advanced_detectors))
                        % Trust more on advanced detectors
                        advanced_Through={'Advanced','Advanced Through','Advanced Through and Right','Advanced Left and Through'};
                        for i=1:length(advanced_Through)
                            idx=ismember([approach.advanced_detectors.Movement],advanced_Through(i));
                            through_proportion=state_estimation.find_traffic_proportion...
                                (advanced_Through(i),default_proportion,movement);
                            flow=flow+approach.advanced_detectors(idx).avg_data.avgFlow * through_proportion;
                        end
                    elseif(~isempty(approach.general_stopline_detectors))
                        general_Through={'All Movements','Through', 'Left and Through', 'Through and Right'};
                        for i=1:length(general_Through)
                            idx=ismember([approach.general_stopline_detectors.Movement],general_Through(i));
                            through_proportion=state_estimation.find_traffic_proportion...
                                (general_Through(i),default_proportion,movement);
                            flow=flow+approach.general_stopline_detectors(idx).avg_data.avgFlow * through_proportion;
                        end
                    end
                otherwise
                    error('Wrong input of traffic movement!')
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
        
        function [status_assessment]=traffic_state_assessment(approach)
            % This function is for traffic state assessment

            if(isempty(approach.exclusive_left_turn)&& isempty(approach.exclusive_right_turn)...
                    && isempty(approach.general_stopline_detectors) && isempty(approach.advanced_detectors)) % No Detector
                status_assessment={'No Detector','No Detector','No Detector'};
                
            else
                % Check advanced detectors
                if(~isempty(approach.advanced_detectors))
                    
                    % Get the states of left-turn, through, and right-turn
                    % from advanded detectors
                    possibleAdvanced.Through={'Advanced','Advanced Through','Advanced Through and Right','Advanced Left and Through'};
                    possibleAdvanced.Left={'Advanced','Advanced Left Turn', 'Advanced Left and Through', 'Advanced Left and Right' };
                    possibleAdvanced.Right={'Advanced','Advanced Right Turn','Advanced Through and Right','Advanced Left and Right' };
                    
                    [advanced_status]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.advanced_detectors, possibleAdvanced, approach.decision_making.advanced_detectors);
                else
                    advanced_status=[0, 0, 0];
                end
                
                % Check general stopline detectors
                if(~isempty(approach.general_stopline_detectors))
                    
                    % Get the states of left-turn, through, and right-turn
                    % from stopline detectors
                    possibleGeneral.Through={'All Movements','Through', 'Left and Through', 'Through and Right'};
                    possibleGeneral.Left={'All Movements','Left and Right', 'Left and Through'};
                    possibleGeneral.Right={'All Movements','Left and Right', 'Through and Right' };
                    [stopline_status]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.general_stopline_detectors, possibleGeneral,approach.decision_making.general_stopline_detectors);
                else
                    stopline_status=[0, 0, 0];
                end
                
                % Check exclusive right turn detectors
                if(~isempty(approach.exclusive_right_turn))
                    
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive right-turn detectors
                    possibleExclusiveRight.Through=[];
                    possibleExclusiveRight.Left=[];
                    possibleExclusiveRight.Right={'Right Turn','Right Turn Queue'};
                    [exc_right_status]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_right_turn,possibleExclusiveRight,approach.decision_making.exclusive_right_turn);
                else
                    exc_right_status=[0, 0, 0];
                end                
               
                % Check exclusive left turn detectors
                if(~isempty(approach.exclusive_left_turn))
                    
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive left-turn detectors
                    possibleExclusiveLeft.Through=[];
                    possibleExclusiveLeft.Left={'Left Turn','Left Turn Queue'};
                    possibleExclusiveLeft.Right=[];
                    [exc_left_status]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_left_turn,possibleExclusiveLeft,approach.decision_making.exclusive_left_turn);
                else
                    exc_left_status=[0, 0, 0];
                end
                
                [status_assessment]=state_estimation.make_a_decision(advanced_status,stopline_status,exc_right_status,exc_left_status);                
            end            
        end
        
        function [status]=check_aggregate_rate_by_movement_type(movement, possibleMovement, decision_making)
            % This function is to get the aggreagated rate by movement (left-turn, through, and right-turn) and
            % type of detectors (exclusive left, exclusive right, general stopline, and advanced detectors)
            
            % Check the number of detector types
            numType=size(movement,1); 
            
            possibleThrough=possibleMovement.Through;
            possibleLeft=possibleMovement.Left;
            possibleRight=possibleMovement.Right;
            
            % Check through movements
            rateSum_through=0;
            count_through=0;
            for i=1:numType
                idx_through=ismember(movement(i).Movement,possibleThrough);
                if(sum(idx_through)) % Find the corresponding through movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates');
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_through=count_through+1;
                            rateSum_through=rateSum_through+rateNum(j);
                        end
                    end
                end                
            end
            if(count_through)
                rateMean_through=rateSum_through/count_through;
            else
                rateMean_through=0;
            end
            
            % Check left-turn movements
            rateSum_left=0;
            count_left=0;
            for i=1:numType
                idx_left=ismember(movement(i).Movement,possibleLeft);
                if(sum(idx_left)) % Find the corresponding left-turn movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates');
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_left=count_left+1;
                            rateSum_left=rateSum_left+rateNum(j);
                        end
                    end
                end                
            end
            if(count_left)
                rateMean_left=rateSum_left/count_left;
            else
                rateMean_left=0;
            end
            
            
            % Check right-turn movements
            rateSum_right=0;
            count_right=0;
            for i=1:numType
                idx_right=ismember(movement(i).Movement,possibleRight);
                if(sum(idx_right)) % Find the corresponding right-turn movement
                    rates=decision_making.rates(i,:);
                    rateNum=state_estimation.convert_rate_to_num(rates');
                    for j=1:size(rateNum,1) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_right=count_right+1;
                            rateSum_right=rateSum_right+rateNum(j);
                        end
                    end
                end                
            end
            if(count_right)
                rateMean_right=rateSum_right/count_right;
            else
                rateMean_right=0;
            end
            
            % Return mean values for different movements            
            status=[rateMean_left, rateMean_through, rateMean_right];
        end

        function [status]=make_a_decision(advanced_status,stopline_status,exc_right_status,exc_left_status)
            % This function is to make a final decision for left-turn,
            % through, and right-turn movements at the approach level
            
            % Check Through movements            
            if(advanced_status(2)==4)
                if(stopline_status(2)==4)
                    % If both the advanced and stop-line detectors report heavy congestion,
                    % it is possible to have "Through Blockage"
                    status_through={'Through Blockage'};
                else
                    % Otherwise, say "Lane Blockage"
                    status_through={'Lane Blockage'};
                end
            else % Otherwise, take the mean value, and get the corresponding rate
                [meanRate]=state_estimation.meanwithouzeros([advanced_status(2),stopline_status(2)]);
                status_through=state_estimation.convert_num_to_rate(meanRate);                
            end
            
            % Check left-turn movements            
            if(advanced_status(1)==4)
                if(exc_left_status(1)>=4)
                    % If both the advanced detector and the exclusive left-turn detectors
                    % report heavy congestion, it is possible to have "Left Turn Blockage"
                    status_left={'Left Turn Blockage'};
                else 
                    % Otherwise, say "Lane Blockage"
                    status_left={'Lane Blockage'};
                end
            else  % Otherwise, take the mean value, and get the corresponding rate
                [meanRate]=state_estimation.meanwithouzeros([exc_left_status(1),stopline_status(1),advanced_status(1)]);
                status_left=state_estimation.convert_num_to_rate(meanRate);
            end
           
            % Check right-turn movements
            if(advanced_status(3)==4)
                if(exc_right_status(3)>=4)
                    % If both the advanced detector and the exclusive right-turn detectors
                    % report heavy congestion, it is possible to have "Right Turn Blockage"
                    status_right={'Right Turn Blockage'};
                else
                    % Otherwise, say "Lane Blockage"
                    status_right={'Lane Blockage'};
                end
            else % Otherwise, take the mean value, and get the corresponding rate
                [meanRate]=state_estimation.meanwithouzeros([exc_right_status(3),stopline_status(3),advanced_status(3)]);
                status_right=state_estimation.convert_num_to_rate(meanRate);
            end                 
            
            status={status_left,status_through,status_right};            
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
        
        function [rateNum]=convert_rate_to_num(rates)
            % This function is to convert a rate to its corresponding
            % number
            
            rateNum=zeros(size(rates));
            
            for i=1:length(rates)
                if(strcmp(rates(i),{'Heavy Congestion'}))
                    rateNum(i)=4;
                elseif(strcmp(rates(i),{'Moderate Congestion'}))
                    rateNum(i)=3;
                elseif(strcmp(rates(i),{'Light Congestion'}))
                    rateNum(i)=2;
                elseif(strcmp(rates(i),{'No Congestion'}))
                    rateNum(i)=1;
                elseif(strcmp(rates(i),{'Unknown'}))
                    rateNum(i)=0;
                end
            end
        end
             
        function [rates]=convert_num_to_rate(rateNum)
            % This function is to convert a number to its corresponding
            % rate
            
            rateNum=round(rateNum);
            rates=cell(size(rateNum));
            
            for i=1:length(rateNum)
                if(rateNum(i)==4)
                    rates(i)={'Heavy Congestion'};
                elseif(rateNum(i)==3)
                    rates(i)={'Moderate Congestion'};
                elseif(rateNum(i)==2)
                    rates(i)={'Light Congestion'};
                elseif(rateNum(i)==1)
                    rates(i)={'No Congestion'};
                else
                    rates(i)={'Unknown'};
                end
            end
        end
        
        function [aggData]=get_aggregated_data(data)
            % This function is to get the aggregated data from a couple of
            % detectors
            
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
                    'avgFlow', mean(data.s_volume),...                  % Average flow
                    'avgOccupancy', mean(data.s_occupancy)/3600,...     % Average occupancy
                    'medFlow', median(data.s_volume),...                % Median of flow
                    'medOccupancy', median(data.s_occupancy)/3600,...   % Median of occupancy
                    'maxFlow', max(data.s_volume),...                   % Maximum value of flow
                    'maxOccupancy', max(data.s_occupancy)/3600,...      % Maximum value of occupancy
                    'minFlow', min(data.s_volume),...                   % Minimum value of flow
                    'minOccupancy', min(data.s_occupancy)/3600);        % Minimum value of occupancy
            end
        end
        
        function extract_to_excel(appStateEst,outputFolder,outputFileName)
            % This function is extract the state estimation results to an
            % excel file

            outputFileName=fullfile(outputFolder,outputFileName);

            xlswrite(outputFileName,[{'Intersection Name'},{'Road Name'},{'Direction'},{'Left Turn Status'}...
                ,{'Through movement Status'},{'Right Turn Status'}]);
                            
            % Write intersection and detector information
            data=vertcat(appStateEst.decision_making);
            assessment=vertcat(data.assessment);
            left_turn=[assessment.left_turn]';
            left_turn=[left_turn{:,1}]';
            through=([assessment.through])';
            through=[through{:,1}]';
            right_turn=([assessment.right_turn])';
            right_turn=[right_turn{:,1}]';
            
            xlswrite(outputFileName,[...
                {appStateEst.intersection_name}',...
                {appStateEst.road_name}',...
                {appStateEst.direction}',...
                left_turn,...
                through,...
                right_turn],sprintf('A2:F%d',length(left_turn)+1));
            
            
        end
    end
end

