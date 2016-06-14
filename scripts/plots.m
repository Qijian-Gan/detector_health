%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
load(fullfile(findFolder.outputs,'Clustered_data.mat'));

ID=[{'608217'}; {'608214'};{'608202'}];
[tf idx]=ismember(ID,{clustered_data.detectorID}');
data=clustered_data(idx,:);

figure
time=data(1).data.time/3600;
volume=data(1).data.s_volume;
occ=data(1).data.s_occupancy;
yyaxis left
plot(time,volume)
xlabel('Time (hr)','FontSize',13)
ylabel('Flow-rate (vph)','FontSize',13)
hold on
yyaxis right
plot(time,occ/3000*100)
ylabel('Occupancy(%)','FontSize',13)

title('Monday traffic profile: Advanced detector','FontSize',13)

figure
time=data(2).data.time/3600;
volume=data(2).data.s_volume;
occ=data(2).data.s_occupancy;
yyaxis left
plot(time,volume)
xlabel('Time (hr)','FontSize',13)
ylabel('Flow-rate (vph)','FontSize',13)
hold on
yyaxis right
plot(time,occ/3000*100)
ylabel('Occupancy(%)','FontSize',13)

title('Monday traffic profile: Left-turn detector','FontSize',13)

figure
time=data(3).data.time/3600;
volume=data(3).data.s_volume;
occ=data(3).data.s_occupancy;
yyaxis left
plot(time,volume)
xlabel('Time (hr)','FontSize',13)
ylabel('Flow-rate (vph)','FontSize',13)
hold on
yyaxis right
plot(time,occ/3000*100)
ylabel('Occupancy(%)','FontSize',13)

title('Monday traffic profile: Through stopline detector','FontSize',13)

