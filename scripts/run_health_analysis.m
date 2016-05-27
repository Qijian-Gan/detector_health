%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
config=load_config('arterial_system_detector_config.xlsx', 'Arcadia');

%% Load the list of files
dp=load_detector_data;
% dp=load_detector_data('C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\TCS Detector Archive');

fileList=dp.obtain_file_list(dp.folderLocation);

%% Run the health check
params=struct(...
    'timeInterval',             300,...      % Five-minute data, default
    'threshold',                400,...      % Threshold for break points: absolute difference in vph
    'criteria_good',            struct(...   % Criteria to say a detector is good
    'MissingRate',         5,...
    'InconsistencyRate',   10,...
    'BreakPoints',         10));

numFile=size(fileList,1);
health_report=struct(health_analysis.metrics_profile);
health_report(1)=[];
for i=1: numFile
    data=dp.parse_csv(fileList(i).name, dp.folderLocation);
    
    hc=health_analysis(data,params);
    hc.measures=hc.health_criteria;
    
    health_report(end+1:end+length(hc.measures))=hc.measures;
end

% Save the health check report to the "output" folder
save_health_report(health_report);




