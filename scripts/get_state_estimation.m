%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all


%% Load the detector config file
config=load_config('arterial_system_detector_config.xlsx', 'Arcadia');

%% Get the approach config file
appConfig=aggregate_detector_to_approach_level(config);

%% Get the data provider
ptr=data_clustering; % Create the object with default file locations
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'dayOfWeek',2,...
    'median', 1,...
    'timeOfDay', [18*3600 18*3600+900 ]);

%% Run state estimation
est=state_estimation(appConfig.approachConfig,ptr,appConfig.detectorConfig);
appStateEst=[];
for i=1:size(appConfig.approachConfig,1)
    approach=appConfig.approachConfig(i);
    [approach]=est.get_data_for_approach(approach,queryMeasures);
    [approach]=est.get_traffic_condition_by_approach(approach);
    appStateEst=[appStateEst;approach];
end

folderLocation=findFolder.reports;
fileName='state_estimation_result.xlsx';
est.extract_to_excel(appStateEst,folderLocation,fileName);



