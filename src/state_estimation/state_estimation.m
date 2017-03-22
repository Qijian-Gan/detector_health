classdef state_estimation
    properties
        
        approachConfig              % Approach-based configuration
        
        dataProvider_sensor         % Data provider: sensor
        dataProvider_midlink        % Data provider: midlink count (historical manual counts)
        dataProvider_turningCount   % Data provider: turning count (historical manual counts)
        dataProvider_simVehicle     % Data provider: simulated vehicles (used to overwrite turning proportions)
        dataProvider_signal_sim     % Data provider: signal settings from simulation
        dataProvider_signal_field   % Data provider: signal settings from field (currently extracted from Aimsun)
        
        default_params              % Default parameters: can be determined through MATLAB GUI
        params                      % Current parameters
        
        default_proportions         % Default proportions of left-turn, through, and right-turn vehicles
    end
    
    methods ( Access = public )
        
        function [this]=state_estimation(approachConfig,dataProvider_sensor, dataProvider_midlink, dataProvider_turningCount,...
                dataProvider_simVehicle, dataProvider_signal_sim, dataProvider_signal_field)
            %% This function is to do the state estimation for arterial approaches
            
            % Check the number of inputs
            if(nargin<2) % At lease two inputs
                error('Not enough inputs!')
            elseif(nargin>7) % At most five inputs
                error('Too many inputs!')
            end
            
            % Check two most important inputs
            if(isempty(approachConfig)||isempty(dataProvider_sensor))
                error('Wrong inputs!');
            end
            this.approachConfig=approachConfig;
            this.dataProvider_sensor=dataProvider_sensor;
            
            % Additional inputs
            if(nargin>2)
                this.dataProvider_midlink=dataProvider_midlink;
            end
            if(nargin>3)
                this.dataProvider_turningCount=dataProvider_turningCount;
            end
            if(nargin>4)
                this.dataProvider_simVehicle=dataProvider_simVehicle;
            end
            if(nargin>5)
                this.dataProvider_signal_sim=dataProvider_signal_sim;
            end
            if(nargin>6)
                this.dataProvider_signal_field=dataProvider_signal_field;
            end
            
            % Default values
            this.default_params=struct(...
                'cycle',                                     120,...        % Cycle length (sec)
                'green_left',                                0.2,...        % Green ratio for left turns
                'green_through',                             0.35,...       % Green ratio for through movements
                'green_right',                               0.35,...       % Green ratio for right turns
                'vehicle_length',                            17,...         % Vehicle length (ft)
                'speed_threshold_for_advanced_detector',     5,...          % Speed scale to determine levels of congestion (mph)(need to be calibrated)
                'occupancy_threshold_for_advanced_detector', 0.15, ...      % Occupancy threshold to determine levels of congestion (it seems this parameter is better;need to be calibrated)
                'speed_freeflow_for_advanced_detector',      35,...         % Speed scale to determine free-flow speed (mph)
                'flow_threshold_for_stopline_detector',      0.5,...        % Threshold to indicate low flow for stopbar detectors
                'saturation_headway',                        2.0,...        % Saturation headway (sec)
                'saturation_speed_left',                     15,...         % Left-turn speed at saturation (mph): slower speed
                'saturation_speed_right',                    15,...         % Right-turn speed at saturation (mph): slower speed
                'saturation_speed_through',                  25,...         % Speed of through movements at saturation (mph)
                'start_up_lost_time',                        2.5,...        % Start-up lost time (sec)
                'jam_spacing',                               24,...         % Jam spacing (ft)
                'distance_advanced_detector',                200,...        % Default distance to the stopbar (ft)
                'left_turn_pocket',                          150,...        % Default left-turn pocket(ft)
                'right_turn_pocket',                         100,...        % default right-turn pocket(ft)
                'distanceToEnd',                             60);           % default distance to end of the link: used to defne turnings
            
            % Default proportions for left-turn, through, and right-turn
            % movements for each type of detectors
            this.default_proportions=struct(...
                'Left_Turn',                        [1, 0, 0],...           % Exclusive left turn: no through and right-turn movements
                'Left_Turn_Queue',                  [0, 0, 0],...           % LT Queue: currently tends not to use this value
                'Right_Turn',                       [0, 0, 1],...           % Exclusive right turn: no through and left-turn movements
                'Right_Turn_Queue',                 [0, 0, 0],...           % RT Queue: currently tends not to use this value
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
        
        %% Functions to get/update params and proportions
        function [proportions]=update_vehicle_proportions(this,approach_in,queryMeasures)
            %% This function is to update vehicle proportions if possible
            
            % Get turning count data
            turning_count_properties=this.get_turning_count_for_approach(approach_in,queryMeasures);
            
            % If not empty: have turning count information
            if(~isempty(turning_count_properties.data))
                % Get turning proportions
                
                data=turning_count_properties.data;
                
                time=data.time; % Get the time
                
                totalVolume=sum(data.volume,2); % Get the total
                proportionLeft=data.volume(:,1)./totalVolume; % Get the LT proportion
                proportionThrough=data.volume(:,2)./totalVolume; % Get the through proportion
                proportionRight=data.volume(:,3)./totalVolume; % Get the RT proportion
                
                if(isnan(queryMeasures.timeOfDay)) % No specific time of day: average over all time stamps
                    avgProportionLeft=mean(proportionLeft);
                    avgProportionThrough=mean(proportionThrough);
                    avgProportionRight=mean(proportionRight);
                else % Given a specific time
                    startTime=queryMeasures.timeOfDay(1);
                    endTime=queryMeasures.timeOfDay(end);
                    
                    idx=(time>=startTime & time<endTime);
                    
                    if(sum(idx)==0) % Do not have data for that time period: average over all time stamps
                        avgProportionLeft=mean(proportionLeft);
                        avgProportionThrough=mean(proportionThrough);
                        avgProportionRight=mean(proportionRight);
                    else % Have data: average over the given time period
                        avgProportionLeft=mean(proportionLeft(idx));
                        avgProportionThrough=mean(proportionThrough(idx));
                        avgProportionRight=mean(proportionRight(idx));
                    end
                end
                
                % Update the proportions in the default settings
                % All movements
                proportions.Advanced=[avgProportionLeft,avgProportionThrough,avgProportionRight];
                proportions.All_Movements=proportions.Advanced;
                
                % Through and Right
                proportions.Advanced_Through_and_Right=...
                    [0,avgProportionThrough/(avgProportionThrough+avgProportionRight),...
                    avgProportionRight/(avgProportionThrough+avgProportionRight)];
                proportions.Through_and_Right=proportions.Advanced_Through_and_Right;
                
                % Left and Through
                proportions.Advanced_Left_and_Through=...
                    [avgProportionLeft/(avgProportionThrough+avgProportionLeft),...
                    avgProportionThrough/(avgProportionThrough+avgProportionLeft),0];
                proportions.Left_and_Through=proportions.Advanced_Left_and_Through;
                
                % Left and Right
                proportions.Advanced_Left_and_Right=...
                    [avgProportionLeft/(avgProportionRight+avgProportionLeft),0,...
                    avgProportionRight/(avgProportionRight+avgProportionLeft)];
                proportions.Left_and_Right=proportions.Advanced_Left_and_Right;
                
                % Others
                proportions.Left_Turn=[1,0,0];
                proportions.Left_Turn_Queue=[0,0,0];
                proportions.Right_Turn=[0,0,1];
                proportions.Right_Turn_Queue=[0,0,0];
                proportions.Advanced_Left_Turn=[1,0,0];
                proportions.Advanced_Right_Turn=[0,0,1];
                proportions.Advanced_Through=[0,1,0];
                proportions.Through=[0,1,0];
                
            else % Not turning count information available
                proportions=this.default_proportions;
            end
            
        end
        
        function [proportions]=update_vehicle_proportions_with_multiple_data_sources(this,...
                approach_in,queryMeasures)
            %% This function is to update vehicle proportions using multiple data sources if possible
            
            % Get turning count data (observed)
            turningCountProperty=this.get_turning_count_for_approach(approach_in,queryMeasures);
            avgProportionFromTurnCount=turningCountProperty.avgProportion;
            
            % Get simulation count data
            simulationCountProperty=this.get_simulation_count_for_approach(approach_in,queryMeasures);
            avgProportionFromSimulationCount=simulationCountProperty.avgProportion;
            
            % Get sensor count data
            sensorCountProperty=this.get_sensor_count_for_approach(approach_in,queryMeasures);
            avgProportionFromSensorCount=sensorCountProperty.avgProportion;
            
            % If not empty: have turning count information
            status=0;
            if(sum(sensorCountProperty.validStatus)==3) % If it is valid from sensor counts
                avgProportionLeft=avgProportionFromSensorCount(1);
                avgProportionThrough=avgProportionFromSensorCount(2);
                avgProportionRight=avgProportionFromSensorCount(3);
                status=1;
            elseif(~isempty(avgProportionFromTurnCount)) % If it is valid from historical turning counts
                avgProportionLeft=avgProportionFromTurnCount(1);
                avgProportionThrough=avgProportionFromTurnCount(2);
                avgProportionRight=avgProportionFromTurnCount(3);
                status=1;
            elseif(~isempty(avgProportionFromSimulationCount)) % If it is valid from simulation turning counts
                status=1;
                avgProportionLeft=avgProportionFromSimulationCount(1);
                avgProportionThrough=avgProportionFromSimulationCount(2);
                avgProportionRight=avgProportionFromSimulationCount(3);
                if(sensorCountProperty.validStatus(1)==1&&sensorCountProperty.validStatus(3)==0)
                    % If left turn from sensor count is valid
                    sumThRT=avgProportionFromSimulationCount(2)+avgProportionFromSimulationCount(3);
                    if(sumThRT>0)
                        avgProportionLeft=avgProportionFromSensorCount(1); % Overwrite it
                        avgProportionThrough=(1-avgProportionLeft)*avgProportionFromSimulationCount(2)/sumThRT;
                        avgProportionRight=(1-avgProportionLeft)*avgProportionFromSimulationCount(3)/sumThRT;
                    end
                elseif(sensorCountProperty.validStatus(1)==0&&sensorCountProperty.validStatus(3)==1)
                    % If right turn from sensor count is valid
                    sumLTTh=avgProportionFromSimulationCount(1)+avgProportionFromSimulationCount(2);
                    if(sumLTTh>0)
                        avgProportionRight=avgProportionFromSensorCount(3); % Overwrite it
                        avgProportionLeft=(1-avgProportionRight)*avgProportionFromSimulationCount(1)/sumLTTh;
                        avgProportionThrough=(1-avgProportionRight)*avgProportionFromSimulationCount(2)/sumLTTh;
                    end
                end
            end
            
            proportions=this.default_proportions;
            if(status)
                % Update the proportions in the default settings
                % All movements
                proportions.Advanced=[avgProportionLeft,avgProportionThrough,avgProportionRight];
                proportions.All_Movements=proportions.Advanced;
                
                % Through and Right
                if(avgProportionThrough+avgProportionRight>0)
                    proportions.Advanced_Through_and_Right=...
                        [0,avgProportionThrough/(avgProportionThrough+avgProportionRight),...
                        avgProportionRight/(avgProportionThrough+avgProportionRight)];
                    proportions.Through_and_Right=proportions.Advanced_Through_and_Right;
                end
                
                % Left and Through
                if(avgProportionThrough+avgProportionLeft>0)
                    proportions.Advanced_Left_and_Through=...
                        [avgProportionLeft/(avgProportionThrough+avgProportionLeft),...
                        avgProportionThrough/(avgProportionThrough+avgProportionLeft),0];
                    proportions.Left_and_Through=proportions.Advanced_Left_and_Through;
                end
                
                % Left and Right
                if(avgProportionRight+avgProportionLeft>0)
                    proportions.Advanced_Left_and_Right=...
                        [avgProportionLeft/(avgProportionRight+avgProportionLeft),0,...
                        avgProportionRight/(avgProportionRight+avgProportionLeft)];
                    proportions.Left_and_Right=proportions.Advanced_Left_and_Right;
                end
            end
            
        end
        
        function [params]=update_signal_setting(this, signal_properties)
            %% This function is to update signal setttings
            
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
        
        function [signal_properties]=get_green_times_for_approach_with_field_signal_plan(this,approach_in,queryMeasures)
            %% This function is used to update signal settings with field signal plans
            
            % First, assign the default signal properties
            if(~isempty(approach_in.signal_properties))
                signal_properties=approach_in.signal_properties;
            else % Set the default values
                signal_properties=struct(...
                    'CycleLength',            120,...
                    'LeftTurnGreen',    15,...
                    'ThroughGreen',     30,...
                    'RightTurnGreen',   30,...
                    'LeftTurnSetting',  'Protected');
            end
            
            % Second, look for field signal data provider
            if(~isempty(this.dataProvider_signal_field)) % If not empty
                
                % Get all active control plans and the corresponding
                % junction IDs
                activeControlPlans=this.dataProvider_signal_field.activeControlPlans;
                JunctionIDs=[activeControlPlans.JunctionID]';
                
                JunctionID=approach_in.intersection_id; % Get the current junction ID
                
                idx=ismember(JunctionIDs,JunctionID);
                if(sum(idx)) % If find the corresponding active control plan
                    currentControlPlan=activeControlPlans(idx,:);
                    
                    if(size(currentControlPlan,1)>1)
                        controlType={currentControlPlan.ControlType}';
                        idx=ismember(controlType,'Unspecified');
                        currentControlPlan(idx,:)=[];
                        if(size(currentControlPlan,1)>1)
                            error('Too many current control plans!')
                        end
                    end
                    
                    signal_properties.CycleLength=currentControlPlan.Cycle;
                    
                    [maxGreenLeft]=state_estimation.find_green_time_by_movement(approach_in,'Left Turn',currentControlPlan);
                    if(maxGreenLeft>0)
                        signal_properties.LeftTurnGreen=maxGreenLeft;
                    end
                    
                    [maxGreenThrough]=state_estimation.find_green_time_by_movement(approach_in,'Through',currentControlPlan);
                    if(maxGreenThrough>0)
                        signal_properties.ThroughGreen=maxGreenThrough;
                    end
                    
                    [maxGreenRight]=state_estimation.find_green_time_by_movement(approach_in,'Right Turn',currentControlPlan);
                    if(maxGreenRight>0)
                        signal_properties.RightTurnGreen=maxGreenRight;
                    end
                    
                end
            end
            
        end
        
        
        
        %% ***************Functions to get data*****************
        function [simulationCountProperty]=get_simulation_count_for_approach(this,approach_in,queryMeasures)
            %% This function is used to get the turning information from simulated data in Aimsun
            
            AimsunSectionID=str2double(approach_in.direction);
            dataVeh=this.dataProvider_simVehicle.get_statistics_for_section_time...
                (AimsunSectionID, queryMeasures.timeOfDay, this.default_params.distanceToEnd);
            
            if(~isnan(dataVeh.data)) % Have simulated data
                simulationCountProperty.data=dataVeh;
                simulationCountProperty.avgProportion=[dataVeh.turning.Left,...
                    1-dataVeh.turning.Left-dataVeh.turning.Right, dataVeh.turning.Right];
            else % if not
                simulationCountProperty.data=[];
                simulationCountProperty.avgProportion=[];
            end
        end
        
        function [sensorCountProperty]=get_sensor_count_for_approach(this,approach_in,queryMeasures)
            %% This function is used to get the turning information from sensor counts
            
            validStatus=[0,0,0];
            if(isempty(approach_in.advanced_detectors) ||(isempty(approach_in.exclusive_left_turn) &&...
                    isempty(approach_in.exclusive_right_turn) && isempty(approach_in.general_stopline_detectors)))
                % We need to have a full map of advanced detectors
                % We also need the set of stopbar detectors not empty!
                sensorCountProperty.validStatus=validStatus;
                sensorCountProperty.avgProportion=[];
            else
                % Get link properties
                numberOfLanes=approach_in.link_properties.NumberOfLanes;
                
                % Get advanced detectors' data
                [totalCountAdvanced, ~,effectiveTotalLanesAdvanced]=this.get_total_count_by_movement(approach_in,queryMeasures,'Advanced');
                if(effectiveTotalLanesAdvanced==0) % No data or bad data
                    sensorCountProperty.validStatus=validStatus;
                    sensorCountProperty.avgProportion=[];
                    return;
                else % Rescale the data
                    totalCountAdvanced=totalCountAdvanced*numberOfLanes/effectiveTotalLanesAdvanced;
                end
                
                % Get exclusive left turn data
                [totalCountLeft, ~,~]=this.get_total_count_by_movement(approach_in,queryMeasures,'Exclusive Left');
                
                % Get exclusive right turn data
                [totalCountRight, ~,~]=this.get_total_count_by_movement(approach_in,queryMeasures,'Exclusive Right');
                
                % Get general stopbar data
                [~, totalCountByMovement,~]=this.get_total_count_by_movement(approach_in,queryMeasures,'General Stopbar');
                
                % Update the proportion for left turn
                if(totalCountLeft~=0)
                    totalCountLeft=totalCountLeft+totalCountByMovement(1);
                    validStatus(1)=1;
                    avgProportionLeft=min(1,totalCountLeft/totalCountAdvanced);
                else
                    avgProportionLeft=nan;
                end
                
                % Update the proportion for right turn
                if(totalCountRight~=0)
                    totalCountRight=totalCountRight+totalCountByMovement(3);
                    validStatus(3)=1;
                    avgProportionRight=min(1,totalCountRight/totalCountAdvanced);
                else
                    avgProportionRight=nan;
                end
                
                % Update the proportion for through movement
                if(validStatus(1)==1 && validStatus(3)==1)
                    if(avgProportionLeft+avgProportionRight>1)
                        avgProportionThrough=nan;
                    else % If it is valid
                        avgProportionThrough=1-avgProportionLeft-avgProportionRight;
                        validStatus(2)=1;
                    end
                else
                    avgProportionThrough=nan;
                end
                
                sensorCountProperty.validStatus=validStatus;
                sensorCountProperty.avgProportion=[avgProportionLeft,avgProportionThrough,avgProportionRight];
            end
            
        end
        
        function [totalCount, totalCountByMovement,effectiveTotalLanes]=get_total_count_by_movement...
                (this,approach_in,queryMeasures,movement)
            %% This function is used to calculate the counts for different movements for different types of detectors
            
            totalCount=0;
            totalLanes=0;
            totalCountByMovement=[0,0,0];
            effectiveTotalLanes=0;
            % Get the detectors by movement
            switch movement
                case 'Advanced'
                    detectors=approach_in.advanced_detectors;
                case 'Exclusive Left'
                    detectors=approach_in.exclusive_left_turn;
                case 'Exclusive Right'
                    detectors=approach_in.exclusive_right_turn;
                case 'General Stopbar'
                    detectors=approach_in.general_stopline_detectors;
                otherwise
                    error('Wrong detector movements!')
            end
            
            % Loop for each movement
            for i=1:size(detectors,1)  % There may be different types of detectors
                totalLanes=totalLanes+sum(detectors(i).NumberOfLanes);
                [tmpTotalCount, tmpEffectiveTotalLanes, tmpTotalCountByMovement]=this.get_total_count_by_detector_type(detectors(i,:),queryMeasures,movement);
                totalCount=totalCount+tmpTotalCount;
                totalCountByMovement=totalCountByMovement+tmpTotalCountByMovement;
                effectiveTotalLanes=effectiveTotalLanes+tmpEffectiveTotalLanes;
            end
            if(effectiveTotalLanes~=0)
                totalCount=totalCount*totalLanes/effectiveTotalLanes;
                totalCountByMovement=totalCountByMovement*totalLanes/effectiveTotalLanes;
            end
            
        end
        
        function [totalCount, effectiveTotalLanes, totalCountByMovement]=get_total_count_by_detector_type...
                (this,detectors,queryMeasures,type)
            %% This function is used to calculate the counts for different movements for different types of detectors
            
            listOfDetectors=cellstr(detectors.IDs);
            detectorData=this.dataProvider_sensor.clustering(listOfDetectors, queryMeasures);
            
            totalCount=0;
            effectiveTotalLanes=0;
            totalCountByMovement=[0, 0, 0];
            
            for i=1:size(detectorData,1) % Loop for each detector belonging to the same movement type
                switch detectorData(i).status
                    case 'Good Data' % If it is good data
                        countByDetector=mean(detectorData(i).data.s_volume)*detectors.NumberOfLanes(i);
                        
                        totalCount=totalCount+countByDetector;
                        effectiveTotalLanes=effectiveTotalLanes+detectors.NumberOfLanes(i);
                        
                        if(strcmp(type,{'General Stopbar'})) % If it is general stopbar detectors
                            detectorMovement=detectors.Movement;     % Check the movements
                            % Get the proportions
                            [proportionLeft]=state_estimation.find_traffic_proportion...
                                (detectorMovement,this.default_proportions,'Left');
                            [proportionThrough]=state_estimation.find_traffic_proportion...
                                (detectorMovement,this.default_proportions,'Through');
                            [proportionRight]=state_estimation.find_traffic_proportion...
                                (detectorMovement,this.default_proportions,'Right');
                            
                            % Update the counts
                            totalCountByMovement(1)=totalCountByMovement(1)+countByDetector*proportionLeft;
                            totalCountByMovement(2)=totalCountByMovement(2)+countByDetector*proportionThrough;
                            totalCountByMovement(3)=totalCountByMovement(3)+countByDetector*proportionRight;
                        end
                end
            end
            
        end
        
        function [turning_count_properties]=get_turning_count_for_approach(this,approach_in, queryMeasures)
            %% This function is to get turning count data for a given
            % approach with given query measures
            
            % Get the file name
            currentFile=sprintf('TP_%s_%s_%s',approach_in.intersection_name,...
                strrep(approach_in.road_name,' ', '_'),approach_in.direction);
            % Note: In Aimsun, we don't know the physical approach direction, so
            % we use the first section's ID as the indicator of direction.
            % Therefore, we need this mapping file
            TPFileMatch=this.dataProvider_turningCount.FieldAimsunFileMatch;
            idx=ismember(TPFileMatch(:,2),currentFile);
            if(sum(idx)) % If find the corresponding file name (field observed data)
                fileName=sprintf('%s.mat',TPFileMatch{idx,1});
            else % If not
                fileName=sprintf('%s.mat',currentFile);
            end
            
            % If: for a particular date
            if(~isnan(queryMeasures.year)&&~isnan(queryMeasures.month) && ~isnan(queryMeasures.day))
                data=this.dataProvider_turningCount.get_data_for_a_date(fileName,queryMeasures);
            else %Else: for historical data
                queryMeasures.timeOfDay=nan; % Get all the data for the particular year,month, and day of week
                [data]=this.dataProvider_turningCount.clustering(fileName, queryMeasures);
                
                if(isempty(data)) % If still no data
                    % Do not specify year, month, and day of week
                    queryMeasures.year=nan;
                    queryMeasures.month=nan;
                    queryMeasures.dayOfWeek=nan;
                    % Query the data again with the new settings
                    [data]=this.dataProvider_turningCount.clustering(fileName, queryMeasures);
                end
            end
            turning_count_properties.data=data;
            
            turning_count_properties.avgProportion=[];
            if(~isempty(data)) % If it is not empty!
                time=data.time; % Get the time
                
                totalVolume=sum(data.volume,2); % Get the total
                proportionLeft=data.volume(:,1)./totalVolume; % Get the LT proportion
                proportionThrough=data.volume(:,2)./totalVolume; % Get the through proportion
                proportionRight=data.volume(:,3)./totalVolume; % Get the RT proportion
                
                if(isnan(queryMeasures.timeOfDay)) % No specific time of day: average over all time stamps
                    avgProportionLeft=mean(proportionLeft);
                    avgProportionThrough=mean(proportionThrough);
                    avgProportionRight=mean(proportionRight);
                else % Given a specific time
                    startTime=queryMeasures.timeOfDay(1);
                    endTime=queryMeasures.timeOfDay(end);
                    
                    idx=(time>=startTime & time<endTime);
                    
                    if(sum(idx)==0) % Do not have data for that time period: average over all time stamps
                        avgProportionLeft=mean(proportionLeft);
                        avgProportionThrough=mean(proportionThrough);
                        avgProportionRight=mean(proportionRight);
                    else % Have data: average over the given time period
                        avgProportionLeft=mean(proportionLeft(idx));
                        avgProportionThrough=mean(proportionThrough(idx));
                        avgProportionRight=mean(proportionRight(idx));
                    end
                end
                turning_count_properties.avgProportion=[avgProportionLeft,avgProportionThrough,avgProportionRight];
            end
        end
        
        function [approach_out]=get_midlink_data_for_approach(this,approach_in, queryMeasures)
            
            approach_out=approach_in;
            fileName=sprintf('Midlink_%s_%s.mat',approach_in.midlink_properties.Location,...
                approach_in.midlink_properties.Approach);
            if(~isnan(queryMeasures.year)&&~isnan(queryMeasures.month) && ~isnan(queryMeasures.day)) % For a particular date
                data_out=this.dataProvider_midlink.get_data_for_a_date(fileName,queryMeasures);
            else % For historical data
                queryMeasures.timeOfDay=nan;
                [data_out]=this.dataProvider_midlink.clustering(fileName, queryMeasures);
                
                if(isempty(data_out))
                    % Do not specify year, month, and day of week
                    queryMeasures.year=nan;
                    queryMeasures.month=nan;
                    queryMeasures.dayOfWeek=nan;
                    [data_out]=this.dataProvider_midlink.clustering(fileName, queryMeasures);
                end
            end
            
            approach_out.midlink_properties.data=data_out;
        end
        
        function [approach_out]=get_sensor_data_for_approach(this,approach_in,queryMeasures)
            % This function is to get data for a given approach with specific query measures
            
            % First, get the flow and occ data for exclusive left-turn detectors if exist
            tmp=[];
            if(~isempty(approach_in.exclusive_left_turn)) % Exclusive left-turn detectors exist
                for i=1:size(approach_in.exclusive_left_turn,1) % Check the types of exclusive left-turn detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach_in.exclusive_left_turn(i),queryMeasures)];
                end
                approach_in.exclusive_left_turn=tmp;
            end
            
            % Second, get the flow and occ data for exclusive right-turn detectors if exist
            tmp=[];
            if(~isempty(approach_in.exclusive_right_turn))  % Exclusive right-turn detectors exist
                for i=1:size(approach_in.exclusive_right_turn,1) % Check the types of exclusive right-turn detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach_in.exclusive_right_turn(i),queryMeasures)];
                end
                approach_in.exclusive_right_turn=tmp;
            end
            
            % Third, get the flow and occ data for advanced detectors if exist
            tmp=[];
            if(~isempty(approach_in.advanced_detectors)) % Advanced detectors exist
                for i=1:size(approach_in.advanced_detectors,1) % Check the types of advanced detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach_in.advanced_detectors(i),queryMeasures)];
                end
                approach_in.advanced_detectors=tmp;
            end
            
            % Fourth, get the flow and occ data for general stopline detectors if exist
            tmp=[];
            if(~isempty(approach_in.general_stopline_detectors)) % General stop-line detectors exist
                for i=1:size(approach_in.general_stopline_detectors,1) % Check the types of stop-line detectors: n-by-1
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach_in.general_stopline_detectors(i),queryMeasures)];
                end
                approach_in.general_stopline_detectors=tmp;
            end
            
            % Return the average flow and occ data
            approach_out=approach_in;
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
                    tmp_data=this.dataProvider_sensor.get_data_for_a_date(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                else % For historical data
                    tmp_data=this.dataProvider_sensor.clustering(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                    
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
            data=this.dataProvider_sensor.clustering(id, queryMeasures);
        end
        
        %% ***************Functions to get traffic states and estimate vehicle queues*****************
        function [decision_making]=get_traffic_condition_by_approach(this,approach_in,queryMeasures)
            % This function is to get traffic conditions by approach:
            % exclusive left turns, exclusive right turns, stop-line
            % detectors, and advanced detectors.
            
            % Update parameter settings, especially the traffic signals
            signal_properties=this.get_green_times_for_approach_with_field_signal_plan(approach_in,queryMeasures);
            this.params=this.update_signal_setting(signal_properties);
            
            % Get the time
            decision_making.time=queryMeasures.timeOfDay(end);
            
            % Check exclusive left turn
            decision_making.exclusive_left_turn.rates=[];
            decision_making.exclusive_left_turn.speeds=[];
            decision_making.exclusive_left_turn.occupancies=[];
            if(~isempty(approach_in.exclusive_left_turn)) % Exclusive left-turn movement exists
                for i=1:size(approach_in.exclusive_left_turn,1) % Check the state for each type of exclusive left-turn movments
                    % Return rates and the corresponding speed/occupancy scales
                    [rates,speeds,occupancies]=this.check_detector_status...
                        (approach_in.exclusive_left_turn(i).avg_data,approach_in.exclusive_left_turn(i).status,...
                        approach_in.exclusive_left_turn(i).DetectorLength, approach_in.exclusive_left_turn(i).NumberOfLanes,...
                        approach_in.exclusive_left_turn(i).Movement,'exclusive_left_turn');
                    
                    decision_making.exclusive_left_turn.rates=...
                        [decision_making.exclusive_left_turn.rates;{rates}];
                    decision_making.exclusive_left_turn.speeds=...
                        [decision_making.exclusive_left_turn.speeds;{speeds}];
                    decision_making.exclusive_left_turn.occupancies=...
                        [decision_making.exclusive_left_turn.occupancies;{occupancies}];
                end
            end
            
            % Check exclusive right turn
            decision_making.exclusive_right_turn.rates=[];
            decision_making.exclusive_right_turn.speeds=[];
            decision_making.exclusive_right_turn.occupancies=[];
            if(~isempty(approach_in.exclusive_right_turn)) % Exclusive right-turn movement exists
                for i=1:size(approach_in.exclusive_right_turn,1) % Check the state for each type of exclusive right-turn movments
                    % Return rates and the corresponding speed/occupancy scales
                    [rates,speeds,occupancies]=this.check_detector_status...
                        (approach_in.exclusive_right_turn(i).avg_data,approach_in.exclusive_right_turn(i).status,...
                        approach_in.exclusive_right_turn(i).DetectorLength, approach_in.exclusive_right_turn(i).NumberOfLanes,...
                        approach_in.exclusive_right_turn(i).Movement,'exclusive_right_turn');
                    
                    decision_making.exclusive_right_turn.rates=...
                        [decision_making.exclusive_right_turn.rates;{rates}];
                    decision_making.exclusive_right_turn.speeds=...
                        [decision_making.exclusive_right_turn.speeds;{speeds}];
                    decision_making.exclusive_right_turn.occupancies=...
                        [decision_making.exclusive_right_turn.occupancies;{occupancies}];
                end
            end
            
            % Check advanced detectors
            decision_making.advanced_detectors.rates=[];
            decision_making.advanced_detectors.speeds=[];
            decision_making.advanced_detectors.occupancies=[];
            if(~isempty(approach_in.advanced_detectors)) % Advanced detectors exist
                for i=1:size(approach_in.advanced_detectors,1) % Check the state for each type of advanced detectors
                    % Return rates and the corresponding speed/occupancy scales
                    [rates,speeds,occupancies]=this.check_detector_status...
                        (approach_in.advanced_detectors(i).avg_data,approach_in.advanced_detectors(i).status,...
                        approach_in.advanced_detectors(i).DetectorLength,approach_in.advanced_detectors(i).NumberOfLanes,...
                        approach_in.advanced_detectors(i).Movement,'advanced_detectors');
                    
                    decision_making.advanced_detectors.rates=...
                        [decision_making.advanced_detectors.rates;{rates}];
                    decision_making.advanced_detectors.speeds=...
                        [decision_making.advanced_detectors.speeds;{speeds}];
                    decision_making.advanced_detectors.occupancies=...
                        [decision_making.advanced_detectors.occupancies;{occupancies}];
                end
            end
            
            % Check general stopline detectors
            decision_making.general_stopline_detectors.rates=[];
            decision_making.general_stopline_detectors.speeds=[];
            decision_making.general_stopline_detectors.occupancies=[];
            if(~isempty(approach_in.general_stopline_detectors)) % Stop-line detectors exist
                for i=1:size(approach_in.general_stopline_detectors,1) % Check the state for each type of stop-line detectors
                    % Return rates and the corresponding speed/occupancy scales
                    [rates,speeds,occupancies]=this.check_detector_status...
                        (approach_in.general_stopline_detectors(i).avg_data,approach_in.general_stopline_detectors(i).status,...
                        approach_in.general_stopline_detectors(i).DetectorLength, approach_in.general_stopline_detectors(i).NumberOfLanes,...
                        approach_in.general_stopline_detectors(i).Movement,'general_stopline_detectors');
                    
                    decision_making.general_stopline_detectors.rates=...
                        [decision_making.general_stopline_detectors.rates;{rates}];
                    decision_making.general_stopline_detectors.speeds=...
                        [decision_making.general_stopline_detectors.speeds;{speeds}];
                    decision_making.general_stopline_detectors.occupancies=...
                        [decision_making.general_stopline_detectors.occupancies;{occupancies}];
                end
            end
            
            % Provide assessments according to the rates from exclusive
            % left turns, exclusive right turns, stop-line detectors, and
            % advanced detectors
            [status_assessment,queue_assessment]=this.traffic_state_and_queue_assessment(approach_in,decision_making);
            
            decision_making.status_assessment.left_turn=status_assessment(1);
            decision_making.status_assessment.through=status_assessment(2);
            decision_making.status_assessment.right_turn=status_assessment(3);
            
            decision_making.queue_assessment.left_turn=queue_assessment(1);
            decision_making.queue_assessment.through=queue_assessment(2);
            decision_making.queue_assessment.right_turn=queue_assessment(3);
            
        end
        
        function [rates,speeds,occupancies]=check_detector_status(this,data,status,detector_length,numberOfLanes,movement,type)
            % This function is to check the status of individual detector
            % which belongs to the same detector type, e.g., exclusive left
            % turns.
            
            % Get the number of detectors belonging to the same type
            numDetector=size(data,1);
            
            % Initialization
            rates=[];
            speeds=[];
            occupancies=[];
            
            % Check different types: Two different algorithms
            switch type
                % For stop-line detectors
                case {'exclusive_left_turn','exclusive_right_turn','general_stopline_detectors'}
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow and occupancy
                            [rate,speed,occupancy]=this.get_occupancy_scale_and_rate_stopline_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,detector_length(i),numberOfLanes(i),movement,type);
                            rates=[rates,rate];
                            speeds=[speeds,speed];
                            occupancies=[occupancies,occupancy];
                        else % Otherwise, say "Unknown"
                            rates=[rates,{'Unknown'}];
                            speeds=[speeds,0];
                            occupancies=[occupancies,0];
                        end
                    end
                    
                    % For advanced detectors
                case 'advanced_detectors'
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data')) % Only use good data
                            % Use average values of flow, occupancy, and
                            % detector length
                            [rate,speed,occupancy]=this.get_occupancy_scale_and_rate_advanced_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,detector_length(i),numberOfLanes(i));
                            rates=[rates,rate];
                            speeds=[speeds,speed];
                            occupancies=[occupancies,occupancy];
                        else % Otherwise, say "Unknown"
                            rates=[rates,{'Unknown'}];
                            speeds=[speeds,0];
                            occupancies=[occupancies,0];
                        end
                    end
                otherwise
                    error('Wrong input of detector type!')
            end
            
        end
        
        function [rate,speed,occupancy]=get_occupancy_scale_and_rate_advanced_detector(this,flow,occ,detector_length,numberOfLanes)
            % This function is to get the rate and speed for advanced detectors. In this case, we consider advanced
            % detectors are different from other stop-line detectors since
            % traffic flow is less impacted by traffic signals
            % Flow: veh/hr/ln
            % Occ: #sec in one hour
            
            % Get effective length that will occupy the advanced detectors
            effectiveLength=detector_length+this.params.vehicle_length;
            
            % Get the occupancy threshold to divide the state into low and
            % high occupancies
            occThreshold=this.params.occupancy_threshold_for_advanced_detector; % Tend to use this one since it seems occupancy is more reliable
            %             occThreshold=min(flow*effectiveLength/5280/this.params.speed_threshold_for_advanced_detector,1);
            
            % Determine the rating based on the average occupancy
            if(occ>=occThreshold)
                rate={'High Occupancy'}; % Congested
            else
                rate={'Low Occupancy'}; % Uncongested
            end
            
            % Store the speed and occupancy information
            speed=flow*effectiveLength/5280/min(occ,1);
            occupancy=occ;
            
        end
        
        function [rate,speed,occupancy]=get_occupancy_scale_and_rate_stopline_detector(this,flow,occ,detector_length,numberOfLanes,detectorMovement,type)
            % This function is to get the rate, speed, and occupancy for stop-line detectors. In this case, we consider stop-line
            % detectors (exclusive left, exclusive right, and other general stop-line detectors)
            % are different from advanced detectors since traffic flow is
            % mostly impacted by traffic signals.
            
            % NOTE: Here we consider flow is the vehicle flow for the
            % detector (per lane), and occupancy is the seconds
            % it occupies (per lane)
            
            % Get the green ratio: should be updated first if historical
            % signal information can be obtained
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
            
            % Get the saturation speed for different movements
            saturation_speed_left=this.params.saturation_speed_left;
            saturation_speed_right=this.params.saturation_speed_right;
            saturation_speed_through=this.params.saturation_speed_through;
            
            % Time to pass a detector for different movements (in seconds)
            time_to_pass_left=(detector_length+this.params.vehicle_length)*3600/saturation_speed_left/5280;
            time_to_pass_right=(detector_length+this.params.vehicle_length)*3600/saturation_speed_right/5280;
            time_to_pass_through=(detector_length+this.params.vehicle_length)*3600/saturation_speed_through/5280;
            
            % Get proportions of vehicles for left-turn, through, and right-turn
            % movements. We use default values since it is hard to tell the
            % actural proportions at the detector level due to the limited
            % detection accuracy.
            proportion_left=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Left');
            proportion_through=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Through');
            proportion_right=state_estimation.find_traffic_proportion(detectorMovement,this.default_proportions,'Right');
            
            % Get the number of vehicles for each movements
            % The flow is per lane
            numVeh=flow*this.params.cycle/3600; % Total per lane
            numVehLeft=numVeh*proportion_left; % Left per lane
            numVehThrough=numVeh*proportion_through; % Through per lane
            numVehRight=numVeh*proportion_right; % Right per lane
            
            % Get the discharging time given the current number of vehicles
            dischargingTime=start_up_lost_time+(time_to_pass_left*numVehLeft+...
                time_to_pass_right*numVehRight+time_to_pass_through*numVehThrough);
            
            % Get the threshold for occupancy: the red time + the discharging
            % time. It is bounded by 1 since our estimates are very rough.
            occ_threshold=min(1,dischargingTime/this.params.cycle+(1-green_ratio));
            
            % Need to time the number of lanes
            capacity=numberOfLanes*(3600/saturation_headway)*green_ratio;
            
            if(occ<occ_threshold) % Under-saturated
                rate={'Under Saturated'};
            else % In saturated conditions
                if(numberOfLanes*flow>capacity*this.params.flow_threshold_for_stopline_detector)
                    % Oversaturated with high flow. In this case, traffic
                    % in the downstream is considered as uncongested
                    rate={'Over Saturated With No Spillback'};
                else
                    % Oversaturated with low flow. In this case, it is
                    % possible to have queue spillback
                    rate={'Over Saturated With Spillback'};
                end
            end
            
            speed=0; % For stopline detectors, no need to use speed information
            occupancy=occ_threshold; % Save the occupancy threshold for further potential useage
        end
        
        function [status_assessment,queue_assessment]=traffic_state_and_queue_assessment(this,approach,decision_making)
            % This function is for traffic state and queue assessment
            
            if(isempty(approach.exclusive_left_turn)&& isempty(approach.exclusive_right_turn)...
                    && isempty(approach.general_stopline_detectors) && isempty(approach.advanced_detectors))
                % IF no Detector
                status_assessment={'No Detector','No Detector','No Detector'};
                queue_assessment=[NaN, NaN, NaN];
                
            else
                % Get the aggregated states and speeds/occupancies for left-turn, through,
                % and right-turn movements for different types of detectors
                if(~isempty(approach.advanced_detectors))% Check advanced detectors
                    % Get the states of left-turn, through, and right-turn
                    % from advanded detectors
                    possibleAdvanced.Through={'Advanced','Advanced Through','Advanced Through and Right','Advanced Left and Through'};
                    possibleAdvanced.Left={'Advanced','Advanced Left Turn', 'Advanced Left and Through', 'Advanced Left and Right' };
                    possibleAdvanced.Right={'Advanced','Advanced Right Turn','Advanced Through and Right','Advanced Left and Right' };
                    
                    [advanced_status,avg_speed,avg_occ]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.advanced_detectors, possibleAdvanced, decision_making.advanced_detectors,'advanced detectors');
                else
                    advanced_status=[0, 0, 0];
                    avg_speed=[0, 0, 0];
                    avg_occ=[0,0,0];
                end
                
                if(~isempty(approach.general_stopline_detectors)) % Check general stopline detectors
                    % Get the states of left-turn, through, and right-turn
                    % from stopline detectors
                    possibleGeneral.Through={'All Movements','Through', 'Left and Through', 'Through and Right'};
                    possibleGeneral.Left={'All Movements','Left and Right', 'Left and Through'};
                    possibleGeneral.Right={'All Movements','Left and Right', 'Through and Right' };
                    [stopline_status,~,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.general_stopline_detectors, possibleGeneral,decision_making.general_stopline_detectors,'stopline detectors');
                else
                    stopline_status=[0, 0, 0];
                end
                
                if(~isempty(approach.exclusive_right_turn)) % Check exclusive right turn detectors
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive right-turn detectors
                    possibleExclusiveRight.Through=[];
                    possibleExclusiveRight.Left=[];
                    possibleExclusiveRight.Right={'Right Turn','Right Turn Queue'};
                    [exc_right_status,~,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_right_turn,possibleExclusiveRight,decision_making.exclusive_right_turn,'stopline detectors');
                else
                    exc_right_status=[0, 0, 0];
                end
                
                if(~isempty(approach.exclusive_left_turn)) % Check exclusive left turn detectors
                    % Get the states of left-turn, through, and right-turn
                    % from exclusive left-turn detectors
                    possibleExclusiveLeft.Through=[];
                    possibleExclusiveLeft.Left={'Left Turn','Left Turn Queue'};
                    possibleExclusiveLeft.Right=[];
                    [exc_left_status,~,~]=state_estimation.check_aggregate_rate_by_movement_type...
                        (approach.exclusive_left_turn,possibleExclusiveLeft,decision_making.exclusive_left_turn,'stopline detectors');
                else
                    exc_left_status=[0, 0, 0];
                end
                
                % Get the queue thresholds for different traffic movements
                [queue_threshold]=state_estimation.calculation_of_queue_thresholds(approach,...
                    approach.turning_count_properties.proportions,this.params);
                % Note it is not clear which one is better:
                % this.default_proportions or approach.turning_count_properties.proportions
                % Currently, we think the latter one is better since they
                % are estimated from real data
                
                % Get the assessment of states and queues
                [status_assessment,queue_assessment]=state_estimation.make_a_decision...
                    (approach.turnIndicator,this.default_params,queue_threshold,advanced_status,stopline_status,exc_right_status,exc_left_status,avg_speed,avg_occ);
            end
        end
        
        
    end
    
    methods(Static)
        
        %% *************** Functions to get traffic states and estimate vehicle queues *****************
        
        function [status,avg_speed,avg_occ]=check_aggregate_rate_by_movement_type(movement, possibleMovement, decision_making,type)
            % This function is to get the aggreagated rate, speed, and occ by movement (left-turn, through, and right-turn) and
            % type of detectors (exclusive left, exclusive right, general stopline, and advanced detectors)
            
            % Check the number of detector types
            numType=size(movement,1);
            
            possibleThrough=possibleMovement.Through;
            possibleLeft=possibleMovement.Left;
            possibleRight=possibleMovement.Right;
            
            % Check through movements
            rateSum_through=0;
            speedSum_through=0;
            occSum_through=0;
            count_through=0;
            for i=1:numType % Loop for all types
                idx_through=ismember(movement(i).Movement,possibleThrough); % Is it a member for the through movement?
                if(sum(idx_through)) % If yes, get the corresponding rate information (row vector)
                    rates=decision_making.rates{i,:};
                    rateNum=state_estimation.convert_rate_to_num(rates,type);
                    speeds=decision_making.speeds{i,:};
                    occs=decision_making.occupancies{i,:};
                    
                    for j=1:size(rateNum,2) % Loop for all detectors with the same type (all columns)
                        if(rateNum(j)>0) % Have availalbe states
                            count_through=count_through+1;
                            rateSum_through=rateSum_through+rateNum(j);
                            speedSum_through=speedSum_through+speeds(j);
                            occSum_through=occSum_through+occs(j);
                        end
                    end
                end
            end
            if(count_through) % If not zero, take the means
                rateMean_through=rateSum_through/count_through;
                speedMean_through=speedSum_through/count_through;
                occMean_through=occSum_through/count_through;
            else % Else, set to be zeros
                rateMean_through=0;
                speedMean_through=0;
                occMean_through=0;
            end
            
            % Check left-turn movements
            rateSum_left=0;
            speedSum_left=0;
            occSum_left=0;
            count_left=0;
            for i=1:numType
                idx_left=ismember(movement(i).Movement,possibleLeft);
                if(sum(idx_left)) % Find the corresponding left-turn movement
                    rates=decision_making.rates{i,:};
                    rateNum=state_estimation.convert_rate_to_num(rates,type);
                    speeds=decision_making.speeds{i,:};
                    occs=decision_making.occupancies{i,:};
                    
                    for j=1:size(rateNum,2) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_left=count_left+1;
                            rateSum_left=rateSum_left+rateNum(j);
                            speedSum_left=speedSum_left+speeds(j);
                            occSum_left=occSum_left+occs(j);
                        end
                    end
                end
            end
            if(count_left) % If not zero, take the means
                rateMean_left=rateSum_left/count_left;
                speedMean_left=speedSum_left/count_left;
                occMean_left=occSum_left/count_left;
            else % Else, set to be zeros
                rateMean_left=0;
                speedMean_left=0;
                occMean_left=0;
            end
            
            % Check right-turn movements
            rateSum_right=0;
            speedSum_right=0;
            occSum_right=0;
            count_right=0;
            for i=1:numType
                idx_right=ismember(movement(i).Movement,possibleRight);
                if(sum(idx_right)) % Find the corresponding right-turn movement
                    rates=decision_making.rates{i,:};
                    rateNum=state_estimation.convert_rate_to_num(rates,type);
                    speeds=decision_making.speeds{i,:};
                    occs=decision_making.occupancies{i,:};
                    
                    for j=1:size(rateNum,2) % Loop for all detectors with the same type
                        if(rateNum(j)>0) % Have availalbe states
                            count_right=count_right+1;
                            rateSum_right=rateSum_right+rateNum(j);
                            speedSum_right=speedSum_right+speeds(j);
                            occSum_right=occSum_right+occs(j);
                        end
                    end
                end
            end
            if(count_right) % If not zero, take the means
                rateMean_right=rateSum_right/count_right;
                speedMean_right=speedSum_right/count_right;
                occMean_right=occSum_right/count_right;
            else % Else, set to be zeros
                rateMean_right=0;
                speedMean_right=0;
                occMean_right=0;
            end
            
            % Return mean values for different movements
            status=[rateMean_left, rateMean_through, rateMean_right];
            avg_speed=[speedMean_left,speedMean_through,speedMean_right];
            avg_occ=[occMean_left,occMean_through,occMean_right];
        end
        
        function [queue_threshold]=calculation_of_queue_thresholds(approach,proportions,params)
            % This function is used to calculate queue thresholds for
            % left-turn, through, and right-turn movements
            
            % Calculate the seperation lengths and number of lanes by exclusive left-/right-turn movements
            num_exclusive_left_lane= approach.link_properties.ExclusiveLeftTurnLane; % If no exclusive left-turn lanes, this value is zero
            seperation_left=approach.link_properties.LeftTurnPocket;
            num_exclusive_right_lane= approach.link_properties.ExclusiveRightTurnLane;
            seperation_right=approach.link_properties.RightTurnPocket;
            
            % Calculate the lane numbers for left turn, through, and right turn movements at
            % general stopline detectors
            movement_lane_proportion_general=[0, 0, 0]; % Left, through, right
            if(~isempty(approach.general_stopline_detectors)) % Have stopline detectors
                for i=1:size(approach.general_stopline_detectors,1) % Loop for all types of general stopline detectors
                    % Get the detector movement type
                    detectorMovement=approach.general_stopline_detectors(i).Movement;
                    % Get the porportions of traffic movements
                    proportion_left=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Left');
                    proportion_through=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Through');
                    proportion_right=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Right');
                    
                    for j=1: size(approach.general_stopline_detectors(i).IDs,1) % Loop for all detectors belonging to the same type
                        % Get the number of lanes
                        num_of_lane=approach.general_stopline_detectors(i).NumberOfLanes(j);
                        
                        % Update the lane proportions
                        movement_lane_proportion_general=movement_lane_proportion_general+...
                            num_of_lane*[proportion_left,proportion_through,proportion_right];
                    end
                end
            end
            % ***************************
            % RESCALED by the number of lanes in the downstream:
            % it is possible to have less detectors installed than
            % the number of lanes in the downstream (or are broken)
            % ***************************
            if(sum(movement_lane_proportion_general)) % Have stopline detectors
                movement_lane_proportion_general=movement_lane_proportion_general...
                    *approach.link_properties.NumberOfLanesDownstream/sum(movement_lane_proportion_general);
            end
            
            
            % Calculate the lane numbers for left turn, through, and right turn movements at
            % advanded detectors
            movement_lane_proportion_advanced=[0, 0, 0]; % Left, through, right
            distance_advanced_detector=0; % If no advanced detectors, this value is zero
            if(~isempty(approach.advanced_detectors)) % Have advanced detectors
                for i=1:size(approach.advanced_detectors,1) % Loop for all types of advanced detectors
                    % Get the detector movement type
                    detectorMovement=approach.advanced_detectors(i).Movement;
                    % Get the porportions of traffic movements
                    proportion_left=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Left');
                    proportion_through=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Through');
                    proportion_right=state_estimation.find_traffic_proportion(detectorMovement,proportions,'Right');
                    
                    for j=1: size(approach.advanced_detectors(i).IDs,1) % Loop for all detectors belonging to the same type
                        % Get the number of lanes
                        num_of_lane=approach.advanced_detectors(i).NumberOfLanes(j);
                        
                        % Update the lane proportions
                        movement_lane_proportion_advanced=movement_lane_proportion_advanced+...
                            num_of_lane*[proportion_left,proportion_through,proportion_right];
                    end
                    
                    % Get the distance to stopbar(may be a vector)
                    distance_to_stopbar=approach.advanced_detectors(i).DistanceToStopbar;
                    % Get the maximum distance of advanced detectors
                    distance_advanced_detector=max(distance_advanced_detector,max(distance_to_stopbar));
                end
            end
            % ***************************
            % RESCALED by the number of lanes in the upstream:
            % it is possible to have more detectors installed than
            % the number of lanes in the upstream (may be in the transition area)
            % ***************************
            if(sum(movement_lane_proportion_advanced)) % Have advanced detectors
                movement_lane_proportion_advanced=movement_lane_proportion_advanced...
                    *approach.link_properties.NumberOfLanes/sum(movement_lane_proportion_advanced);
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
                distance_advanced_detector,approach,'Left');
            % For right-turn movements
            [queue_threshold.right]=state_estimation.get_queue_threshold_for_movement(num_exclusive_right_lane,movement_lane_proportion_advanced,...
                movement_lane_proportion_general,num_jam_vehicle_per_lane,seperation_right,...
                distance_advanced_detector,approach,'Right');
            % For through movements
            [queue_threshold.through]=state_estimation.get_queue_threshold_for_movement(0,movement_lane_proportion_advanced,...
                movement_lane_proportion_general,num_jam_vehicle_per_lane,max(seperation_left,seperation_right),...
                distance_advanced_detector,approach,'Through');
            
        end
        
        function [threshold]=get_queue_threshold_for_movement(num_exclusive_lane,movement_lane_proportion_advanded,movement_lane_proportion_general,...
                num_jam_vehicle_per_lane,seperation,distance_advanded_detector,approach,type)
            % This function is used to calculate queue thresholds for a
            % particular traffic movenent (left, right, and through)
            
            link_length=approach.link_properties.LinkLength;
            NumberOfLanes=approach.link_properties.NumberOfLanes;
            NumberOfLanesDownstream=approach.link_properties.NumberOfLanesDownstream;
            ExclusiveLeftTurnLane=approach.link_properties.ExclusiveLeftTurnLane;
            ExclusiveRightTurnLane=approach.link_properties.ExclusiveRightTurnLane;
            
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
                    % Try to use smaller values to avoid the case that
                    % downstream has more lanes than upstream within a link
                    if(idx==2) % For through movement: empirically take half of the value
                        movement_lane_proportion_advanded(idx)=movement_lane_proportion_general(idx)...
                            *NumberOfLanes/(ExclusiveLeftTurnLane+ExclusiveRightTurnLane+NumberOfLanesDownstream); % Scaling factor
                    else % For left and right turns: get the mean
                        movement_lane_proportion_advanded(idx)=(num_exclusive_lane/2+movement_lane_proportion_general(idx))...
                            *NumberOfLanes/(ExclusiveLeftTurnLane+ExclusiveRightTurnLane+NumberOfLanesDownstream);
                    end
                end
            else % Have information from advandec detectors
                if(movement_lane_proportion_general(idx)==0 && num_exclusive_lane ==0) % But downstream has no information
                    % Over-write the proportion for general stopline
                    % detectors
                    movement_lane_proportion_general(idx)=movement_lane_proportion_advanded(idx)...
                        *(ExclusiveLeftTurnLane+ExclusiveRightTurnLane+NumberOfLanesDownstream)/NumberOfLanes; % Scaling factor;
                end
            end
            
            % Calculate different components of queues
            if(movement_lane_proportion_advanded(idx)==0 && movement_lane_proportion_general(idx)==0 ...
                    && num_exclusive_lane ==0) % No detector
                queue_exclusive=0;
                queue_general=0;
                queue_advanced=0;
            else
                queue_exclusive=num_exclusive_lane*num_jam_vehicle_per_lane*seperation/5280;
                queue_general=(movement_lane_proportion_general(idx)*seperation+...
                    movement_lane_proportion_advanded(idx)*max(0,distance_advanded_detector-seperation))*num_jam_vehicle_per_lane/5280;
                queue_advanced=movement_lane_proportion_advanded(idx)*num_jam_vehicle_per_lane...
                    *max(0,link_length-distance_advanded_detector)/5280;
            end
            
            threshold.to_advanced=queue_exclusive+queue_general;
            threshold.to_link=queue_exclusive+queue_general+queue_advanced;
        end
        
        function [status,queue]=make_a_decision(turnIndicator,default_params,queue_threshold,advanced_status,stopline_status,exc_right_status,exc_left_status,avg_speed,avg_occ)
            % This function is to make a final decision for left-turn,
            % through, and right-turn movements at the approach level
            
            
            % Get the states for left-turn, through, and right-turn
            % movements
            downstream_status_left=(state_estimation.meanwithouzeros([exc_left_status(1),stopline_status(1)]));
            advanced_status_left=(advanced_status(1));
            
            downstream_status_through=(stopline_status(2));
            advanced_status_through=(advanced_status(2));
            
            downstream_status_right=(state_estimation.meanwithouzeros([exc_right_status(3),stopline_status(3)]));
            advanced_status_right=(advanced_status(3));
            
            % Check the existence of lane blockage by other movements
            % Rates for advanced detectors: 0(no data), 1(low occupancy), 2(high occupancy)
            % Thresholds considering the averages from multiple detectors: [<1.5], [>=1.5]
            
            % Rates for stopline detectors: 0(no data), 1(under saturated), 2(over saturated with high flow)
            % 3(over saturated with low flow)
            % Thresholds considering the averages from multiple detectors:
            % [<1.5], [1.5<=, <2.5], [>= 2.5]
            
            blockage=[0,0,0];
            % Check left turn and adjacent movements
            if(downstream_status_left>=2.5 && advanced_status_left>=1.5) % Left turn congested
                % Through is blocked: advanced congestion, stopline uncongested
                if(advanced_status_through>=1.5 && downstream_status_through<1.5)
                    blockage(1)=1; % Left-turn blockage
                end
            end
            % Check right turn and adjacent movements
            if(downstream_status_right>=2.5 && advanced_status_right>=1.5) % Right turn congested
                if(advanced_status_through>=1.5 && downstream_status_through<1.5) % Through is blocked
                    blockage(3)=1; % Right turn blockage
                end
            end
            % Check through and adjacent movements
            if(downstream_status_through>=2.5 && advanced_status_through>=1.5) % Through congested
                if((downstream_status_right<1.5 && advanced_status_right>=1.5)||...
                        (downstream_status_left<1.5 && advanced_status_left>=1.5)) % Left or right is blocked
                    blockage(2)=1; % Through blockage
                end
            end
            
            
            status=cell(3,1);
            queue=zeros(3,1);
            speed_threshold=default_params.speed_threshold_for_advanced_detector;
            speed_freeflow=default_params.speed_freeflow_for_advanced_detector;
            occ_threshold=default_params.occupancy_threshold_for_advanced_detector;
            
            [status(1,1), queue(1)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_left,advanced_status_left,avg_speed,speed_threshold,speed_freeflow,...
                avg_occ,occ_threshold,'Left');
            [status(2,1), queue(2)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_through,advanced_status_through,avg_speed,speed_threshold,speed_freeflow,...
                avg_occ,occ_threshold,'Through');
            [status(3,1), queue(3)]=state_estimation.decide_status_queue_for_movement...
                (blockage,queue_threshold,downstream_status_right,advanced_status_right,avg_speed,speed_threshold,speed_freeflow,...
                avg_occ,occ_threshold,'Right');
            
            % Check turn indicator
            for i=1:length(turnIndicator)
                if(turnIndicator(i)==0)
                    status(i)={'No Movement'};
                    queue(i)=-2;
                end
            end
            
        end
        
        function [status, queue]=decide_status_queue_for_movement(blockage,queue_threshold,downstream_status,advanced_status,...
                avg_speed,speed_threshold,speed_freeflow,avg_occ,occ_threshold,type)
            
            switch type
                case 'Left'
                    threshold=queue_threshold.left;
                    blockage(1)=0;
                    speed=avg_speed(1);
                    occ=avg_occ(1);
                case 'Through'
                    threshold=queue_threshold.through;
                    blockage(2)=0;
                    speed=avg_speed(2);
                    occ=avg_occ(2);
                case 'Right'
                    threshold=queue_threshold.right;
                    blockage(3)=0;
                    speed=avg_speed(3);
                    occ=avg_occ(3);
                otherwise
                    error('Wrong input of movements!')
            end
            
            % Check the existence of lane blockage by other movements
            % Rates for advanced detectors: 0(no data), 1(low occupancy), 2(high occupancy)
            % Thresholds considering the averages from multiple detectors: [<1.5], [>=1.5]
            
            % Rates for stopline detectors: 0(no data), 1(under saturated), 2(over saturated with high flow)
            % 3(over saturated with low flow)
            % Thresholds considering the averages from multiple detectors:
            % [<1.5], [1.5<=, <2.5], [>= 2.5]
            
            if(advanced_status>=1.5) % Upstream high occupancy
                if(downstream_status==0) % No downstream detector
                    if(sum(blockage)) % Lane blockage by other lanes
                        status={'Lane Blockage By Other Movements'};
                        queue=max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                        %                         queue=max(0,(speed_threshold-speed)/speed_threshold*(threshold.to_link-threshold.to_advanced));
                    else
                        status={'Long Queue'};
                        queue=threshold.to_advanced+...
                            max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                        %                         queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                        %                             *(threshold.to_link-threshold.to_advanced));
                    end
                elseif(downstream_status <1.5)
                    if(sum(sum(blockage)))
                        status={'Lane Blockage By Other Movements'};
                        queue=max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                    else
                        status={'Oversaturated With Long Queue'};
                        queue=threshold.to_advanced+...
                            max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                    end
                    %                     queue=max(0,(speed_threshold-speed)/speed_threshold...
                    %                         *(threshold.to_link-threshold.to_advanced));
                elseif(downstream_status>=1.5 && downstream_status<2.5)
                    status={'Oversaturated With Long Queue'};
                    queue=threshold.to_advanced+...
                        max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                    %                     queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                    %                         *(threshold.to_link-threshold.to_advanced));
                elseif(downstream_status>=2.5)
                    status={'Downstream Spillback With Long Queue'};
                    queue=threshold.to_advanced+...
                        max(0,(occ-occ_threshold)/(1-occ_threshold)*(threshold.to_link-threshold.to_advanced));
                    %                     queue=threshold.to_advanced+ max(0,(speed_threshold-speed)/speed_threshold...
                    %                         *(threshold.to_link-threshold.to_advanced));
                end
            elseif(advanced_status>=1 && advanced_status<1.5) % Upstream low occupancy
                if(downstream_status==0) % No downstream detector
                    status={'Short Queue'};
                    queue=max(0,occ/occ_threshold*threshold.to_advanced);
                    %                     queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                elseif(downstream_status <1.5)
                    status={'No Congestion'};
                    queue=max(0,occ/occ_threshold*threshold.to_advanced);
                    %                     queue=0;
                elseif(downstream_status>=1.5 && downstream_status<2.5)
                    status={'Oversaturated With Short Queue'};
                    queue=max(0,occ/occ_threshold*threshold.to_advanced);
                    %                     queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                elseif(downstream_status>=2.5)
                    status={'Downstream Spillback With Short Queue'};
                    queue=max(0,occ/occ_threshold*threshold.to_advanced);
                    %                     queue=max(0,(speed_freeflow-speed)/(speed_freeflow-speed_threshold)*threshold.to_advanced);
                end
            elseif(advanced_status==0) % No upstream information
                if(downstream_status==0) % No downstream detector
                    status={'Unknown'};
                    queue=-1;
                elseif(downstream_status <1.5)
                    if(sum(blockage))
                        status={'Lane Blockage By Other Movements'};
                        queue=max(0,(threshold.to_link-threshold.to_advanced)*rand); % Randomly pick a value
                    else
                        status={'No Congestion'};
                        queue=max(0,threshold.to_advanced*rand); % Randomly pick a value
                        %                         queue=0;
                    end
                elseif(downstream_status>=1.5 && downstream_status<2.5)
                    status={'Oversaturated'};
                    queue=0.5*threshold.to_link*rand; % Randomly pick a value
                elseif(downstream_status>=2.5)
                    status={'Downstream Spillback'};
                    queue=0.5*threshold.to_link+0.5*threshold.to_link*rand;
                end
            end
        end
        
        function [proportion]=find_traffic_proportion(detectorMovement,default_proportion,movement)
            % This function is to find the default proportion for a certain
            % movement through a given type of detector
            
            % Get the index
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
            
            % Find the corresponding proportion
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
        
        function [maxGreen]=find_green_time_by_movement(approach_in,type,currentControlPlan)
            
            turningInf=approach_in.turningInf;
            turningIDs=[turningInf.TurningProperty.TurnID]';
            turningDescriptions={turningInf.TurningProperty.Description}';
            
            % Check left-turn movements            
            idx=ismember(turningDescriptions,type);
            maxGreen=0;
            if(sum(idx)) % If not empty
                turningBelongToType=turningIDs(idx);                
                for i=1:length(turningBelongToType) % Loop for each turning movement
                    signalByTurn=[];
                    turnID=turningBelongToType(i); % Get turn ID
                    
                    % Check the signals involved
                    for j=1:size(currentControlPlan.Signals,1)
                        for k=1:length(currentControlPlan.Signals(j).TurningInSignal)
                            if(currentControlPlan.Signals(j).TurningInSignal(k)==turnID)
                                signalByTurn=[signalByTurn;currentControlPlan.Signals(j).SignalID];
                                break;
                            end
                        end
                    end
                    
                    % Check the total green time for this turn
                    totalGreen=0;
                    if(~isempty(signalByTurn))
                        for s=1:length(signalByTurn)
                            signalID=signalByTurn(s);
                            for j=1:size(currentControlPlan.Phases,1)
                                for k=1:length(currentControlPlan.Phases(j).SignalInPhase)
                                    if(currentControlPlan.Phases(j).SignalInPhase(k)==signalID)
                                        totalGreen=totalGreen+currentControlPlan.Phases(j).Duration;
                                        break;
                                    end
                                end
                            end
                        end
                    end
                    
                    if(maxGreen<totalGreen)
                        maxGreen=totalGreen;
                    end
                end
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
                    'medFlow', median(data.s_volume,'omitnan'),...                % Median flow
                    'medOccupancy', median(data.s_occupancy,'omitnan')/3600,...   % Median occupancy
                    'maxFlow', max(data.s_volume),...                   % Maximum value of flow
                    'maxOccupancy', max(data.s_occupancy)/3600,...      % Maximum value of occupancy
                    'minFlow', min(data.s_volume),...                   % Minimum value of flow
                    'minOccupancy', min(data.s_occupancy)/3600);        % Minimum value of occupancy
            end
        end
        
        
        %% *************** Functions to extract estimation performance *****************
        function extract_to_excel(appStateEst,outputFolder,outputFileName,outputSheetName)
            % This function is extract the state estimation results to an
            % excel file
            
            outputFileName=fullfile(outputFolder,outputFileName);
            
            xlswrite(outputFileName,[{'Intersection Name'},{'Road Name'},{'Direction'},{'Time'},...
                {'Left Turn Status'},{'Through movement Status'},{'Right Turn Status'},...
                {'Left Turn Queue'},{'Through movement Queue'},{'Right Turn Queue'}],outputSheetName);
            
            % Write intersection and detector information
            int_name=[];
            road_name=[];
            direction=[];
            for i=1:size(appStateEst,1)
                int_name=[int_name;repmat({appStateEst(i).intersection_name},size(appStateEst(i).decision_making,1),1)];
                road_name=[road_name;repmat({appStateEst(i).road_name},size(appStateEst(i).decision_making,1),1)];
                direction=[direction;repmat({appStateEst(i).direction},size(appStateEst(i).decision_making,1),1)];
            end
            
            data=vertcat(appStateEst.decision_making);
            time=vertcat({data.time})';
            assessment=vertcat(data.status_assessment);
            left_turn=[assessment.left_turn]';
            through=([assessment.through])';
            right_turn=([assessment.right_turn])';
            
            xlswrite(outputFileName,[...
                int_name,...
                road_name,...
                direction,...
                time,...
                left_turn,...
                through,...
                right_turn],outputSheetName,sprintf('A2:G%d',length(left_turn)+1));
            
            queue=vertcat(data.queue_assessment);
            left_turn_queue=ceil([queue.left_turn]');
            through_queue=ceil([queue.through]');
            right_turn_queue=ceil([queue.right_turn]');
            
            xlswrite(outputFileName,[...
                left_turn_queue,...
                through_queue,...
                right_turn_queue],outputSheetName,sprintf('H2:J%d',length(left_turn_queue)+1));
            
            
        end
        
        function [Table]=extract_to_csv(appStateEst,outputFolder,outputFileName)
            % This function is extract the state estimation results to an
            % excel file
            
            outputFileName=fullfile(outputFolder,outputFileName);
            
            fid = fopen(outputFileName,'w');
            
            fprintf(fid,'%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n','Junction ID','Junction Name','Junction ExtID','Signalized',...
                'Direction (Section ID)','Section Name','Section ExtID','Time',...
                'Left Turn Status','Through movement Status','Right Turn Status',...
                'Left Turn Queue','Through movement Queue','Right Turn Queue');
            
            % Write intersection and detector information
            int_id=[];
            int_extid=[];
            signalized=[];
            int_name=[];
            road_name=[];
            road_extid=[];
            direction=[];
            for i=1:size(appStateEst,1)
                int_id=[int_id;repmat({appStateEst(i).intersection_id},size(appStateEst(i).decision_making,1),1)];
                int_extid=[int_extid;repmat({appStateEst(i).intersection_extID},size(appStateEst(i).decision_making,1),1)];
                signalized=[signalized;repmat({appStateEst(i).signalized},size(appStateEst(i).decision_making,1),1)];
                int_name=[int_name;repmat({appStateEst(i).intersection_name},size(appStateEst(i).decision_making,1),1)];
                road_name=[road_name;repmat({appStateEst(i).road_name},size(appStateEst(i).decision_making,1),1)];
                direction=[direction;repmat({appStateEst(i).direction},size(appStateEst(i).decision_making,1),1)];
                road_extid=[road_extid;repmat({appStateEst(i).road_extID},size(appStateEst(i).decision_making,1),1)];
            end
            
            data=vertcat(appStateEst.decision_making);
            time=vertcat({data.time})';
            assessment=vertcat(data.status_assessment);
            left_turn=[assessment.left_turn]';
            through=([assessment.through])';
            right_turn=([assessment.right_turn])';
            
            queue=vertcat(data.queue_assessment);
            left_turn_queue=ceil([queue.left_turn]');
            through_queue=ceil([queue.through]');
            right_turn_queue=ceil([queue.right_turn]');
            
            for i=1:length(left_turn)
                fprintf(fid,'%i,%s,%i,%i,%s,%s,%s,%i,%s,%s,%s,%i,%i,%i\n',int_id{i,:},int_name{i,:},int_extid{i,:},signalized{i,:},...
                    direction{i,:},road_name{i,:},road_extid{i,:},time{i,:},...
                    left_turn{i,:},through{i,:},right_turn{i,:},left_turn_queue(i,:),through_queue(i,:),right_turn_queue(i,:));
            end
            
            fclose(fid);
            
            Table=[int_id,int_name,int_extid,signalized,direction,road_name,road_extid,time,...
                left_turn,through,right_turn,...
                num2cell(left_turn_queue),num2cell(through_queue),num2cell(right_turn_queue)];
        end
    end
end

