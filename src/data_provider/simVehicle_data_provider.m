classdef simVehicle_data_provider 
    properties
        
        inputFolderLocation             % Folder that stores the vehicle trajectory file
        outputFolderLocation            % Folder that outputs the processed files
        
        listSections                 % List of detectors
        timePeriod                   % Time period: [start_time, end_time] in seconds
        distance                     % Distance from the stopbar that is used to get the turning proportions of vehicles in this region
    end
    
    methods ( Access = public )

        function [this]=simVehicle_data_provider(inputFolderLocation, outputFolderLocation,listSections, timePeriod, distance)
            %% This function is to obtain the sensor data
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.temp;
            this.outputFolderLocation=findFolder.outputs;
            
            if(nargin>=1)
                this.inputFolderLocation=inputFolderLocation; % Get the input folder
            elseif(nargin>=2)
                this.outputFolderLocation=outputFolderLocation; % Get the output folder
            elseif(nargin>=3)
                this.listSections=listSections; % Get the list of sections
            elseif(nargin==4)
                this.timePeriod=timePeriod; % Get the time period
            elseif(nargin==5)
                this.distance=distance; % Get the distance
            elseif(nargin>5)
                error('Too many inputs!')
            end
        end
         
        function [data_out]=get_statistics_for_section_time(this, listOfSections, timePeriod, distance)
            % This function is to get data for given sections and time
            % period
            
            % Get all parameters
            if(isempty(listOfSections))
                error('No section list!')
            end
                 
            % Get the number of sections
            numOfSections=length(listOfSections);
            data_out=[];
            % First read the data file
            for i=1:numOfSections
                sectionID=char(listOfSections(i));
                
                % Load data file
                dataFile=fullfile(this.inputFolderLocation,sprintf('SimVeh_Section%s.mat',sectionID));
                if(exist(dataFile,'file'))
                    load(dataFile); % Inside: vehSectionAll
                    
                    if(~isempty(timePeriod))
                        startTime=timePeriod(1);
                        endTime=timePeriod(2);                        
                        idx=(vehSectionAll(:,1)>=startTime & vehSectionAll(:,1)<endTime);
                        tmp_data=vehSectionAll(idx,:);
                    else
                        tmp_data=vehSectionAll;
                    end
                    
                    if(isempty(tmp_data)) % Data for that day not found
                        data_out=[data_out;struct(...
                            'sectionID', sectionID,...
                            'startTime',startTime,...
                            'endTime',endTime,...
                            'data',nan,...
                            'proportionQueue',nan,...
                            'proportionLeft',nan,...
                            'proportionRight',nan,...
                            'turningLane',nan,...
                            'centriodLane',nan,...
                            'speed',nan,...
                            'speedLane',nan)];
                    else
                                                
                        proportionQueue=sum(tmp_data(:,end))/length(tmp_data(:,end)); % Get the proportion of stopped vehicles
                        
                        % Check turning proportions
                        idx=(tmp_data(:,7)<=distance);
                        turning_data=tmp_data(idx,:);
                        proportionLeft=sum(turning_data(:,11))/length(turning_data(:,11));
                        proportionRight=sum(turning_data(:,12))/length(turning_data(:,12));
                        
                        lanes=unique(tmp_data(:,6));
                        turningLane=[];                       
                        centriodLane=[];
                        for j=1:length(lanes)
                            turning_data_lane=turning_data(turning_data(:,6)==j,:);
                            turningLane=[turningLane; struct(...
                                'laneID',j,...
                                'turningLeft',sum(turning_data_lane(:,11))/length(turning_data_lane(:,11)),...
                                'turningRight',sum(turning_data_lane(:,12))/length(turning_data_lane(:,12)))];
                            
                            centriodLane=[centriodLane; struct(...
                                'laneID',j,...
                                'ODcentriods',turning_data_lane(:,9:10))];
                        end                        
                        
                        % Get average/median speed
                        speed.average=mean(tmp_data(:,8));
                        speed.median=median(tmp_data(:,8));
                        speed.all=tmp_data(:,8);
                        
                        % Get lane speeds                        
                        speedLane=[];
                        for j=1:length(lanes)
                            tmp_data_lane=tmp_data(tmp_data(:,6)==j,:);
                            speedLane=[speedLane; struct(...
                                'laneID',j,...
                                'average',mean(tmp_data_lane(:,8)),...
                                'median',median(tmp_data_lane(:,8)),...
                                'all',tmp_data_lane(:,8))];
                        end
                        
                        data_out=[data_out;struct(...
                            'sectionID', sectionID,...
                            'startTime',startTime,...
                            'endTime',endTime,...
                            'data',tmp_data,...
                            'proportionQueue',proportionQueue,...
                            'proportionLeft',proportionLeft,...
                            'proportionRight',proportionRight,...
                            'turningLane',turningLane,...
                            'centriodLane',centriodLane,...
                            'speed',speed,...
                            'speedLane',speedLane)];
                        
                    end
                else
                    disp(sprintf('Missing the data file for section ID:%s\n',(sectionID)));  
                    data_out=[data_out;struct(...
                            'sectionID', sectionID,...
                            'startTime',startTime,...
                            'endTime',endTime,...
                            'data',nan,...
                            'proportionQueue',nan,...
                            'proportionLeft',nan,...
                            'proportionRight',nan,...
                            'turningLane',nan,...
                            'centriodLane',nan,...
                            'speed',nan,...
                            'speedLane',nan)];
                end
            end            
        end
        
    end

end

