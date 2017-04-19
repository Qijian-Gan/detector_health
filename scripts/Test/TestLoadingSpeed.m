clc
clear

dp=load_IEN_configuration();

importFolder=fullfile(dp.outputFolderLocation,'\device_data');
outputFolder=fullfile(dp.outputFolderLocation,'\test');
tmpOrganization=dir(importFolder);
tmpOrganization=tmpOrganization(3:end,:);

for i=1:size(tmpOrganization,1)
    load(fullfile(importFolder,tmpOrganization(i).name));
    save(fullfile(outputFolder,tmpOrganization(i).name),'dataDevData','-v6');
end