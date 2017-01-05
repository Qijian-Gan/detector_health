classdef fieldSignal_data_provider 
    properties
        
        inputFolderLocation             % Folder that stores the signal phasing information
        outputFolderLocation            % Folder that outputs the processed files
        
        listJunctions                 % List of sections
        timeStamp                     % Current time stamp
    end
    
    methods ( Access = public )

        function [this]=fieldSignal_data_provider(inputFolderLocation, outputFolderLocation,listJunctions, timeStamp)
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
            elseif(nargin>4)
                error('Too many inputs!')
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

