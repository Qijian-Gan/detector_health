classdef health_analysis_update_criteria
    properties
        data                    % The input data
        
        interval                % Time interval of the data samples
        saturation_flow         % Saturation flow per lane
        criteria_good           % Criteria to say a detector is good
        laneInformation         % Lane information of the detectors
        
        cases                   % Combinations of {detector ID, year, month, day} inside the data file
        numCases                % Number of combinations
        
        measures                % Measures of the data quality
        
    end
    
    methods ( Access = public )
        
        function [this]=health_analysis_update_criteria(data, params,laneInformation)
            %% This function is to load the detector config file
            
            [this.data]=health_analysis_update_criteria.struct2matrix_detector_data(data);
            
            % Get the params
            this.interval=params.timeInterval; % Intervel of the data points            
            this.saturation_flow=params.saturationFlow; % Saturation flow            
            this.criteria_good=params.criteria_good; % Criteria to determine good detectors
            
            if(nargin==3)
                this.laneInformation=laneInformation;
            else
                this.laneInformation=[];
            end
            
            % Get the number of cases in the data file
            this.cases=unique(this.data(:,1:4),'rows'); % 1:4--Detector ID, year, month, day
            this.numCases=size(this.cases,1);
            
        end
        
        function [measures]=health_criteria(this)
            %% This function is used to apply the health check for the input data
            
            % Get the metrics profile
            metrics=health_analysis_update_criteria.metrics_profile;            
            tmpMeasures=[];
            
            % Get the number of intervals
            numInterval=24*3600/this.interval;
            
            for i=1:this.numCases % Loop for all available cases in the input data
                
                % Get the ID, year, month, and day first
                
                metrics.Year=this.cases(i,2);
                metrics.Month=this.cases(i,3);
                metrics.Day=this.cases(i,4);
                
                % Also get the date number in matlab so that it would be
                % easier for later usage
                metrics.DateNum=datenum(sprintf('%d-%d-%d',metrics.Year,metrics.Month,metrics.Day));
                
                if(size(this.laneInformation,2)==2) % Original source from Arcadia's TCS server
                    metrics.DetectorID=this.cases(i,1);
                    idx=ismember(this.laneInformation(:,1),this.cases(i,1));
                    if(sum(idx)>0)
                        numLane=this.laneInformation(idx,2);
                    else
                        numLane=1;
                        disp(strcat('A new detector with ID=',num2str(metrics.DetectorID)));
                    end
                else % A new source from IEN
                    
                    idx=ismember(this.laneInformation(:,1),this.cases(i,1));
                    
                    if(sum(idx)>0) % Arcadia's data
                        metrics.Organization={'Arcadia'};
                        metrics.DetectorID=this.cases(i,1);
                        numLane=max(this.laneInformation(idx,2)); % May be multiple lane numbers
                    else
                        % Get the subset of LACO detectors
                        idxOrg=(this.laneInformation(:,3)==29);
                        tmpLaneInformation=this.laneInformation(idxOrg,:);
                        
                        tmpID=mod(tmpLaneInformation(:,1),10000); % Get rid of the intersection ID
                        idx=ismember(tmpID,this.cases(i,1));
                        if(sum(idx)>0) % LACO's data
                            metrics.Organization={'LACO'};
                            metrics.DetectorID=unique(tmpLaneInformation(idx,1));
                            numLane=max(tmpLaneInformation(idx,2)); % May be multiple lane numbers
                        else % Unkown
                            % Arcadia's detector is with 6 digits; LACO's
                            % detector is more than 6 digits
                            if(this.cases(i,1)<999999 && this.cases(i,1)>99999) % 6 digits ?
                                metrics.Organization={'Arcadia'};
                                metrics.DetectorID=this.cases(i,1);
                                numLane=1;
                                disp(strcat('A new detector with ID=',num2str(metrics.DetectorID)));
                            else
                                metrics.Organization={'Unknown'};
                                metrics.DetectorID=this.cases(i,1);
                                numLane=1;
                                disp(strcat('A new detector with ID=',num2str(metrics.DetectorID)));
                            end
                        end
                    end
                end
                
                
                % Get the data for that given case
                tmpData=this.get_data_for_day_and_ID(this.cases(i,:));
                
                % ******************************************************
                % ***** Perform a series of health checking criteria ***
                % ******************************************************
                %'MissingRate',                  nan,... % Insufficient data rate
                %'ExcessiveRate',                nan,... % Excessive data rate                
                %'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
                %'HighValueRate',                nan,... % High value rate
                %'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
                %'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
                %'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed
                
                % First: Insufficient Data Diagnostic
                metrics.MissingRate=health_analysis_update_criteria.check_missing_rate(tmpData,numInterval);
                
                % Second: Excessive Data Diagnostic
                metrics.ExcessiveRate=health_analysis_update_criteria.check_excessive_data(tmpData,numInterval);
                
                % Third: Card Off Diagnostic
                metrics.MaxZeroValues=health_analysis_update_criteria.check_zero_values(tmpData,this.interval);
                
                % Fourth: High Value Diagnostic
                metrics.HighValueRate=health_analysis_update_criteria.check_high_values(tmpData,numInterval,...
                    this.saturation_flow,numLane);
                
                % Fifth: Constant Value Diagnostic
                metrics.ConstantOrNot=health_analysis_update_criteria.check_constant_values(tmpData);
                
                % Sixth: Inconsistent Data Diagnostic
                [metrics.InconsisRateWithSpeed,metrics.InconsisRateWithoutSpeed]=...
                    health_analysis_update_criteria.check_inconsistency_rate(tmpData,numInterval);

                % Provide the rating: good/bad
                % Will be updated while performing feed unstable test
                metrics.Health=this.identification_good_or_bad(metrics);
                
                tmpMeasures=[tmpMeasures;metrics];
            end
            
            measures=tmpMeasures;
            
        end
        
        function [data]=get_data_for_day_and_ID(this,params)
            %% This function is used to get the detector data for a particular date and detector ID
            
            % Params(1-by-4): ID, year, month, day
            idx=ismember(this.data(:,1:4),params,'rows');
            data=this.data(idx,:);
        end
        
        function [status]=identification_good_or_bad(this,metrics)
            %% This function is used to identify whether a detector is good or bad
            
            status=1; % Initially it is good
            
            %'MissingRate',                  nan,... % Insufficient data rate
            %'ExcessiveRate',                nan,... % Excessive data rate
            %'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
            %'HighValueRate',                nan,... % High value rate
            %'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
            %'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
            %'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed
                
            % First--Insufficient Data Diagnostic: Missing rate is too high
            if(metrics.MissingRate>this.criteria_good.MissingRate)
                status=0;
            end
            
            % Second--Excessive Data Diagnostic: Excessiving rate is too high
            if(metrics.ExcessiveRate>this.criteria_good.ExcessiveRate)
                status=0;
            end
            
            % Third--Card Off Diagnostic: Too long time period with zero samples
            if(metrics.MaxZeroValues>this.criteria_good.MaxZeroValues)
                status=0;
            end
            
            % Fourth--High Value Diagnostic: Too many samples with high flow-rates
            if(metrics.HighValueRate>this.criteria_good.HighValueRate)
                status=0;
            end
            
            % Fifth--Constant Value Diagnostic: Constant values
            if(metrics.ConstantOrNot==1)
                status=0;
            end
            
            % Sixth--Inconsistent Data Diagnostic: Too many inconsistent
            % samples
            if(metrics.InconsisRateWithoutSpeed>this.criteria_good.InconsisRateWithoutSpeed)
                status=0; % Currently, do not use speed information
            end
%             % Or use the following
%             if(metrics.InconsisRateWithSpeed>this.criteria_good.InconsisRateWithSpeed)
%                 status=0;
%             end 
            
        end
        
    end
    
    methods ( Static)
                
        function [metrics]=metrics_profile
            %% This function is used to return a metrics profile
            
            metrics=struct(...
                'DetectorID',                   nan,...
                'Year',                         nan,... 
                'Month',                        nan,...
                'Day',                          nan,...
                'DateNum',                      nan,... % Date number in Matlab   
                ...
                'MissingRate',                  nan,... % Insufficient data rate
                'ExcessiveRate',                nan,... % Excessive data rate                
                'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
                'HighValueRate',                nan,... % High value rate
                'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
                'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
                'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed
                ...
                'Health',                       nan);   % Health indicator: 0/1 (bad/good)
        end
        
        function [rate]=check_missing_rate(data,numInterval)
            %% This function is to check data missing rate: Insufficuent Data Diagnostic
            
            time=unique(data(:,5)); % Get the unique times
            obsInterval=length(time); % Get the number of observations
            
            rate=max(numInterval-obsInterval,0)/numInterval*100; % Use Max to avoid negative values
        end
        
        function [rate]=check_excessive_data(data,numInterval)
            %% This function is to check data excessive rate: Excessive Data Diagnostic
            
            time=unique(data(:,5)); % Get the unique times
            obsInterval=length(time); % Get the number of observations
            
            rate=max(obsInterval-numInterval,0)/numInterval*100; % Use Max to avoid negative values
        end
        
        function [maxLengthZeroValues]=check_zero_values(data,interval)
            %% This function is to check whether the system keeps reporting zero values: Card Off Diagnostic
            
            % But this criterion only apply to the time period from 6:00AM to 10:00PM
            % Some detectors can have zero values during midnight
            
            % Selected data from 6:00AM to 10:00PM            
            idx=(data(:,5)>=6*3600 & data(:,5)<22*3600);
            tmpData=data(idx,:); % Get that data
            clear idx
            
            % Find index of zero values
            idx=(sum((tmpData(:,6:8)==0),2)==3);  % 1: all zeros, 0: not all zeros          
            
            % Find the MaxLengthZeroValues
            maxLengthZeroValues=0;
            cur_missing_length=0;
            for i=1:length(idx) % Loop for the whole index
                if(idx(i)==1) % For current step, if all zero values
                    cur_missing_length=cur_missing_length+1; % Add one
                else % If not
                    % Check the criterion
                    if(cur_missing_length>=maxLengthZeroValues)
                        maxLengthZeroValues=cur_missing_length;
                    end
                    
                    cur_missing_length=0; % Reset
                end
            end
                
            % Check the last step: Extreme case with all zero values
            if(cur_missing_length>=maxLengthZeroValues)
                maxLengthZeroValues=cur_missing_length;
            end
            
            maxLengthZeroValues=maxLengthZeroValues*interval/3600; % Return the value in hours
        end
     
        function [rate]=check_high_values(data,numInterval,saturation_flow,numLane)
            %% This function is used to check high values: High Value Diagnostic
            
            % Note: the flow is hourly flow per detector
            
            % Column 6: flow
            % Column 7: occ 
            % Column 8: speed (if available)
            
            idx=(data(:,6)>saturation_flow*numLane);            
            rate=sum(idx)/numInterval*100;
        end
        
        function [constantOrNot]=check_constant_values(data)
            %% This function is used to check constant values: Constant Diagnostic
            
            % Column 6: flow
            % Column 7: occ 
            % Column 8: speed (if available)
            
            % Only check flow and occupancy
            % Flow
            meanFlow=mean(data(:,6));
            stdFlow=std(data(:,6));
            
            % Occ
            meanOcc=mean(data(:,7));
            stdOcc=std(data(:,7));
            
            % Check the mean value and the standard deviation
            % "meanOcc" can not be zero
            constantOrNot=0;
            if((meanFlow>=0 && stdFlow==0)||(meanOcc>=0 && stdOcc==0))
                % Either the flow or occupancy is zero
                if(meanFlow+meanOcc>0) % They can not be all zeros
                    constantOrNot=1;
                end
            end
            
        end
        
        function [rateWithSpeed,rateWithoutSpeed]=check_inconsistency_rate(data,numInterval)
            %% This function is used to check the inconsistency rate: Inconsistent Data
                        
            % Column 6: flow
            % Column 7: occ 
            % Column 8: speed (if available)
            
            %*******Check without speed*********
            % Find those with occ=0, flow!=0
            idx=(data(:,6)~=0 & data(:,7)==0);
            data_inconsistent=data(idx,:);
            rateWithoutSpeed=size(data_inconsistent,1)/numInterval*100;
            clear idx;
            
            %*******Check with speed*********
            if(all(data(:,8)>=0)) 
                % If speed information is available: speed not negative;
                
                % Get the data with zeros inside flow, occ, or speed
                idx=(sum(data(:,6:8)==0,2)>0);
                data_with_zero=data(idx,:);
                clear idx
                
                % Excluse those with occ=0, flow=0, speed=0: empty road
                % Excluse those with occ!=0, flow=0, speed=0: totally stop
                idx=(data_with_zero(:,6)==0 & data_with_zero(:,8)==0);
                data_with_zero(idx,:)=[];
                
                % For all other cases, they are inconsistent
                rateWithSpeed=size(data_with_zero,1)/numInterval*100;
            else
                rateWithSpeed=rateWithoutSpeed;
            end
            
        end
        
        function [feedUnstableIndex]=check_feed_unstable_index(data,numInterval,interval)
            %% This function is used to get the index of the stability of the data feed
            
            % Get the time sequence
            time=(0:1:numInterval-1)*interval;
            
            % Set the feed unstable index: false
            feedUnstableIndex=false(numInterval,1);

            for i=1:numInterval % Loop for each time step
                idx=ismember(data(i,5),time(i)); 
                if(sum(idx)==0) % No corresponding time intervals?
                    feedUnstableIndex(i)=true; % Set it to be true!
                end
            end
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

