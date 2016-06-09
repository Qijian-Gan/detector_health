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
                this.folderLocation=findFolder.temp;
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
            DetourRoute=[];
            for i=1:numDetector
                if(SensorIDs(i)<10)
                    DetectorIDs=[DetectorIDs;{strcat(num2str(IntersectionIDs(i)),'0',num2str(SensorIDs(i)))}];
                else
                    DetectorIDs=[DetectorIDs;{strcat(num2str(IntersectionIDs(i)),num2str(SensorIDs(i)))}];
                end
                if(strcmp(this.DetectorList.detectorConfig(i).DetourRoute,'YES'))
                    DetourRoute=[DetourRoute;1];
                else
                    DetourRoute=[DetourRoute;0];
                end
            end
            
           StartDateID=datenum(sprintf('%d-%d-%d',this.StartDate.Year,this.StartDate.Month,this.StartDate.Day));
           EndDateID=datenum(sprintf('%d-%d-%d',this.EndDate.Year,this.EndDate.Month,this.EndDate.Day));
           numDay=EndDateID-StartDateID+1;
            
           performance=zeros(numDetector,numDay);
           avgPerformance=zeros(3,numDay);
           performanceDetour=zeros(6,numDay);
           
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
           
           avgPerformance(1,:)= mean(performance>0)*100;
           avgPerformance(2,:)= mean(performance==0)*100;
           avgPerformance(3,:)= mean(performance<0)*100;
               
           for k=0:1:1
               idx=(DetourRoute==1-k);               
               performanceDetour(3*(k)+1,:)= mean(performance(idx,:)>0)*100;
               performanceDetour(3*(k)+2,:)= mean(performance(idx,:)==0)*100;
               performanceDetour(3*(k)+3,:)= mean(performance(idx,:)<0)*100;
           end
           
           this.write_to_excel(DetectorIDs,StartDateID,EndDateID,performance,avgPerformance,performanceDetour);
        end

        function [this]=write_to_excel(this,DetectorIDs,StartDateID,EndDateID,performance,avgPerformance,performanceDetour)
            outputFolder=findFolder.reports;
            outputFileName=fullfile(outputFolder,sprintf('Health_Report_%s_TO_%s.xlsx',datestr(StartDateID),datestr(EndDateID)));
            
            dateString=datestr((StartDateID:EndDateID));
            
            %*****Writing daily performance ******
            % Write the header
            xlswrite(outputFileName,[{'Intersection Name', 'Intersection ID','County','City','Road Name','Direction',...
                'Sensor ID','Movement','Status','Detour Route'},cellstr(dateString)'],'Daily Report');
            
            % Write intersection and detector information
            xlswrite(outputFileName,[{this.DetectorList.detectorConfig.IntersectionName}',...
                {this.DetectorList.detectorConfig.IntersectionID}',...
                {this.DetectorList.detectorConfig.County}',...
                {this.DetectorList.detectorConfig.City}',...
                {this.DetectorList.detectorConfig.RoadName}',...
                {this.DetectorList.detectorConfig.Direction}',...
                {this.DetectorList.detectorConfig.SensorID}',...
                {this.DetectorList.detectorConfig.Movement}',...
                {this.DetectorList.detectorConfig.Status}',...
                {this.DetectorList.detectorConfig.DetourRoute}'],'Daily Report',sprintf('A2:J%d',length(DetectorIDs)+1));
            
            % Write daily performance            
            performanceGrade=extract_health_report.convert_from_number_to_Grade(performance);
            endColumn=10+size(performanceGrade,2);
            numRound=floor(endColumn/26);
            if(numRound>0)
                firstChar=char(numRound+'A'-1);
                secondChar=char(mod(endColumn,26)+'A'-1);                
                asciiEndColumn = strcat(firstChar,secondChar);
            else
                asciiEndColumn = char(endColumn+'A'-1);
            end
            xlswrite(outputFileName,performanceGrade,'Daily Report',sprintf('K2:%s%d',asciiEndColumn,size(performanceGrade,1)+1));
            
            xlswrite(outputFileName,[{'Daily Good (%)'};{'Daily Bad (%)'};{'Daily No Data (%)'}],...
                'Daily Report',sprintf('J%d:J%d',size(performanceGrade,1)+2,size(performanceGrade,1)+4));
            xlswrite(outputFileName,avgPerformance,'Daily Report',sprintf('K%d:%s%d',size(performanceGrade,1)+2,...
                asciiEndColumn,size(performanceGrade,1)+1+size(avgPerformance,1)));
            
            %*****Writing daily performance ******
            numDay=size(avgPerformance,2);
            if(numDay>=7) % Only provide weekly report when the number of days greater than or equal to one week
                xlswrite(outputFileName,[{'Weekly Data Quality (%)'},{''},{this.DetectorList.city}],'Weekly Report');
                
                xlswrite(outputFileName,[{' '},{'Detour Routes'},{' '}, {' '},{'Not Detour Routes'},{' '},{' '}]...
                    ,'Weekly Report','A2:G2');
                
                xlswrite(outputFileName,[{' '},{'Good'}, {'Bad'},{'No Data'},{'Good'}, {'Bad'},{'No Data'}]...
                    ,'Weekly Report','A3:G3');
                
                numWeek=floor(numDay/7);
                weeklyPerformance=zeros(numWeek,6);
                for k=0:1:1                    
                    for i=1:numWeek
                        for j=1:3                            
                            weeklyPerformance(i,3*k+j)=mean(performanceDetour(3*k+j,(i-1)*7+1:i*7));
                        end
                    end
                end
                
                xlswrite(outputFileName,weeklyPerformance,'Weekly Report',sprintf('B4:G%d',numWeek+3));
                
                weekStart=cellstr(datestr(StartDateID:7:StartDateID+7*(numWeek-1)));
                weekEnd=cellstr(datestr(StartDateID+6:7:StartDateID+6+7*(numWeek-1)));
                
                weekstr= strcat(weekStart,{' To '}, weekEnd);
                
                xlswrite(outputFileName,weekstr,'Weekly Report',sprintf('A4:A%d',numWeek+3));
                
            end                
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

