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
            
            % Get the params
            this.interval=params.timeInterval;
            this.threshold=params.threshold;
            this.criteria_good=params.criteria_good;
            
            % Get the number of cases in the data file
            this.cases=unique(this.data(:,1:4),'rows');
            this.numCases=size(this.cases,1);
            
        end
        
        function [measures]=health_criteria(this)
            % This function is used to apply the health check for the input
            % data
            
            % Get the metrics profile
            metrics=health_analysis.metrics_profile;            
            tmpMeasures=struct(metrics);
            
            % Get the number of intervals
            numInterval=24*3600/this.interval;
            
            count=0;
            for i=1:this.numCases % Loop for all available cases in the input data
                
                % Get the ID, year, month, and day first
                metrics.DetectorID=this.cases(i,1);
                metrics.Year=this.cases(i,2);
                metrics.Month=this.cases(i,3);
                metrics.Day=this.cases(i,4);
                
                % Also get the date number in matlab so that it would be
                % easier for later usage
                metrics.DateNum=datenum(sprintf('%d-%d-%d',metrics.Year,metrics.Month,metrics.Day));
                
                % Get the data for that given case
                tmpData=this.get_data_for_day_and_ID(this.cases(i,:));
                
                % Perform a series of health checking criteria
                % First check the data missing rate
                metrics.MissingRate=health_analysis.check_missing_rate(tmpData,numInterval);

                % Second check the inconsisitency rate
                metrics.InconsistencyRate=health_analysis.check_inconsistency_rate(tmpData,numInterval);

                % Third check the number of significant break points (changes in flows)
                metrics.BreakPoints=health_analysis.check_number_of_break_points(tmpData,this.interval,this.threshold);
                
                % Fourth check whether the detector is reporting zeros
                % during day time: from 7AM to 10PM
                metrics.ZeroValues=health_analysis.check_zero_values(tmpData);

                % Provide the rating: good/bad
                metrics.Health=this.identification_good_or_bad(metrics);
                
                count=count+1;
                tmpMeasures(count)=metrics;
            end
            measures=tmpMeasures;
            
        end
        
        function [data]=get_data_for_day_and_ID(this,params)
            % This function is used to get the detector data for a
            % particular date and detector ID
            
            % Params(1-by-4): ID, year, month, day
            idx=ismember(this.data(:,1:4),params,'rows');
            data=this.data(idx,:);
        end
        
        function [status]=identification_good_or_bad(this,metrics)
            % This function is used to identify whether a detector is good
            % or bad
            
            status=1; % Initially it is good
            
            % Missing rate is too high
            if(metrics.MissingRate>this.criteria_good.MissingRate)
                status=0;
            end
            
            % Inconsistency rate is too high
            if(metrics.InconsistencyRate>this.criteria_good.InconsistencyRate)
                status=0;
            end
            
            % Reporting zero values
            if(metrics.ZeroValues==1)
                status=0;
            end
            
            % Not a realiable metric currently            
%             % Too many break points
%             if(metrics.BreakPoints>=this.criteria_good.BreakPoints)
%                 status=0;
%             end          
            
        end
        
    end
    
    methods ( Static)
                
        function [metrics]=metrics_profile
            % This function is used to return a metrics profile
            
            metrics=struct(...
                'DetectorID',           nan,...
                'Year',                 nan,...
                'Month',                nan,...
                'Day',                  nan,...
                'DateNum',              nan,...
                'MissingRate',          nan,...                
                'InconsistencyRate',    nan,...
                'BreakPoints',          nan,...
                'ZeroValues',           nan,...
                'Health',               nan);
        end
        
        function [rate]=check_missing_rate(data,numInterval)
            % This function is to check data missing rate
            
            obsInterval=size(data,1); % Get the number of observations
            
            rate=(numInterval-obsInterval)/numInterval*100;
        end
        
        function [rate]=check_inconsistency_rate(data,numInterval)
            % This function is used to check the inconsistency rate
                        
            % Column 6: flow
            % Column 7: occ 
            % Column 8: speed
            
            % Get the data with zeros inside flow, occ, or speed
            idx=(sum(data(:,6:8)==0,2)>0);
            data_with_zero=data(idx,:);
            clear idx
            
            % Excluse those with occ=0, flow=0, speed=0
            % Excluse those with occ!=, flow=0, speed=0
            idx=(data_with_zero(:,6)==0 & data_with_zero(:,8)==0);
            data_with_zero(idx,:)=[];
            
            % For all other cases, they are inconsistent
            rate=size(data_with_zero,1)/numInterval*100;
            
        end
        
        function [rate]=check_zero_values(data)
            % This function is to check whether the system keeps reporting
            % zero values. But this criterion only apply to the time period
            % from 7:00AM to 10:00PM
            
            idx1=(data(:,5)>=7*3600); % Greater than 7:00AM
            idx2=(data(:,5)<22*3600); % Less than 10:00PM
            idx=(idx1+idx2==2);
            tmpData=data(idx,:); % Get that data
            
            % Exclusive those with one or two varialbes (flow, occ, speed) with zero values  
            % Only those with non-zero values or all zero values left
            idx=(sum((tmpData(:,6:8)==0),2)>0 & sum((tmpData(:,6:8)==0),2)<3);            
            tmpData=(tmpData(idx==0,:));
            
            % Get the sums of flow, occ, and speed
            sumFlow=sum(tmpData(:,6));
            sumOcc=sum(tmpData(:,7));
            sumSpeed=sum(tmpData(:,8));
            
            % If all sums are zeros, then say it is reporting zero values
            if(sumFlow==0 && sumOcc==0 && sumSpeed==0)
                rate=1;
            else
                rate=0;
            end          
            
        end
        
        function [numPoints]=check_number_of_break_points(data,interval,threshold)
            % This function is used to check the number of significant
            % break points (changes) in flow. It is currently not used to
            % identify the detector health since traffic data from arterial
            % detectors is very noisy
            
            % Get the difference matrix: time difference, absolute flow
            % difference, flow in the previous step (flow_pre), flow in the next step (flow_next),
            % min(flow_pre,flow_next)
            diff=[data(2:end,5)-data(1:end-1,5), abs(data(2:end,6)-data(1:end-1,6)),...
                data(1:end-1,6),data(2:end,6),min([data(1:end-1,6),data(2:end,6)]')'];
            
            % Only use the data with sequential time steps
            diff=diff(diff(:,1)==interval,:);
            % Only use the data with nonzero flows
            diff=diff(diff(:,end)>0,:);

            % Get the data that with error rates greater than the threshold
            idx=((diff(:,2)./diff(:,end)*100)>=threshold);
            % Get the number of break points
            numPoints=sum(idx);
        end
        
        function [dataOut]=struct2matrix_detector_data(dataIn)
            % This function is used to change the structure into matrix for
            % detector data
            
            % Detector ID, year, month, day, time, volume, occ, speed,
            % delay, stops, and smoothed volume, occupancy,....
            dataOut=[[dataIn.DetectorID]', [dataIn.Year]', [dataIn.Month]', [dataIn.Day]', [dataIn.Time]'...
                [dataIn.Volume]',[dataIn.Occupancy]',[dataIn.Speed]',[dataIn.Delay]',[dataIn.Stops]',...
                [dataIn.S_Volume]',[dataIn.S_Occupancy]',[dataIn.S_Speed]',[dataIn.S_Delay]',[dataIn.S_Stops]'];
            
            % Change the data unit to double
            dataOut=double(dataOut);
        end
    end
end

