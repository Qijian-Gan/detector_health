%% This script is to read the estStateQueue files
clear
clc
close all

%% Load the estStateQueue file
dp=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
estStateQueue=dp.parse_csv('aimsun_queue_estimated.csv',dp.folderLocation);





