classdef save_health_report
    properties
        health_report               % Current updated health report   
        
        DetectorIDs                 % Current detector ids needed to be updated
        numDetectors                % Number of detectors needed to be updated
        
        folderLocation              % Folder location that saves the data reports
    end
    
    methods ( Access = public )
        
        function [this]=save_health_report(data,folderLocation)
            % This function is to save the updated health reports to the
            % corresponding detectors
            
            if nargin>1
                this.folderLocation=folderLocation;
            else
                this.folderLocation=findFolder.temp;
            end    
            
            this.health_report=save_health_report.struct2matrix_health_report(data);
            
            % Get the list of detector IDs that need to be updated
            this.DetectorIDs=unique(this.health_report(:,1));          
            this.numDetectors=length(this.DetectorIDs);
            
            % Call the function to update the health report
            this.save_by_detector_id;
        end
     
        function [this]=save_by_detector_id(this)
            % This function is to save the health report by detector ID

            for i=1:this.numDetectors % Loop for all detectors that need to be updated
                
                detectorID=this.DetectorIDs(i); % Get the ID
                data=this.health_report(this.health_report(:,1)==detectorID,:); % Get the corresponding health report
                
                % Get the file name
                fileName=fullfile(this.folderLocation,sprintf('Health_Report_%d.mat',detectorID));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);                    
                    for j=1:size(data,1) % Loop for the number of days that need to be updated for a given detector
                        if(~ismember(data(j,1:5),dataAll(:,1:5),'rows')) % If such a date does not exist in the current health report
                            dataAll(end+1,:)=data(j,:); % Append it to the end
                        end
                    end
                    
                    dataAll=sortrows(dataAll,[1 5]); % Sort the rows according to the ID and datenum                    
                else    
                    % If it is the first time
                    dataAll=sortrows(data,[1 5]);                    
                end
                
                % Save the health report
                save(fileName,'dataAll');
            end
        end

    end
    
    methods(Static)
        function [dataOut]=struct2matrix_health_report(dataIn)
            % This function is used to change the structral health report
            % to a matrix
            
            dataOut=[[dataIn.DetectorID]', [dataIn.Year]', [dataIn.Month]', [dataIn.Day]',[dataIn.DateNum]'...
                [dataIn.MissingRate]',[dataIn.InconsistencyRate]',[dataIn.BreakPoints]',[dataIn.ZeroValues]',[dataIn.Health]'];
        end
    end
    
end

