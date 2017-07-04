%% This script is to read the IEN configuration files
clear
clc
close all

%% Load the list of files to be updated
% Load the list of files that have been read if it exists (saved in the 'Obj' folder)
folderLocation=findFolder.objects;
fileNameOrg=fullfile(folderLocation,'IEN_organization_file_been_read.mat'); % Organization configuration files
fileNameData=fullfile(folderLocation,'IEN_ienData_file_been_read.mat'); % IEN data files

% Get the organization configuration file
if(exist(fileNameOrg,'file'))
    % If found
    load(fileNameOrg);
else
    fileReadOrg=[];
end
% Get the detector configuration file
if(exist(fileNameData,'file'))
    % If found
    load(fileNameData);
else
    fileReadData=[];
end

% Load the IEN configuration data and get the list of files that are needed to be updated

% currentOrgLoc='D:\BOX\Box Sync\IEN_Data';
% currentDataLoc='D:\BOX\Box Sync\IEN_Data';

currentOrgLoc='D:\BOX\Box Sync\IEN_Data';
currentDataLoc='D:\BOX\IEN_Data';
movedFileLoc='D:\BOX\IEN_Data_Read';

% currentDataLoc='D:\BOX\IEN_Data_Unprocessed';
% movedFileLoc='D:\BOX\IEN_Data_Read_Test';

dp=load_IEN_configuration(currentOrgLoc,currentDataLoc); % With empty input: Default folder ('data/IEN_feed')
fileListOrg=dp.fileListOrganization; % Get the list of organization configuration files
fileListData=dp.fileListData; % Get the list of IEN data files

%% Read the organization configuration files
numFileOrg=size(fileListOrg,1);
tmpList=[];
data=[];
for i=1:numFileOrg % Loop for each file
    if(isempty(fileReadOrg) || ~any(strcmp({fileListOrg(i).name},fileReadOrg))) % Empty or Not yet read
        disp(fileListOrg(i).name)
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

%% Read the detector files
% First categorize the files by year-month
[fileNameByYearMonth]=load_IEN_configuration.categorize_file_name_by_year_month({fileListData.name}');
numOfFile=120;

% Start parallel computing
close all
delete(gcp('nocreate'));
parpool;

% Check whether the subnetwork of LACO is used or not
if(exist('IntAllUniqueSubnetwork_LACO.mat','file'))
    load('IntAllUniqueSubnetwork_LACO.mat'); % Variable: IntAllUniqueSubnetwork
else
    IntAllUniqueSubnetwork=[];
end
if(exist('SigAllUniqueSubnetwork_LACO.mat','file'))
    load('SigAllUniqueSubnetwork_LACO.mat'); % Variable: SigAllUniqueSubnetwork
else
    SigAllUniqueSubnetwork=[];
end

for t=1:size(fileNameByYearMonth,1) 
    %% loop for each year-month
    
    % Get the list of files by year and month
    strYearMonth=fileNameByYearMonth(t).YearMonth;
    fileListData=fileNameByYearMonth(t).Files;

    %% Start to process and update the device data
    numFileData=size(fileListData,1);    
  
    i=1;
    while (i<=numFileData)
        % Reset all variables
        DevInv=[];
        DevData=[];
        SigInv=[];
        SigData=[];
        PlanPhase=[];
        LastCyclePhase=[];
        tmpfileReadData=[];
        
        tic        
        % Parse data
        parfor j=i:min(i+numOfFile-1,numFileData)
            if(isempty(fileReadData) || ~any(strcmp(fileListData(j,:),fileReadData))) % Empty or Not yet read
                
                disp(fileListData{j,:})
                
                [tmpDevInv,tmpDevData,tmpSigInv,tmpSigData,tmpPlanPhase,tmpLastCyclePhase]=...
                getString(fullfile(dp.folderLocationData,fileListData{j,:}));
                
                DevInv=[DevInv;tmpDevInv];
                DevData=[DevData;tmpDevData];
                SigInv=[SigInv;tmpSigInv];
                SigData=[SigData;tmpSigData];
                PlanPhase=[PlanPhase;tmpPlanPhase];
                LastCyclePhase=[LastCyclePhase;tmpLastCyclePhase];
                tmpfileReadData=[tmpfileReadData;fileListData(j,:)];
            end
        end
        toc 
        i=min(i+numOfFile-1,numFileData)+1;
        
        tic
        % Save device inventory
        if(~isempty(DevInv))
            disp('Saving/Updating device inventory!')
            dp.save_data_by_year_month(DevInv,'DevInv',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        clear DevInv
        
        % Save device data
        if(~isempty(DevData))
            disp('Saving/Updating device data!')
            dp.save_data_by_year_month(DevData,'DevData',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        clear DevData
        
        % Save signal inventory
        if(~isempty(SigInv))
            disp('Saving/Updating intersection signal inventory!')
            dp.save_data_by_year_month(SigInv,'SigInv',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        clear SigInv
        
        % Save signal data
        if(~isempty(SigData))
            disp('Saving/Updating intersection signal data!')
            dp.save_data_by_year_month(SigData,'SigData',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        clear SigData
        
        % Save planned phases
        if(~isempty(PlanPhase))
            disp('Saving/Updating signal planned phase!')
            dp.save_data_by_year_month(PlanPhase,'PlanPhase',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        clear PlanPhase
        
        % Save last-cycle phases
        if(~isempty(LastCyclePhase))
            disp('Saving/Updating signal last-cycle phase!')
            dp.save_data_by_year_month(LastCyclePhase,'LastCyclePhase',strYearMonth,IntAllUniqueSubnetwork,SigAllUniqueSubnetwork)
        end
        toc
        clear LastCyclePhase
        
        % Save and move the files that have been read
        fileReadData=[fileReadData;tmpfileReadData];
        save(fileNameData,'fileReadData');
        for k=1:size(tmpfileReadData,1)
            movefile(fullfile(currentDataLoc,tmpfileReadData{k,:}),movedFileLoc);
        end
        
        
    end
end

% End parallel computing
delete(gcp);



