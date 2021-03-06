%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
% load(fullfile(findFolder.temp,'Health_Report_307505.mat'));
% load(fullfile(findFolder.temp,'Processed_data_307505.mat'));
% load(fullfile(findFolder.temp,'Health_Report_608202.mat'));
% load(fullfile(findFolder.temp,'Processed_data_608202.mat'));
detector='608202';
load(fullfile(findFolder.temp,sprintf('Health_Report_%s.mat',detector)));
load(fullfile(findFolder.temp,sprintf('Processed_data_%s.mat',detector)));

days=[processed_data.day]';
[tf idx]=ismember(days,dataAll(:,5));
dataAll=dataAll(idx,:);

% Set day of week
daynum=weekday(days);
idx=(daynum==3);
processed_data=processed_data(idx,:);
dataAll=dataAll(idx,:);

% Select good days
idx=(dataAll(:,end)==1);
processed_data=processed_data(idx,:);
dataAll=dataAll(idx,:);

% Set time of day
startTime=0*3600;
endTime=24*3600;
idx1=(processed_data(1).data.time>=startTime);
idx2=(processed_data(1).data.time<endTime);
idx=(idx1+idx2==2);

data=vertcat(processed_data.data);
flow=vertcat(data.s_volume);
flow=flow(:,idx);
flow=reshape(flow,size(flow,1)*size(flow,2),1);
occ=vertcat(data.s_occupancy)/3600*100;
occ=occ(:,idx);
occ=reshape(occ,size(occ,1)*size(occ,2),1);

figure
scatter(occ,flow)
hold on
% plot(15*ones(size((1:max(flow)))),(1:max(flow)),'--r', 'LineWidth',2)
xlabel('Occupancy (%)','FontSize',13)
ylabel('Flow-rate (vph)','FontSize',13)
% title('Monday traffic profile: Advanced detector','FontSize',13)
% title('Monday traffic profile: Left-turn detector','FontSize',13)
title('Stopbar Detector:608202 & Monday Profile','FontSize',13)
% title(sprintf('Advanced Detector:%s & Monday Profile',detector),'FontSize',13)