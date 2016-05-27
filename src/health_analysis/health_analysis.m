classdef health_analysis
    properties
        data            % The input data
        
        interval        % Time interval of the data samples
        threshold       % Threshold to identify significant breakpoints
        criteria_good   % Criteria to say a detector is good
        
        cases           % Combinations of {detector ID, year, month, day} inside the data file
        numCases        % Number of combinations
        
        measures        % Measures of the data quality
        
    end
    
    methods ( Access = public )
        
        function [this]=health_analysis(data, params)
            % This function is to load the detector config file
            [this.data]=health_analysis.struct2matrix_detector_data(data);
            
            this.interval=params.timeInterval;
            this.threshold=params.threshold;
            this.criteria_good=params.criteria_good;
            
            this.cases=unique(this.data(:,1:4),'rows');
            this.numCases=size(this.cases,1);
            
        end
        
        function [measures]=health_criteria(this)
            
            metrics=health_analysis.metrics_profile;            
            tmpMeasures=struct(metrics);
            numInterval=24*3600/this.interval;
            
            count=0;
            for i=1:this.numCases
                metrics.DetectorID=this.cases(i,1);
                metrics.Year=this.cases(i,2);
                metrics.Month=this.cases(i,3);
                metrics.Day=this.cases(i,4);
                
                tmpData=this.get_data_for_day_and_ID(this.cases(i,:));
                
                % Perform a series of health checking criteria
                % First check the data missing rate
                metrics.MissingRate=health_analysis.check_missing_rate(tmpData,numInterval);

                % Second check the inconsisitency rate
                metrics.InconsistencyRate=health_analysis.check_inconsistency_rate(tmpData,numInterval);

                % Third check the number of significant break points
                metrics.BreakPoints=health_analysis.check_number_of_break_points(tmpData,this.interval,this.threshold);

                % Provide the rating: good/bad
                metrics.Health=this.identification_good_or_bad(metrics);
                
                count=count+1;
                tmpMeasures(count)=metrics;
            end
            measures=tmpMeasures;
            
        end
        
        function [data]=get_data_for_day_and_ID(this,params)
            idx=ismember(this.data(:,1:4),params,'rows');
            data=this.data(idx,:);
        end
        
        function [status]=identification_good_or_bad(this,metrics)
            status=1; % Initially it is good
            
            % Missing rate is too high
            if(metrics.MissingRate>=this.criteria_good.MissingRate)
                status=0;
            end
            
            % Inconsistency rate is too high
            if(metrics.InconsistencyRate>=this.criteria_good.InconsistencyRate)
                status=0;
            end
            
            % Too many break points
            if(metrics.BreakPoints>=this.criteria_good.BreakPoints)
                status=0;
            end          
            
        end
        
    end
    
    methods ( Static)
                
        function [metrics]=metrics_profile
            metrics=struct(...
                'DetectorID',           nan,...
                'Year',                 nan,...
                'Month',                nan,...
                'Day',                  nan,...
                'MissingRate',          nan,...                
                'InconsistencyRate',    nan,...
                'BreakPoints',          nan,...
                'Health',               nan);
        end
        
        function [rate]=check_missing_rate(data,numInterval)
            obsInterval=size(data,1);
            rate=(numInterval-obsInterval)/numInterval*100;
        end
        
        function [rate]=check_inconsistency_rate(data,numInterval)
            
            % Occupancy or Speed or Volume =0, but others != 0
            idx=(sum((data(:,6:8)==0),2)>0 & sum((data(:,6:8)==0),2)<3);
            rate=sum(idx)/numInterval*100;
        end
        
        function [numPoints]=check_number_of_break_points(data,interval,threshold)
            diff=[data(2:end,5)-data(1:end-1,5), abs(data(2:end,6)-data(1:end-1,6)),...
                data(1:end-1,6),data(2:end,6)];
            
            diff=diff(diff(:,1)==interval,:);

            idx=(diff(:,2)>=threshold);
            numPoints=sum(idx);
        end
        
        function [dataOut]=struct2matrix_detector_data(dataIn)
            dataOut=[[dataIn.DetectorID]', [dataIn.Year]', [dataIn.Month]', [dataIn.Day]', [dataIn.Time]'...
                [dataIn.Volume]',[dataIn.Occupancy]',[dataIn.Speed]',[dataIn.Delay]',[dataIn.Stops]',...
                [dataIn.S_Volume]',[dataIn.S_Occupancy]',[dataIn.S_Speed]',[dataIn.S_Delay]',[dataIn.S_Stops]'];
            dataOut=double(dataOut);
        end
    end
end

