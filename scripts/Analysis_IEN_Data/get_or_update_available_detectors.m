%% This script is used to get/update all available detectors
clear
clc
close all

% Get the current folder
currentFileLoc=findFolder.IEN_temp();
tmpFiles=dir(fullfile(currentFileLoc,'\device_data'));

fileNames={tmpFiles.name}';
detectorNameArcadia=[];
detectorNameLACO=[];
for i=1:size(fileNames,1)
    tmp=strsplit(fileNames{i,:},'.');
    tmp=tmp{:,1};
    tmp=strsplit(tmp,'_');
    if(~isempty(tmp{:,end}))
        switch tmp{:,end-1}
            case 'Arcadia'
                detectorNameArcadia=[detectorNameArcadia;str2double(tmp{:,end})];
            case 'LACO'
                detectorNameLACO=[detectorNameLACO;str2double(tmp{:,end})];
        end
    end
end

detectorNameArcadia=unique(detectorNameArcadia);
detectorNameLACO=unique(detectorNameLACO);

save('detectorNameArcadia.mat','detectorNameArcadia')
save('detectorNameLACO.mat','detectorNameLACO')