classdef initialization_in_aimsun_with_beats
    properties
        outputFolderLocation    % Location of the output folder
        
        networkData             % Data that contains the link properties of both Aimsun and beats links
        simVehDataProvider      % Data provider that contains the simulated vehicles in Aimsun
        simBeatsDataProvider    % Data provider that contains the simulation results from beats
        
        defaultParams
    end
    
    methods ( Access = public )
        
        function [this]=initialization_in_aimsun_with_beats(networkData,simVehDataProvider,simBeatsDataProvider,defaultParams,outputFolder)
            %% This function is to generate vehicles for the initialization of aimsun using beats results
            
            this.networkData=networkData; % Get the Beats network data
            this.simVehDataProvider=simVehDataProvider; % Data provider for Aimsun simulation
            this.defaultParams=defaultParams; % Get default parameters
            this.simBeatsDataProvider=simBeatsDataProvider; % Data provider for Beats simulation
            
            if(~isnan(outputFolder))
                this.outputFolderLocation=outputFolder;
            else
                this.outputFolderLocation=findFolder.BEATS_temp;
            end
        end
        
        function [vehList]=generate_vehicles_for_a_link(this,aimsunWithBeatsInitialization,queryMeasures,querySetting,t)
            %% This function is used to generate vehicles for a given aimsun link using beats simulation outputs
            
            vehList=[];
            
            aimsunLinkID=(aimsunWithBeatsInitialization.AimsunLinkID);
            beatsSimLinkIDs=[aimsunWithBeatsInitialization.BEATSLinks.SimLinkID]';
            distToEnd=aimsunWithBeatsInitialization.DistToEndByBeatsLinkByLane;
            linkLength=max(aimsunWithBeatsInitialization.LinkProperty.LaneLengths);
            
            aimsunVehData=initialization_in_aimsun_with_beats.get_vehicle_statistics_from_simulation...
                (aimsunLinkID,this.simVehDataProvider,querySetting,t);
            
            beatsLinkData=initialization_in_aimsun_with_beats.get_estimates_from_beats_simulation...
                (beatsSimLinkIDs,this.simBeatsDataProvider,queryMeasures);
            
            % Data availability check
            symbol=1;
            for i=1:size(beatsLinkData,1)
                if(strcmp(beatsLinkData(i).status,{'No Data'}))
                    fprintf('Not enough BEATS simulation data for the Aimsun link: %d\n',aimsunLinkID);
                    symbol=0;
                end
            end
            for i=1:size(aimsunVehData,1)
                if(isnan(aimsunVehData(i).data))
                    fprintf('Not enough Aimsun OD data for the Aimsun link: %d\n',aimsunLinkID);
                    symbol=0;
                end
            end
            
            % Start to generate vehicles            
            if(symbol==1)
                numLane=size(distToEnd,1);
                for i=1:numLane
                    % Look for OD information for the current lane
                    symbol=0;
                    aimsunLaneID=numLane-i+1;
                    for j=1:size(aimsunVehData.centroidLane)                        
                        if(aimsunVehData.centroidLane(j).laneID==aimsunLaneID)                            
                            ODcentroids=aimsunVehData.centroidLane(j).ODcentroids;
                            if(~isempty(ODcentroids)) % There may be no OD information for a certain link
                                symbol=1;
                            end
                            break;
                        end
                    end
                    
                    if(symbol==1) % If found
                        vehListByLane=initialization_in_aimsun_with_beats.generate_vehicles_by_lane...
                            (aimsunLinkID,distToEnd(i,:),linkLength,aimsunLaneID,1,0,ODcentroids,beatsLinkData,this.defaultParams);
                        vehList=[vehList;vehListByLane];
                    else
                        fprintf('No OD information for current lane %d on link %d\n',aimsunLaneID,aimsunLinkID);
                    end
                end
            end
            
        end
        
    end
    
    methods ( Static)
        function [vehListByLane]=generate_vehicles_by_lane(aimsunLinkID,distToEndByLane,linkLength,laneID,vehicleType,tracking,ODCentroids,beatsLinkData,parameters)
            %% This function is used to generate vehicle by lane
            
            % Section ID, laneID, vehicle type (default 1), orgin ID, destination ID,
            % position, speed, tracking (0/1)
            vehListByLane=[];
            
            numBeatsLinks=size(distToEndByLane,2);            
            
            for i=1:numBeatsLinks
                [avgDensityBeats,~,avgSpeedBeats,avgSpeedStdDevBeats]=...
                    initialization_in_aimsun_with_beats.get_averages(beatsLinkData(i));
                
                if(i==1)
                    distance=distToEndByLane(i);
                else
                    distance=distToEndByLane(i)-distToEndByLane(i-1);
                end
                
                numVeh=round(distance*0.3048*avgDensityBeats);
                numODCentroids=size(ODCentroids,1);
                
                if(numVeh>0) % If has vehicles
                    % Select the OD information
                    idx=randi(numODCentroids,numVeh,1);
                    ODSelected=ODCentroids(idx,:);
                    
                    % Combine with the section ID, lane ID, vehicle type
                    tmpVehListByLane=repmat([aimsunLinkID,laneID,vehicleType],numVeh,1);
                    tmpVehListByLane=[tmpVehListByLane,ODSelected(:,1:2)];
                    
                    % Get the current length
                    if(i==1)
                        curLength=linkLength;
                    else
                        curLength=linkLength-distToEndByLane(i-1);
                    end
                    
                    spacing=distance-numVeh*parameters.JamSpacing; % Get the spacing
                    if(spacing<0) % Too many vehicles inside the link? set it to be jammed
                        numVeh=floor(distance/parameters.JamSpacing); % Change the size
                        
                        % Selected position
                        position=zeros(numVeh,1);                        
                        for j=1:numVeh
                            position(j)=curLength-(j-0.5)*parameters.JamSpacing;
                        end
                        tmpVehListByLane=[tmpVehListByLane,position];
                        
                        %Select speed: jammed in this case
                        tmpVehListByLane=[tmpVehListByLane,zeros(numVeh,1)];    
                        
                        % Add tracking
                        tmpVehListByLane=[tmpVehListByLane,tracking*ones(numVeh,1)];   
                    else % Have enough space to assign vehicles
                        
                        % Selected position
                        vehSpacing=randn(numVeh,1)+spacing/numVeh; % Generate the spacing
                        vehSpacing(vehSpacing<0)=0; % Ignore the zero values
                        vehGap=vehSpacing./sum(vehSpacing)*spacing+parameters.JamSpacing; % Normalized and obtain the gap distance
                        
                        position=zeros(numVeh,1);
                        for j=1:numVeh
                            position(j)=curLength-vehGap(j)/2; % Get the middle point position
                            curLength=curLength-vehGap(j); % Update the current length
                        end
                        tmpVehListByLane=[tmpVehListByLane,position];
                        
                        %Select speed: jammed in this case
                        vehSpeed=2.23694*(avgSpeedStdDevBeats*randn(numVeh,1)+avgSpeedBeats); % Generate the speeds
                        vehSpeed(vehSpeed<0)=0; % Ignore the zero values
                        tmpVehListByLane=[tmpVehListByLane,vehSpeed];  
                        
                        % Add tracking
                        tmpVehListByLane=[tmpVehListByLane,tracking*ones(numVeh,1)]; 
                    end
                    
                    vehListByLane=[vehListByLane;tmpVehListByLane];
                end
            end            
        end
        
        function [avgDensityBeats,avgDensityStdDevBeats,avgSpeedBeats,avgSpeedStdDevBeats]=get_averages(beatsLinkDataByLink)
            %% This function is used to get the averages of density and speed
            
            avgDensityBeats=mean(beatsLinkDataByLink.data.DensityMean);
            avgSpeedBeats=mean(beatsLinkDataByLink.data.VelocityMean);
            
            avgDensityStdDevBeats=mean(beatsLinkDataByLink.data.DensityStdDev);
            avgSpeedStdDevBeats=mean(beatsLinkDataByLink.data.VelocityStdDev);
        end
        
        function [simDataBeats]=get_estimates_from_beats_simulation(listOfSections,simBeatsDataProvider,queryMeasures)
            %% This function is used to obtain the simulated results from BEATs
            
            simDataBeats=simBeatsDataProvider.clustering(listOfSections,queryMeasures);
        end
               
        function [statisticsSection]=get_vehicle_statistics_from_simulation(listOfSections,simVehDataProvider,querySetting,CurrentTime)
            %% This function is used to obtain the statistics on simulated vehicles for a given approach
            
            TimePeriod=[CurrentTime-querySetting.SearchTimeDuration CurrentTime]; % Define the searching time period
            Distance=querySetting.Distance; % Defined the searching distance to obtain turning proportions
            
            % Get the statistics of traffic for those sections
            statisticsSection=simVehDataProvider.get_statistics_for_section_time(listOfSections, TimePeriod, Distance);
        end
        
    end
end

