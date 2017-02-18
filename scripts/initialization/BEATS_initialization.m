%% This script is to generate vehicles for Aimsun initialization from BEATS
clear
clc
close all

%% Load the network information file
% Aimsun
InputFolder=findFolder.aimsunNetwork_data_whole();
dp_network_Aimsun=load_aimsun_network_files(InputFolder); 
if(exist(fullfile(InputFolder,'SectionInf.txt'),'file'))
    sectionData=dp_network_Aimsun.parse_sectionInf_txt('SectionInf.txt');
else
    error('Cannot find the section information file in the folder!')
end

%BEATS
dp_network_BEATS=load_BEATS_network;
data.XMLNetwork=dp_network_BEATS.parse_BEATS_network_files('210E_for_estimation_v5_links_fixed.xml');
data.XMLMapping=dp_network_BEATS.parse_BEATS_network_files('link_id_map_450.csv');
data.BEATSWithAimsunMapping=dp_network_BEATS.parse_BEATS_network_files('BEATSLinkTable.csv');
data.AimsunWithBEATSMapping=dp_network_BEATS.transfer_beats_to_aimsun(data.BEATSWithAimsunMapping,sectionData);

% %% Reconstruct the Aimsun network
% recAimsunNet=reconstruct_aimsun_network(junctionData,sectionData,detectorData,defaultSigSettingData,midlinkConfigData,nan);
% % Reconstruct the network
% recAimsunNet.networkData=recAimsunNet.reconstruction();
% % Generate the configuration of approaches for traffic state estimation
% appDataForEstimation=recAimsunNet.get_approach_config_for_estimation(recAimsunNet.networkData);
% 
% %% Run state estimation
% %Get the data provider
% ptr_sensor=sensor_count_provider; 
% ptr_midlink=midlink_count_provider;
% ptr_turningCount=turning_count_provider;
% 
% % Default settings
% days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
% from=8.5*3600; % Starting time
% to=8.5*3600;  % Ending time
% interval=300;
% 
% % Run state estimation
% est=state_estimation(appDataForEstimation,ptr_sensor,ptr_midlink,ptr_turningCount);
% folderLocation='C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\data\estStateQueueData\';
% fileName='aimsun_queue_estimated.csv';
% for day=8:8 % Weekday
%     appStateEst=[];    
%     for i=1:size(appDataForEstimation,1) % Loop for all approaches 
%         for t=from:interval:to % Loop for all prediction intervals
%             queryMeasures=struct(...
%                 'year',     nan,...
%                 'month',    nan,...
%                 'day',      nan,...
%                 'dayOfWeek',day,...
%                 'median', 1,...
%                 'timeOfDay', [t t+interval]); % Use a longer time interval to obtain more reliable data
% 
%             tmp_approach=appDataForEstimation(i);
%             [tmp_approach.turning_count_properties.proportions]=est.update_vehicle_proportions(tmp_approach,queryMeasures);
%             [tmp_approach]=est.get_sensor_data_for_approach(tmp_approach,queryMeasures);
%             [tmp_approach.decision_making]=est.get_traffic_condition_by_approach(tmp_approach,queryMeasures);
%             if (t==from)
%                 approach=tmp_approach;
%             else
%                 approach.decision_making=[approach.decision_making;tmp_approach.decision_making];
%             end                
%         end
%         appStateEst=[appStateEst;approach];
%     end
%     sheetName=days{day+1};
%     est.extract_to_csv(appStateEst,folderLocation,fileName);
%     save(sprintf('appStateEst_%s.mat',days{day+1}),'appStateEst');
% end
% 
% %% Run initialization
% 
% % Load the estStateQueue file
% dp_StateQueue=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
% estStateQueue=dp_StateQueue.parse_csv('aimsun_queue_estimated.csv',dp_StateQueue.folderLocation);
% 
% % simVehicle data provider
% dp_vehicle=simVehicle_data_provider; 
% 
% % simSignal data provider
% dp_signal_sim=simSignal_data_provider;
% dp_signal_field=fieldSignal_data_provider;
% 
% % Generate vehicles
% defaultParams=struct(... % Default parameters
%     'VehicleLength', 17,...
%     'JamSpacing', 24,...
%     'Headway', 2);
% 
% querySetting=struct(... % Query settings
%     'SearchTimeDuration', 30*60,...
%     'Distance', 60);
% dp_initialization=initialization_in_aimsun(recAimsunNet.networkData,estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan); % Currently missing field signal data provider
% vehicleList=dp_initialization.generate_vehicle(querySetting);
% dlmwrite('VehicleInfEstimation.csv', vehicleList, 'delimiter', ',', 'precision', 9); 
% 
% 
% 
