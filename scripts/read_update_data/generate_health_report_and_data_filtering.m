%% This script is to run the detector health report for the City of Arcadia
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileName=fullfile(folderLocation,'Detector_file_been_read.mat');

if(exist(fileName,'file'))
    % If found
    load(fileName);
else
    fileRead=[]; % This is the variable save in the mat file 'Detector_file_been_read.mat'
end

% Load the detector data and get the list of files that is needed to be updated
% dp=load_detector_data('D:\I210_Arcadia\2016');
dp=load_detector_data; % With empty input: Default folder ('data')
fileList=dp.obtain_file_list(dp.folderLocation); % Get the list of detector files

%% Run the health analysis
% Define the parameters
params=struct(...
    'timeInterval',             300,...      % Five-minute data, default
    'threshold',                200,...      % Threshold for break points: difference in percentage
    'criteria_good',            struct(...   % Criteria to say a detector is good
        'MissingRate',         5,...  % Percentage
        'InconsistencyRate',   15,... % Percentage
        'BreakPoints',         40));  % # of break points

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
        
        % Only save the file name when it is a whole week data
        numDetector=length(unique([hc.measures.DetectorID]'));
        numID_and_Date=size(unique([[hc.measures.DetectorID]',[hc.measures.DateNum]'],'rows'),1);
        numDate=numID_and_Date/numDetector;
        if(numDate==7)
            tmpList=[tmpList;{fileList(i).name}];
        end
        
        % Run data imputation and smoothing analysis
        % Settings
        params_filtering=struct(...
            'interval', hc.interval,...
            'threshold', hc.threshold,...
            'imputation', struct(... % Settings for imputation
                'k', 5,... % A span of 5
                'medianValue', false),... % Not using median values
            'smoothing', struct(... % Settings for smoothing: smooth
                'span', 0.02,... % A span of 0.02 percents of the data length
                'method','moving',... % Simple moving averages
                'degree', nan));
        
        % Data filtering and smoothing
        folderLocationFiltering=findFolder.temp; % Get the folder to save the filtered data
        data_filtering(folderLocationFiltering,params_filtering,hc.data,hc.measures);
        
    end
end

% Update and save the reports to the "output" folder
save_health_report(health_report);

% Save the files that have been read
fileRead=[fileRead;tmpList];
save(fileName,'fileRead');



