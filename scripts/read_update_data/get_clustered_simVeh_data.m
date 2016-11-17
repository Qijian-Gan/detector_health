%% This script is to run the clustered simVeh data (Testing)
clear
clc
close all

ptr=simVehicle_data_provider; % Create the object with default file locations

startTime=8*3600;
endTime=8*3600+5*60;
timePeriod=[startTime endTime];

distance=50;

listOfSections=[338 400 403 458 461];

data=ptr.get_statistics_for_section_time(listOfSections, timePeriod, distance);
