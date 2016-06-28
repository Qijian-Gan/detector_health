classdef DetectorDataProfile

    properties
		time                    % Time of day: in seconds
        s_volume                % Hourly volumes
        s_occupancy             % Vehicle average occupancy
        s_speed                 % Vehicle average speed
        s_delay                 % Vehicle average delay
        s_stops                 % Vehicle stops
    end
	
    methods( Access = public )

        function [this] = DetectorDataProfile(time,s_volume,s_occupancy,s_speed, s_delay, s_stops)
            % This function is to return the structual detector data
            % profile
        
            % First initialize the profile 
            this.time = [];
            this.s_volume = [];
            this.s_occupancy = [];
            this.s_speed = []; % Optional
            this.s_delay = []; % Optional
            this.s_stops = []; % Optional
                
            if nargin == 0 % Just need empty data profile
                return; 
            end            
            
            if nargin > 0 && nargin < 3 % At least contain: time, flow, occupancy
                error('Not enough inputs!')
            else
                if(isempty(time)) % Time can not be empty
                    error('Empty time input!')
                end
                n = length(time);
                this.time = DetectorDataProfile.row_vector(time);
                
                if nargin >=3
                    if ~isempty(s_volume) && n~=length(s_volume)
                        error('Bad dimensions!')
                    end
                    
                    if ~isempty(s_occupancy) && n~=length(s_occupancy)
                        error('Bad dimensions!')
                    end
                    
                    this.s_volume = DetectorDataProfile.row_vector(s_volume);
                    this.s_occupancy = DetectorDataProfile.row_vector(s_occupancy);
                end
                
                if nargin >=4
                    if ~isempty(s_speed) && n~=length(s_speed)
                        error('Bad dimensions!')
                    end
                    this.s_speed = DetectorDataProfile.row_vector(s_speed);
                end
                
                if nargin >=5
                    if ~isempty(s_delay) && n~=length(s_delay)
                        error('Bad dimensions!')
                    end
                    this.s_delay = DetectorDataProfile.row_vector(s_delay);
                end
                
                if nargin ==6
                    if ~isempty(s_stops) && n~=length(s_stops)
                        error('Bad dimensions!')
                    end
                    this.s_stops = DetectorDataProfile.row_vector(s_stops);
                end
                
                if nargin >6 
                    error('Too many inputs!')
                end
            end            
		end

    end
    
    methods (Static)
        
        function [y] = row_vector(x)
            
            if isempty(x)
                y = x;
                return
            end
            minsize = min(size(x));
            maxsize = max(size(x));
            y=reshape(x,1,maxsize*minsize);
        end
    end
end

