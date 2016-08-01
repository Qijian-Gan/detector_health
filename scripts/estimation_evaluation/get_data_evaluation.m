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
ptr_sensor=sensor_count_provider; % Create the object with default file locations
ptr_midlink=midlink_count_provider;
ptr_turningCount=turning_count_provider;

%% Run data source evaluation

evl=data_evaluation(appConfig.approachConfig,ptr_sensor,ptr_midlink,ptr_turningCount);
appDataEvl=[];
for i=5:size(appConfig.approachConfig,1)
    % For approach
    [approach]=evl.get_turning_count_for_approach(appConfig.approachConfig(i));
    [approach]=evl.get_midlink_data_for_approach(approach);
    [approach]=evl.get_stopbar_data_for_approach(approach);
    [approach]=evl.get_advanced_data_for_approach(approach);
    [approach]=evl.diagnose_approach_flow(approach,900);
    [approach]=evl.get_rescaled_approach_flow(approach);
    
    % For individual movement
    [approach]=evl.get_turning_count_for_movement(approach,'Left Turn');
    [approach]=evl.get_turning_count_for_movement(approach,'Through');
    [approach]=evl.get_turning_count_for_movement(approach,'Right Turn');    
    [approach]=evl.get_stopbar_data_for_movement(approach,'Left Turn');
    [approach]=evl.get_stopbar_data_for_movement(approach,'Through');
    [approach]=evl.get_stopbar_data_for_movement(approach,'Right Turn');
    
    [approach]=evl.diagnose_movement_flow(approach, 'Left Turn', 900);
    [approach]=evl.diagnose_movement_flow(approach, 'Through', 900);
    [approach]=evl.diagnose_movement_flow(approach, 'Right Turn', 900);
    [approach]=evl.get_scaled_movement_flow(approach,'Left Turn');
    [approach]=evl.get_scaled_movement_flow(approach,'Through');
    [approach]=evl.get_scaled_movement_flow(approach,'Right Turn');
    
    appDataEvl=[appDataEvl;approach];
end




