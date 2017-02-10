%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

intersectionID=[5105,5072,5141];
numOfDetectors=[12,12,10];

intersectionIDs=[];
for i=1:length(intersectionID)
    intersectionIDs=[intersectionIDs;intersectionID(i)*ones(numOfDetectors(i),1)];
end
detectorIDs=[14,2,6,13,1,5,8,12,7,4,11,3,...
    15,4,8,3,7,13,2,6,14,9,1,5,...
    6,5,2,1,8,27,7,4,23,3];

folderLocation=findFolder.temp();
outputLocation=findFolder.reports();
for i=1:length(detectorIDs)
    i
    if(detectorIDs(i)<10)
        fileName=(sprintf('Health_Report_%d0%d.mat',intersectionIDs(i),detectorIDs(i)));
        detectorID=(sprintf('%d0%d',intersectionIDs(i),detectorIDs(i)));
    else
        fileName=(sprintf('Health_Report_%d%d.mat',intersectionIDs(i),detectorIDs(i)));
        detectorID=(sprintf('%d%d',intersectionIDs(i),detectorIDs(i)));
    end
    
    if(exist(fullfile(folderLocation,fileName),'file'))
        load(fullfile(folderLocation,fileName))
        
        header ={'DetectorID', 'Year', 'Month', 'Day','Date Number(Matlab)', 'Missing Rate', 'Inconsistency Rate',...
            'Number of Break Points', 'Reporting Zero Values (1/0)','Health'};
        xlswrite(fullfile(outputLocation,'Detector_Health_Sample_Arcadia.xlsx'), header, detectorID)
        xlswrite(fullfile(outputLocation,'Detector_Health_Sample_Arcadia.xlsx'), dataAll, detectorID,'A2')
    end
end


