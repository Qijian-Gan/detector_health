%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
% detector_ids={'508217','508204','508208','508215','508216'}; % Huntington @ Santa Clara : NB
% detector_ids={'508203','508207'}; % Huntington @ Santa Clara : SB
% detector_ids={'508226','508202','508206'}; % Huntington @ Santa Clara : EB
% detector_ids={'508201','508205'}; % Huntington @ Santa Clara : WB

% detector_ids={'508311','508315','508303','508307'}; % Huntington @ Santa Anita : NB
% detector_ids={'508312','508328','508324','508304','508308'}; % Huntington @ Santa Anita : SB
% detector_ids={'508321','508325','508309','508301','508305'}; % Huntington @ Santa Anita : EB
% detector_ids={'508322','508310','508302','508306'}; % Huntington @ Santa Anita : WB

% detector_ids={'608104','608108'}; % Huntington @ First : NB
% detector_ids={'608103','608107'}; % Huntington @ First : SB
% detector_ids={'608114','608102','608106'}; % Huntington @ First : EB
% detector_ids={'608113','608101','608105'}; % Huntington @ First : WB

% detector_ids={'608223','608213','608203','608207'}; % Huntington @ Second : NB
% detector_ids={'608224','608212','608204','608208'}; % Huntington @ Second : SB
% detector_ids={'608214','608206','608202','608217','608219'}; % Huntington @ Second : EB
% detector_ids={'608213','608209','608201','608205'}; % Huntington @ Second : WB

% detector_ids={'608323','608327'}; % Huntington @ Gateway : NB
% detector_ids={'608303','608307'}; % Huntington @ Gateway : SB
% detector_ids={'608306','608322','608326'}; % Huntington @ Gateway : EB
detector_ids={'608302','608301','608305'}; % Huntington @ Gateway : WB

from=6*3600; % Starting time
to=22*3600;  % Ending time
interval=300;
% Types: 0--9
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 

% Data provider
dp_sensor=sensor_count_provider; % Sensors

%% Get weekday data
daynum=8;
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',daynum,...
    'median', 1,...
    'timeOfDay', [from to]);

sensor_data=dp_sensor.clustering(detector_ids, queryMeasures);


for i=1:length(sensor_data)
    if(strcmp(sensor_data(i).status,'Good Data'))
        figure
        h=plotyy(sensor_data(i).data.time/3600,sensor_data(i).data.s_volume,...
            sensor_data(i).data.time/3600, sensor_data(i).data.s_occupancy/3600*100);
        hold on
        xlabel('Time','FontSize',13)
        ylabel(h(1),'Flow-rate (vph)','FontSize',13)
        ylabel(h(2),'Occupancy (%)','FontSize',13)
        title(sprintf('Detector:%s & %s Profile',detector_ids{i}, days{daynum+1}),'FontSize',13)
    end
end
