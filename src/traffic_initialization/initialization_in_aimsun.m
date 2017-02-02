classdef initialization_in_aimsun
    properties
        outputFolderLocation    % Location of the output folder
        
        networkData             % Data that contains both junction and section information (reconstructed)
        estStateQueue           % Data that contains the estimated traffic states and queues
        simVehDataProvider      % Data provider that contains the simulated vehicles
        simSigDataProvider      % Data provider that contains the signal plans in simulation
        fieldSigDataProvider    % Data Provider that contains the signal plans in the field
        
        defaultParams
    end
    
    methods ( Access = public )
        
        function [this]=initialization_in_aimsun(networkData,estStateQueue,simVehDataProvider,simSigDataProvider,fieldSigDataProvider,defaultParams,outputFolder)
            %% This function is to generate vehicles for the initialization of aimsun
            
            this.networkData=networkData;
            this.estStateQueue=estStateQueue;
            this.simVehDataProvider=simVehDataProvider;
            this.simSigDataProvider=simSigDataProvider;
            this.defaultParams=defaultParams;
            this.fieldSigDataProvider=fieldSigDataProvider;
            
            if(~isnan(outputFolder))
                this.outputFolderLocation=outputFolder;
            else
                this.outputFolderLocation=findFolder.temp_aimsun;
            end
        end
        
        function [vehicleList]=generate_vehicle(this,querySetting)
            %% Main function: generate vehicles
            
            vehicleList=[]; % Return the list of vehicles that will be injected into Aimsun simulation
            
            % Get the current time: This is the time to initialize the
            % Aimsun simulation
            CurrentTime=this.estStateQueue(1).Time;
            
            % Get the number of approaches of the whole network
            numApproach=size(this.networkData,1);
            
            % Use junction-Section ID for searching: In aimsun, there is no
            % information to indicate EB, WB, NB, and SB unless using
            % External IDs
            junctionSectionAll=[[this.networkData.JunctionID]',[this.networkData.FirstSectionID]'];
            
            % Get the approaches with field estimates available
            junctionSectionWithData=[[this.estStateQueue.JunctionID]',[this.estStateQueue.SectionID]'];
            
            for i=1: numApproach % Loop for each approach
                junctionSectionID=junctionSectionAll(i,:); % Get the junction-section ID
                junctionSectionInf=this.networkData(i,:); % Get the junction-section Information
                
                [idx,loc]=ismember(junctionSectionID,junctionSectionWithData,'rows'); % Check whether field estimates are available or not
                
                % Get the statistics of the sections of that approach
                [statisticsSection]=initialization_in_aimsun.get_vehicle_statistics_from_simulation...
                    (junctionSectionInf,this.simVehDataProvider,querySetting,CurrentTime);
                
                if(sum(idx)&& ~isempty(this.estStateQueue(loc).Status)) 
                    % If the estimated traffic states and queues are available, use our proposed method
                    
                    % Get the estimated traffic states and queues
                    estStateQueueApproach=this.estStateQueue(ismember(junctionSectionWithData,junctionSectionID,'rows'),:);
                    
                    % Update the number of vehicles according to the
                    % estimated traffic states, queues, singla phasing, and
                    % current time
                    estStateQueueApproachUpdate=initialization_in_aimsun.update_vehicles_according_to_phase_currentTime...
                        (this.fieldSigDataProvider,this.simSigDataProvider,CurrentTime,estStateQueueApproach,...
                        junctionSectionInf,this.defaultParams);
                    
                    % Generate vehicle with field estimation
                    tmpVehicleList=initialization_in_aimsun.generate_vehicle_with_fieldEstimation...
                        (junctionSectionInf,estStateQueueApproachUpdate,statisticsSection,this.defaultParams);
                else
                    % If the estimated traffic states and queues are not available, use the simulated results
                    data=[];                    
                    for j=1:size(statisticsSection,1)
                        if(~isnan(statisticsSection(j).data))
                            data=[data;statisticsSection(j).data];
                        end                         
                    end
                    
                    if (isempty(data))
                        tmpVehicleList=[];
                    else
                        tmpVehicleList=initialization_in_aimsun.generate_vehicle_without_fieldEstimation...
                            (junctionSectionInf,data,CurrentTime);
                    end
                end
                
                vehicleList=[vehicleList;tmpVehicleList];
            end
        end
        
        function [phaseListTable,phaseListAimsun]=determine_phases(this,type)
            % This function is used to determine the active phases and how
            % long they have been activated
            
            currentTimeStamp=this.estStateQueue(1).Time; % Get the current time
            
            % Load the control plans
            switch type.ControlPlanSource
                case 'FieldInAimsun'
                    controlPlans=this.fieldSigDataProvider.activeControlPlans;      
                otherwise
                    error('Unrecognized source of active control plans!')
            end
            
            numOfPlans=size(controlPlans,1);
            
            % Loop for each control plane --junction
            phaseList=[];            
            for i=1:numOfPlans
                controlPlanStartTime=controlPlans(i).PlanOffset;                
                coordination=controlPlans(i).Coordination;
                numRings=controlPlans(i).NumRings;
                
                % Get the phase properties
                phases=controlPlans(i).Phases;
                phaseRingAll=[phases.RingID]';
                starttimePhaseAll=[phases.StartTime]';
                durationPhaseAll=[phases.Duration]';
                endtimePhaseAll=durationPhaseAll+starttimePhaseAll;
                phaseInRingID=(1:size(phases,1));
                phaseIDAll=[phases.PhaseID]';
                
                switch type.LastCycleInformation
                    case 'None' % Don't use the last cycle information to determine the current phases
                        
                        % Check the junction is coordinated or not
                        isCoordinated=0;
                        for j=1:size(coordination,1)
                            if(coordination(j).PhaseID>0)
                                isCoordinated=1;
                                break;
                            end
                        end
                        
                        
                        if isCoordinated==0 % Not coordinated? No need to use the phase offset
                            timeControlPlanIsActivated=controlPlanStartTime;
                            timeControlPlanHasActivated=currentTimeStamp-timeControlPlanIsActivated;
                            if(timeControlPlanHasActivated<0)
                                timeControlPlanIsActivated=timeControlPlanIsActivated-controlPlans(i).Cycle;
                                timeControlPlanHasActivated=timeControlPlanHasActivated+controlPlans(i).Cycle;
                            end
                            
                            restTime=mod(timeControlPlanHasActivated,controlPlans(i).Cycle);                            
                            timeEndOfLastCycle=currentTimeStamp-restTime;
                            
                            % Determine the active phase in each ring                            
                            for j=1:numRings
                                ringID=j; % Ring ID
                                idx=(phaseRingAll==j &...
                                    (starttimePhaseAll<=restTime & endtimePhaseAll>restTime));                                
                                phaseIDInAimsun=[phases(idx).PhaseID];
                                phaseIDInCycle=phaseInRingID(idx);
                                durationActivated=(currentTimeStamp-timeEndOfLastCycle-starttimePhaseAll(idx));
                                
                                
                                for k=1:length(phaseIDInCycle)
                                    phaseList=[phaseList, struct(...
                                        'JunctionID',controlPlans(i).JunctionID,...
                                        'PlanIDInAimsun',controlPlans(i).PlanID,...
                                        'ControlType', controlPlans(i).ControlType,...
                                        'CycleLength',controlPlans(i).Cycle,...
                                        'Coordinated',isCoordinated,...
                                        'RingID',ringID,...
                                        'PhaseIDInAimsun',phaseIDInAimsun(k),...
                                        'PhaseIDInCycle',phaseIDInCycle(k),...
                                        'DurationActivated',durationActivated(k))];
                                end
                            end
                            
                        else
                            % Get the time elapse
                            for j=1:size(coordination,1)
                                if(coordination(j).PhaseID>0)
                                    phaseOffSet=coordination(j).PhaseOffset;
                                    phaseID=coordination(j).PhaseID;
                                    fromEndOfPhase=coordination(j).FromEndOfPhase;
                                    break;
                                end
                            end
                            
                            coordinatedPhase=phases(phaseIDAll==phaseID,:);
                            startTimePhase=coordinatedPhase.StartTime;
                            durationPhase=coordinatedPhase.Duration;
                            if(fromEndOfPhase==1)
                                timeElapse=startTimePhase+durationPhase;
                            else
                                timeElapse=startTimePhase;
                            end
                            
                            timeControlPlanIsActivated=controlPlanStartTime-(timeElapse-phaseOffSet);
                            timeControlPlanHasActivated=currentTimeStamp-timeControlPlanIsActivated;
                            if(timeControlPlanHasActivated<0)
                                timeControlPlanIsActivated=timeControlPlanIsActivated-controlPlans(i).Cycle;
                                timeControlPlanHasActivated=timeControlPlanHasActivated+controlPlans(i).Cycle;
                            end
                            
                            restTime=mod(timeControlPlanHasActivated,controlPlans(i).Cycle);                            
                            timeEndOfLastCycle=currentTimeStamp-restTime;
                            
                            % Determine the active phase in each ring                            
                            for j=1:numRings
                                ringID=j; % Ring ID
                                idx=(phaseRingAll==j &...
                                    (starttimePhaseAll<=restTime & endtimePhaseAll>restTime));                                
                                phaseIDInAimsun=[phases(idx).PhaseID];
                                phaseIDInCycle=phaseInRingID(idx);
                                durationActivated=(currentTimeStamp-timeEndOfLastCycle-starttimePhaseAll(idx));
                                
                                for k=1:length(phaseIDInCycle)
                                    phaseList=[phaseList, struct(...
                                        'JunctionID',controlPlans(i).JunctionID,...
                                        'PlanIDInAimsun',controlPlans(i).PlanID,...
                                        'ControlType', controlPlans(i).ControlType,...
                                        'CycleLength',controlPlans(i).Cycle,...
                                        'Coordinated',isCoordinated,...
                                        'RingID',ringID,...
                                        'PhaseIDInAimsun',phaseIDInAimsun(k),...
                                        'PhaseIDInCycle',phaseIDInCycle(k),...
                                        'DurationActivated',durationActivated(k))];
                                end
                            end
                        end

                    otherwise
                        error('Can not find the method to determine the last cycle information')
                end
                
            end
            
            phaseListTable=[];
            phaseListAimsun=[];
            if(~isempty(phaseList))
                phaseListTable=[num2cell([phaseList.JunctionID]'),num2cell([phaseList.PlanIDInAimsun]'),{phaseList.ControlType}',...
                    num2cell([phaseList.CycleLength]'),num2cell([phaseList.Coordinated]'),num2cell([phaseList.RingID]'),...
                    num2cell([phaseList.PhaseIDInAimsun]'),num2cell([phaseList.PhaseIDInCycle]'),num2cell([phaseList.DurationActivated]')];
          
                phaseListAimsun=[[phaseList.JunctionID]',[phaseList.PhaseIDInCycle]',[phaseList.DurationActivated]'];
            end
            
        end
    end
    
    methods ( Static)
        
        function [estStateQueueApproachUpdate]=update_vehicles_according_to_phase_currentTime...
                (fieldSigDataProvider,simSigDataProvider,currentTime,estStateQueueApproach,junctionSectionInf,defaultParams)
            %% This function is used to update the number of vehicles accoridng to the average queue
            %% and the information of phasing and current time
            
            estStateQueueApproachUpdate=estStateQueueApproach;
            
            if(isempty(fieldSigDataProvider) && isempty(simSigDataProvider))
                % If both fieldSigDataProvider and simSigDataProvider are not available
                % Used some naive methods: 50-50 percent
                estStateQueueApproach.Queue(estStateQueueApproach.Queue<0)=0;
                estStateQueueApproachUpdate.CurrentQueue=round(estStateQueueApproach.Queue*0.5);
                estStateQueueApproachUpdate.CurrentMoving=round(estStateQueueApproach.Queue*0.5);
            else
                % Movements are organized from left to right
                if(~isempty(fieldSigDataProvider))
                    % Use fieldSigDataProvider if it exists
                    % Currently  there is no field signal data!!
                    phaseForApproach=fieldSigDataProvider.get_signal_phasing_for_junction_time(junctionSectionInf, currentTime);
                else
                    % Else, use simSigDataProvider
                    phaseForApproach=simSigDataProvider.get_signal_phasing_for_junction_time(junctionSectionInf, currentTime);
                end
                
                % Initialization
                estStateQueueApproach.Queue(estStateQueueApproach.Queue<0)=0;
                estStateQueueApproachUpdate.CurrentQueue=zeros(size(estStateQueueApproach.Queue));
                estStateQueueApproachUpdate.CurrentMoving=zeros(size(estStateQueueApproach.Queue));
                
                for i=1:length(estStateQueueApproach.Queue) % Loop for each queue/movement
                    if(estStateQueueApproach.Queue(i)>0) % If the current movement has an average queue
                        avgQueue=estStateQueueApproach.Queue(i);
                        signalByMovement=phaseForApproach.SignalByMovement(i);
                        headway=defaultParams.Headway;
                        
                        % Get the maximum and minimum numbers of queued
                        % vehicles
                        [maxNumVeh,minNumVeh,~]=initialization_in_aimsun.determine_max_min_vehicles...
                            (avgQueue,signalByMovement,headway);
                        
                        % Assign the number of moving and queued vehicles
                        % according to the signal settings
                        [numVehQueue,numVehMoving]=initialization_in_aimsun.determine_queue_and_moving_vehicles...
                            (maxNumVeh,minNumVeh,signalByMovement);
                        
                        estStateQueueApproachUpdate.CurrentQueue(i)=numVehQueue;
                        estStateQueueApproachUpdate.CurrentMoving(i)=numVehMoving;
                    end
                end
            end
            
        end
        
        function [numVehQueue,numVehMoving]=determine_queue_and_moving_vehicles...
                (maxNumVeh,minNumVeh,signalByMovement)
            %% This function is used to determine the numbers of moving and queued vehicles
            
            % Here we consider the number of vehicles inside this approach
            % is the maxNumVeh. We try to determine the proportions of
            % queued and moving vehicles based on the signal input
            
            % Get all the signal information
            greenTime=signalByMovement.GreenTime;
            redTime=signalByMovement.RedTime;
            currentStatus=signalByMovement.CurrentStatus;
            durationSinceActivated=signalByMovement.DurationSinceActivated;
            
            switch currentStatus % Check current status
                case 'Green' % If it is green
                    if(durationSinceActivated>greenTime)
                        error('Incorrect signal settings: durationSinceActivated > greenTime! ')
                    else
                        proportion=durationSinceActivated/greenTime;   % Know the time elapse during the green phase
                        numVehMoving=ceil((maxNumVeh-minNumVeh)*proportion); % Assign the number of moving vehicles
                        numVehQueue=max(0,maxNumVeh-numVehMoving); % Assign the number of queued vehicles
                    end
                case 'Red'
                    if(durationSinceActivated>redTime) % If it is red
                        error('Incorrect signal settings: durationSinceActivated > redTime! ')
                    else
                        proportion=durationSinceActivated/redTime;  % Know the time elapse during the red phase
                        numVehQueue=minNumVeh+ceil((maxNumVeh-minNumVeh)*proportion); % Assign the number of queued vehicles
                        numVehMoving=max(0,maxNumVeh-numVehQueue); % Assign the number of moving vehicles
                    end
            end
        end
        
        function [maxNumVeh,minNumVeh,GreenTimeUsed]=determine_max_min_vehicles(avgQueue,signal,headway)
            %% This function is used to determine the maximun and the minimum numbers of vehicles
            
            greenTime=signal.GreenTime; % Get the green time
            
            numVehByGreen=ceil(greenTime/headway); % Get the number of vehicles that can pass through the green time
            
            % Get the minimum number of vehicles
            if(numVehByGreen/2<avgQueue) % If the green time is not enough to clear all queued vehicles
                minNumVeh=ceil((avgQueue*2-numVehByGreen)/2); % Residual queue
                GreenTimeUsed=greenTime;    % Green time is fully used
            else
                minNumVeh=0;    % No residual queue
                GreenTimeUsed=ceil(avgQueue*2*headway); % Green time is not fully used
            end
            
            % Get the maximum number of vehicles
            maxNumVeh=min(numVehByGreen+minNumVeh,avgQueue*2);
            
        end
        
        function [tmpVehicleList]=generate_vehicle_with_fieldEstimation(junctionSectionInf,estStateQueueApproachUpdate,staticsSection,defaultParams)
            %% This function is used to generate vehicles for the approach
            %% with estimated states and queues from the field
            
            JunctionID=junctionSectionInf.JunctionID;
            SectionID=junctionSectionInf.FirstSectionID;
            
            
            if(isnan(staticsSection(1).data)) % If no simulation data
                fprintf('Warning: Lacking OD Information from simulations for Junction: %d--Section %d in the given time period!\n',JunctionID,SectionID);
                tmpVehicleList=[];
                % Not enough information, e.g., OD information, and thus return []
            else
                % Currently not used, but MAY be used the lane blockage information in the future
                avgStatus=estStateQueueApproachUpdate.Status;
                
                if(isempty(avgStatus)) % If no information is available
                    fprintf('Warning: Lacking status and queue Information from simulations for Junction: %d--Section %d in the given time period!\n',JunctionID,SectionID);
                    tmpVehicleList=[];
                else
                    % Get the numbers of queued and moving vehicles
                    CurrentQueue=estStateQueueApproachUpdate.CurrentQueue;
                    CurrentMoving=estStateQueueApproachUpdate.CurrentMoving;
                    
                    % First: assign vehicles with OD and lane
                    [vehQueueWithODAndLaneInitial]=initialization_in_aimsun.assign_vehicle_with_OD_and_Lane(junctionSectionInf,staticsSection,CurrentQueue);
                    [vehMovingWithODAndLaneInitial]=initialization_in_aimsun.assign_vehicle_with_OD_and_Lane(junctionSectionInf,staticsSection,CurrentMoving);
                    
                    % Second: assign vehicles to the corresponding links
                    status=0; % To see whether all vehicles are assigned or not
                    for i=1:5 % Threshold: is used to bound the gap for moving vehicles [jam_spacing, jam_spacing*threshold]
                        tmpVehicleList=[];
                        vehQueueWithODAndLane=vehQueueWithODAndLaneInitial;
                        vehMovingWithODAndLane=vehMovingWithODAndLaneInitial;
                        
                        threshold=3-(i-1)*0.5;
                        ListOfSections=junctionSectionInf.SectionBelongToApproach.ListOfSections; % Get the list of sections
                        numSections=length(ListOfSections);
                        for sectionAdd=1:numSections % Loop for sections from downstream to upstream
                            [tmpVehicleListBySection,restVehQueueWithODAndLane,restVehMovingWithODAndLane]=...
                                initialization_in_aimsun.assign_vehicle_to_one_section(avgStatus,vehQueueWithODAndLane,...
                                vehMovingWithODAndLane,junctionSectionInf,staticsSection,defaultParams,sectionAdd,threshold);
                            
                            tmpVehicleList=[tmpVehicleList;tmpVehicleListBySection];
                            
                            if(isempty(restVehQueueWithODAndLane)&& isempty(restVehMovingWithODAndLane)) % If all vehicles are assigned
                                status=1; % Set the status to be one and break
                                break;
                            else % If not, try to assign the rest of vehicles to the upstream links
                                vehQueueWithODAndLane=restVehQueueWithODAndLane;
                                vehMovingWithODAndLane=restVehMovingWithODAndLane;
                            end
                        end
                        
                        if(status==1) % After looping for all sections, check the status
                            break; % If all vehicles are assigned, break; else, reduce the threshold and try again
                        end
                    end
                    
                    if(status==0) % After trying all thresholds, if we still have unassigned vehicles, display the warning!
                        sprintf('Warning: There are still vehicles unassigned for Intersection: %d --Section: %d\n', JunctionID, SectionID);
                    end
                end
            end
        end
        
        function [vehWithODAndLane]=assign_vehicle_with_OD_and_Lane(junctionSectionInf,staticsSection,CurrentVehNum)
            
            % Get the junction--section ID
            JunctionID=junctionSectionInf.JunctionID;
            SectionID=junctionSectionInf.FirstSectionID;
            
            vehWithODAndLane=[];
            
            Turns=junctionSectionInf.TurningBelongToApproach.TurningsAtFirstSectionFromLeftToRight;
            TurningProperty=junctionSectionInf.TurningBelongToApproach.TurningProperty;
            numTurns=length(Turns);
            
            centroidLaneByDownSection=staticsSection(1).centroidLaneByDownSection;
            downSections=[centroidLaneByDownSection.downSectionID]';
            for i=1:numTurns % Loop for each turn
                TurnID=Turns(i); % Get the turn ID
                nextSectionByTurn=TurningProperty(i).DestSectionID; % Get the downstream section ID of that turn
                [~,idx]=ismember(nextSectionByTurn,downSections);
                
                if(sum(idx))
                    ODcentroidAndLane=centroidLaneByDownSection(idx).ODcentroidAndLane;
                    totODcentroidAndLane=size(ODcentroidAndLane,1);
                    numVehByTurn=CurrentVehNum(i);
                    
                    if(numVehByTurn<totODcentroidAndLane)
                        idx=randsample(totODcentroidAndLane,numVehByTurn);
                        ODcentroidAndLaneSelected=ODcentroidAndLane(idx,:);
                    else
                        idx=randsample(totODcentroidAndLane,numVehByTurn,'true'); % With replacement
                        ODcentroidAndLaneSelected=ODcentroidAndLane(idx,:);
                    end
                    
                    % The last column is the turn ID, which will be used
                    % later in assigning vhicles to other lanes if their
                    % dedicated lanes are full
                    vehWithODAndLane=[vehWithODAndLane;[SectionID*ones(size(ODcentroidAndLaneSelected,1),1), ODcentroidAndLaneSelected(:,1),...
                        1*ones(size(ODcentroidAndLaneSelected,1),1), ODcentroidAndLaneSelected(:,2:end)],TurnID*ones(size(ODcentroidAndLaneSelected,1),1)];
                else
                    fprintf('No OD data available for Junction: %d--Section: %d--Turn ID: %d in the given time period!\n',JunctionID,SectionID,TurnID);
                end
                
            end
            
        end
        
        function [tmpVehicleList,vehQueueWithODAndLane,vehMovingWithODAndLane]=...
                assign_vehicle_to_one_section(avgStatus,vehQueueWithODAndLane,...
                vehMovingWithODAndLane,junctionSectionInf,staticsSection,defaultParams,sectionAdd,threshold)
            %% This function is used to generate vehicles on one section belong to a given approach
            
            tmpVehicleList=[];
            
            % If it is not the first section, we need to re-assign the
            % lanes to the vehicles
            if(sectionAdd>1)
                [vehQueueWithODAndLane]=initialization_in_aimsun.reassign_turns_and_lanes(junctionSectionInf,sectionAdd,vehQueueWithODAndLane);
                [vehMovingWithODAndLane]=initialization_in_aimsun.reassign_turns_and_lanes(junctionSectionInf,sectionAdd,vehMovingWithODAndLane);
            end
            
            % Lanes ordered from left to right: ID from N, N-1, ..., 1
            numLanes=junctionSectionInf.SectionBelongToApproach.Property(sectionAdd).NumLanes;
            laneLengths=junctionSectionInf.SectionBelongToApproach.Property(sectionAdd).LaneLengths;
            rearBoundaryByLane=[(numLanes:-1:1)',laneLengths,zeros(numLanes,1)];
            
            %*********Step 1: Assign positions and speeds for queued vehicles if
            % exist
            [tmpVehicleList,vehQueueWithODAndLane,rearBoundaryByLane]=initialization_in_aimsun.assign_vehicles...
                (tmpVehicleList,rearBoundaryByLane,'Queued',vehQueueWithODAndLane,numLanes,defaultParams,sectionAdd,junctionSectionInf,staticsSection,threshold);
            
            %++++++++++++++++Step 2: Assign positions and speeds for moving
            %vehicles if there is enough space
            [tmpVehicleList,vehMovingWithODAndLane,rearBoundaryByLane]=initialization_in_aimsun.assign_vehicles...
                (tmpVehicleList,rearBoundaryByLane,'Moving',vehMovingWithODAndLane,numLanes,defaultParams,sectionAdd,junctionSectionInf,staticsSection,threshold);
            
        end
        
        function [tmpVehicleList,vehWithODAndLane,rearBoundaryByLane]=assign_vehicles...
                (tmpVehicleList,rearBoundaryByLane,type,vehWithODAndLane,numLanes,defaultParams,sectionAdd,junctionSectionInf,staticsSection,threshold)
            %% This function is used to assign vehicles (either queued or moving) according to their predefined lanes and the road geometry
            
            % Get the speed information within the given section: sectionAdd
            speedInf=staticsSection(sectionAdd).speedLane;
            lanesBySpeed=[speedInf.laneID]';
            
            if(~isempty(vehWithODAndLane)) % If it is not empty
                %*********First: assign vehicles according to their predefined lanes*****
                for i=1:numLanes % Loop for each lane
                    laneID=rearBoundaryByLane(i,1);
                    
                    % Get the speed information for a given lane
                    [~,idx]=ismember(laneID,lanesBySpeed);
                    if(sum(idx)) % If found
                        speeds=speedInf(idx).all;
                        speeds=sort(speeds(speeds>0)); % Get the non-zero speeds
                    else % If not found
                        speeds=[];
                    end
                    clear idx
                    
                    % Selected by lane
                    tmpSelectedVehicleByLane=vehWithODAndLane(vehWithODAndLane(:,2)==laneID,:);
                    
                    % Reorganized randomly
                    idx=randperm(size(tmpSelectedVehicleByLane,1));
                    selectedVehicleByLane=tmpSelectedVehicleByLane(idx,:);
                    clear idx
                    
                    % Assign vehicles one by one
                    for j=1:size(selectedVehicleByLane,1)
                        % Get a valid speed
                        [spacing,speed]=initialization_in_aimsun.get_a_speed(type,defaultParams,threshold,speeds);
                        
                        if(rearBoundaryByLane(i,2)<=rearBoundaryByLane(i,3)+spacing) % Reach the upstream boundary of the section
                            break; % Exit
                        else % Else, have enough space
                            tmpVehicleList=[tmpVehicleList;[selectedVehicleByLane(j,1:end-1),...
                                max(rearBoundaryByLane(:,2))-rearBoundaryByLane(i,3)-spacing/2,speed,0]]; % Vehicle is not tracked
                            rearBoundaryByLane(i,3)=rearBoundaryByLane(i,3)+spacing;
                            
                            % Clear the vehicle that has been assigned with position and speed
                            [~,idx]=ismember(selectedVehicleByLane(j,:),vehWithODAndLane,'rows');
                            vehWithODAndLane(idx,:)=[];
                            clear idx
                        end
                    end
                end
                
                %*********Second: Lane-level assignemnt for remaining vehicles (Remain in the same turn ID)*****
                if(~isempty(vehWithODAndLane))
                    % If not empty, try to assign them to other lanes belonging to the same turning ID
                    
                    turnIDRemaining=unique(vehWithODAndLane(:,end)); % Get the remaining turn IDs
                    
                    for i=1:length(turnIDRemaining) % Loop for each remaining turn ID
                        turnID=turnIDRemaining(i);  % Get the turn ID
                        
                        % Get the lane IDs belonging to that turn ID
                        LaneTurningProperty=junctionSectionInf.LaneTurningProperty(sectionAdd).Lanes;
                        laneIDsByTurn=[];
                        for j=1:size(LaneTurningProperty,1)
                            for k=1:length(LaneTurningProperty(j).TurnMovements) %There may be multiple turns within one lane
                                if(LaneTurningProperty(j).TurnMovements(k)==turnID)
                                    laneIDsByTurn=[laneIDsByTurn,LaneTurningProperty(j).LaneID];
                                end
                            end
                        end
                        
                        % Select the vehicles belonging to that turn ID
                        vehWithODAndLaneByTurn=vehWithODAndLane(vehWithODAndLane(:,end)==turnID,:);
                        
                        % Re-assign lanes to these vehicles
                        j=1; % Initialization
                        succeed=1;  % Use this variable to identify whether there is still space to assign vehicles
                        while (succeed)
                            succeed=0; % Set it to be zero
                            for k=1:length(laneIDsByTurn) % Loop for each lane ID belonging to that turn ID
                                laneID=laneIDsByTurn(k);
                                
                                % Get the speed information for a given lane
                                [~,idx]=ismember(laneID,lanesBySpeed);
                                if(sum(idx))
                                    speeds=speedInf(idx).all;
                                    speeds=sort(speeds(speeds>0));
                                else
                                    speeds=[];
                                end
                                clear idx
                                
                                % Still have space in other lanes and
                                % vehicles
                                [spacing,speed]=initialization_in_aimsun.get_a_speed(type,defaultParams,threshold,speeds);
                                idx=(rearBoundaryByLane(:,1)==laneID);
                                if(j<=size(vehWithODAndLaneByTurn,1) && ...
                                        rearBoundaryByLane(idx,2)>rearBoundaryByLane(idx,3)+spacing)
                                    tmpVehicleList=[tmpVehicleList;...
                                        [vehWithODAndLaneByTurn(j,1),laneID,vehWithODAndLaneByTurn(j,3:end-1),...
                                        max(rearBoundaryByLane(:,2))-rearBoundaryByLane(idx,3)-spacing/2,speed,0]]; % Re-assigned the lane ID
                                    rearBoundaryByLane(idx,3)=rearBoundaryByLane(idx,3)+spacing;
                                    
                                    % Clear the vehicle that has been assigned with position and speed
                                    clear idx
                                    [~,idx]=ismember(vehWithODAndLaneByTurn(j,:),vehWithODAndLane,'rows');
                                    vehWithODAndLane(idx,:)=[];
                                    j=j+1;
                                    succeed=1;
                                end
                            end
                        end
                    end
                end
                
                %*********Third: Turn-level assignment for remaining queued vehicles*****
                if(~isempty(vehWithODAndLane))
                    % If still not empty, try to assign them to adjacent lanes belonging
                    % to other turning ID
                    
                    turnIDRemaining=unique(vehWithODAndLane(:,end)); % Get the remaining turn IDs
                    
                    % Get the available adjacent lanes for the remaining
                    % turning movements
                    turnWithAdjacentLane=[];
                    for i=1:length(turnIDRemaining)
                        turnID=turnIDRemaining(i);
                        
                        if(sectionAdd==1)
                            TurningBelongToApproachBySection.TurningFromLeftToRight=...
                                junctionSectionInf.TurningBelongToApproach.TurningsAtFirstSectionFromLeftToRight;
                            TurningBelongToApproachBySection.TurningProperty=...
                                junctionSectionInf.TurningBelongToApproach.TurningProperty;
                        else
                            tmpTurning=junctionSectionInf.SectionBelongToApproach.Property(sectionAdd).DownstreamJunction.Turnings;
                            tmpTurningInf=tmpTurning.TurningInf;
                            tmpTurningIDs=[tmpTurningInf.TurnID]';
                            
                            TurningBelongToApproachBySection.TurningFromLeftToRight=tmpTurningIDs;
                            TurningBelongToApproachBySection.TurningProperty=[];
                            for j=1:size(TurningBelongToApproachBySection.TurningFromLeftToRight,1)
                                turnID=TurningBelongToApproachBySection.TurningFromLeftToRight(j);
                                
                                idx=(tmpTurningIDs==turnID);
                                TurningBelongToApproachBySection.TurningProperty=[TurningBelongToApproachBySection.TurningProperty;...
                                    tmpTurningInf(idx,:)];
                            end
                        end
                        [adjacentLaneID]=initialization_in_aimsun.find_available_adjacent_lane...
                            (TurningBelongToApproachBySection,rearBoundaryByLane,turnID);
                        
                        if(~isempty(adjacentLaneID)) % If has available lanes
                            for j=1:length(adjacentLaneID)
                                turnWithAdjacentLane=[turnWithAdjacentLane;[turnID,adjacentLaneID(j)]];
                            end
                        end
                    end
                    
                    % In the following, we want to assign one vehicle to
                    % each turn-lane pair for each time, which considers
                    % each turn-lane pair has the same priority
                    succeed=1;
                    while(succeed) % Check whether there exists at least one assignment for each interation of "for" loop
                        succeed=0;
                        for i=1:size(turnWithAdjacentLane,1) % Loop for each turn-lane pair
                            idx=(vehWithODAndLane(:,end)==turnWithAdjacentLane(i,1));
                            vehWithODAndLaneByTurn=vehWithODAndLane(idx,:); % Get the corresponding set of vehicles
                            clear idx
                            
                            if(~isempty(vehWithODAndLaneByTurn)) % If it is not empty
                                laneID=turnWithAdjacentLane(i,2); % Get the lane information
                                % Get the speed information for a given lane
                                [~,idx]=ismember(laneID,lanesBySpeed);
                                if(sum(idx))
                                    speeds=speedInf(idx).all;
                                    speeds=sort(speeds(speeds>0));
                                else
                                    speeds=[];
                                end
                                clear idx
                                
                                idx=(rearBoundaryByLane(:,1)==laneID);
                                [spacing,speed]=initialization_in_aimsun.get_a_speed(type,defaultParams,threshold,speeds);
                                if(rearBoundaryByLane(idx,2)>rearBoundaryByLane(idx,3)+spacing) % Has space to assign a vehicle
                                    tmpVehicleList=[tmpVehicleList;...
                                        [vehWithODAndLaneByTurn(1,1),turnWithAdjacentLane(i,2),vehWithODAndLaneByTurn(1,3:end-1),...
                                        max(rearBoundaryByLane(:,2))-rearBoundaryByLane(idx,3)-spacing/2,speed,0]]; % Re-assigned the lane ID for the first vehicle
                                    rearBoundaryByLane(idx,3)=rearBoundaryByLane(idx,3)+spacing;
                                    clear idx
                                    
                                    % Clear the vehicle that has been assigned with position and speed
                                    [~,idx]=ismember(vehWithODAndLaneByTurn(1,:),vehWithODAndLane,'rows');
                                    vehWithODAndLane(idx,:)=[];
                                    succeed=1;
                                end
                            end
                        end
                    end
                end
                
                %*********Fourth: If still have un-assigned vehicles, try to change the lane ID to the one which is a full lane*****
                if(~isempty(vehWithODAndLane))
                    isFullLane=junctionSectionInf.SectionBelongToApproach.Property(sectionAdd).IsFullLane; % From left to right
                    for i=1:size(vehWithODAndLane)
                        laneID=vehWithODAndLane(i,2); % Lane ID from right to left
                        
                        if(~isFullLane(numLanes-laneID+1))
                            if(laneID==1) % Rightmost lane, search left
                                for j=2:numLanes
                                    if(isFullLane(numLanes-j+1))
                                        vehWithODAndLane(i,2)=j;
                                        break;
                                    end
                                end
                            elseif(laneID==numLanes) % Leftmost lane, search left
                                for j=numLanes-1:-1:1
                                    if(isFullLane(numLanes-j+1))
                                        vehWithODAndLane(i,2)=j;
                                        break;
                                    end
                                end
                            else
                                % Searching left
                                for j=laneID+1:numLanes
                                    if(isFullLane(numLanes-j+1))
                                        leftAdjacentLane=j;
                                        break;
                                    end
                                end
                                % Searching right
                                for j=laneID-1:-1:1
                                    if(isFullLane(numLanes-j+1))
                                        rightAdjacentLane=j;
                                        break;
                                    end
                                end
                                idx=(rand()<=0.5);
                                vehWithODAndLane(i,2)=idx*leftAdjacentLane+(1-idx)*rightAdjacentLane;
                            end
                        end
                        
                    end
                end
            end
        end
        
        function [vehWithODAndLane]=reassign_turns_and_lanes(junctionSectionInf,sectionAdd,vehWithODAndLane)
            %% This function is used to reassign turns and lanes to the vehicles remained unassigned from the previous section
            
            % Get the property of the current section
            curSectionProperty=junctionSectionInf.SectionBelongToApproach.Property(sectionAdd);
            
            sectionID=junctionSectionInf.SectionBelongToApproach.ListOfSections(sectionAdd);
            
            % Get the turning information at the current section
            turnInf=[];
            for i=1:size(curSectionProperty.DownstreamJunction.Turnings.TurningInf,1)
                tmpTurnInf=curSectionProperty.DownstreamJunction.Turnings.TurningInf(i,:);
                turnInf=[turnInf;...
                    [tmpTurnInf.TurnID,tmpTurnInf.OrigFromLane,tmpTurnInf.OrigToLane,...
                    tmpTurnInf.DestFromLane,tmpTurnInf.DestToLane]];
            end
            
            % Re-assign the turning and lane information to the vehicles
            numCurTurning=size(turnInf,1);
            for i=1:size(vehWithODAndLane,1)
                laneID=vehWithODAndLane(i,2);
                
                curTurningByLane=[];
                for j=1:numCurTurning
                    if(turnInf(j,4)<=laneID && turnInf(j,5)>=laneID)
                        curTurningByLane=[curTurningByLane;turnInf(j,:)];
                    end
                end
                
                % Randomly select the upstream turning
                curTurnIdx=randperm(numCurTurning,1);
                curTurnID=turnInf(curTurnIdx,1);
                % After selecting the upstream turning, randomly select the
                % lane of that turn
                curLane=randi([turnInf(curTurnIdx,2),turnInf(curTurnIdx,3)],1,1);
                
                % Overwrite the section ID, lane ID and turn ID of that vehicle
                vehWithODAndLane(i,1)=sectionID;
                vehWithODAndLane(i,2)=curLane;
                vehWithODAndLane(i,end)=curTurnID;
            end
            
        end
        
        function [spacing,speed]=get_a_speed(type,defaultParams,threshold,speeds)
            %% This function returns a speed for a vehicle
            
            switch type
                case 'Queued' % Queued vehicle, speed=0
                    speed=0;
                    spacing=defaultParams.JamSpacing;
                case 'Moving'
                    % Get the spacing
                    spacing=randi([defaultParams.JamSpacing threshold*defaultParams.JamSpacing],1,1);
                    
                    if(isempty(speeds))
                        speed=5;
                    else
                        idx=max(floor((spacing-defaultParams.JamSpacing)/2/defaultParams.JamSpacing*length(speeds)),1);
                        speed=speeds(idx);
                    end
            end
        end
        
        function [adjacentLaneID]=find_available_adjacent_lane(TurningBelongToApproach,rearBoundaryByLane,turnID)
            %% This function is used to find the available adjacent lanes belonging to other turning movements
            
            adjacentLaneID=[];
            
            % Get the orders of turns from left to right
            turningFromLeftToRight=TurningBelongToApproach.TurningFromLeftToRight;
            % Get the properties of these turns
            turningProperty=TurningBelongToApproach.TurningProperty;
            
            % Select the turning property of the given turn ID
            [~,idx]=ismember(turnID,turningFromLeftToRight);
            turningPropertyByTurnID=turningProperty(idx,:);
            
            % Get the two boundary lanes
            origFromLane=turningPropertyByTurnID.OrigFromLane;
            origToLane=turningPropertyByTurnID.OrigToLane;
            
            % Get the two adjacent lanes
            rightAdjacentLane=origFromLane-1;
            leftAdjacentLane=origToLane+1;
            
            % Find the maximum current queue boundary of this turning ID
            maxCurrentQueueBoundary=0;
            for i=origFromLane:origToLane % Loop for each lane belonging to this turning ID
                [~,idx]=ismember(i,rearBoundaryByLane(:,1)); % Search for the index
                if(maxCurrentQueueBoundary<rearBoundaryByLane(idx,end)) % Find a bigger queue boundary
                    maxCurrentQueueBoundary=rearBoundaryByLane(idx,end);
                end
            end
            
            % Check the right adjacent lane
            if(rightAdjacentLane>=min(rearBoundaryByLane(:,1)))
                [~,idx]=ismember(rightAdjacentLane,rearBoundaryByLane(:,1)); % Search for the index
                if(maxCurrentQueueBoundary<rearBoundaryByLane(idx,2)&&... % Maximum queue boundary is smaller than the lane boundary
                        rearBoundaryByLane(idx,end)< rearBoundaryByLane(idx,2)) % and that lane is Not full
                    adjacentLaneID=[adjacentLaneID;rightAdjacentLane];
                end
            end
            
            % Check the left adjacent lane
            if(leftAdjacentLane<=max(rearBoundaryByLane(:,1)))
                [~,idx]=ismember(leftAdjacentLane,rearBoundaryByLane(:,1)); % Search for the index
                if(maxCurrentQueueBoundary<rearBoundaryByLane(idx,2)&&... % Maximum queue boundary is smaller than the lane boundary
                        rearBoundaryByLane(idx,end)< rearBoundaryByLane(idx,2)) % and that lane is Not full
                    adjacentLaneID=[adjacentLaneID;leftAdjacentLane];
                end
            end
            
        end
        
        function [tmpVehicleList]=generate_vehicle_without_fieldEstimation(junctionSectionInf,data,CurrentTime)
            % This function is used to generate vehicles for the approach
            % without estimated states and queues from the field
            
            % data:Time	VehicleID	Type	SectionID	SegmentID	NumLane	CurPosition	CurrentSpeed(mph)	 CentroidOrigin	 CentroidDest	Distance2End	statusLeft	statusRight	statusStop             tmpVehicleList=[];
            
            JunctionID=junctionSectionInf.JunctionID;
            SectionID=junctionSectionInf.FirstSectionID;
            if(any(isnan(data)))
                fprintf('No simulation data available for Junction: %d--Section %d in the given time period!\n',JunctionID,SectionID);
                tmpVehicleList=[];
            else
                % Get the vehicle information at the closest time interval
                time=data(:,1);
                timeIntervals=unique(time);
                [~,I]=min(abs(timeIntervals-CurrentTime));
                closestTimeInterval=timeIntervals(I);
                
                idx=(time==closestTimeInterval);
                dataSelected=data(idx,:);
                
                tmpVehicleList=dataSelected(:,[4,6,3,9,10,7,8]);
                tmpVehicleList=[tmpVehicleList,zeros(size(tmpVehicleList,1),1)]; % Do not track the vehicles
            end
        end
        
        function [statisticsSection]=get_vehicle_statistics_from_simulation(junctionSectionInf,simVehDataProvider,querySetting,CurrentTime)
            %% This function is used to obtain the statistics on simulated vehicles for a given approach
            
            TimePeriod=[CurrentTime-querySetting.SearchTimeDuration CurrentTime]; % Define the searching time period
            Distance=querySetting.Distance; % Defined the searching distance to obtain turning proportions
            
            listOfSections=junctionSectionInf.SectionBelongToApproach.ListOfSections; % Get the list of sections
            
            % Get the statistics of traffic for those sections
            statisticsSection=simVehDataProvider.get_statistics_for_section_time(listOfSections, TimePeriod, Distance);
        end
        
    end
end

