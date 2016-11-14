%% This script is to extract the clustered data to a model
clear
clc
close all


%% Extract clustered data to aimsun
dp=extract_clustered_data;

for i=1:10
    dp.extract_to_aimsun_by_day_of_week(i);
end
