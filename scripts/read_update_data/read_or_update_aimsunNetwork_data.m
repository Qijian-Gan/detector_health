%% This script is to read the aimsun network data files
clear
clc
close all

%% Load the network information file
dp=load_aimsun_network_files; % With empty input: Default folder ('data/aimsun_simSigData')

junctionData=dp.parse_junctionInf_txt('JunctionInf.txt');
sectionData=dp.parse_sectionInf_txt('SectionInf.txt');

recAimsunNet=reconstruct_aimsun_network(junctionData,sectionData,nan);
recAimsunNet.networkData=recAimsunNet.reconstruction();




