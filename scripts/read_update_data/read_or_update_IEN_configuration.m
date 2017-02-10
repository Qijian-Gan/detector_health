%% This script is to read the IEN configuration files
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileNameOrg=fullfile(folderLocation,'organization_file_been_read.mat'); % Organization configuration files
fileNameDet=fullfile(folderLocation,'detectorConfig_file_been_read.mat'); % Detector configuration files

% Get the organization configuration file
if(exist(fileNameOrg,'file'))
    % If found
    load(fileNameOrg);
else
    fileReadOrg=[]; 
end
% Get the detector configuration file
if(exist(fileNameDet,'file'))
    % If found
    load(fileNameDet);
else
    fileReadDet=[]; 
end

% Load the IEN configuration data and get the list of files that are needed to be updated
dp=load_IEN_configuration; % With empty input: Default folder ('data/IEN_feed')
fileListOrg=dp.fileListOrganization; % Get the list of organization configuration files
fileListDet=dp.fileListDetector; % Get the list of detector configuration files

%% Read the organization configuration files
numFileOrg=size(fileListOrg,1);
tmpList=[];
data=[];
for i=1:numFileOrg % Loop for each file   
    if(isempty(fileReadOrg) || ~any(strcmp({fileListOrg(i).name},fileReadOrg))) % Empty or Not yet read
        % Parse data
        tmp_data=dp.parse_txt_organization(fileListOrg(i).name);
        data=[data;tmp_data];
        tmpList=[tmpList;{fileListOrg(i).name}];
    end
end

if(~isempty(data))
    dp.save_data(data,'Organization')
end
% Save the files that have been read
fileReadOrg=[fileReadOrg;tmpList];
save(fileNameOrg,'fileReadOrg');

%% Read the detector configuration files
numFileDet=size(fileListDet,1);
tmpList=[];
data=[];
for i=1:numFileDet    
    if(isempty(fileReadDet) || ~any(strcmp({fileListDet(i).name},fileReadDet))) % Empty or Not yet read
        % Parse data
        tmp_data=dp.parse_txt_detector(fileListDet(i).name);
        data=[data;tmp_data];
        tmpList=[tmpList;{fileListDet(i).name}];
    end
end

if(~isempty(data))
    dp.save_data(data,'Detector')
end
% Save the files that have been read
fileReadDet=[fileReadDet;tmpList];
save(fileNameDet,'fileReadDet');



