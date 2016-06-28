%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all


%% Extract clustered data to aimsun
dp=extract_clustered_data;

for i=1:7
    dp.extract_to_aimsun_by_day_of_week(i);
end
