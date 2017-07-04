classdef data_filtering_updated_criteria 
    properties
        
        folderLocationFiltering             % Folder that stores the processed data files
        
        input_data                          % Input data
        measures                            % Measures
        numCases                            % Number of cases needed to be updated
        
        interval                            % Interval
        imputation                          % Method to fill in missing data
        smoothing                           % Method to smooth the raw data
        
        
    end
    
    methods ( Access = public )
        
        function [this]=data_filtering_updated_criteria(folderLocationFiltering,params,data, measures,organization)
            %% This function is to do the data filtering
            
            % Obtain inputs
            this.folderLocationFiltering=folderLocationFiltering;
            this.interval= params.interval;
            this.imputation=params.imputation; % Imputation settings 
            this.smoothing= params.smoothing; % Smoothing settings
            
            this.input_data=data; % Input data            
            this.measures= measures;    % Measures of detector health         
            this.numCases=size(measures,1); % Number of cases
            
            % Get the number of detector IDs
            detectorIDAll=unique([this.measures.DetectorID]);
            detectorIDNum=length(detectorIDAll);
            
            for i=1:detectorIDNum % Loop for each detector
                detectorID=detectorIDAll(i); % Get the ID
                
                % Get the file name and load the processed data
                if(nargin==5)
                    fileName=fullfile(this.folderLocationFiltering,sprintf('Processed_data_%s_%d.mat',organization,detectorID));
                else
                    fileName=fullfile(this.folderLocationFiltering,sprintf('Processed_data_%d.mat',detectorID));
                end
                if(exist(fileName,'file'))
                    load(fileName); % Variable: process_data, which is a structure 
                else
                    processed_data=[];
                end

                tmp_data=[];                
                for j=1:this.numCases % Loop for the number of cases in the health measures
                    if(detectorID==this.measures(j).DetectorID) % Check the case with the same detector ID
                        dateNum=this.measures(j).DateNum;
                        
                        if(isempty(processed_data) || ...
                                ~any(ismember([[processed_data.id]',[processed_data.day]'],[detectorID,dateNum],'rows')))
                            % Is empty or do not have the corresponding data
                            
                            data_out=this.data_imputation(this.measures(j)); % Do data imputation
                            tmp_data=[tmp_data;struct(...
                                'id', detectorID,...
                                'day', dateNum,...
                                'data',DetectorDataProfile(data_out(:,1),data_out(:,2),data_out(:,3),...
                                data_out(:,4), data_out(:,5), data_out(:,6)))];
                        end                        
                    end
                end
                
                % For each detector, update the processed data and save it
                processed_data=[processed_data;tmp_data];                
                save(fileName,'processed_data');
                clear processed_data
            end
        end
         
        function [data_out]=data_imputation(this,measures)
            %% This function is used to do the data imputation and smoothing
            
            % Get all parameters
            detectorID=measures.DetectorID;
            year=measures.Year;
            month=measures.Month;
            day=measures.Day;

            %'MissingRate',                  nan,... % Insufficient data rate
            %'ExcessiveRate',                nan,... % Excessive data rate                
            %'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
            %'HighValueRate',                nan,... % High value rate
            %'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
            %'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
            %'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed 
            MR=measures.MissingRate;
            ER=measures.ExcessiveRate;
            
            % Select data: ordered
            data_in=this.input_data(ismember(this.input_data(:,1:4), [detectorID,year,month,day],'rows'),:);
            time_in=floor(data_in(:,5)/this.interval)*this.interval;
            maxTimeObserved=max(time_in);
            
            % Build time index
            timeIndex=(0:this.interval:24*3600);
            timeIndex=timeIndex(1:end-1);
            
            % Create tmp data file
            tmp_data=zeros(length(timeIndex),6);
            
            % Check whether there are missing values or excessive values
            if(MR>0 || ER >0)   % If yes, do data imputation
                % First fill in nan values
                for i=1:length(timeIndex) % Loop for each step
                    if(timeIndex(i)<=maxTimeObserved) % Within the maximum observed time stamp
                        idx=ismember(time_in,timeIndex(i)); % Check whether we have the same interval
                        if(sum(idx)>0) % If yes
                            tmp=data_in(idx,6:10); %There may be multiple rows with the same time stamp
                            tmp_data(i,:)=[timeIndex(i),tmp(1,:)];
                        else % If not
                            tmp_data(i,:)=[timeIndex(i), nan(1,5)];
                        end 
                    else % If there is not enough data
                        tmp_data(i,:)=[timeIndex(i), zeros(1,5)];
                    end
                end
                
                % Second call the imputation function
                tmp_data=data_filtering_updated_criteria.fill_in_missing_value(tmp_data,this.imputation);                
            else % No need to do imputation
                tmp_data=data_in(:,5:10);
            end
            
            if(any(isnan(tmp_data)))
                disp('has nan value!')
            end
            % Second smooth the data
            tmp_data=data_filtering_updated_criteria.smoothing_data(tmp_data,this.smoothing);
            
            if(any(isnan(tmp_data)))
                disp('has nan value!')
            end
            
            data_out=tmp_data;
            
        end
        
        
    end
   
    methods(Static)
        
        function [data_out]=fill_in_missing_value(data_in,imputation_setting)
            %% This function is to do data imputation
            
            k= imputation_setting.k; % Set the span
            medianValue = imputation_setting.medianValue; % Whether to use median value or not
            
            data_out=data_in;
            for i=1:size(data_out,1) % Loop for all rows
                for j=2:size(data_out,2) % For columns from 2 to end
                    if(isnan(data_out(i,j))) % Find a NaN value
                        if(i==0) % The first data point
                            data_out(i,j)=0;
                            
                        elseif(i>0 && i<=k) % Less than the span
                            if(medianValue)
                                data_out(i,j)=median(data_out(1:i-1,j));
                            else
                                data_out(i,j)=mean(data_out(1:i-1,j));
                            end
                            
                        else % Longer than the span
                            if(medianValue)
                                data_out(i,j)=median(data_out(i-k:i-1,j));
                            else
                                data_out(i,j)=mean(data_out(i-k:i-1,j));
                            end
                            
                        end
                    end
                end
            end
        end
        
        function [data_out]=smoothing_data(data_in,smoothing_setting)
            %% This function is to smooth the data to reduce the noise impact
            
            span=smoothing_setting.span;
            method=smoothing_setting.method;
            degree=smoothing_setting.degree;
            
            data_out=data_in;
            if(strcmp(method,'sgolay')&& ~isnan(degree)) % Use the sgolay method in matlab
                for i=2:size(data_in,2) % For each column
                    data_out(:,i)=smooth(data_in(:,i),span,'sgolay',degree);
                end                    
            else % Use other methods
                for i=2:size(data_in,2) % For each column
                    data_out(:,i)=smooth(data_in(:,i),span,method);
                end 
            end
            
        end
    end
end

