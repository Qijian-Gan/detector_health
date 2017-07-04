%% This script is used to get detector ID and Type
clear
clc
close all


%% Load configuration file
config=load_config('Arcadia_detector_config.xlsx');
config.detectorConfig=config.detector_property('Detector_Properties');

detectorType={config.detectorConfig.Movement}';
detectorTypeIdx=zeros(length(detectorType),1);
for i=1:length(detectorType)
    detectorTypeIdx(i) =~isempty(findstr('Advanced', detectorType{i,:}));
end

detectorIDAndType=[[config.detectorConfig.IntersectionID]'*100+[config.detectorConfig.SensorID]',...
    detectorTypeIdx];

save('detectorIDAndType.mat','detectorIDAndType')
