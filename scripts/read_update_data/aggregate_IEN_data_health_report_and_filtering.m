%% This script is to run the detector health report for the City of Arcadia with updated criteria
clear
clc
close all

%% Load configuration file
close all

%% Load configuration file
% Arcadia
configArcadia=load_config('Arcadia_detector_config.xlsx');
configArcadia.detectorConfig=configArcadia.detector_property('Detector_Properties');

DetectorIDAndLane=[[configArcadia.detectorConfig.IntersectionID]'*100+[configArcadia.detectorConfig.SensorID]',...
    [configArcadia.detectorConfig.NumberOfLanes]',5*ones(size([configArcadia.detectorConfig.IntersectionID]'))];

% LACO
configLACO=load_config_LACO('LACO_detector_information_20170814.xlsx');
configLACO.detectorConfig=configLACO.detector_property('Detector_Properties');

DetectorIDAndLane=[DetectorIDAndLane;[configLACO.detectorConfig.IntersectionID]'*10000+...
    [configLACO.detectorConfig.SensorID]',[configLACO.detectorConfig.NumberOfLanes]',...
    29*ones(size([configLACO.detectorConfig.IntersectionID]'))];

DetectorIDAndLane=unique(DetectorIDAndLane,'rows');
%% Define the parameters
params=struct(...
    'timeInterval',             300,...      % Five-minute data, default
    'saturationFlow',           1200,...     % Saturation flow per lane
    'criteria_good',            struct(...   % Criteria to say a detector is good
    'MissingRate',              5,...  % Percentage
    'ExcessiveRate',            5,...  % Percentage
    'MaxZeroValues',            4,...  % Hours
    'HighValueRate',            5,...  % Percentage
    'InconsisRateWithSpeed',    15,... % Percentage
    'InconsisRateWithoutSpeed', 5 ...  % Percentage
    ));

%% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileName=fullfile(folderLocation,'IEN_detector_file_been_read_updated_criteria.mat');

if(exist(fileName,'file'))
    % If found
    load(fileName);
else
    fileRead=[]; % This is the variable save in the mat file 'IEN_detector_file_been_read_updated_criteria.mat'
end

%% Run the health analysis
InputFolder=fullfile(findFolder.IEN_temp(),'device_data_aggregated');
tmpData=dir(InputFolder);
idx=strmatch('Data_By_300Second',{tmpData.name});
fileList=tmpData(idx,:);

numFile=size(fileList,1);

health_report=[];
tmpList=[];
for i=1:numFile
    disp(fileList(i).name)
    
    % Parse data
    load(fullfile(InputFolder,fileList(i).name));
    
    str=strsplit(fileList(i).name,'_');
    organization=str{1,4};
    % Run health analysis
    for j=1:size(aggregatedData,1)
        fileNameDate=strcat(fileList(i).name,aggregatedData(j).Date);
        if(isempty(fileRead) || ~any(strcmp({fileList(i).name},fileRead))) % Empty or Not yet read
            hc=health_analysis_update_criteria(aggregatedData(j).Data',params,DetectorIDAndLane);
            hc.measures=hc.health_criteria;
            
            health_report=[health_report;hc.measures];
            
            % Run data imputation and smoothing analysis
            % Settings
            params_filtering=struct(...
                'interval', hc.interval,...
                'threshold', nan,...
                'imputation', struct(... % Settings for imputation
                'k', 5,... % A span of 5
                'medianValue', 0),... % Not using median values
                'smoothing', struct(... % Settings for smoothing: smooth
                'span', 0.02,... % A span of 0.02 percents of the data length
                'method','moving',... % Simple moving averages
                'degree', nan));
            
            % Data filtering and smoothing
            folderLocationFiltering=InputFolder; % Get the folder to save the filtered data
            data_filtering_updated_criteria(folderLocationFiltering,params_filtering,hc.data,hc.measures,organization);
            
            tmpList=[tmpList;{fileNameDate}];
        end
    end
end

% Update and save the reports to the "output" folder
save_health_report(health_report,InputFolder,'IEN');

% Save the files that have been read
fileRead=[fileRead;tmpList];
save(fileName,'fileRead');
