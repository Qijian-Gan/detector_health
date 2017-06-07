%% This script is used to read the detector health reports
clear
clc
close all

% % Get the current folder
% currentFileLoc=findFolder.temp();
% tmpFiles=dir(currentFileLoc);
% idx=strmatch('Health_Report',{tmpFiles.name});
% fileList=tmpFiles(idx,:);
% idx=ismember({fileList.name},{'Health_Report_9901.mat'});
% fileList(idx)=[];
% 
% DetectorHealthAll=[];
% 
% for i=1:size(fileList,1)
%     load(fullfile(currentFileLoc,fileList(i).name));
%     DetectorHealthAll=[DetectorHealthAll;dataAll];
% end
% save('DetectorHealthAll.mat','DetectorHealthAll')

load('DetectorHealthAll.mat')

%% First, plot the distribution of rate of inconsistent data
% Number of error steps
numErrorStep=6;% No data, 0, <=5%, >5% and <=10%, >10% and <=15%, >15%

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

% Select the date
dateUnique=unique(DetectorHealthAll(:,5));
startDate=datenum('2017-1-1');
endDate=datenum('2017-5-27');
dateSelect=dateUnique(dateUnique>=startDate & dateUnique<endDate);
numDate=length(dateSelect);

% Start to perform the analysis
countTableWithSpeed=zeros(numErrorStep,numDate);
countTableWithoutSpeed=zeros(numErrorStep,numDate);


for i=1:numDate
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    countTableWithSpeed(1,i)=numDetector-size(tmpDetectorHealth,1);    
    for j=1:size(tmpDetectorHealth,1)
        if(tmpDetectorHealth(j,11)==0)
            countTableWithSpeed(2,i)=countTableWithSpeed(2,i)+1;
        elseif(tmpDetectorHealth(j,11)>0 && tmpDetectorHealth(j,11)<=5)
            countTableWithSpeed(3,i)=countTableWithSpeed(3,i)+1;
        elseif(tmpDetectorHealth(j,11)>5 && tmpDetectorHealth(j,11)<=10)
            countTableWithSpeed(4,i)=countTableWithSpeed(4,i)+1;
        elseif(tmpDetectorHealth(j,11)>10 && tmpDetectorHealth(j,11)<=15)
            countTableWithSpeed(5,i)=countTableWithSpeed(5,i)+1;       
        else
            countTableWithSpeed(6,i)=countTableWithSpeed(6,i)+1;
        end
    end   
   
    countTableWithoutSpeed(1,i)=numDetector-size(tmpDetectorHealth,1);    
    for j=1:size(tmpDetectorHealth,1)
        if(tmpDetectorHealth(j,12)==0)
            countTableWithoutSpeed(2,i)=countTableWithoutSpeed(2,i)+1;
        elseif(tmpDetectorHealth(j,12)>0 && tmpDetectorHealth(j,12)<=5)
            countTableWithoutSpeed(3,i)=countTableWithoutSpeed(3,i)+1;
        elseif(tmpDetectorHealth(j,12)>5 && tmpDetectorHealth(j,12)<=10)
            countTableWithoutSpeed(4,i)=countTableWithoutSpeed(4,i)+1;
        elseif(tmpDetectorHealth(j,12)>10 && tmpDetectorHealth(j,12)<=15)
            countTableWithoutSpeed(5,i)=countTableWithoutSpeed(5,i)+1;       
        else
            countTableWithoutSpeed(6,i)=countTableWithoutSpeed(6,i)+1;
        end
    end   
end

figure
for i=1:numDate
    hold on
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    hs=scatter(curDate*ones(size(tmpDetectorHealth,1),1),tmpDetectorHealth(:,11),'filled');
    set(hs,'MarkerFaceColor','b');
    alpha(hs,.1);
end

figure
for i=1:numDate
    hold on
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    hs=scatter(curDate*ones(size(tmpDetectorHealth,1),1),tmpDetectorHealth(:,12),'filled');
    set(hs,'MarkerFaceColor','b');
    alpha(hs,.1);
end

figure 
hold on
plot(dateSelect,countTableWithoutSpeed(2,:)/numDetector*100,'--b')
plot(dateSelect,sum(countTableWithoutSpeed(2:3,:))/numDetector*100,'-xc')
plot(dateSelect,sum(countTableWithoutSpeed(2:4,:))/numDetector*100,'-+m')
plot(dateSelect,sum(countTableWithoutSpeed(2:5,:))/numDetector*100,'-.r')
legend('Rate_{Inconsistent}=0%','Rate_{Inconsistent}<=5%',...
    'Rate_{Inconsistent}<=10%','Rate_{Inconsistent}<=15%','Location','SouthEast')
xlabel('Date','FontSize',20)
ylabel('Percentage of satisfied detectors','FontSize',20)
title('Inconsistency check between volume and occupancy','FontSize',15)
h=get(gca,'XTick');
hDateTime= datetime(h,'ConvertFrom','datenum');
set(gca,'XTickLabel',cellstr(hDateTime))
set(gca,'XTickLabelRotation',20);
grid on
set(gca, 'YLim',[0 100])
set(findobj('type','axes'),'fontsize',13)

figure 
hold on
plot(dateSelect,countTableWithSpeed(2,:)/numDetector*100,'--b')
plot(dateSelect,sum(countTableWithSpeed(2:3,:))/numDetector*100,'-xc')
plot(dateSelect,sum(countTableWithSpeed(2:4,:))/numDetector*100,'-+m')
plot(dateSelect,sum(countTableWithSpeed(2:5,:))/numDetector*100,'-.r')
legend('Rate_{Inconsistent}=0%','Rate_{Inconsistent}<=5%',...
    'Rate_{Inconsistent}<=10%','Rate_{Inconsistent}<=15%','Location','SouthEast')
xlabel('Date','FontSize',20)
ylabel('Percentage of satisfied detectors','FontSize',20)
title('Inconsistency check among volume, speed and occupancy','FontSize',15)
h=get(gca,'XTick');
hDateTime= datetime(h,'ConvertFrom','datenum');
set(gca,'XTickLabel',cellstr(hDateTime))
set(gca,'XTickLabelRotation',20);
grid on
set(gca, 'YLim',[0 100])
set(findobj('type','axes'),'fontsize',13)

