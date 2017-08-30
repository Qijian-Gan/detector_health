clear
clc
close all

load('detectorNameArcadia.mat','detectorNameArcadia')
load('detectorNameLACO.mat','detectorNameLACO')

%% Setttings
Year=2017;
Month=7;
StartDay=17; % Monday
EndDay=21; % Friday
lineScheme={'*r';'xg';'ob';'+c';'sm'};
City='LACO';

here = fileparts(mfilename('fullpath'));
outputFolderRawData = fullfile(here,'\figure\raw_data');

startDate=datenum(sprintf('%d-%d-%d',Year,Month,StartDay));
endDate=datenum(sprintf('%d-%d-%d',Year,Month,EndDay));
%% Get the raw detector data
switch City
    case 'Arcadia'
        detectorName=detectorNameArcadia;
        idx=(detectorName==9901);
        detectorName(idx)=[];
    case 'LACO'
        detectorName=detectorNameLACO;
end
    
% Get the current folder
currentFileLoc=(fullfile(findFolder.IEN_temp(),'\device_data'));
currentInvFileLoc=(fullfile(findFolder.IEN_temp(),'\device_inventory'));
for i=1:length(detectorName) % Loop for each detector
    detectorID=detectorName(i);
    
    YearMonth=Year*100+Month;
    fileName=sprintf('Detector_Data_%d_%s_%d.mat',YearMonth,City,detectorID);
    load(fullfile(currentFileLoc,fileName)); % dataDevData    
    date={dataDevData.Date}';
    date=datenum(strrep(date,'.','-'));
    
    fileNameInv=sprintf('Detector_Inv_%d_%s_%d.mat',YearMonth,City,detectorID);
    load(fullfile(currentInvFileLoc,fileNameInv)); % dataInvData   
    Description=UtilityFunction.splitIENDescription(dataDevInv(1).Data(1).Description);
    IntID=dataDevInv(1).Data(1).AssociatedIntersectionID;
    RoadName=dataDevInv(1).Data(1).RoadName;
    CrossStreet=dataDevInv(1).Data(1).CrossStreet;
    
    legendStringArray=[];
    DataArray=[];
    for j=startDate:endDate % Loop for each date
        % Load the data       
        legendStringArray=[legendStringArray;strcat('Raw Data:', datestr(j))];
        idx=(date==j);
        
        dataSelect=dataDevData(idx).Data;
        
        Time={dataSelect.Time}';        
        Occupancy=str2double({dataSelect.Occupancy}');
        Volume=str2double({dataSelect.Volume}');        
        
        [I,B]=unique(Time);
        Time=Time(B);
        TimeInSecond=hour(Time)*3600+minute(Time)*60+second(Time);
        Volume=Volume(B);
        Occupancy=Occupancy(B);        
        DataArray=[DataArray;struct(...
            'Time', TimeInSecond,...
            'Occupancy',Occupancy,...
            'Flow',Volume)];
            
    end
    titleString=sprintf('City:%s & Int:%s-%s@%s & Det ID:%d & Descrip:%s',City,IntID,RoadName,CrossStreet,...
        detectorID,Description);
    
    plotFunctions.plotFlowOccupancyMultiDay(DataArray,titleString,lineScheme,legendStringArray,...
        'Yes',outputFolderRawData,sprintf('%s_Int_%s_Det_%d',City,IntID,detectorID))
end



