%% This script is used to read the detector health reports
clear
clc
close all

% Get the current folder
currentFileLoc=findFolder.temp();
tmpFiles=dir(currentFileLoc);
idx=strmatch('Health_Report',{tmpFiles.name});
fileList=tmpFiles(idx,:);
idx=ismember({fileList.name},{'Health_Report_9901.mat'});
fileList(idx)=[];

DetectorHealthAll=[];

for i=1:size(fileList,1)
    load(fullfile(currentFileLoc,fileList(i).name));
    DetectorHealthAll=[DetectorHealthAll;dataAll];
end
save('DetectorHealthAll.mat','DetectorHealthAll')