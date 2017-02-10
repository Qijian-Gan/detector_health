classdef simVehicle_data_provider 
    properties
        
        inputFolderLocation             % Folder that stores the vehicle trajectory file
        outputFolderLocation            % Folder that outputs the processed files
        
        listSections                 % List of sections
        timePeriod                   % Time period: [start_time, end_time] in seconds
        distance                     % Distance from the stopbar that is used to get the turning proportions of vehicles in this region
    end
    
    methods ( Access = public )

        function [this]=simVehicle_data_provider(inputFolderLocation, outputFolderLocation,listSections, timePeriod, distance)
            %% This function is to obtain the sensor data
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.temp_aimsun;
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
            
            %% Note: the lane IDs are ordered from rightmost to leftmost!!
            
            % Get all parameters
            if(isempty(listOfSections))
                error('No section list!')
            end
                 
            % Get the number of sections
            numOfSections=length(listOfSections);
            data_out=[];
            startTime=timePeriod(1);
            endTime=timePeriod(2);  
                        
            % First read the data file
            for i=1:numOfSections
                sectionID=(listOfSections(i));
                
                % Load data file
                dataFile=fullfile(this.inputFolderLocation,sprintf('SimVeh_Section_%d.mat',sectionID));
                if(exist(dataFile,'file'))
                    load(dataFile); % Inside: vehSectionAll
                    
                    if(~isempty(timePeriod)) % Time periods in seconds                                              
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
                            'queue',nan,...
                            'queueLane',nan,...
                            'turning',nan,...
                            'turningLane',nan,...
                            'centroidLane',nan,...
                            'centroidLaneByDownSection', nan,...
                            'speed',nan,...
                            'speedLane',nan)];
                    else
                          
                        lanes=sort(unique(tmp_data(:,6)));
                        
                        % Get the proportion of stopped vehicles
                        numInterval=length(unique(tmp_data(:,1)));
                        queue.proportion=sum(tmp_data(:,14))/length(tmp_data(:,14)); 
                        queue.avgNumVehicle=length(tmp_data(:,14))/numInterval;
                        queue.avgNumQueue=queue.proportion*queue.avgNumVehicle;
                             
                        queueLane=[];
                        for j=1:length(lanes)
                            data_lane=tmp_data(tmp_data(:,6)==lanes(j),:);
                            queueLane=[queueLane; struct(...
                                'laneID',lanes(j),...
                                'proportion',sum(data_lane(:,14))/length(data_lane(:,14)))];
                        end      
                        
                        % Check turning proportions: aggregated level
                        idx=(tmp_data(:,11)<=distance & tmp_data(:,end)>0);% Compared with the Distance2End and has a valid downstream section
                        turning_data=tmp_data(idx,:);
                        turning.Left=sum(turning_data(:,12))/length(turning_data(:,12));
                        turning.Right=sum(turning_data(:,13))/length(turning_data(:,13));
                       
                        % Get the lane information                        
                        turningLane=[];                       
                        centroidLane=[];
                        for j=1:length(lanes)
                            turning_data_lane=turning_data(turning_data(:,6)==lanes(j),:);
                            turningLane=[turningLane; struct(...
                                'laneID',lanes(j),...
                                'turningLeft',sum(turning_data_lane(:,12))/length(turning_data_lane(:,12)),...
                                'turningRight',sum(turning_data_lane(:,13))/length(turning_data_lane(:,13)))];
                            
                            centroidLane=[centroidLane; struct(...
                                'laneID',lanes(j),...
                                'ODcentroids',turning_data_lane(:,[9,10,15]))];
                        end
                        
                        % Get the centroid-lane information by downstream
                        % link
                        downSections=unique(turning_data(:,end));
                        numDownLinks=length(downSections);
                        centroidLaneByDownSection=[];
                        for j=1:numDownLinks
                            dataByDownSection=turning_data(turning_data(:,end)==downSections(j),:);
                            centroidLaneByDownSection=[centroidLaneByDownSection; struct(...
                                'downSectionID',downSections(j),...
                                'ODcentroidAndLane',dataByDownSection(:,[6,9,10]))];
                        end
                        
                        % Get average/median speed
                        speed.average=mean(tmp_data(:,8));
                        speed.median=median(tmp_data(:,8));
                        speed.all=tmp_data(:,8);
                        
                        % Get lane speeds                        
                        speedLane=[];
                        for j=1:length(lanes)
                            tmp_data_lane=tmp_data(tmp_data(:,6)==lanes(j),:);
                            speedLane=[speedLane; struct(...
                                'laneID',lanes(j),...
                                'average',mean(tmp_data_lane(:,8)),...
                                'median',median(tmp_data_lane(:,8)),...
                                'all',tmp_data_lane(:,8))];
                        end
                        
                        data_out=[data_out;struct(...
                            'sectionID', sectionID,...
                            'startTime',startTime,...
                            'endTime',endTime,...
                            'data',tmp_data,...
                            'queue',queue,...
                            'queueLane',queueLane,...
                            'turning',turning,...
                            'turningLane',turningLane,...
                            'centroidLane',centroidLane,...
                            'centroidLaneByDownSection',centroidLaneByDownSection,...
                            'speed',speed,...
                            'speedLane',speedLane)];
                        
                    end
                else
                    fprintf('Missing the data file for section ID:%d\n',sectionID);  
                    data_out=[data_out;struct(...
                            'sectionID', sectionID,...
                            'startTime',startTime,...
                            'endTime',endTime,...
                            'data',nan,...
                            'queue',nan,...
                            'queueLane',nan,...
                            'turning',nan,...
                            'turningLane',nan,...
                            'centroidLane',nan,...
                            'centroidLaneByDownSection',nan,...
                            'speed',nan,...
                            'speedLane',nan)];
                end
            end            
        end
        
    end

end

