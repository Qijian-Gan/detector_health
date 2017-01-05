%% This script is to run the state estimation
clear
clc
close all

%% Load the detector config file
config=load_config('Arcadia_state_estimation_config.xlsx');
config.detectorConfig=config.detector_property('Detector_Properties');
config.linkConfig=config.link_property('Link_Properties');
config.signalConfig=config.signal_property('Signal_Settings'); % Historical values
config.midlinkConfig=config.midlink_config('Midlink_Config');

%% Get the approach config file
appConfig=aggregate_detector_to_approach_level(config);
[appConfig.approachConfig]=appConfig.detector_to_approach;

%% Get the data provider
% Create the object with default file locations
ptr_sensor=sensor_count_provider; 
ptr_midlink=midlink_count_provider;
ptr_turningCount=turning_count_provider;

days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
from=6*3600; % Starting time
to=22*3600;  % Ending time
interval=300;

%% Run state estimation
est=state_estimation(appConfig.approachConfig,ptr_sensor,ptr_midlink,ptr_turningCount);
folderLocation=findFolder.reports;
fileName='state_estimation_result.xlsx';
for day=8:9 % Weekday and weekend
    appStateEst=[];    
    for i=1:size(appConfig.approachConfig,1) % Loop for all approaches 
        i
        for t=from:interval:to % Loop for all prediction intervals
            t
            queryMeasures=struct(...
                'year',     nan,...
                'month',    nan,...
                'day',      nan,...
                'dayOfWeek',day,...
                'median', 1,...
                'timeOfDay', [t t+interval]); % Use a longer time interval to obtain more reliable data

            tmp_approach=appConfig.approachConfig(i);
            [tmp_approach.turning_count_properties.proportions]=est.update_vehicle_proportions(tmp_approach,queryMeasures);
            [tmp_approach]=est.get_sensor_data_for_approach(tmp_approach,queryMeasures);
            [tmp_approach.decision_making]=est.get_traffic_condition_by_approach(tmp_approach,queryMeasures);
            if (t==from)
                approach=tmp_approach;
            else
                approach.decision_making=[approach.decision_making;tmp_approach.decision_making];
            end                
        end
        appStateEst=[appStateEst;approach];
    end
    sheetName=days{day+1};
    est.extract_to_excel(appStateEst,folderLocation,fileName,sheetName);
    save(sprintf('appStateEst_%s.mat',days{day+1}),'appStateEst');
end


