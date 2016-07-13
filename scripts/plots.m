%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
day='Thursday';
load(fullfile(findFolder.outputs,strcat('Clustered_data_',day,'.mat')));

% ID=[{'307505'}; {'307506'};{'307501'}; {'307502'};{'307503'}; {'307507'}];
% ID=[{'307602'}; {'307614'};{'307601'}; {'307613'};{'307607'}; {'307603'};{'307627'}; {'307623'}];
ID=[{'307702'}; {'307706'};{'307714'};{'307722'}; {'307726'};...
    {'307701'}; {'307705'};{'307713'};{'307721'};...
    {'307707'}; {'307703'};{'307715'}; {'307711'};...
    {'307704'}; {'307708'};{'307716'}; {'307724'}];
[tf idx]=ismember(ID,{clustered_data.detectorID}');
data=clustered_data(idx,:);

for i=1: 5 %length (ID)
    figure
    time=data(i).data.time/3600;
    volume=data(i).data.s_volume;
    occ=data(i).data.s_occupancy;
    yyaxis left
    plot(time,volume)
    xlabel('Time (hr)','FontSize',13)
    ylabel('Flow-rate (vph)','FontSize',13)
    hold on
    yyaxis right
    plot(time,occ/3600*100)
    ylabel('Occupancy(%)','FontSize',13)
%     set(gca,'XLim',[6 10])
    title(strcat(day,' traffic profile for detector:  ',ID{i}),'FontSize',13)
end