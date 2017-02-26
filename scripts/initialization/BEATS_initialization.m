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
data.AimsunWithBEATSMapping=dp_network_BEATS.transfer_beats_to_aimsun(data.BEATSWithAimsunMapping,sectionData,data.XMLMapping,data.XMLNetwork);

%% Initialization
% Beats data provider
ptr_beats=simBEATS_data_provider; 

% simVehicle data provider
inputFileLoc=findFolder.temp_aimsun_whole;
dp_vehicle=simVehicle_data_provider(inputFileLoc); 

defaultParams=struct(... % Default parameters
    'VehicleLength', 17,...
    'JamSpacing', 24,...
    'Headway', 2);

querySetting=struct(... % Query settings
    'SearchTimeDuration', 30*60,...
    'Distance', 60);

dp_initialization_beats=initialization_in_aimsun_with_beats(data,dp_vehicle,ptr_beats,defaultParams,nan);

% Default settings
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
from=7.5*3600; % Starting time
to=7.5*3600;  % Ending time
interval=300;

aimsunWithBeatsInitialization=dp_initialization_beats.networkData.AimsunWithBEATSMapping;
vehListWithBeats=[];
for day=8:8 % Weekday   
    for i=1:size(aimsunWithBeatsInitialization,1) % Loop for all approaches 
        for t=from:interval:to % Loop for all prediction intervals
            queryMeasures=struct(...
                'year',     nan,...
                'month',    nan,...
                'day',      nan,...
                'dayOfWeek',day,...
                'median', 1,...
                'timeOfDay', [t t+interval]); % Use a longer time interval to obtain more reliable data
            
            [tmpVehList]=dp_initialization_beats.generate_vehicles_for_a_link...
                (aimsunWithBeatsInitialization(i),queryMeasures,querySetting,t);
            vehListWithBeats=[vehListWithBeats;tmpVehList];                
        end
    end
end
outputFolder=findFolder.aimsun_initialization;
dlmwrite(fullfile(outputFolder,'VehicleInfEstimation.csv'), vehListWithBeats, 'delimiter', ',', 'precision', 9); 

