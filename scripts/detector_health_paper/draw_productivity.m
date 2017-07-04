%% This script is used to draw missing data
clear
clc
close all

load('DetectorHealthAll.mat')

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

% Select the date
date=[datenum('2015-7-1'),datenum('2016-1-1'),datenum('2016-7-1'),datenum('2017-1-1'),datenum('2017-6-1')];
totalProductivity=zeros(4,1);
figure('Position',[283 432 723 474])
hold on
line={'-.r';'-+b';'-xc';'--m'};
for k=1:4
    idx=(DetectorHealthAll(:,5)>=date(k) & DetectorHealthAll(:,5)<date(k+1));
    HealthSelected=DetectorHealthAll(idx,:);
    
    numDay=date(k+1)-date(k);
    percentReliableDay=zeros(numDetector,1);
    
    for i=1:numDetector
        detID=detectorUnique(i,1);
        temHealth=HealthSelected(HealthSelected(:,1)==detID,:);
        percentReliableDay(i)=sum(temHealth(:,end))/numDay;
    end
    
    x=(1:100);
    productivity=zeros(length(x),1);
    for i=1:length(x)
        productivity(i)=1/numDetector*sum(percentReliableDay<x(i)/100)*100;
    end
    
    totalProductivity(k)=mean(percentReliableDay)*100;
    plot(x,productivity,line{k,:},'LineWidth',1.5)
       
end
formatOut = 'mm/dd/yy';
xlabel('Percentage of working days','FontSize',25)
ylabel('Fraction (%) of detectors','FontSize',25)
legend(...
    sprintf('Total Productivity ([%s,%s])=%.2f%%',datestr(date(1),formatOut),datestr(date(2)-1,formatOut),totalProductivity(1)),...
    sprintf('Total Productivity ([%s,%s])=%.2f%%',datestr(date(2),formatOut),datestr(date(3)-1,formatOut),totalProductivity(2)),...
    sprintf('Total Productivity ([%s,%s])=%.2f%%',datestr(date(3),formatOut),datestr(date(4)-1,formatOut),totalProductivity(3)),...
    sprintf('Total Productivity ([%s,%s])=%.2f%%',datestr(date(4),formatOut),datestr(date(5)-1,formatOut),totalProductivity(4)),...
    'Location', 'NorthWest')
set(gca, 'YTick',[0 :5:100])
set(gca, 'XTick',[0 :5:100])
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')
grid on

