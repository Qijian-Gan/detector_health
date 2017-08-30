function plot_stability(DetectorHealthAll,detectorUnique,type)

numDetector=size(detectorUnique,1);

% Select the date
date=[datenum('2015-7-1'),datenum('2016-1-1'),datenum('2016-7-1'),datenum('2017-1-1'),datenum('2017-6-1')];
totalStability=zeros(4,1);
figure('Position',[283 432 723 474])
hold on
line={'-.r';'-+b';'-xc';'--m'};
for k=1:4
    idx=(DetectorHealthAll(:,5)>=date(k) & DetectorHealthAll(:,5)<date(k+1));
    HealthSelected=DetectorHealthAll(idx,:);
    
    numDay=date(k+1)-date(k);
    stateChange=zeros(numDetector,3);
    
    for i=1:numDetector
        fromGoodToBad=0;
        fromBadToGood=0;
        detID=detectorUnique(i);
        tmpHealth=HealthSelected(HealthSelected(:,1)==detID,:);
        if(~isempty(tmpHealth) && size(tmpHealth,1)>=2)
            for j=2:size(tmpHealth,1)
                if(tmpHealth(j,end)-tmpHealth(j-1,end)~=0)
                    if(tmpHealth(j,end)==0)
                        fromGoodToBad=fromGoodToBad+1;
                    else
                        fromBadToGood=fromBadToGood+1;
                    end
                end
            end
        end
        stateChange(i,1)=fromGoodToBad;
        stateChange(i,2)=fromBadToGood;
        stateChange(i,3)=sum(stateChange(i,1:2))/numDay;
    end
    
    x=(1:100);
    stability=zeros(length(x),1);
    for i=1:length(x)
        stability(i)=1/numDetector*sum(stateChange(:,3)<x(i)/100)*100;
    end
    totalStability(k)=sum(stability/100);
    
    plot(x,stability,line{k,:},'LineWidth',1.5)

end
formatOut = 'mm/dd/yy';
xlabel('Percentage of switching times','FontSize',25)
ylabel('Fraction (%) of detectors','FontSize',25)
title(type,'FontSize',25)
legend(...
    sprintf('Total Stability ([%s,%s])=%.2f%%',datestr(date(1),formatOut),datestr(date(2)-1,formatOut),totalStability(1)),...
    sprintf('Total Stability ([%s,%s])=%.2f%%',datestr(date(2),formatOut),datestr(date(3)-1,formatOut),totalStability(2)),...
    sprintf('Total Stability ([%s,%s])=%.2f%%',datestr(date(3),formatOut),datestr(date(4)-1,formatOut),totalStability(3)),...
    sprintf('Total Stability ([%s,%s])=%.2f%%',datestr(date(4),formatOut),datestr(date(5)-1,formatOut),totalStability(4)),...
    'Location', 'SouthEast')
set(gca, 'YTick',[0 :5:100])
set(gca, 'XTick',[0 :5:100])
set(findobj('type','axes'),'fontsize',13)
set(gca,'FontWeight','bold')
grid on
