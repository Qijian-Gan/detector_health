clc
clear
close all

station_A='Huntington_SantaClara';
station_B='Huntington_Gateway';

dp=bluetooth_travel_time_provider;
% First direction: from A to B
fileName=sprintf('Bluetooth_%s_%s.mat',station_A, station_B);

daynum=9;
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',daynum,...
    'median', 1,...
    'timeOfDay', nan);

% days: 0--9
interval=300;
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
BT_travel_time=dp.clustering(fileName, queryMeasures, interval);
time=[];
tt=[];
for i=1:length(BT_travel_time.time)
    if(~isnan(BT_travel_time.travel_time(i).median))
        tt=[tt;BT_travel_time.travel_time(i).median];
        time=[time;BT_travel_time.time(i)/3600];
    end
end
section_length=3800/5280;
speed_limit=30;
plot_functions.plot_BT_travel_time_by_time(tt,time,section_length,speed_limit,...
    sprintf('Travel Times from %s to %s on %s',strrep(station_A,'_','@'), strrep(station_B,'_','@'), days{daynum+1}))


interval=1800;
BT_travel_time=dp.clustering(fileName, queryMeasures, interval);
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

