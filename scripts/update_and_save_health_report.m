%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileName=fullfile(folderLocation,'Detector_file_been_read.mat');

if(exist(fileName,'file'))
    load(fileName);
else
    fileRead=[];
end

% Load the detector data and get the list of files that is needed to be updated
dp=load_detector_data;
fileList=dp.obtain_file_list(dp.folderLocation);

%% Run the health analysis
% Define the parameters
params=struct(...
    'timeInterval',             300,...      % Five-minute data, default
    'threshold',                400,...      % Threshold for break points: absolute difference in vph
    'criteria_good',            struct(...   % Criteria to say a detector is good
    'MissingRate',         5,...
    'InconsistencyRate',   10,...
    'BreakPoints',         10));

% Health analysis
numFile=size(fileList,1);
health_report=struct(health_analysis.metrics_profile);
health_report(1)=[];

tmpList=[];
for i=1:numFile
    if(isempty(fileRead) || ~any(strcmp({fileList(i).name},fileRead))) % Empty or Not yet read
        
        % Parse data
        data=dp.parse_csv(fileList(i).name, dp.folderLocation);
        
        % Run health analysis
        hc=health_analysis(data,params);
        hc.measures=hc.health_criteria;
        
        health_report(end+1:end+length(hc.measures))=hc.measures;
        
        tmpList=[tmpList;{fileList(i).name}];
    end
end

% Update and save the reports to the "output" folder
save_health_report(health_report);

fileRead=[fileRead;tmpList];
save(fileName,'fileRead');



