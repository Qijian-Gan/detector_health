clc
clear
close all

% Name of the stations
station_A='Huntington_SantaClara';
station_B='Huntington_Gateway';

% Approach detectors between two stations
% Santa Anita, First, Second, Gateway
detector_IDs_from_A_to_B={{'508301';'508305'};{'608102';'608106'};{'608217';'608219'};{'608322';'608326'}}; 
% Second, First, Santa Anita, Santa Clara
detector_IDs_from_B_to_A={{'608201';'608205'};{'608101';'608105'};{'508302';'508306'};{'508205';'508201'}};

% Intersection names between two stations
string_from_A_to_B={'Huntington@SantaAnita','Huntington@First','Huntington@Second','Huntington@Gateway'};
string_from_B_to_A={'Huntington@Second','Huntington@First','Huntington@SantaAnita','Huntington@SantaClara'};

% Selections
% selected_detector=detector_IDs_from_A_to_B;
% selected_str=string_from_A_to_B;
% select_file=sprintf('Bluetooth_%s_%s.mat',station_A, station_B); % Bluetooth data

selected_detector=detector_IDs_from_B_to_A;
selected_str=string_from_B_to_A;
select_file=sprintf('Bluetooth_%s_%s.mat',station_B, station_A); % Bluetooth data

from=6*3600; % Starting time
to=22*3600;  % Ending time
interval=300;
% Types: 0--9
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
 
% Data providers
dp_BT=bluetooth_travel_time_provider; % Bluetooth
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

[time_weekday,tt_weekday,occ_weekday,flow_weekday]=get_BT_and_Occ_data...
    (dp_BT,dp_sensor,select_file,queryMeasures,interval,selected_detector);

plot_functions.plot_BT_travel_time_and_occupancy_flow_with_time(time_weekday,tt_weekday,time_weekday,occ_weekday,selected_str,...
    'Travel Time (Sec)','Occupancy (%)', sprintf('BT Travel Time VS Occupancy on %s',days{daynum+1}))

plot_functions.plot_BT_travel_time_and_occupancy_flow_with_time(time_weekday,tt_weekday,time_weekday,flow_weekday,selected_str,...
    'Travel Time (Sec)','Flow (vph)', sprintf('BT Travel Time VS Flow on %s',days{daynum+1}))

%% Get weekend data
daynum=9;
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',daynum,...
    'median', 1,...
    'timeOfDay', [from to]);

[time_weekend,tt_weekend,occ_weekend,flow_weekend]=get_BT_and_Occ_data...
    (dp_BT,dp_sensor,select_file,queryMeasures,interval,selected_detector);

plot_functions.plot_BT_travel_time_and_occupancy_flow_with_time(time_weekend,tt_weekend,time_weekend,occ_weekend,selected_str,...
    'Travel Time (Sec)','Occupancy (%)', sprintf('BT Travel Time VS Occupancy on %s',days{daynum+1}))

plot_functions.plot_BT_travel_time_and_occupancy_flow_with_time(time_weekend,tt_weekend,time_weekend,flow_weekend,selected_str,...
    'Travel Time (Sec)','Flow (vph)', sprintf('BT Travel Time VS Flow on %s',days{daynum+1}))

%% Get whole week data
occ=[];
tt=[];
flow=[];
for i=1:7
    daynum=i;
    queryMeasures=struct(...
        'year',     nan,...
        'month',    nan,...
        'day',      nan,...
        'dayOfWeek',daynum,...
        'median', 1,...
        'timeOfDay', [from to]);
    
    [~,tmp_tt,tmp_occ,tmp_flow]=get_BT_and_Occ_data...
        (dp_BT,dp_sensor,select_file,queryMeasures,interval,selected_detector);
    
    occ=[occ;tmp_occ];
    tt=[tt;tmp_tt];
    flow=[flow;tmp_flow];
end

plot_functions.plot_BT_travel_time_speed_and_occupancy_flow_relation(tt,occ,selected_str,'Occupancy (#)','BT Travel Time (sec)',...
    'BT Travel Time VS Occupancy')

plot_functions.plot_BT_travel_time_speed_and_occupancy_flow_relation(tt,flow,selected_str,'Flow (vph)','BT Travel Time (sec)',...
    'BT Travel Time VS Flow-rate')

speed=3800/5280./tt*3600;
plot_functions.plot_BT_travel_time_speed_and_occupancy_flow_relation(speed,occ,selected_str,'Occupancy (#)','BT Avg Speed (mph)',...
    'BT Average Speed VS Occupancy')

plot_functions.plot_BT_travel_time_speed_and_occupancy_flow_relation(speed,flow,selected_str,'Flow (vph)','BT Avg Speed (mph)',...
    'BT Average Speed VS Flow-rate')

idx=any(occ>0,2);
plot_functions.plot_occupancy_flow_relation(occ(idx,:),flow(idx,:),selected_str,'Occ (%)','Flow (vph)')

%% Get the BT travel time distribution
for j=1:7
    daynum=j;
    queryMeasures=struct(...
        'year',     nan,...
        'month',    nan,...
        'day',      nan,...
        'dayOfWeek',daynum,...
        'median', 1,...
        'timeOfDay', [16*3600 20*3600]);
    interval=300;
    BT_travel_time=dp_BT.clustering(select_file, queryMeasures, interval);
    time=[];
    tt=[];
    for i=1:length(BT_travel_time.time)
        if(~isnan(BT_travel_time.travel_time(i).median))
            tt=[tt;BT_travel_time.travel_time(i).all];
            time=[time;BT_travel_time.time(i)/3600*ones(size(BT_travel_time.travel_time(i).all))];
        end
    end
    section_length=3800/5280;
    speed_limit=30;
    plot_functions.boxplot_BT_travel_time_by_time(tt,time,section_length,speed_limit,...
        sprintf('Travel Times from %s to %s on %s',strrep(station_A,'_','@'), strrep(station_B,'_','@'), days{daynum+1}))
    
end
