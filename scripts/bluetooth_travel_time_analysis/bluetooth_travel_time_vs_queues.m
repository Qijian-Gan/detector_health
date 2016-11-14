clc
clear
close all

load('appStateEst_Weekday.mat')

% Name of the stations
station_A='Huntington_SantaClara';
station_B='Huntington_Gateway';

% Approach detectors between two stations
% Santa Anita, First, Second, Gateway
station_IDs_from_A_to_B=[5083;6081;6082;6083]; 
% Second, First, Santa Anita, Santa Clara
station_IDs_from_B_to_A=[6082;6081;5083;5082];

% Intersection names between two stations
string_from_A_to_B={'Huntington@SantaAnita','Huntington@First','Huntington@Second','Huntington@Gateway'};
string_from_B_to_A={'Huntington@Second','Huntington@First','Huntington@SantaAnita','Huntington@SantaClara'};

% Selections
selected_station=station_IDs_from_A_to_B;
selected_str=string_from_A_to_B;
direction='EB';
select_file=sprintf('Bluetooth_%s_%s.mat',station_A, station_B); % Bluetooth data
plot_start=14;
plot_end=20;

% selected_station=station_IDs_from_B_to_A;
% selected_str=string_from_B_to_A;
% direction='WB';
% select_file=sprintf('Bluetooth_%s_%s.mat',station_B, station_A); % Bluetooth data
% plot_start=6;
% plot_end=10;

from=6*3600; % Starting time
to=22*3600;  % Ending time
interval=300;
% Types: 0--9
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
 
% Data providers
dp_BT=bluetooth_travel_time_provider; % Bluetooth

%% Get weekday data
daynum=8;
queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',daynum,...
    'median', 1,...
    'timeOfDay', [from to]);

BT_travel_time=dp_BT.clustering(select_file, queryMeasures, interval);

time_BT=BT_travel_time.time/3600;
BTdata=[BT_travel_time.travel_time.median]';

time_queue=[];
queue=[];
for i=1:length(selected_station)
    idx=([appStateEst.intersection_id]'==selected_station(i) & ismember({appStateEst.direction}',direction));
    data=appStateEst(idx).decision_making;
    time_queue=[data.time]'/3600;
    left_turn=[];
    through=[];
    right_turn=[];
    for j=1:length(data)
        left_turn=[left_turn;data(j).queue_assessment.left_turn];
        through=[through;data(j).queue_assessment.through];
        right_turn=[right_turn;data(j).queue_assessment.right_turn];
    end

    left_turn(left_turn<0)=0;
    through(through<0)=0;
    right_turn(right_turn<0)=0;
    
    queue=[queue,left_turn+through+right_turn];
end

plot_functions.plot_BT_travel_time_and_occupancy_flow_with_time(time_BT,BTdata,time_queue, queue,selected_str,...
    'Travel Time (Sec)','Total Queued Vehicles (#)', sprintf('BT Travel Time VS Estimated Queue on %s',days{daynum+1}))

figure
idx_BT=(time_BT>=plot_start & time_BT<plot_end);
idx_queue=(time_queue>=plot_start+300/3600 & time_queue<plot_end+300/3600);

for i=1:4
subplot(2,2,i)
scatter(queue(idx_queue,i),BTdata(idx_BT))
xlabel('Queue (per intersection) (#)', 'FontSize', 13)
ylabel('Travel Time (sec)', 'FontSize', 13)
title(sprintf('Time: %d:00--%d:00 At %s',plot_start,plot_end,selected_str{i}), 'FontSize', 13)
end

figure
tot_queue=sum(queue(idx_queue,:),2);
tot_BTdata=BTdata(idx_BT);
scatter(tot_queue,tot_BTdata)
hold on
[b,bint,r,rint,stats] = regress(tot_BTdata,[ones(size(tot_queue)),tot_queue])
correlation=corrcoef(tot_queue,tot_BTdata)
X=(0:1:max(tot_queue)+1);
Y=b(1)+b(2)*X;
h=plot(X,Y,'r');
legend(h,sprintf('TT=%.2f + %.2f Q_{avg} with R^2=%.2f & correlation=%.2f',b(1),b(2),stats(1),correlation(1,2)),'Location','NorthWest');
xlabel('Total Queue (#)', 'FontSize', 13)
ylabel('Travel Time (sec)', 'FontSize', 13)
axis([0 max(tot_queue) 0 max(tot_BTdata)])
title(sprintf('Time: %d:00--%d:00 ',plot_start,plot_end), 'FontSize', 13)
