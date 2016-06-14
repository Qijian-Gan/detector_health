classdef state_estimation < handle
    properties
        
        detectorConfig              % Detector-based configuration
        approachConfig              % Approach-based configuration
        
        dataProvider                % Data provider
        
        default_params              % Default parameters
        params                      % Current parameters
        
    end
    
    methods ( Access = public )
        
        function [this]=state_estimation(detectorConfig,approachConfig,dataProvider)
            % This function is to do the state estimation
            
            this.detectorConfig=detectorConfig;
            this.approachConfig=approachConfig;
            this.dataProvider=dataProvider;
            
            this.default_params=struct(...
                'cycle',                    120,...
                'green_left',               0.15,...
                'green_through',            0.35,...
                'green_right',              0.35,...
                'detector_length',          12,...
                'vehicle_length',           17,...
                'speed_scales',             [30 15 5],...
                'saturation_headway',       2.5);
            
        end
        
        function [approachData]=get_data_for_approach(this,approach,queryMeasures)
            
            % First, get the flow and occ data for the exclusive left-turn
            % detectors if exist
            tmp=[];
            if(~isempty(approach.exclusive_left_turn))
                for i=1:size(approach.exclusive_left_turn,1)
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.exclusive_left_turn(i),queryMeasures)];
                end
                approach.exclusive_left_turn=tmp;
            end
            
            % Second, get the flow and occ data for the exclusive right-turn
            % detectors if exist
            tmp=[];
            if(~isempty(approach.exclusive_right_turn))
                for i=1:size(approach.exclusive_right_turn,1)
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.exclusive_right_turn(i),queryMeasures)];
                end
                approach.exclusive_right_turn=tmp;
            end
            
            % Third, get the flow and occ data for the advanced detectors
            % if exist
            tmp=[];
            if(~isempty(approach.advanced_detectors))
                for i=1:size(approach.advanced_detectors,1)
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.advanced_detectors(i),queryMeasures)];
                end
                approach.advanced_detectors=tmp;
            end
            
            % Fourth, get the flow and occ data for the general stopline
            % detectors if exist
            tmp=[];
            if(~isempty(approach.general_stopline_detectors))
                for i=1:size(approach.general_stopline_detectors,1)
                    tmp=[tmp;...
                        this.get_average_data_for_movement(approach.general_stopline_detectors(i),queryMeasures)];
                end
                approach.general_stopline_detectors=tmp;
            end
            
            approachData=approach;
        end
        
        function [movementData_Out]=get_average_data_for_movement(this,movementData_In,queryMeasures)
            
            movementData_Out=movementData_In;
            
            movementData_Out.data=[];
            movementData_Out.avg_data=[];
            movementData_Out.status=[];
            for i=1: size(movementData_Out.IDs,1)
                tmp_data=this.dataProvider.clustering(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                
                if(~strcmp(tmp_data.status,'Good Data'))
                    % Not good data, try historical averages
                    tmp_data_hist=this.get_historical_average(cellstr(movementData_Out.IDs(i,:)), queryMeasures);
                    
                    if(strcmp(tmp_data_hist.status,'Good Data'))
                        % Only when it returns good historical averages
                        tmp_data=tmp_data_hist;
                    end
                end
                
                movementData_Out.status=[movementData_Out.status;{tmp_data.status}];
                movementData_Out.data=[movementData_Out.data;tmp_data.data];
                
                aggData=state_estimation.get_aggregated_data(tmp_data.data);
                movementData_Out.avg_data=[movementData_Out.avg_data;aggData];
            end
        end
        
        function [data]=get_historical_average(this,id,queryMeasures)
            
            queryMeasures.year=nan;
            queryMeasures.month=nan;
            queryMeasures.dayOfWeek=nan;
            
            data=this.dataProvider.clustering(id, queryMeasures);
        end
        
        
        
        function [approachData]=get_traffic_condition_by_approach(this,approach,params)
            
            % For each approach, we may need to update its parameter
            % settings
            if(nargin>=3) % Have new settings
                this=this.update_param_setting(params);
            else % Do not have param settings
                this=this.update_param_setting;
            end
            
            % Check exclusive left turn
            approach.decision_making.exclusive_left_turn.rates=[];
            approach.decision_making.exclusive_left_turn.scales=[];
            if(~isempty(approach.exclusive_left_turn))
                for i=1:size(approach.exclusive_left_turn,1)
                    [rates,scales]=this.check_detector_status...
                        (approach.exclusive_left_turn(i).avg_data,approach.exclusive_left_turn(i).status,'exclusive_left_turn');
                    
                    approach.decision_making.exclusive_left_turn.rates=...
                        [approach.decision_making.exclusive_left_turn.rates;rates];
                    approach.decision_making.exclusive_left_turn.scales=...
                        [approach.decision_making.exclusive_left_turn.scales;scales];
                end
            end
            
            % Check exclusive right turn
            approach.decision_making.exclusive_right_turn.rates=[];
            approach.decision_making.exclusive_right_turn.scales=[];
            if(~isempty(approach.exclusive_right_turn))
                for i=1:size(approach.exclusive_right_turn,1)
                    [rates,scales]=this.check_detector_status...
                        (approach.exclusive_right_turn(i).avg_data,approach.exclusive_right_turn(i).status,'exclusive_right_turn');
                    
                    approach.decision_making.exclusive_right_turn.rates=...
                        [approach.decision_making.exclusive_right_turn.rates;rates];
                    approach.decision_making.exclusive_right_turn.scales=...
                        [approach.decision_making.exclusive_right_turn.scales;scales];
                end
            end
            
            % Check advanced detectors
            approach.decision_making.advanced_detectors.rates=[];
            approach.decision_making.advanced_detectors.scales=[];
            if(~isempty(approach.advanced_detectors))
                for i=1:size(approach.advanced_detectors,1)
                    [rates,scales]=this.check_detector_status...
                        (approach.advanced_detectors(i).avg_data,approach.advanced_detectors(i).status,'advanced_detectors');
                    
                    approach.decision_making.advanced_detectors.rates=...
                        [approach.decision_making.advanced_detectors.rates;rates];
                    approach.decision_making.advanced_detectors.scales=...
                        [approach.decision_making.advanced_detectors.scales;scales];
                end
            end
            
            % Check general stopline detectors
            approach.decision_making.general_stopline_detectors.rates=[];
            approach.decision_making.general_stopline_detectors.scales=[];
            if(~isempty(approach.general_stopline_detectors))
                for i=1:size(approach.general_stopline_detectors,1)
                    [rates,scales]=this.check_detector_status...
                        (approach.general_stopline_detectors(i).avg_data,approach.general_stopline_detectors(i).status,...
                        'general_stopline_detectors');
                    
                    approach.decision_making.general_stopline_detectors.rates=...
                        [approach.decision_making.general_stopline_detectors.rates;rates];
                    approach.decision_making.general_stopline_detectors.scales=...
                        [approach.decision_making.general_stopline_detectors.scales;scales];
                end
            end
            
            [status_assessment]=state_estimation.traffic_state_assessment(approach);
            approach.decision_making.assessment.left_turn=status_assessment(1);
            approach.decision_making.assessment.through=status_assessment(2);
            approach.decision_making.assessment.right_turn=status_assessment(3);
                
            approachData=approach;
            
        end
        
        function [rates,scales]=check_detector_status(this,data,status,type)
            numDetector=size(data,1);
            rates=[];
            scales=[];
            switch type
                case {'exclusive_left_turn','exclusive_right_turn','general_stopline_detectors'}
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data'))
                            [occ_rate,occ_scale]=this.get_occupancy_scale_and_rate_stopline_detector...
                                (data(i).avgFlow,data(i).avgOccupancy,type);
                            rates=[rates;occ_rate];
                            scales=[scales;occ_scale];
                        else
                            rates=[rates;{'Unknown'}];
                            scales=[scales;nan(1,3)];
                        end
                    end
                case 'advanced_detectors'
                    for i=1:numDetector
                        if(strcmp(cellstr(status(i,:)),'Good Data'))
                            [occ_rate,occ_scale]=this.get_occupancy_scale_and_rate_advanced_detector...
                                (data(i).avgFlow,data(i).avgOccupancy);
                            rates=[rates;occ_rate];
                            scales=[scales;occ_scale];
                        else
                            rates=[rates;{'Unknown'}];
                            scales=[scales;nan(1,3)];
                        end
                    end
                otherwise
                    error('Wrong input of detector type!')
            end
            
        end
        
        function [occ_rate,occ_scale]=get_occupancy_scale_and_rate_advanced_detector(this,flow,occ)
            
            effectiveLength=this.params.detector_length+this.params.vehicle_length;
            
            % Get low-level occupancy
            lowOcc=min(flow*effectiveLength/5280/this.params.speed_scales(1),1);
            
            % Get mid-level occupancy
            midOcc=min(flow*effectiveLength/5280/this.params.speed_scales(2),1);
            
            % Get high-level occupancy
            highOcc=min(flow*effectiveLength/5280/this.params.speed_scales(3),1);
            
            occ_scale=[lowOcc, midOcc, highOcc];
            
            % Get the rating based on the average occupancy
            if(occ>=highOcc)
                occ_rate={'Heavy Congestion'};
            elseif(occ>=midOcc)
                occ_rate={'Moderate Congestion'};
            elseif(occ>=lowOcc)
                occ_rate={'Light Congestion'};
            else
                occ_rate={'No Congestion'};
            end
        end
        
        function [occ_rate,occ_scale]=get_occupancy_scale_and_rate_stopline_detector(this,flow,occ,type)
            
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
            
            % Get low-level occupancy: consider moving queue at saturation
            % flow-rate
            numVeh=flow*this.params.cycle/3600;
            lowTime=numVeh*this.params.saturation_headway;
            lowOcc=min(lowTime/this.params.cycle,1);
            
            % Get mid-level occupancy: consider expected waiting delay
            expected_delay=this.params.cycle*(1-green_ratio)*0.5;
            midTime=expected_delay+lowTime;
            midOcc=min(midTime/this.params.cycle,1);
            
            % Get high-level occupancy: consider the worst case to wait
            % for the whole red time
            max_delay=this.params.cycle*(1-green_ratio);
            highTime=max_delay+lowTime;
            highOcc=min(highTime/this.params.cycle,1);
            
            occ_scale=[lowOcc, midOcc, highOcc];
            
            % Get the rating based on the average occupancy
            if(occ>=highOcc)
                occ_rate={'Heavy Congestion'};
            elseif(occ>=midOcc)
                occ_rate={'Moderate Congestion'};
            elseif(occ>=lowOcc)
                occ_rate={'Light Congestion'};
            else
                occ_rate={'No Congestion'};
            end
        end
        
        function [this]=update_param_setting(this,params)
            
            this.params=this.default_params;
            if (nargin>1) % Get updated values
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
                % Check detector length
                if(isfiled(params,'detector_length'))
                    this.params.detector_length=params.detector_length;
                end
                % Check vehicle length
                if(isfiled(params,'vehicle_length'))
                    this.params.vehicle_length=params.vehicle_length;
                end
                % Check speed scales
                if(isfiled(params,'speed_scales'))
                    this.params.speed_scales=params.speed_scales;
                end
                % Check saturation headway
                if(isfiled(params,'saturation_headway'))
                    this.params.saturation_headway=params.saturation_headway;
                end
            end
            
        end
        
    end
    
    methods(Static)
        
        function [status_assessment]=traffic_state_assessment(approach)

            if(isempty(approach.exclusive_left_turn)&& isempty(approach.exclusive_right_turn)...
                    && isempty(approach.general_stopline_detectors) && isempty(approach.advanced_detectors)) % No Detector
                status_assessment={'No Detector','No Detector','No Detector'};
            else
                % Check advanced detectors
                if(~isempty(approach.advanced_detectors))
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
                if(sum(idx_left)) % Find the corresponding through movement
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
                if(sum(idx_right)) % Find the corresponding through movement
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

            % Check Through movements
            if(advanced_status(2)==4 || stopline_status(2)==4) % Through blockage
                status_through={'Through Blockage'};
            else
                [meanRate]=state_estimation.meanwithouzeros([advanced_status(2),stopline_status(2)]);
                status_through=state_estimation.convert_num_to_rate(meanRate);                
            end
            
            % Check left-turn movements
            if(advanced_status(1)==4 && exc_left_status(1)>=3) % Left turn blockage
                status_left={'Left Turn Blockage'};
            else % Take the mean value
                [meanRate]=state_estimation.meanwithouzeros([exc_left_status(1),stopline_status(1),advanced_status(1)]);
                status_left=state_estimation.convert_num_to_rate(meanRate);
            end
           
            % Check right-turn movements
            if(advanced_status(3)==4 && exc_right_status(3)>=3) % Right turn blockage
                status_right={'Right Turn Blockage'};
            else % Take the mean value
                [meanRate]=state_estimation.meanwithouzeros([exc_right_status(3),stopline_status(3),advanced_status(3)]);
                status_right=state_estimation.convert_num_to_rate(meanRate);
            end                 
            
            status={status_left,status_through,status_right};            
        end        
        
        function [output]=meanwithouzeros(input)
            if(sum(input)==0)
                output=0;
            else
                output=mean(input(input~=0));
            end
        end
        
        function [rateNum]=convert_rate_to_num(rates)
            
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
            if(isempty(data.time))
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
            else
                aggData=struct(...
                    'startTime',data.time(1),...
                    'endTime', data.time(end),...
                    'avgFlow', mean(data.s_volume),...
                    'avgOccupancy', mean(data.s_occupancy)/3600,...
                    'medFlow', median(data.s_volume),...
                    'medOccupancy', median(data.s_occupancy)/3600,...
                    'maxFlow', max(data.s_volume),...
                    'maxOccupancy', max(data.s_occupancy)/3600,...
                    'minFlow', min(data.s_volume),...
                    'minOccupancy', min(data.s_occupancy)/3600);
            end
        end
        
        function extract_to_excel(appStateEst,outputFolder,outputFileName)

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

