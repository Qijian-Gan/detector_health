classdef simSignal_data_provider 
    properties
        
        inputFolderLocation             % Folder that stores the signal phasing information
        outputFolderLocation            % Folder that outputs the processed files
        
        listJunctions                 % List of sections
        timeStamp                     % Current time stamp
    end
    
    methods ( Access = public )

        function [this]=simSignal_data_provider(inputFolderLocation, outputFolderLocation,listJunctions, timeStamp)
            %% This function is to obtain the signal phasing data
            
            % First, set default input and output folders
            this.inputFolderLocation=findFolder.temp_aimsun;
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
         
        function [data_out]=get_signal_phasing_for_junction_time(this, listJunctions, timeStamp)
            % This function is to get data for given intersection and time
            % stamp
            
            % Get all parameters
            if(isempty(listJunctions))
                error('No section list!')
            end
                 
            % Get the number of sections
            numOfJunctions=length(listJunctions);
            data_out=[];
            
            % First read the data file
            for i=1:numOfJunctions
                junctionID=(listJunctions(i));
                
                % Load data file
                dataFile=fullfile(this.inputFolderLocation,sprintf('SimSig_Junction_%d.mat',junctionID));
                if(exist(dataFile,'file'))
                    load(dataFile); % Inside: sigJunctionAll
                    
                    timeStampAll=[sigJunctionAll.TimeStamp]';
                    
                    if(~isempty(timeStamp)) % Time stamp is not empty                                  
                        if(max(timeStampAll)<timeStamp) % Time stamp too large
                            error('Input time stamp too large!')
                        elseif(min(timeStampAll)>timeStamp) % Time stamp too small
                            error('Input time stamp too small!')
                        end
                        
                        % Sort the data according to the time stamp
                        [timeStampAll,I]=sort(timeStampAll);
                        sigJunctionAll=sigJunctionAll(I,:);
                        startTimeOfPhase=[];
                        for j=1:length(I)
                            startTimeOfPhase=[startTimeOfPhase;sigJunctionAll(j).StartTimeOfRings(1)];
                        end

                        idx=(timeStamp-startTimeOfPhase>=0);   % Should greater than the starting time of a phase                     
                        sigJunctionAllSelected=sigJunctionAll(idx,:);
                        startTimeOfPhaseSelected=startTimeOfPhase(idx);
                        timeStampAllSelected=timeStampAll(idx);
                        clear idx
                        
                        [~,idx]=min(abs(timeStamp-timeStampAllSelected)); % Get the closest data point                       
                        sigJunctionAllSelected=sigJunctionAllSelected(idx,:);
                        startTimeOfPhaseSelected=startTimeOfPhaseSelected(idx);
                        timeStampAllSelected=timeStampAllSelected(idx);
                        clear idx
                        
                        if(isempty(sigJunctionAllSelected)) % Can not find one?
                            data_out=[data_out;struct(...
                                'TimeStamp',                 nan,...
                                'JunctionID',                nan,...
                                'ControlType',               nan,...
                                'CurrentPhase',              nan,...
                                'NumberOfRings',             nan,...
                                'StartTimeOfRings',          nan)];
                        else                             
                            tmp_data=sigJunctionAllSelected;                            
                            tmp_data.TimeStamp=timeStamp;
                            data_out=[data_out;tmp_data];
                        end
                    else % If time stamp is empty
                        data_out=[data_out;struct(...
                            'TimeStamp',                 nan,...
                            'JunctionID',                nan,...
                            'ControlType',               nan,...
                            'CurrentPhase',              nan,...
                            'NumberOfRings',             nan,...
                            'StartTimeOfRings',          nan)];
                    end                   
                else
                    disp(sprintf('Missing the data file for junction ID:%s\n',(junctionID)));  
                    data_out=[data_out;struct(...
                        'TimeStamp',                 nan,...
                        'JunctionID',                nan,...
                        'ControlType',               nan,...
                        'CurrentPhase',              nan,...
                        'NumberOfRings',             nan,...
                        'StartTimeOfRings',          nan)];
                end
            end            
        end
        
    end

end

