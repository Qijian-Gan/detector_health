%% This script is used to draw the downtime distribution
clear
clc
close all

[num,str]=xlsread('data_availability.xlsx');
dayID=datenum(str);


% boxplot(num,str);
% set(gca,'XTickLabelRotation',90);
% xlabel('Date','FontSize',13)
% ylabel('Downtime (Minutes)','FontSize',13)
% grid on
% set(gca,'YLim',[-1,max(num)])

[uniqueDay,I,B]=unique(dayID);
uniqueDate=str(I);
totDownTime=zeros(size(uniqueDay));
for i=1:length(uniqueDay)
    idx=(dayID==uniqueDay(i));
    totDownTime(i)=sum(num(idx))/24/60*100;
end
plot(uniqueDay,totDownTime,'--x','LineWidth',2)
set(gca,'XTick',uniqueDay)
set(gca,'XTickLabel',uniqueDate)
set(gca,'XTickLabelRotation',90);
set(gca,'YLim',[0 100])
grid on
xlabel('Date','FontSize',18)
ylabel('Daily Percentage of Downtime (%)','FontSize',18)