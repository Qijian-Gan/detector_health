classdef congestion_identification 
    properties
        
        default_cycle                   % Default cycle length
        default_green_left              % Default green ratio for left turns
        default_green_through           % Default green ratio for through vehicles
        default_green_right             % Default green ratio for right turns
        default_detector_length         % Default detector length
        default_vehicle_length          % Default vehicle length
        default_speed_scales            % Default speed scales
        default_saturation_headway      % Default saturation headway   
        
        cycle                           % Cycle length
        green_left                      % Green ratio for left turns
        green_through                   % Green ratio for through vehicles
        green_right                     % Green ratio for right turns
        detector_length                 % Detector length
        vehicle_length                  % Vehicle length     
        speed_scales                    % Speed Scales
        saturation_headway              % Saturation headway 
        
    end
    
    methods ( Access = public )
        
        function [this]=congestion_identification
            % This function is to identify traffic congestion level
            % according to the type of detectors
            this.default_cycle=120;
            this.default_green_left=0.15;
            this.default_green_through=0.35;
            this.default_green_right=0.35;
            
            this.default_detector_length=12;
            this.default_vehicle_length=17;
            
            this.default_speed_scales=[30 15 5];
            this.default_saturation_headway=2.5;            
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
            if(~isempty(approach.exclusive_left_turn))
                [rates,scales]=this.check_detector_status...
                    (approach.exclusive_left_turn.avg_data,approach.exclusive_left_turn.status,'exclusive_left_turn');
                approach.exclusive_left_turn.traffic_condition_by_detector=struct(...
                    'rates',        rates,...
                    'occ_scales',   scales);                
            end
        
            % Check exclusive right turn
            if(~isempty(approach.exclusive_right_turn))
                [rates,scales]=this.check_detector_status...
                    (approach.exclusive_right_turn.avg_data,approach.exclusive_right_turn.status,'exclusive_right_turn');
                approach.exclusive_right_turn.traffic_condition_by_detector=struct(...
                    'rates',        rates,...
                    'occ_scales',   scales);                
            end
            
            % Check advanced detectors
            if(~isempty(approach.advanced_detectors))
                [rates,scales]=this.check_detector_status...
                    (approach.advanced_detectors.avg_data,approach.advanced_detectors.status,'advanced_detectors');
                approach.advanced_detectors.traffic_condition_by_detector=struct(...
                    'rates',        rates,...
                    'occ_scales',   scales);                
            end
            
            % Check general stopline detectors
            if(~isempty(approach.general_stopline_detectors))
                [rates,scales]=this.check_detector_status...
                    (approach.general_stopline_detectors.avg_data,approach.general_stopline_detectors.status,'general_stopline_detectors');
                approach.general_stopline_detectors.traffic_condition_by_detector=struct(...
                    'rates',        rates,...
                    'occ_scales',   scales);                
            end
            
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
            
            effectiveLength=this.detector_length+this.vehicle_length;
            
            % Get low-level occupancy        
            lowOcc=min(flow*effectiveLength/5280/this.speed_scales(1),1);
            
            % Get mid-level occupancy
            midOcc=min(flow*effectiveLength/5280/this.speed_scales(2),1);

            % Get high-level occupancy
            highOcc=min(flow*effectiveLength/5280/this.speed_scales(3),1);
            
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
                    green_ratio=this.green_left;
                case 'exclusive_right_turn'
                    green_ratio=this.green_right;
                case 'general_stopline_detectors'
                    green_ratio=this.green_through;
                otherwise
                    error('Wrong input of detector type!')
            end
            
            % Get low-level occupancy: consider moving queue at saturation
            % flow-rate
            numVeh=flow*this.cycle/3600;
            lowTime=numVeh*this.saturation_headway;            
            lowOcc=min(lowTime/this.cycle,1);
            
            % Get mid-level occupancy: consider expected waiting delay
            expected_delay=this.cycle*(1-green_ratio)*0.5;
            midTime=expected_delay+lowTime;
            midOcc=min(midTime/this.cycle,1);

            % Get high-level occupancy: consider the worst case to wait
            % for the whole red time
            max_delay=this.cycle*(1-green_ratio);
            highTime=max_delay+lowTime;
            highOcc=min(highTime/this.cycle,1);
            
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
            
            if (nargin==1) % Get default values
                this.cycle=this.default_cycle;                   
                this.green_left=this.default_green_left;              
                this.green_through=this.default_green_through;           
                this.green_right=this.default_green_right;           
                
                this.detector_length=this.default_detector_length;        
                this.vehicle_length=this.default_vehicle_length;          
                
                this.speed_scales=this.default_speed_scales;         
                this.saturation_headway=this.default_saturation_headway;     
                
            else % Get updated values
                % Check cycle
                if(isfiled(params,'cycle'))
                    this.cycle=params.cycle;
                else
                    this.cycle=this.default_cycle;    
                end
                % Check gree ratio for left turns
                if(isfiled(params,'green_left'))
                    this.green_left=params.green_left;
                else
                    this.green_left=this.default_green_left;    
                end
                % Check green ratio for through vehicles
                if(isfiled(params,'green_through'))
                    this.green_through=params.green_through;
                else
                    this.green_through=this.default_green_through;    
                end
                % Check green ratio for right turns
                if(isfiled(params,'green_right'))
                    this.green_right=params.green_right;
                else
                    this.green_right=this.default_green_right;    
                end
                % Check detector length
                if(isfiled(params,'detector_length'))
                    this.detector_length=params.detector_length;
                else
                    this.detector_length=this.default_detector_length;    
                end
                % Check vehicle length
                if(isfiled(params,'vehicle_length'))
                    this.vehicle_length=params.vehicle_length;
                else
                    this.vehicle_length=this.default_vehicle_length;    
                end
                % Check speed scales
                if(isfiled(params,'speed_scales'))
                    this.speed_scales=params.speed_scales;
                else
                    this.speed_scales=this.default_speed_scales;    
                end
                % Check saturation headway
                if(isfiled(params,'saturation_headway'))
                    this.saturation_headway=params.saturation_headway;
                else
                    this.saturation_headway=this.default_saturation_headway;    
                end
            end
          
        end
        
     
     
    end
   
    
end

