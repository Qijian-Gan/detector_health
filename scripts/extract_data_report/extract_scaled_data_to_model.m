%% This script is to extract the scaled data to a model
clear
clc
close all


%% Extract clustered data to aimsun
dp=extract_clustered_data;

fileName='Scaled_data_test.mat';
interval=300; % 5 minutes
%i=1: 10 {'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
for i=1:10
    dp.extract_scaled_approach_flow_to_aimsun_by_day_of_week(fileName,i,interval,'Approach');
    dp.extract_scaled_approach_flow_to_aimsun_by_day_of_week(fileName,i,interval,'Left Turn');
    dp.extract_scaled_approach_flow_to_aimsun_by_day_of_week(fileName,i,interval,'Through');
    dp.extract_scaled_approach_flow_to_aimsun_by_day_of_week(fileName,i,interval,'Right Turn');
end
