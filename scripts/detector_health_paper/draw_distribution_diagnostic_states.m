%% This script is used to draw missing data
clear
clc
close all

load('DetectorHealthAll.mat')

% Number of error steps
numErrorStep=6;% No data, 0, <=5%, >5% and <=10%, >10% and <=15%, >15%

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

% Select the date
dateUnique=unique(DetectorHealthAll(:,5));
startDate=datenum('2015-7-1');
endDate=datenum('2017-5-31');
dateSelect=dateUnique(dateUnique>=startDate & dateUnique<endDate);
numDate=length(dateSelect);

% Check the missing data;
colID=6; 
threshold=[0 2 5 15];

% % Check the zero values
% colID=8; 
% threshold=[0 0.5 1 4];

% % Check the high values
% colID=9; 
% threshold=[0 1 2 5];

% % Check the inconsistent data: speed volume, occupancy
% colID=11; 
% threshold=[0 5 10 15];

% Check the inconsistent data: volume and occupancy
colID=12; 
threshold=[0 5 10 15];

% Start to perform the analysis
countTable=zeros(numErrorStep,numDate);

for i=1:numDate
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    countTable(1,i)=numDetector-size(tmpDetectorHealth,1);    
    for j=1:size(tmpDetectorHealth,1)
        if(tmpDetectorHealth(j,colID)==threshold(1))
            countTable(2,i)=countTable(2,i)+1;
        elseif(tmpDetectorHealth(j,colID)>threshold(1) && tmpDetectorHealth(j,colID)<=threshold(2))
            countTable(3,i)=countTable(3,i)+1;
        elseif(tmpDetectorHealth(j,colID)>threshold(2) && tmpDetectorHealth(j,colID)<=threshold(3))
            countTable(4,i)=countTable(4,i)+1;
        elseif(tmpDetectorHealth(j,colID)>threshold(3) && tmpDetectorHealth(j,colID)<=threshold(4))
            countTable(5,i)=countTable(5,i)+1;       
        else
            countTable(6,i)=countTable(6,i)+1;
        end
    end   
end


figure('Position',[9 374 1269 528]) 
hold on
plot(dateSelect,countTable(2,:)/numDetector*100,'--b')
plot(dateSelect,sum(countTable(2:3,:))/numDetector*100,'-xc')
plot(dateSelect,sum(countTable(2:4,:))/numDetector*100,'-+m')
plot(dateSelect,sum(countTable(2:5,:))/numDetector*100,'-.r')
stringLegend=[];
for i=1:length(threshold)
    if(i==1)
        sign='=';
    else
        sign='<=';
    end
    if(colID==6)
        stringLegend=[stringLegend;{sprintf('Rate_{Missing Data}%s%d%%',sign,threshold(i))}];
    elseif(colID==8)
        stringLegend=[stringLegend;{sprintf('MaxLength_{Zero Values}%s%.2f hr',sign,threshold(i))}];
    elseif(colID==9)
        stringLegend=[stringLegend;{sprintf('Rate_{High Values}%s%d %%',sign,threshold(i))}];
    elseif(colID==11)
        stringLegend=[stringLegend;{sprintf('Rate_{Inconsistent}%s%d %%',sign,threshold(i))}];
        title('Inconsistency check among volume, speed and occupancy','FontSize',15)
    elseif(colID==12)
        stringLegend=[stringLegend;{sprintf('Rate_{Inconsistent}%s%d %%',sign,threshold(i))}];
        title('Inconsistency check between volume and occupancy','FontSize',15)
    end
end
legend(stringLegend,'Location','SouthWest')
xlabel('Date','FontSize',25)
ylabel('Percentage','FontSize',25)
h=get(gca,'XTick');
hDateTime= datetime(h,'ConvertFrom','datenum');
set(gca,'XTickLabel',cellstr(hDateTime))
set(gca,'XTickLabelRotation',20);
grid on
if(colID~=9)
    set(gca, 'YLim',[0 100])
end
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')


% Start to perform the analysis
colID=10;
countTableConstant=zeros(3,numDate);

for i=1:numDate
    curDate=dateSelect(i);
    idx=(DetectorHealthAll(:,5)==curDate);
    tmpDetectorHealth=DetectorHealthAll(idx,:);
    
    countTableConstant(1,i)=numDetector-size(tmpDetectorHealth,1);    
    for j=1:size(tmpDetectorHealth,1)
        if(tmpDetectorHealth(j,colID)==0)
            countTableConstant(2,i)=countTableConstant(2,i)+1;
        else
            countTableConstant(3,i)=countTableConstant(3,i)+1;
        end
    end   
end

figure('Position',[9 374 1269 528]) 
hold on
plot(dateSelect,countTableConstant(3,:)/numDetector*100,'--b')
xlabel('Date','FontSize',25)
ylabel('Percentage','FontSize',25)
h=get(gca,'XTick');
hDateTime= datetime(h,'ConvertFrom','datenum');
set(gca,'XTickLabel',cellstr(hDateTime))
set(gca,'XTickLabelRotation',20);
grid on
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')
