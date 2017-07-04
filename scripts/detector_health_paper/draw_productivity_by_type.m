%% This script is used to draw missing data
clear
clc
close all

load('DetectorHealthAll.mat')
load('detectorIDAndType.mat')

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

detectorUniqueStopbar=[];
detectorUniqueAdvanced=[];
count=0;
for i=1:length(detectorUnique)
    idx=(detectorIDAndType(:,1)==detectorUnique(i));
    if(sum(idx))
        if(detectorIDAndType(idx,2)==0)
            detectorUniqueStopbar=[detectorUniqueStopbar;[detectorUnique(i),detectorIDAndType(idx,2)]];
        else
            detectorUniqueAdvanced=[detectorUniqueAdvanced;[detectorUnique(i),detectorIDAndType(idx,2)]];
        end
    end
end

plot_productivity(DetectorHealthAll,detectorUnique,'All Detectors')
plot_productivity(DetectorHealthAll,detectorUniqueStopbar,'Stopbar Detectors')
plot_productivity(DetectorHealthAll,detectorUniqueAdvanced,'Advanced Detectors')