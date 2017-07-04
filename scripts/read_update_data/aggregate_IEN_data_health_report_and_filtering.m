%% This script is to run the detector health report for the City of Arcadia with updated criteria
clear
clc
close all

%% Load configuration file
config=load_config('Arcadia_detector_config.xlsx');
config.detectorConfig=config.detector_property('Detector_Properties');

DetectorIDAndLane=[[config.detectorConfig.IntersectionID]'*100+[config.detectorConfig.SensorID]',...
    [config.detectorConfig.NumberOfLanes]'];

%% Define the parameters
%'MissingRate',                  nan,... % Insufficient data rate
%'ExcessiveRate',                nan,... % Excessive data rate
%'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
%'HighValueRate',                nan,... % High value rate
%'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
%'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
%'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed
params=struct(...
    'timeInterval',             300,...      % Five-minute data, default
    'saturationFlow',           1200,...     % Saturation flow per lane
    'criteria_good',            struct(...   % Criteria to say a detector is good
    'MissingRate',              5,...  % Percentage
    'ExcessiveRate',            5,...  % Percentage
    'MaxZeroValues',            4,...  % Hours
    'HighValueRate',            5,...  % Percentage
    'InconsisRateWithSpeed',    15,... % Percentage
    'InconsisRateWithoutSpeed', 5 ...  % Percentage
    ));

%% Run the health analysis
InputFolder=fullfile(findFolder.IEN_temp(),'device_data_aggregated');
tmpData=dir(InputFolder);
idx=strmatch('Data_By_300Second_Arcadia',{tmpData.name});
fileList=tmpData(idx,:);

numFile=size(fileList,1);

health_report=[];
tmpList=[];
for i=1:numFile
    disp(fileList(i).name)
    
    % Parse data
    load(fullfile(InputFolder,fileList(i).name));
    
    str=strsplit(fileList(i).name,'_');
    organization=str{1,4};
    % Run health analysis
    for j=1:size(aggregatedData,1)
        hc=health_analysis_update_criteria(aggregatedData(j).Data',params,DetectorIDAndLane);
        hc.measures=hc.health_criteria;
        
        health_report=[health_report;hc.measures];
        
        % Run data imputation and smoothing analysis
        % Settings
        params_filtering=struct(...
            'interval', hc.interval,...
            'threshold', nan,...
            'imputation', struct(... % Settings for imputation
            'k', 5,... % A span of 5
            'medianValue', 0),... % Not using median values
            'smoothing', struct(... % Settings for smoothing: smooth
            'span', 0.02,... % A span of 0.02 percents of the data length
            'method','moving',... % Simple moving averages
            'degree', nan));
        
        % Data filtering and smoothing
        folderLocationFiltering=InputFolder; % Get the folder to save the filtered data
        data_filtering_updated_criteria(folderLocationFiltering,params_filtering,hc.data,hc.measures,organization);
        
    end
end

DateAll=[health_report.DateNum]';
UniqueDate=unique(DateAll);

HeathRate=zeros(size(UniqueDate));
for i=1:length(UniqueDate)
    idx=(DateAll==UniqueDate(i));
    SelectedHealthReport=health_report(idx,:);
    HeathRate(i)=sum([SelectedHealthReport.Health]);
end



