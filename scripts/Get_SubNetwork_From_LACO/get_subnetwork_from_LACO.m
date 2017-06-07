%% This script is used to get the subnetwork from LACO
clear
clc
close all

% 
% % Get the current folder
% currentFileLoc=fullfile(findFolder.IEN_temp(),'\device_inventory');
% tmpFiles=dir(currentFileLoc);
% idx=strmatch('Detector_Inv_201704_LACO',{tmpFiles.name});
% fileList=tmpFiles(idx,:);
% 
% DetInvAll=[];
% parfor i=1:size(fileList,1)
%     [data]=load_DevInv_Data(fullfile(currentFileLoc,fileList(i).name));
%     DetInvAll=[DetInvAll;data];
% end
% 
% IntID=str2double({DetInvAll.AssociatedIntersectionID}');
% [B,I]=sort(IntID);
% DetInvAllSort=DetInvAll(I,:);
% 
% save('DetInvAllSort.mat','DetInvAllSort');

NW=[34.177850,-118.177816];
SW=[34.102176,-118.177816];
NE=[34.177850,-117.924289];
SE=[34.102176,-117.924289];

load('DetInvAllSort.mat');
IntAll=[{DetInvAllSort.AssociatedIntersectionID}',{DetInvAllSort.RoadName}',{DetInvAllSort.CrossStreet}',{DetInvAllSort.Latitude}',...
    {DetInvAllSort.Longitude}'];
[~,idx]=unique(IntAll(:,1));
IntAllUnique=IntAll(idx,:);
LatLongPair=str2double(IntAllUnique(:,4:5))/1000000;



IntAllUniqueSubnetwork=[];
LatLongPairSubnetwork=[];
for i=1:size(LatLongPair,1)
    if(LatLongPair(i,1)>SW(1)&&LatLongPair(i,1)<NW(1) &&...
            LatLongPair(i,2)>NW(2)&& LatLongPair(i,2)<NE(2))
        IntAllUniqueSubnetwork=[IntAllUniqueSubnetwork;IntAllUnique(i,:)];
        LatLongPairSubnetwork=[LatLongPairSubnetwork;LatLongPair(i,:)];
    end    
end

save('IntAllUniqueSubnetwork_LACO.mat','IntAllUniqueSubnetwork');


% % Get the current folder
% currentFileLoc=fullfile(findFolder.IEN_temp(),'\intersection_signal_inventory');
% tmpFiles=dir(currentFileLoc);
% idx=strmatch('Int_Sig_Inv_201705_LACO',{tmpFiles.name});
% fileList=tmpFiles(idx,:);
% 
% SigInvAll=[];
% parfor i=1:size(fileList,1)
%     [data]=load_SigInv_Data(fullfile(currentFileLoc,fileList(i).name));
%     SigInvAll=[SigInvAll;data];
% end
% 
% IntID=str2double({SigInvAll.DeviceID}');
% [B,I]=sort(IntID);
% SigInvAllSort=SigInvAll(I,:);
% 
% save('SigInvAllSort.mat','SigInvAllSort');

NW=[34.177850,-118.177816];
SW=[34.102176,-118.177816];
NE=[34.177850,-117.924289];
SE=[34.102176,-117.924289];

load('SigInvAllSort.mat');
SigAll=[{SigInvAllSort.DeviceID}',{SigInvAllSort.MainStreet}',{SigInvAllSort.CrossStreet}',{SigInvAllSort.Latitude}',...
    {SigInvAllSort.Longitude}'];
[~,idx]=unique(SigAll(:,1));
SigAllUnique=SigAll(idx,:);
LatLongPair=str2double(SigAllUnique(:,4:5))/1000000;



SigAllUniqueSubnetwork=[];
for i=1:size(LatLongPair,1)
    if(LatLongPair(i,1)>SW(1)&&LatLongPair(i,1)<NW(1) &&...
            LatLongPair(i,2)>NW(2)&& LatLongPair(i,2)<NE(2))
        SigAllUniqueSubnetwork=[SigAllUniqueSubnetwork;SigAllUnique(i,:)];
    end    
end

save('SigAllUniqueSubnetwork_LACO.mat','SigAllUniqueSubnetwork');



