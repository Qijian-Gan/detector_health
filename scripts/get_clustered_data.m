%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the detector config file
config=load_config('arterial_system_detector_config.xlsx', 'Arcadia');


%% Extract the clustered data for given settings
ptr=data_clustering; % Create the object with default file locations

queryMeasures=struct(...
        'year',     nan,...
        'month',    nan,...
        'dayOfWeek',2,...
        'timeOfDay', 0);

numDetector=size(config.detectorConfig,1);

clustered_data=[];
for i=1:numDetector
    if(config.detectorConfig(i).SensorID<10)
        detectorID={sprintf('%d0%d',config.detectorConfig(i).IntersectionID,config.detectorConfig(i).SensorID)};
    else
        detectorID={sprintf('%d%d',config.detectorConfig(i).IntersectionID,config.detectorConfig(i).SensorID)};
    end
    tmp_data=ptr.clustering(detectorID,queryMeasures);
    
    clustered_data=[clustered_data;struct(...
        'detectorID',detectorID,...
        'config',config.detectorConfig(i),...
        'data',tmp_data.data,...
        'status',tmp_data.status)];
end

save(fullfile(ptr.outputFolderLocation,'Clustered_data.mat'),'clustered_data')


