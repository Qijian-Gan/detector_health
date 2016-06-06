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
            
            this.DetectorIDs=unique(this.health_report(:,1));          
            this.numDetectors=length(this.DetectorIDs);
            
            this.save_by_detector_id;
        end
     
        function [this]=save_by_detector_id(this)
            % This function is to save the health report by detector ID

            for i=1:this.numDetectors
                detectorID=this.DetectorIDs(i);
                data=this.health_report(this.health_report(:,1)==detectorID,:);
                
                fileName=fullfile(this.folderLocation,sprintf('Health_Report_%d.mat',detectorID));
                if(exist(fileName,'file'))
                    load(fileName);                    
                    for j=1:size(data,1)
                        if(~ismember(data(j,1:4),dataAll(:,1:4),'rows'))
                            dataAll(end+1,:)=data(j,:);
                        end
                    end
                    
                    dataAll=sortrows(dataAll,[1:4]);                    
                else                    
                    dataAll=sortrows(data,[1:4]);                    
                end
                save(fileName,'dataAll');
            end
        end

    end
    
    methods(Static)
        function [dataOut]=struct2matrix_health_report(dataIn)
            dataOut=[[dataIn.DetectorID]', [dataIn.Year]', [dataIn.Month]', [dataIn.Day]',[dataIn.DateNum]'...
                [dataIn.MissingRate]',[dataIn.InconsistencyRate]',[dataIn.BreakPoints]',[dataIn.Health]'];
        end
    end
    
end

