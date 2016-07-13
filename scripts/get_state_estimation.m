%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all


%% Load the detector config file
config=load_config('Arcadia_state_estimation_config.xlsx');
config.detectorConfig=config.detector_property('Detector_Properties');
config.linkConfig=config.link_property('Link_Properties');
config.signalConfig=config.signal_property('Signal_Settings');
config.midlinkConfig=config.midlink_config('Midlink_Config');

%% Get the approach config file
appConfig=aggregate_detector_to_approach_level(config);
[appConfig.approachConfig]=appConfig.detector_to_approach;

%% Get the data provider
ptr=data_clustering; % Create the object with default file locations
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',2,...
    'median', 1,...
    'timeOfDay', [19*3600+1800 19*3600+2700 ]);

%% Run state estimation
est=state_estimation(appConfig.approachConfig,ptr);
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



