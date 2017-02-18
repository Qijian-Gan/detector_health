%% This script is to read the IEN configuration files
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileNameNetwork=fullfile(folderLocation,'BEATS_network_file_been_read.mat'); % Network configuration files
fileNameResult=fullfile(folderLocation,'BEATS_simulation_file_been_read.mat'); % Simulation result files

% Get the BEATS network configuration file
if(exist(fileNameNetwork,'file'))
    % If found
    load(fileNameNetwork);
else
    fileReadBEATSNetwork=[]; 
end
% Get the BEATS result configuration file
if(exist(fileNameResult,'file'))
    % If found
    load(fileNameResult);
else
    fileReadBEATSResult=[]; 
end

% Load the BEATS data and get the list of files that are needed to be updated
dp=load_BEATS_network; % With empty input: Default folder ('data\BEATS_simulation')
fileListNetwork=dp.fileListNetwork; % Get the list of network files

% Aimsun
InputFolder=findFolder.aimsunNetwork_data_whole();
dp_network_Aimsun=load_aimsun_network_files(InputFolder); 
if(exist(fullfile(InputFolder,'SectionInf.txt'),'file'))
    sectionData=dp_network_Aimsun.parse_sectionInf_txt('SectionInf.txt');
else
    error('Cannot find the section information file in the folder!')
end

%% Read the network configuration files
numFileNetwork=size(fileListNetwork,1);
tmpList=[];
data=[];
for i=1:numFileNetwork % Loop for each file   
%     if(isempty(fileReadBEATSNetwork) || ~any(strcmp({fileListNetwork(i).name},fileReadBEATSNetwork))) % Empty or Not yet read
        % Parse data
        [tmp_data,type]=dp.parse_BEATS_network_files(fileListNetwork(i).name);
        switch type
            case 'XMLNetwork'
                data.XMLNetwork=tmp_data;
            case 'XMLMapping'
                data.XMLMapping=tmp_data;
            case 'BEATSMapping'
                data.BEATSWithAimsunMapping=tmp_data;
                data.AimsunWithBEATSMapping=dp.transfer_beats_to_aimsun(data.BEATSWithAimsunMapping,sectionData);
        end
        tmpList=[tmpList;{fileListNetwork(i).name}];
%     end
end

if(~isempty(data))
    dp.save_data(data)
end
% Save the files that have been read
fileReadBEATSNetwork=tmpList;
save(fileNameNetwork,'fileReadBEATSNetwork');

%% Read the BEATS simulation output files
% Load the BEATS data and get the list of files that are needed to be updated
dp=load_BEATS_result; % With empty input: Default folder ('data\BEATS_simulation')
fileListResult=dp.fileListResult; % Get the list of result files
numFileResult=size(fileListResult,1);
tmpList=[];
data=[];
for i=1:numFileResult    
    if(isempty(fileReadBEATSResult) || ~any(strcmp({fileListResult(i).name},fileReadBEATSResult))) % Empty or Not yet read
        % Parse data
        tmp_data=dp.parse_BEATS_simulation_results(fileListResult(i).name);
        data=[data;tmp_data];
        tmpList=[tmpList;{fileListResult(i).name}];
    end
end

if(~isempty(data))
    dp.save_data(data)
end
% Save the files that have been read
fileReadBEATSResult=[fileReadBEATSResult;tmpList];
save(fileNameResult,'fileReadBEATSResult');



