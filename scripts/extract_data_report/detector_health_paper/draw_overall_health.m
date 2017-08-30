%% This script is used to draw missing data
clear
clc
close all

load('DetectorHealthAll.mat')

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

% Select the date
dateUnique=unique(DetectorHealthAll(:,5));
startDate=datenum('2015-7-1');
endDate=datenum('2017-6-30');
dateSelect=dateUnique(dateUnique>=startDate & dateUnique<endDate);
numDate=length(dateSelect);

numState=7;

countTable=zeros(numState,numDate);
for i=1:numDate
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    countTable(1,i)=numDetector-size(tmpDetectorHealth,1);     
    countTable(2,i)=sum(tmpDetectorHealth(:,6)>5); % Missing data
    countTable(3,i)=sum(tmpDetectorHealth(:,8)>4); % Zero values
    countTable(4,i)=sum(tmpDetectorHealth(:,9)>5); % High values
    countTable(5,i)=sum(tmpDetectorHealth(:,10)==1);% Constant values
    countTable(6,i)=sum(tmpDetectorHealth(:,12)>5);% Inconsistent data
    countTable(7,i)=sum(tmpDetectorHealth(:,13)==1);
end

% width=0.3;
% b = bar3(countTable(1:6,500:end)',width,'stacked');
% legend('No Data','Insufficient Data','Card Off','High Value','Constant value','Inconsistent Data')

figure('Position',[9 374 1269 528]) 
plot(dateSelect,countTable(7,:)/numDetector*100,'-+r')
xlabel('Date','FontSize',25)
ylabel('Percentage','FontSize',25)
set(gca, 'XLim',[startDate-5 endDate+5])
h=get(gca,'XTick');
hDateTime= datestr(h,'mm-dd-yyyy');
% hDateTime= datetime(h,'ConvertFrom','datenum');
set(gca,'XTickLabel',cellstr(hDateTime))
set(gca,'XTickLabelRotation',20);
grid on
set(gca, 'YLim',[0 100])
set(gca,'YTick',[0:5:100])
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')


