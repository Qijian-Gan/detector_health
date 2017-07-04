function [DevInv,DevData,IntSigInv,IntSigData,PlanPhase,LastCyclePhase]=getString(string)

javaFolderLocation=findFolder.find_java_class();
eval(sprintf('javaaddpath %s',javaFolderLocation))
x=IENReaderByJava.Main();
arrayAllTypes=x.readIENData(string);

arrayByType=arrayAllTypes.toArray();
dp=load_IEN_configuration();

%% For detector inventory
array=char(arrayByType(1).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
arrayString=strrep(strsplit(tmpString{1,1},','),' ','');

intervalDevInv=13;
OrgID=arrayString(:,1:intervalDevInv:end)';
DeviceID=arrayString(:,2:intervalDevInv:end)';
LastUpdate=arrayString(:,3:intervalDevInv:end)';
Date=arrayString(:,4:intervalDevInv:end)';
Time=arrayString(:,5:intervalDevInv:end)';
Description=arrayString(:,6:intervalDevInv:end)';
RoadName=arrayString(:,7:intervalDevInv:end)';
CrossStreet=arrayString(:,8:intervalDevInv:end)';
Latitude=arrayString(:,9:intervalDevInv:end)';
Longitude=arrayString(:,10:intervalDevInv:end)';
Direction=arrayString(:,11:intervalDevInv:end)';
AvgPeriod=arrayString(:,12:intervalDevInv:end)';
AssIntID=arrayString(:,13:intervalDevInv:end)';

DevInv=dp.dataFormatDevInv(OrgID,DeviceID,LastUpdate,Date,Time,Description,RoadName,CrossStreet,...
    Latitude,Longitude,Direction,AvgPeriod,AssIntID);

%% For detector data
array=char(arrayByType(2).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
tmpString=strsplit(tmpString{1,1},',');
arrayString=strrep(tmpString,' ','');

intervalDevData=12;
OrgID=arrayString(:,1:intervalDevData:end)';
DeviceID=arrayString(:,2:intervalDevData:end)';
LastUpdate=arrayString(:,3:intervalDevData:end)';
Date=arrayString(:,4:intervalDevData:end)'; 
Time=arrayString(:,5:intervalDevData:end)';
State=arrayString(:,6:intervalDevData:end)';
Speed=arrayString(:,7:intervalDevData:end)';
Occupancy=arrayString(:,8:intervalDevData:end)';
Volume=arrayString(:,9:intervalDevData:end)';
AvgSpeed=arrayString(:,10:intervalDevData:end)';
AvgOccupancy=arrayString(:,11:intervalDevData:end)';
AvgVolume=arrayString(:,12:intervalDevData:end)';

% There is something wrong with "date" in Arcadia's data
dateNumTmp=datenum(Date,'yyyy.mm.dd');
dateMostFrequent=mode(dateNumTmp);
difference=abs(dateNumTmp-dateMostFrequent);
idx=(difference>1);
if(sum(idx))
    OrgID(idx)=[];
    DeviceID(idx)=[];
    LastUpdate(idx)=[];
    Date(idx)=[];
    Time(idx)=[];
    State(idx)=[];
    Speed(idx)=[];
    Occupancy(idx)=[];
    Volume(idx)=[];
    AvgSpeed(idx)=[];
    AvgOccupancy(idx)=[];
    AvgVolume(idx)=[];
end
    
DevData=dp.dataFormatDevData(OrgID,DeviceID,LastUpdate,Date,Time,State,Speed,Occupancy,Volume,...
    AvgSpeed,AvgOccupancy,AvgVolume);

%% For intersection signal inventory
array=char(arrayByType(3).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
arrayString=strrep(strsplit(tmpString{1,1},','),' ','');

intervalIntSigInv=11;
OrgID=arrayString(:,1:intervalIntSigInv:end)';
DeviceID=arrayString(:,2:intervalIntSigInv:end)';
LastUpdate=arrayString(:,3:intervalIntSigInv:end)';
Date=arrayString(:,4:intervalIntSigInv:end)';
Time=arrayString(:,5:intervalIntSigInv:end)';
SignalType=arrayString(:,6:intervalIntSigInv:end)';
Description=arrayString(:,7:intervalIntSigInv:end)';
MainStreet=arrayString(:,8:intervalIntSigInv:end)';
CrossStreet=arrayString(:,9:intervalIntSigInv:end)';
Latitude=arrayString(:,10:intervalIntSigInv:end)';
Longitude=arrayString(:,11:intervalIntSigInv:end)';

IntSigInv=dp.dataFormatSigInv(OrgID,DeviceID,LastUpdate,Date,Time,SignalType,Description,MainStreet,...
    CrossStreet,Latitude,Longitude);

%% For intersection signal data
array=char(arrayByType(4).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
arrayString=strrep(strsplit(tmpString{1,1},','),' ','');

intervalIntSigData=12;
OrgID=arrayString(:,1:intervalIntSigData:end)';
DeviceID=arrayString(:,2:intervalIntSigData:end)';
LastUpdate=arrayString(:,3:intervalIntSigData:end)';
Date=arrayString(:,4:intervalIntSigData:end)';
Time=arrayString(:,5:intervalIntSigData:end)';
CommState=arrayString(:,6:intervalIntSigData:end)';
SignalState=arrayString(:,7:intervalIntSigData:end)';
TimingPlan=arrayString(:,8:intervalIntSigData:end)';
DesiredCycleLength=arrayString(:,9:intervalIntSigData:end)';
DesiredOffset=arrayString(:,10:intervalIntSigData:end)';
ActualOffset=arrayString(:,11:intervalIntSigData:end)';
ControlMode=arrayString(:,12:intervalIntSigData:end)';

IntSigData=dp.dataFormatSigData(OrgID,DeviceID,LastUpdate,Date,Time,CommState,SignalState,TimingPlan,...
    DesiredCycleLength,DesiredOffset,ActualOffset,ControlMode);

%% For intersection planned phases
array=char(arrayByType(5).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
arrayString=strrep(strsplit(tmpString{1,1},','),' ','');

intervalPlanPhase=6;
OrgID=arrayString(:,1:intervalPlanPhase:end)';
DeviceID=arrayString(:,2:intervalPlanPhase:end)';
LastUpdate=arrayString(:,3:intervalPlanPhase:end)';
Date=arrayString(:,4:intervalPlanPhase:end)';
Time=arrayString(:,5:intervalPlanPhase:end)';
PhaseTime=arrayString(:,6:intervalPlanPhase:end)';

PlanPhase=dp.dataFormatPhase(OrgID,DeviceID,LastUpdate,Date,Time,PhaseTime);

%% For intersection last-cycle phases
array=char(arrayByType(6).toString());
tmpString=strsplit(array,'[');
tmpString=strsplit(tmpString{1,2},']');
arrayString=strrep(strsplit(tmpString{1,1},','),' ','');

intervalLastCyclePhase=7;
OrgID=arrayString(:,1:intervalLastCyclePhase:end)';
DeviceID=arrayString(:,2:intervalLastCyclePhase:end)';
LastUpdate=arrayString(:,3:intervalLastCyclePhase:end)';
Date=arrayString(:,4:intervalLastCyclePhase:end)';
Time=arrayString(:,5:intervalLastCyclePhase:end)';
LastCycle=arrayString(:,6:intervalLastCyclePhase:end)';
PhaseTime=arrayString(:,7:intervalLastCyclePhase:end)';

LastCyclePhase=dp.dataFormatPhaseLastCycle(OrgID,DeviceID,LastUpdate,Date,Time,LastCycle,PhaseTime);


