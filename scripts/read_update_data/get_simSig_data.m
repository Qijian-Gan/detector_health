%% This script is to run the clustered simVeh data (Testing)
clear
clc
close all

ptr=simSignal_data_provider; % Create the object with default file locations

timestamp=7.5*3600+7;

listOfJunctions=[3329 3341 3344 3369 3370];

data=ptr.get_signal_phasing_for_junction_time(listOfJunctions, timestamp);
