classdef extract_health_report
    properties
        StartDate               % The start date of the report          
        EndDate                 % The end date of the report
        
        DetectorList            % The List of detectors
        
        folderLocation          % Location of the output folder
    end
    
    methods ( Access = public )
        
        function [this]=extract_health_report(params,folderLocation)
            % This function is to extract the health report for given
            % settings
            if nargin>1
                this.folderLocation=folderLocation;
            else
                this.folderLocation=findFolder.outputs;
            end   
            
            this.StartDate=params.StartDate;
            this.EndDate=params.EndDate;
            this.DetectorList=params.DetectorList;
           
            this.extract_all;
        end
     
        function [this]=extract_all(this)
            % This function is to extract the detector reports for all
            % detectors
            
            numDetector=size(this.DetectorList.detectorConfig,1);
            
            % Get Detector IDs
            IntersectionIDs=[this.DetectorList.detectorConfig.IntersectionID]';
            SensorIDs=[this.DetectorList.detectorConfig.SensorID]';
            DetectorIDs=[];
            for i=1:numDetector
                if(SensorIDs(i)<10)
                    DetectorIDs=[DetectorIDs;{strcat(num2str(IntersectionIDs(i)),'0',num2str(SensorIDs(i)))}];
                else
                    DetectorIDs=[DetectorIDs;{strcat(num2str(IntersectionIDs(i)),num2str(SensorIDs(i)))}];
                end
            end
            
           StartDateID=datenum(sprintf('%d-%d-%d',this.StartDate.Year,this.StartDate.Month,this.StartDate.Day));
           EndDateID=datenum(sprintf('%d-%d-%d',this.EndDate.Year,this.EndDate.Month,this.EndDate.Day));
           numDay=EndDateID-StartDateID+1;
            
           performance=zeros(numDetector,numDay);
           avgPerformance=zeros(1,numDay);
           
           for i=1:numDetector
               id=DetectorIDs{i};
               fileName=fullfile(this.folderLocation,sprintf('Health_Report_%s.mat',id));
               if(~exist(fileName,'file')) % No file available 
                   performance(i,:)=-1*ones(1,numDay);
               else      
                   load(fileName);
                   for j=1:numDay
                       tmpData=dataAll(dataAll(:,5)==StartDateID+j-1,:);
                       if(isempty(tmpData))
                           performance(i,j)=-1; % No data
                       else
                           performance(i,j)=tmpData(:,end);
                       end
                   end
               end
           end          
           
           avgPerformance= mean(performance>0)*100;
           
           this.write_to_excel(DetectorIDs,StartDateID,EndDateID,performance,avgPerformance);
        end

        function [this]=write_to_excel(this,DetectorIDs,StartDateID,EndDateID,performance,avgPerformance)
            outputFolder=findFolder.reports;
            outputFileName=fullfile(outputFolder,sprintf('Health_Report_%s_TO_%s.xlsx',datestr(StartDateID),datestr(EndDateID)));
            
            dateString=datestr((StartDateID:EndDateID));
            
            % Write the header
            xlswrite(outputFileName,[{'Intersection Name', 'Intersection ID','County','City','Road Name','Direction',...
                'Sensor ID','Location'},cellstr(dateString)']);
            
            % Write Intersection and detector information
            xlswrite(outputFileName,[{this.DetectorList.detectorConfig.IntersectionName}',...
                {this.DetectorList.detectorConfig.IntersectionID}',...
                {this.DetectorList.detectorConfig.County}',...
                {this.DetectorList.detectorConfig.City}',...
                {this.DetectorList.detectorConfig.RoadName}',...
                {this.DetectorList.detectorConfig.Direction}',...
                {this.DetectorList.detectorConfig.SensorID}',...
                {this.DetectorList.detectorConfig.Location}'],sprintf('A2:H%d',length(DetectorIDs)+1));
            
            % Write Performance            
            performanceGrade=extract_health_report.convert_from_number_to_Grade(performance);
            endColumn=8+size(performanceGrade,2);
            asciiEndColumn = char(endColumn+'A'-1);
            xlswrite(outputFileName,performanceGrade,sprintf('I2:%s%d',asciiEndColumn,size(performanceGrade,1)+1));
            
            xlswrite(outputFileName,avgPerformance,sprintf('I%d:%s%d',size(performanceGrade,1)+2,...
                asciiEndColumn,size(performanceGrade,1)+2));
            
        end
    end
    
    methods(Static)
        function [performanceGrade]=convert_from_number_to_Grade(performanceNumber)
            performanceGrade=cell(size(performanceNumber));
            idx=(performanceNumber==-1);
            performanceGrade(idx)={'No Data'};
            
            idx=(performanceNumber==0);
            performanceGrade(idx)={'Bad'};
            
            idx=(performanceNumber==1);
            performanceGrade(idx)={'Good'};
            
        end
    end
    
end

