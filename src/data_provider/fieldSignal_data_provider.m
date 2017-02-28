classdef fieldSignal_data_provider
    properties
        
        inputFolderLocation             % Folder that stores the signal phasing information
        outputFolderLocation            % Folder that outputs the processed files
        AimsunControlPlans              % Control plans in Aimsun
        FieldControlPlans               % Control Plans in the field
        AimsunMasterControlPlans        % Master control plans in Aimsun
        FieldMasterControlPlans         % Master control plans in the field
        
        listJunctions                 % List of sections
        
        timeStamp                     % Current time stamp
        day                           % Current day config
        source                        % Source to get the control plans
        activeControlPlans            % Get the active control plans
        LastCycleInformation          % Last cycle information
    end
    
    methods ( Access = public )
        
        function [this]=fieldSignal_data_provider(inputFolderLocation, outputFolderLocation,listJunctions, timeStamp, dayConfig,source)
            %% This function is to obtain the signal phasing data from the field
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.fieldSimSignal_data;
            this.outputFolderLocation=findFolder.outputs;
            
            if(nargin>=1)
                this.inputFolderLocation=inputFolderLocation; % Get the input folder
            elseif(nargin>=2)
                this.outputFolderLocation=outputFolderLocation; % Get the output folder
            elseif(nargin>=3)
                this.listJunctions=listJunctions; % Get the list of sections
            elseif(nargin==4)
                this.timeStamp=timeStamp; % Get the time stamp
            elseif(nargin==5)  % Get the day
                switch dayConfig.type
                    case 'Date' % It can be a particular date
                        DayForm = 'long';
                        [~,DayName] = weekday(dayConfig.value,DayForm); % Get the corresponding name of day
                    case 'Day'   % Directly given the name of day
                        DayName=dayConfig.value; % Get the day
                end
                this.day=DayName;
            elseif(nargin==6)
                % Get the source of control plans: from field, from
                % Aimsun(refer to field settings). These two may be
                % different sometimes.
                this.source=source;
            elseif(nargin>6)
                error('Too many inputs!')
            end
            
            % Get the control plans and master control plans in Aimsun
            load(fullfile(this.inputFolderLocation,'recAimsunNet.mat'))
            this.AimsunControlPlans=recAimsunNet.controlPlanAimsun;
            this.AimsunMasterControlPlans=recAimsunNet.masterControlPlanAimsun;
            
            % Get the control plans and master control plans in the field
            % Note: currently not available
            % Note: the control plans in Aimsun are mostly consistent with
            % those in the field
            this.FieldControlPlans=[];
            this.FieldMasterControlPlans=[];
            
        end
        
        function [controlPlans]=get_active_control_plans_for_given_day_and_time(this,DayConfig,currentTime,source)
            %% This function returns the active control plans for a given day and time
            
            % Get the source of control plans and master control plans
            switch source
                case 'FromAimsun'
                    masterControlPlan=this.AimsunMasterControlPlans;
                    controlPlan=this.AimsunControlPlans;
                case 'FromField'
                    masterControlPlan=this.FieldMasterControlPlans;
                    controlPlan=this.FieldControlPlans;
                otherwise
                    error('Unrecognized source of control plans!')
            end
            
            days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
            SelectedDayID=find(ismember(days,DayConfig)==1); % Select the day
            % In the current model, only "weekday" and "weekend" master
            % control plans are available
            if(SelectedDayID==1 || (SelectedDayID>=3 && SelectedDayID<=7) || SelectedDayID==9) % Use the weekday
                masterPlanName='Weekday';
            else
                masterPlanName='Weekend';
            end
            
            % Select the corresponding master control plans
            if (~isempty(masterControlPlan) && ~isempty(controlPlan)) % If both are not empty
                % Get the information from the stored master control plans
                masterPlanNameAll={masterControlPlan.Name}';
                startingTime=[masterControlPlan.StartingTime]';
                duration=[masterControlPlan.Duration]';
                endingTime=startingTime+duration;
                
                % Get the candidate control plans in the master control
                % plan
                idx=(ismember(masterPlanNameAll,masterPlanName) &... % With the same name
                    (startingTime<=currentTime & endingTime>currentTime)); % Time period covers current time
                candidateControlPlan=masterControlPlan(idx,:);
                
                % Get the detailed information of the control plans
                PlanIDAll=[controlPlan.PlanID]'; % Get all plan IDs from the stored control plans
                controlPlans=[];
                if (~isempty(candidateControlPlan)) % If candidate control plan is not empty
                    for i=1:size(candidateControlPlan,1)
                        PhaseID=candidateControlPlan(i).ControlPlanID;
                        idx=ismember(PlanIDAll,PhaseID);
                        if(sum(idx)==0) % If not found
                            fprintf('Control Plan ID: %d is not for traffic signal!\n',PhaseID)
                        else
                            controlPlans=[controlPlans;controlPlan(idx,:)];
                        end
                    end
                end
            else
                controlPlans=[];
            end
            
        end
        
        function [data_out,this]=get_signal_phasing_for_junction_time(this, junctionSectionInf, DayConfig,currentTime,source)
            %% This function is to get data for given intersection and time stamp
            
            % Get all parameters
            if(isempty(junctionSectionInf))
                error('No junction information!')
            end
            
            if(isempty(this.activeControlPlans)) % If the activeControlPlans is empty
                if(nargin==5)
                    controlPlans=this.get_active_control_plans_for_given_day_and_time(DayConfig,currentTime,source);
                    this.timeStamp=currentTime;
                    this.day=DayConfig;
                    this.source=source;
                else
                    error('Not enough/(or too many) inputs for day and time!')
                end
            else
                controlPlans=this.activeControlPlans;
            end
            
            % Get the junction information and turning information
            junctionID=junctionSectionInf.JunctionID;
            turningProperty=junctionSectionInf.TurningBelongToApproach.TurningProperty;
            numOfTurns=size(turningProperty,1);
            movements={turningProperty.Description}';
            
            % Get the corresponding control plan for the junction
            junctionIDInPlan=[controlPlans.JunctionID]';
            idx=ismember(junctionIDInPlan,junctionID);
            if(sum(idx)==1) % Junction ID found
                % Currently, no such files, use some default settings
                junctionControlPlan=controlPlans(idx,:);
                [~,restTime]=fieldSignal_data_provider...
                    .determine_time_of_last_cycle_for_a_junction(junctionControlPlan,this.LastCycleInformation,this.timeStamp);
                SignalByMovement=[];
                for i=1:numOfTurns
                    [tmpSignalByMovement]=fieldSignal_data_provider.determine_signal_state_for_a_movement_at_junction...
                        (junctionControlPlan,restTime,turningProperty,movements(i,:));
                    SignalByMovement=[SignalByMovement;tmpSignalByMovement];
                end
                data_out=struct(...
                    'JunctionID',               junctionID,...
                    'TimeStamp',                this.timeStamp,...
                    'SignalByMovement',         SignalByMovement);
                
            elseif(sum(idx)==0) % If not found, use default values: assume they are in red times
                fprintf('Use default values since no signal information for junction ID:%d\n',junctionID);
                SignalByMovement=[];
                for i=1:numOfTurns % Loop for each turn
                    switch movements{i,:}
                        case 'Left Turn' % Left turn, use a smaller green time
                            SignalByMovement=[SignalByMovement;...
                                struct(...
                                'Movement',                 movements(i,:),...
                                'Cycle',                    120,...
                                'GreenTime',                15,...
                                'RedTime',                  105,...
                                'CurrentStatus',            {'Red'},...
                                'DurationSinceActivated',   5)];
                        otherwise % For other movements, use a higher green time
                            SignalByMovement=[SignalByMovement;...
                                struct(...
                                'Movement',                 movements(i,:),...
                                'Cycle',                    120,...
                                'GreenTime',                45,...
                                'RedTime',                  75,...
                                'CurrentStatus',            {'Red'},...
                                'DurationSinceActivated',   15)];
                    end
                end
                data_out=struct(...
                    'JunctionID',               junctionID,...
                    'TimeStamp',                this.timeStamp,...
                    'SignalByMovement',         SignalByMovement);
            else % Two or more active control plans
                error('Two or more active control plans for junction ID:%d\n',junctionID);
            end
        end
        
    end
    
    methods (Static)
        
        function [SignalByMovement]=determine_signal_state_for_a_movement_at_junction...
                (junctionControlPlan,restTime,turningProperty,movement)
            %% This function is used to determine the signal state for a given movement at a junction
            
            turnID=turningProperty.TurnID; % Get the turn ID
            cycle=junctionControlPlan.Cycle;
            
            numSignal=size(junctionControlPlan.Signals,1); % Get the number of signal movements
                        
            signalInTurn=[];
            for i=1:numSignal % Loop for all signal movements
                turns=junctionControlPlan.Signals(i).TurningInSignal; % Get the turning information
                signalID=junctionControlPlan.Signals(i).SignalID; % Get the signal movement ID
                
                for j=1:length(turns) % Loop for each turn
                    if(turns(j)==turnID) % Find the same turning ID
                       signalInTurn=[signalInTurn;signalID];
                    end
                end
            end            
            
            if(isempty(signalInTurn)) % If we can not find the corresponding signal movement, ERROR!
                error('No signal movement is associated with the turn: %d',turnID);
            end
            
            numPhases=size(junctionControlPlan.Phases,1);
            Phases=junctionControlPlan.Phases;
            phaseInTurn=[];
            for i=1:numPhases % Loop for each phase
                numSignalInPhase=Phases(i).NumSignalInPhase; % Get the number of signal movements in each phase
                for j=1:numSignalInPhase % Loop for each signal movement
                    for k=1:length(signalInTurn)
                        if(Phases(i).SignalInPhase(j)==signalInTurn(k)) % Find the corresponding phase
                            phaseInTurn=[phaseInTurn;...
                                [Phases(i).PhaseID, Phases(i).RingID,Phases(i).StartTime,Phases(i).Duration]]; 
                            % May be need the permissive time in the
                            % future. Currently, the permissive setting in
                            % Aimsun is problematic
                        end
                    end
                end
            end
            
            % Sort the phase according to the starting time
            [~,inx]=sort(phaseInTurn(:,3));
            phaseInTurn = phaseInTurn(inx,:);
            
            % Get the total green time

            totalGreen=sum(phaseInTurn(:,4));
            totalRed=cycle-totalGreen;
            
            idx=(phaseInTurn(:,3)<restTime & phaseInTurn(:,3)+phaseInTurn(:,4)>restTime);
            hasActivated=0;
            if(sum(idx)) % Is in the green period
                status={'Green'};
                [~,I]=find(idx==1);
                
                for i=1:I-1
                    hasActivated=hasActivated+phaseInTurn(i,4);
                end
                hasActivated=hasActivated+restTime-phaseInTurn(I,3);
            else % Is not in the green period
                status={'Red'};
                
                % Note: Theoretically, the following method is not working with more than one
                % phases
                if(restTime<=phaseInTurn(1,3)) % Before the first phase
                    hasActivated=totalRed-(phaseInTurn(1,3)-restTime);
                else % If not
                    for i=1:size(phaseInTurn,1) % Loop for each phase
                        if(restTime>phaseInTurn(i,3)+phaseInTurn(i,4)) % Find the nearest phase
                            hasActivated=restTime-(phaseInTurn(i,3)+phaseInTurn(i,4)); % Get the activated duration
                        end
                    end
                end
            end
            
            SignalByMovement=struct(...
                'Movement',                 movement,...
                'Cycle',                    cycle,...
                'GreenTime',                totalGreen,...
                'RedTime',                  totalRed,...
                'CurrentStatus',            status,...
                'DurationSinceActivated',   hasActivated);
            
        end
        
        function [timeEndOfLastCycle,restTime]=determine_time_of_last_cycle_for_a_junction(junctionControlPlan,LastCycleInformation,currentTimeStamp)
            
            % Get the control plan information: offset, coordination,
            % numOfrings, etc.
            controlPlanStartTime=junctionControlPlan.PlanOffset;
            coordination=junctionControlPlan.Coordination;
            numRings=junctionControlPlan.NumRings;
            
            % Get the phase properties
            phases=junctionControlPlan.Phases;
            phaseRingAll=[phases.RingID]'; % Ring IDs
            starttimePhaseAll=[phases.StartTime]'; % Start times
            durationPhaseAll=[phases.Duration]'; % Durations
            endtimePhaseAll=durationPhaseAll+starttimePhaseAll; % End times
            phaseInRingID=(1:size(phases,1)); % Phase IDs in ring: 1 to NumOfPhases
            phaseIDAll=[phases.PhaseID]'; % Phase IDs
            
            % Determine the last cycle information
            switch LastCycleInformation 
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
                        if(timeControlPlanHasActivated<0) % If the plan is activated earlier
                            timeControlPlanIsActivated=timeControlPlanIsActivated-junctionControlPlan.Cycle; % Shift left by one cycle length
                            timeControlPlanHasActivated=timeControlPlanHasActivated+junctionControlPlan.Cycle; % Update the duration
                        end                                                
                        restTime=mod(timeControlPlanHasActivated,junctionControlPlan.Cycle); % Get the residual time
                        timeEndOfLastCycle=currentTimeStamp-restTime; % Get the end time of the last cycle
                                                
                    else % If it is coordinated
                        % Get the time elapse
                        for j=1:size(coordination,1)
                            if(coordination(j).PhaseID>0)
                                phaseOffSet=coordination(j).PhaseOffset;
                                phaseID=coordination(j).PhaseID;
                                fromEndOfPhase=coordination(j).FromEndOfPhase;
                                break;
                            end
                        end
                        
                        % Get the elasped time
                        coordinatedPhase=phases(phaseIDAll==phaseID,:);
                        startTimePhase=coordinatedPhase.StartTime;
                        durationPhase=coordinatedPhase.Duration;
                        if(fromEndOfPhase==1)
                            timeElapse=startTimePhase+durationPhase;
                        else
                            timeElapse=startTimePhase;
                        end
                        
                        % Calculated the activation time
                        timeControlPlanIsActivated=controlPlanStartTime+phaseOffSet-timeElapse;
                        timeControlPlanHasActivated=currentTimeStamp-timeControlPlanIsActivated;
                        if(timeControlPlanHasActivated<0) % If it is activated earlier
                            timeControlPlanIsActivated=timeControlPlanIsActivated-junctionControlPlan.Cycle; % Shift by one cycle
                            timeControlPlanHasActivated=timeControlPlanHasActivated+junctionControlPlan.Cycle;
                        end                        
                        restTime=mod(timeControlPlanHasActivated,junctionControlPlan.Cycle);
                        timeEndOfLastCycle=currentTimeStamp-restTime;
                    end                    
                otherwise
                    error('Can not find the method to determine the last cycle information')
            end
            
        end
        
    end
end

