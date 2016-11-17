%% This script is to read the simulation signal data files
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileName=fullfile(folderLocation,'simSignal_file_have_been_read.mat');

if(exist(fileName,'file'))
    % If found
    load(fileName);
else
    fileRead=[]; % This is the variable save in the mat file 'simSignal_file_have_been_read.mat'
end

% Load the simSignal data and get the list of files that is needed to be updated
dp=load_simSignal_data; % With empty input: Default folder ('data/aimsun_simSigData')
fileList=dp.fileList; % Get the list of detector files

%% Read the data
numFile=size(fileList,1);

tmpList=[];
data=[];
for i=1:numFile
    i
    if(isempty(fileRead) || ~any(strcmp({fileList(i).name},fileRead))) % Empty or Not yet read
        % Parse data
        tmp_data=dp.parse_txt(fileList(i).name,dp.folderLocation);
        data=[data;tmp_data];
        tmpList=[tmpList;{fileList(i).name}];
    end
end
if(~isempty(data))
    dp.save_data(data);
end

% Save the files that have been read
fileRead=[fileRead;tmpList];
save(fileName,'fileRead');



