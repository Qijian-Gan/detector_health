%% This script is to generate vehicles for Aimsun initialization
clear
clc
close all

%% Load the estStateQueue file
dp_StateQueue=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
estStateQueue=dp_StateQueue.parse_csv('aimsun_queue_estimated.csv',dp_StateQueue.folderLocation);

%% Load the network information file
dp_network=load_aimsun_network_files; % With empty input: Default folder ('data\aimsun_networkData')
junctionData=dp_network.parse_junctionInf_txt('JunctionInf.txt');
sectionData=dp_network.parse_sectionInf_txt('SectionInf.txt');
detectorData=dp_network.parse_detectorInf_csv('DetectorInf.csv');
defaultSigSettingData=dp_network.parse_defaultSigSetting_csv('DefaultSigSetting.csv');
midlinkConfigData=dp_network.parse_midlinkCountConfig_csv('MidlinkCountConfig.csv');

%% Reconstruct the Aimsun network
recAimsunNet=reconstruct_aimsun_network(junctionData,sectionData,detectorData,defaultSigSettingData,midlinkConfigData,nan);
% Reconstruct the network
recAimsunNet.networkData=recAimsunNet.reconstruction();


%% simVehicle data provider
dp_vehicle=simVehicle_data_provider; 

%% simSignal data provider
dp_signal_sim=simSignal_data_provider;
dp_signal_field=[];
%% Generate vehicles
defaultParams=struct(... % Default parameters
    'VehicleLength', 17,...
    'JamSpacing', 22);

querySetting=struct(... % Query settings
    'SearchTimeDuration', 5*60,...
    'Distance', 60);

dp_initialization=initialization_in_aimsun(recAimsunNet.networkData,estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan); % Currently missing field signal data provider
vehicleList=dp_initialization.generate_vehicle(querySetting);
dlmwrite('VehicleInfEstimation.csv', vehicleList, 'delimiter', ',', 'precision', 9); 



