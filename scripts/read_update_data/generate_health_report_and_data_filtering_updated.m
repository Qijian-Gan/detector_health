%% This script is to run the detector health report for the City of Arcadia with updated criteria
clear
clc
close all

%% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileName=fullfile(folderLocation,'Detector_file_been_read_updated_criteria.mat');

if(exist(fileName,'file'))
    % If found
    load(fileName);
else
    fileRead=[]; % This is the variable save in the mat file 'Detector_file_been_read_updated_criteria.mat'
end

%% Load the detector data and get the list of files that is needed to be updated
dp=load_detector_data('K:\Arcadia_data\2014_All');
% dp=load_detector_data('K:\Arcadia_data\2015_All');
% dp=load_detector_data('K:\Arcadia_data\2016_All');
% dp=load_detector_data('K:\Arcadia_data\2017_All');
% dp=load_detector_data('K:\Arcadia_data\2017');
% dp=load_detector_data; % With empty input: Default folder ('data')

fileList=dp.obtain_file_list(dp.folderLocation); % Get the list of detector files

%% Define the parameters
    %'MissingRate',                  nan,... % Insufficient data rate
    %'ExcessiveRate',                nan,... % Excessive data rate
    %'MaxZeroValues',                nan,... % Card Off: maximun length of zeros in hours
    %'HighValueRate',                nan,... % High value rate
    %'ConstantOrNot',                nan,... % Constant values (not zeros): 0/1 (No/Yes)
    %'InconsisRateWithSpeed',        nan,... % Inconsistent data rate with speed included
    %'InconsisRateWithoutSpeed',     nan,... % Inconsistent data rate without speed
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

%% Run the health analysis
numFile=size(fileList,1);

health_report=[];
tmpList=[];
for i=1:numFile
    i
    if(isempty(fileRead) || ~any(strcmp({fileList(i).name},fileRead))) % Empty or Not yet read
        
        % Parse data
        data=dp.parse_csv(fileList(i).name, dp.folderLocation);
        
        % Run health analysis
        hc=health_analysis_update_criteria(data,params);
        hc.measures=hc.health_criteria;
        
        health_report=[health_report;hc.measures];
        
        % Only save the file name when it is a whole week data
        % This is designed for Arcadia's system
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
            'threshold', nan,...
            'imputation', struct(... % Settings for imputation
                'k', 5,... % A span of 5
                'medianValue', 0),... % Not using median values
            'smoothing', struct(... % Settings for smoothing: smooth
                'span', 0.02,... % A span of 0.02 percents of the data length
                'method','moving',... % Simple moving averages
                'degree', nan));
        
        % Data filtering and smoothing
        folderLocationFiltering=findFolder.temp; % Get the folder to save the filtered data
        data_filtering_updated_criteria(folderLocationFiltering,params_filtering,hc.data,hc.measures);
        
    end
end

% Update and save the reports to the "output" folder
save_health_report(health_report);

% Save the files that have been read
fileRead=[fileRead;tmpList];
save(fileName,'fileRead');



