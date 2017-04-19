clc
clear
% 
% close all
% delete(gcp('nocreate'));
% parpool;

fileLocation=findFolder.IEN_data();
fileName='ienData-2017-04-11-125701.txt';
a=[];

[DevInv,DevData,IntSigInv,IntSigData,PlanPhase,LastCyclePhase]=getString(fullfile(fileLocation,fileName));

