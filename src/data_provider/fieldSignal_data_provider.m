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
                    case 'Date'
                        DayForm = 'long';
                        [~,DayName] = weekday(dayConfig.value,DayForm);
                    case 'Day'   
                        this.day=dayConfig.value; % Get the day
                end
                this.day=DayName;
            elseif(nargin==6) % Get the source of control plans
                this.source=source; 
            elseif(nargin>6)
                error('Too many inputs!')
            end
            
            % Get the control plans and master control plans in Aimsun
            inputFolder=findFolder.objects();
            load(fullfile(inputFolder,'recAimsunNet.mat'))
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
            % This function returns the active control plans for a given
            % day and time
                               
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
            SelectedDayID=find(ismember(days,DayConfig)==1);
            if(SelectedDayID==1 || (SelectedDayID>=3 && SelectedDayID<=7) || SelectedDayID==9) % Use the weekday
                masterPlanName='Weekday';
            else
                masterPlanName='Weekend';
            end
            
            % Select the corresponding master control plans
            if (~isempty(masterControlPlan) && ~isempty(controlPlan))                
                masterPlanNameAll={masterControlPlan.Name}';
                startingTime=[masterControlPlan.StartingTime]';
                duration=[masterControlPlan.Duration]';
                endingTime=startingTime+duration;
                
                idx=(ismember(masterPlanNameAll,masterPlanName) &...
                    (startingTime<=currentTime & endingTime>currentTime));
                candidateControlPlan=masterControlPlan(idx,:);
                
                % Get the detailed information of the control plans
                PlanIDAll=[controlPlan.PlanID]';
                controlPlans=[];
                if (~isempty(candidateControlPlan))
                    for i=1:size(candidateControlPlan,1)
                        PhaseID=candidateControlPlan(i).ControlPlanID;
                        idx=ismember(PlanIDAll,PhaseID);
                        if(sum(idx)==0)
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
        
        function [data_out]=get_signal_phasing_for_junction_time(this, junctionSectionInf, timeStamp)
            %% This function is to get data for given intersection and time stamp
            
            % Get all parameters
            if(isempty(junctionSectionInf))
                error('No junction information!')
            end
            
            junctionID=junctionSectionInf.JunctionID;
            
            turningProperty=junctionSectionInf.TurningBelongToApproach.TurningProperty;
            numOfTurns=size(turningProperty,1);
            movements={turningProperty.Description}';
            
            % Load data file
            dataFile=fullfile(this.inputFolderLocation,sprintf('FieldSig_Junction_%d.mat',junctionID));
            if(exist(dataFile,'file'))
                
                % Currently, no such files, use some default settings
                SignalByMovement=[];
                for i=1:numOfTurns
                    SignalByMovement=[SignalByMovement;...
                        struct(...
                        'Movement',             movements(i,:),...
                        'Cycle',                    120,...
                        'GreenTime',                30,...
                        'RedTime',                  90,...
                        'CurrentStatus',            {'Green'},...
                        'DurationSinceActivated',   15)];
                end
                data_out=struct(...
                    'JunctionID',               junctionID,...
                    'TimeStamp',                timeStamp,...
                    'SignalByMovement',         SignalByMovement);
                
            else
                disp(sprintf('Missing the field signal file for junction ID:%d\n',junctionID));
                SignalByMovement=[];
                for i=1:numOfTurns
                    SignalByMovement=[SignalByMovement;...
                        struct(...
                        'Movement',             movements(i,:),...
                        'Cycle',                    120,...
                        'GreenTime',                30,...
                        'RedTime',                  90,...
                        'CurrentStatus',            {'Green'},...
                        'DurationSinceActivated',   15)];
                end
                data_out=struct(...
                    'JunctionID',               junctionID,...
                    'TimeStamp',                timeStamp,...
                    'SignalByMovement',         SignalByMovement);
            end
        end
        
    end    
end

