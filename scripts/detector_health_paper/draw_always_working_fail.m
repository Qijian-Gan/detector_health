%% This script is used to draw missing data
clear
clc
close all

load('DetectorHealthAll.mat')

% Number of detectors
detectorUnique=unique(DetectorHealthAll(:,1));
numDetector=length(detectorUnique);

% Select the date
% N=8;
% M=6;
% fail=[0,1,2,3,4,5];
% date=[datenum('2015-7-1'),datenum('2015-10-1'),datenum('2016-1-1'),datenum('2016-4-1'),...
%     datenum('2016-7-1'),datenum('2016-10-1'),datenum('2017-1-1'),datenum('2017-4-1'),datenum('2017-6-1')];
% daymissing=[8,17,2,0,0,0,0,2];
% alwaysWorkingFail=zeros(N,M+1);

N=4;
M=6;
fail=[0,1,2,3,4,5];
date=[datenum('2015-7-1'),datenum('2016-1-1'), datenum('2016-7-1'),datenum('2017-1-1'),datenum('2017-6-1')];
daymissing=[25,2,0,2];
alwaysWorkingFail=zeros(N,M+1);
for k=1:N
    idx=(DetectorHealthAll(:,5)>=date(k) & DetectorHealthAll(:,5)<date(k+1));
    HealthSelected=DetectorHealthAll(idx,:);
    numDay=date(k+1)-date(k)-daymissing(k);
    for i=1:numDetector      
        detID=detectorUnique(i);
        tmpHealth=HealthSelected(HealthSelected(:,1)==detID,:);
        if(isempty(tmpHealth))
            alwaysWorkingFail(k,end)=alwaysWorkingFail(k,end)+1;
        else
            for j=1:M
                if(sum(tmpHealth(:,end))>=numDay-fail(j))
                    alwaysWorkingFail(k,j)=alwaysWorkingFail(k,j)+1;
                end
            end
            
            if(sum(tmpHealth(:,end))==0)
                alwaysWorkingFail(k,end)=alwaysWorkingFail(k,end)+1;
            end
        end
    end

end

figure('Position',[116 384 1131 542])
labels = {'Always Working', 'Failed One Day ', 'Failed Two Days', 'Failed Three Days',...
    'Failed Four Days','Failed Five Days','Always Failed'};
bar(alwaysWorkingFail')
xticklabels(labels)
set(gca,'XTickLabelRotation',20);
formatOut = 'mm/dd/yy';
legend(...
    sprintf('Time Period:[%s,%s]',datestr(date(1),formatOut),datestr(date(2)-1,formatOut)),...
    sprintf('Time Period:[%s,%s]',datestr(date(2),formatOut),datestr(date(3)-1,formatOut)),...
    sprintf('Time Period:[%s,%s]',datestr(date(3),formatOut),datestr(date(4)-1,formatOut)),...
    sprintf('Time Period:[%s,%s]',datestr(date(4),formatOut),datestr(date(5)-1,formatOut)),...
    'Location', 'NorthWest')
xlabel('Detector Status','FontSize',25)
ylabel('Number of Detectors','FontSize',25)
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')
