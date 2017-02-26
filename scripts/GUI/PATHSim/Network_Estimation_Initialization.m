function varargout = Network_Estimation_Initialization(varargin)
% NETWORK_ESTIMATION_INITIALIZATION MATLAB code for Network_Estimation_Initialization.fig
%      NETWORK_ESTIMATION_INITIALIZATION, by itself, creates a new NETWORK_ESTIMATION_INITIALIZATION or raises the existing
%      singleton*.
%
%      H = NETWORK_ESTIMATION_INITIALIZATION returns the handle to a new NETWORK_ESTIMATION_INITIALIZATION or the handle to
%      the existing singleton*.
%
%      NETWORK_ESTIMATION_INITIALIZATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in NETWORK_ESTIMATION_INITIALIZATION.M with the given input arguments.
%
%      NETWORK_ESTIMATION_INITIALIZATION('Property','Value',...) creates a new NETWORK_ESTIMATION_INITIALIZATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Network_Estimation_Initialization_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Network_Estimation_Initialization_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Network_Estimation_Initialization

% Last Modified by GUIDE v2.5 24-Feb-2017 11:52:07

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @Network_Estimation_Initialization_OpeningFcn, ...
    'gui_OutputFcn',  @Network_Estimation_Initialization_OutputFcn, ...
    'gui_LayoutFcn',  [] , ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

%% Main functions
% --- Executes just before Network_Estimation_Initialization is made visible.
function Network_Estimation_Initialization_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Network_Estimation_Initialization (see VARARGIN)

% Choose default command line output for Network_Estimation_Initialization
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Network_Estimation_Initialization wait for user response (see UIRESUME)
% uiwait(handles.figure1);

% Logos are put under the same folder
here = fileparts(mfilename('fullpath'));
axes(handles.axes1)
matlabImage = imread(fullfile(here,'\Logos\Logo.png'));
image(matlabImage)
axis off
axis image
axes(handles.axes3)
matlabImage = imread(fullfile(here,'\Logos\Path_logo_0.jpg'));
image(matlabImage)
axis off
axis image

% Output the table formats
handles.EstimationTable.ColumnName = {'Junction ID','Junction Name','Junction ExtID','Signalized',...
    'Direction (Section ID)','Section Name','Section ExtID','Time',...
    'Left Turn Status','Through movement Status','Right Turn Status',...
    'Left Turn Queue','Through movement Queue','Right Turn Queue'};
handles.InitializationTable.ColumnName = {'Aimsun Section ID','Lane ID','Vehicle Type','Origin ID',...
    'Destination ID','Distance To End (ft)','Speed (mph)','Track Or Not'};
handles.PhaseDeterminationTable.ColumnName = {'Aimsun JunctionID','Aimsun Control Plan ID','Control Type','Cycle Length',...
    'Coordinated','Ring ID','Aimsun Phase ID','Phase ID In Cycle', 'Time Has Been Activated'};

% Resize the figure
handles.figure1.Tag='Network_Estimation_Initialization';
% set(handles.figure1,'Units','Pixels','Position',get(0,'ScreenSize'))

% --- Outputs from this function are returned to the command line.
function varargout = Network_Estimation_Initialization_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



%% Aimsun Network Settings
% --- Executes on button press in Settings.
function AimsunSettings_Callback(hObject, eventdata, handles)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\AimsunProjectSettings.m'));

% --- Executes on button press in ExtractAimsunNetwork.
function ExtractAimsunNetwork_Callback(hObject, eventdata, handles)
% hObject    handle to ExtractAimsunNetwork (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc
disp('*********************************************************')
disp('***********Extracting Aimsun network!********************')
disp('*********************************************************')
%Aimsun
tmpFileFolder=findFolder.GUI_temp();
fileName=fullfile(tmpFileFolder,'AimsunProjectSetting.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: AimsunProjectSetting
else
    error('Can not find the Aimsun project settings!')
end

FileLocation=AimsunProjectSetting.FileLocation;
NameOfPythonCode='AimsunStart.py';
AimsunFile=AimsunProjectSetting.AimsunFile;
JunctionYes=(AimsunProjectSetting.JunctionYes);
SectionYes=(AimsunProjectSetting.SectionYes);
DetectorYes=(AimsunProjectSetting.DetectorYes);
SignalYes=(AimsunProjectSetting.SignalYes);

InputFolder=AimsunProjectSetting.OutputFolder;
switch InputFolder
    case 'Default'
        OutputFolder=findFolder.aimsunNetwork_data_whole();
    otherwise
        OutputFolder=InputFolder;
end
system(sprintf('aimsun.exe -script %s %s %d %d %d %d %s',fullfile(FileLocation,NameOfPythonCode),...
    fullfile(FileLocation,AimsunFile),JunctionYes,SectionYes,DetectorYes,SignalYes,OutputFolder));
disp('*********************************************************')
disp('***********Done!*****************************************')
disp('*********************************************************')

% --- Executes on button press in NetworkReconstruction.
function NetworkReconstruction_Callback(hObject, eventdata, handles)
% hObject    handle to NetworkReconstruction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc
disp('*******************************************************')
disp('***************Network Reconstruction!***************')
disp('*******************************************************')

%% Load the network information file
% Input folder
tmpFileFolder=findFolder.GUI_temp();
fileName=fullfile(tmpFileFolder,'AimsunProjectSetting.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: AimsunProjectSetting
else
    error('Can not find the Aimsun project settings!')
end
InputFolder=AimsunProjectSetting.OutputFolder;
if (strcmp(InputFolder,'Default'))
    % With empty input: Default folder ('data\aimsun_networkData_whole')
    InputFolder=findFolder.aimsunNetwork_data_whole();
end
dp_network=load_aimsun_network_files(InputFolder);

% Junction input file
disp('*********************************************')
disp('Step 1/8: Loading the Junction Information!')
disp('*********************************************')
if(exist(fullfile(InputFolder,'JunctionInf.txt'),'file'))
    junctionData=dp_network.parse_junctionInf_txt('JunctionInf.txt');
else
    error('Cannot find the junction information file in the folder!')
end

% Section input file
disp('*********************************************')
disp('Step 2/8: Loading the Section Information!')
disp('*********************************************')
if(exist(fullfile(InputFolder,'SectionInf.txt'),'file'))
    sectionData=dp_network.parse_sectionInf_txt('SectionInf.txt');
else
    error('Cannot find the section information file in the folder!')
end

% Detector data file
disp('*********************************************')
disp('Step 3/8: Loading the Detector Information!')
disp('*********************************************')
if(exist(fullfile(InputFolder,'DetectorInf.csv'),'file'))
    detectorData=dp_network.parse_detectorInf_csv('DetectorInf.csv');
else
    error('Cannot find the detector information file in the folder!')
end

% Control plans
disp('*********************************************')
disp('Step 4/8: Loading the Control Plans!')
disp('*********************************************')
if(exist(fullfile(InputFolder,'ControlPlanInf.txt'),'file'))
    controlPlanAimsun=dp_network.parse_controlPlanInf_txt('ControlPlanInf.txt');
else
    error('Cannot find the control plan information file in the folder!')
end

% Master Control plans
disp('*********************************************')
disp('Step 5/8: Loading the Master Control Plan!')
disp('*********************************************')
if(exist(fullfile(InputFolder,'MasterControlPlanInf.txt'),'file'))
    masterControlPlanAimsun=dp_network.parse_masterControlPlanInf_txt('MasterControlPlanInf.txt');
else
    error('Cannot find the master control plan information file in the folder!')
end

% Default signal settings
disp('*********************************************')
disp('Step 6/8: Loading the Default Signal Settings!')
disp('*********************************************')
DefaultSigInfFile=AimsunProjectSetting.DefaultSigInfFile;
if(exist(DefaultSigInfFile,'file'))
    defaultSigSettingData=dp_network.parse_defaultSigSetting_csv(DefaultSigInfFile);
else
    error('Cannot find the default signal information file in the folder!')
end

% Midlink config data
disp('*********************************************')
disp('Step 7/8: Loading the Midlink Configuration!')
disp('*********************************************')
MidlinkCountInfFile=AimsunProjectSetting.MidlinkCountInfFile;
if(exist(MidlinkCountInfFile,'file'))
    midlinkConfigData=dp_network.parse_midlinkCountConfig_csv(MidlinkCountInfFile);
else
    error('Cannot find the midlink configuration information file in the folder!')
end

%% Reconstruct the Aimsun network
disp('*********************************************')
disp('Step 8/8: Reconstructing the Network!')
disp('*********************************************')
recAimsunNet=reconstruct_aimsun_network(junctionData,sectionData,detectorData,defaultSigSettingData,...
    midlinkConfigData,controlPlanAimsun,masterControlPlanAimsun,nan);

% Reconstruct the network
recAimsunNet.networkData=recAimsunNet.reconstruction();
outputFolder=findFolder.GUI_temp();
save(fullfile(outputFolder,'recAimsunNet.mat'),'recAimsunNet')
save(fullfile(outputFolder,'netInputFiles.mat'),'junctionData',...
    'sectionData','detectorData','controlPlanAimsun','masterControlPlanAimsun')

disp('*********************************************')
disp('Done!')
disp('*********************************************')



%% Beats Network Settings
% --- Executes on button press in BeatsSetting.
function BeatsSetting_Callback(hObject, eventdata, handles)
% hObject    handle to BeatsSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% Logos are put under the same folder
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\BeatsProjectSettings.m'));

% --- Executes on button press in BeatsNetworkReconstruction.
function BeatsNetworkReconstruction_Callback(hObject, eventdata, handles)
% hObject    handle to BeatsNetworkReconstruction (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('*********************************************************')
disp('***********Reconstructing BEATS network!*****************')
disp('*********************************************************')
% Aimsun
InputFolder=findFolder.aimsunNetwork_data_whole();
dp_network_Aimsun=load_aimsun_network_files(InputFolder);
if(exist(fullfile(InputFolder,'SectionInf.txt'),'file'))
    sectionData=dp_network_Aimsun.parse_sectionInf_txt('SectionInf.txt');
else
    error('In order to reconstruct the BEATS network, please extract the section information from Aimsun first!')
end

tmpFileFolder=findFolder.GUI_temp();
fileName=fullfile(tmpFileFolder,'BeatsNetwork.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: BeatsNetwork
else
    error('Can not find the Beats network files!')
end

BeatsNetwork.Data.AimsunWithBEATSMapping=BeatsNetwork.DataProvider.transfer_beats_to_aimsun...
    (BeatsNetwork.Data.BEATSWithAimsunMapping,sectionData,...
    BeatsNetwork.Data.XMLMapping,BeatsNetwork.Data.XMLNetwork);
save(fileName,'BeatsNetwork');

disp('*********************************************************')
disp('***********Done!*****************************************')
disp('*********************************************************')

% --- Executes on button press in BeatsNetworkLoading.
function BeatsNetworkLoading_Callback(hObject, eventdata, handles)
% hObject    handle to BeatsNetworkLoading (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('*********************************************************')
disp('***********Loading BEATS network!*****************')
disp('*********************************************************')
%BEATS
tmpFileFolder=findFolder.GUI_temp();
fileName=fullfile(tmpFileFolder,'BeatsProjectSetting.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: BeatsProjectSetting
else
    error('Can not find the BEATS project settings!')
end

% Get the beats network data provider
switch BeatsProjectSetting.FileLocation
    case 'Default'
        dp_network_BEATS=load_BEATS_network;
    otherwise
        dp_network_BEATS=load_BEATS_network(BeatsProjectSetting.FileLocation);
end

% Load the XML file
disp('***********Step 1/3: XML File****************************')
XMLFileName=fullfile(dp_network_BEATS.folderLocationNetwork,BeatsProjectSetting.XMLNetwork);
if(exist(XMLFileName,'file'))
    data.XMLNetwork=dp_network_BEATS.parse_BEATS_network_files(BeatsProjectSetting.XMLNetwork);
else
    error('Can not find the XML file!')
end

% Load the XML mapping file
disp('***********Step 2/3: XML Mapping File********************')
XMLMappingFileName=fullfile(dp_network_BEATS.folderLocationNetwork,BeatsProjectSetting.XMLMapping);
if(exist(XMLMappingFileName,'file'))
    data.XMLMapping=dp_network_BEATS.parse_BEATS_network_files(BeatsProjectSetting.XMLMapping);
else
    error('Can not find the XML mapping file!')
end

% Load the mapping file between Beats and Aimsun
disp('***********Step 3/3: Mapping Between BEATS and Aimsun****')
BeatsMappingWithAimsunFileName=fullfile(dp_network_BEATS.folderLocationNetwork,...
    BeatsProjectSetting.BEATSWithAimsunMapping);
if(exist(BeatsMappingWithAimsunFileName,'file'))
    data.BEATSWithAimsunMapping=dp_network_BEATS.parse_BEATS_network_files...
        (BeatsProjectSetting.BEATSWithAimsunMapping);
else
    error('Can not find the mapping file between BEATS and Aimsun!')
end

BeatsNetwork.DataProvider=dp_network_BEATS;
BeatsNetwork.Data=data;
save(fullfile(tmpFileFolder,'BeatsNetwork.mat'),'BeatsNetwork');

disp('*********************************************************')
disp('***********Done!*****************************************')
disp('*********************************************************')



%% Parameter Settings
% --- Executes on button press in DataQueryParameters.
function DataQueryParameters_Callback(hObject, eventdata, handles)
% hObject    handle to DataQueryParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\DataQueryParameter.m'));

% --- Executes on button press in VehicleParameters.
function VehicleParameters_Callback(hObject, eventdata, handles)
% hObject    handle to VehicleParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\VehicleParameters.m'));

% --- Executes on button press in EstimationParameters.
function EstimationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to EstimationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\EstimationParameters.m'));

% --- Executes on button press in InitializationParameters.
function InitializationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to InitializationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\InitializationParameters.m'));



%% Estimation
% --- Executes on button press in ArterialFieldData.
function ArterialFieldData_Callback(hObject, eventdata, handles)
% hObject    handle to ArterialFieldData (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in FreewayBeats.
function FreewayBeats_Callback(hObject, eventdata, handles)
% hObject    handle to FreewayBeats (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in RunEstimation.
function RunEstimation_Callback(hObject, eventdata, handles)
% hObject    handle to RunEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
clc
inputFolder=findFolder.GUI_temp();
disp('*******************************************************')
disp('******Runing Estimation********************************')
disp('*******************************************************')

disp('*******************************************************')
disp('******Collecting Data!*********************************')
disp('*******************************************************')
if(exist(fullfile(inputFolder,'recAimsunNet.mat'),'file'))
    load(fullfile(inputFolder,'recAimsunNet.mat'));
else
    error('Please extract and reconstruct the Aimsun network first!')
end
if(exist(fullfile(inputFolder,'DataQueryParameter.mat'),'file'))
    load(fullfile(inputFolder,'DataQueryParameter.mat'));
else
    error('Please set the data query parameters first!')
end
if(exist(fullfile(inputFolder,'EstimationParameters.mat'),'file'))
    load(fullfile(inputFolder,'EstimationParameters.mat'));
else
    error('Please set the estimation parameters first!')
end

% Default settings
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
DayConfig=DataQueryParameter.DaySetting;
SelectedDayID=find(ismember(days,DayConfig)==1);
from=str2double(DataQueryParameter.TimeSetting)*3600;
interval=str2double(EstimationParameters.SearchIntervalEstimation);
Median=DataQueryParameter.UseMedian;
switch Median
    case 'Yes'
        UseMedianOrNot=1;
    case 'No'
        UseMedianOrNot=0;
end

queryMeasures=struct(...
    'year',     nan,...
    'month',    nan,...
    'day',      nan,...
    'dayOfWeek',SelectedDayID-1,...
    'median', UseMedianOrNot,...
    'timeOfDay', [from-interval from]); % Use a longer time interval to obtain more reliable data

if(handles.ArterialFieldData.Value==1)
    
    disp('*******************************************************')
    disp('******Arterial links!**********************************')
    disp('*******************************************************')
    % Generate the configuration of approaches for traffic state estimation
    appDataForEstimation=recAimsunNet.get_approach_config_for_estimation(recAimsunNet.networkData);
    
    %% Run state estimation
    %Get the data provider
    ptr_sensor=sensor_count_provider;
    ptr_midlink=midlink_count_provider;
    ptr_turningCount=turning_count_provider;

    % Run state estimation
    est=state_estimation(appDataForEstimation,ptr_sensor,ptr_midlink,ptr_turningCount);
    appStateEst=[];
    folderLocation=findFolder.estStateQueue_data();
    fileName='AimsunQueueEstimated.csv';
    for i=1:size(appDataForEstimation,1) % Loop for all approaches        
        tmp_approach=appDataForEstimation(i);
        [tmp_approach.turning_count_properties.proportions]=est.update_vehicle_proportions(tmp_approach,queryMeasures);
        [tmp_approach]=est.get_sensor_data_for_approach(tmp_approach,queryMeasures);
        [tmp_approach.decision_making]=est.get_traffic_condition_by_approach(tmp_approach,queryMeasures);
        appStateEst=[appStateEst;tmp_approach];
    end
    sheetName=DayConfig;
    ArterialEstimationTable=est.extract_to_csv(appStateEst,folderLocation,fileName);
    save(fullfile(inputFolder,sprintf('appStateEst_%s.mat',DayConfig)),'appStateEst');
    save(fullfile(inputFolder,'ArterialEstimationTable.mat'),'ArterialEstimationTable');
    
    disp('*******************************************************')
    disp('******Done with Arterial Links!************************')
    disp('*******************************************************')
end

if(handles.FreewayBeats.Value==1)
    disp('*******************************************************')
    disp('******Freeway links!***********************************')
    disp('*******************************************************')
    %% Load the network information file
    % Aimsun
    inputFolder=findFolder.GUI_temp();
    fileName=fullfile(inputFolder,'BeatsNetwork.mat');
    if(exist(fileName,'file'))
        load(fileName); % Variable: BeatsNetwork
        dp_network_BEATS=BeatsNetwork.DataProvider;
        data=BeatsNetwork.Data;
    else
        error('Please load and reconstruct the BEATS network first!')
    end
    
    %% Estimation
    % Beats data provider
    ptr_beats=simBEATS_data_provider;

    EstimationResultsBeats=[];
    AimsunWithBEATSMapping=data.AimsunWithBEATSMapping;
    for i=1:size(AimsunWithBEATSMapping,1)
        AimsunLinkID=AimsunWithBEATSMapping(i).AimsunLinkID;
        BeatsLinks=AimsunWithBEATSMapping(i).BEATSLinks;
        BeatsLinkIDs=[BeatsLinks.SimLinkID]';
                
        % Obtain the simulated BEATS data
        beatsLinkData=initialization_in_aimsun_with_beats.get_estimates_from_beats_simulation...
            (BeatsLinkIDs,ptr_beats,queryMeasures);
        AimsunWithBEATSMapping(i).BEATSLinkData=beatsLinkData;
        
        for j=1:size(beatsLinkData,1)
            [avgDensityBeats,avgDensityStdDevBeats,avgSpeedBeats,avgSpeedStdDevBeats]=...
                initialization_in_aimsun_with_beats.get_averages(beatsLinkData(j));
            EstimationResultsBeats=[EstimationResultsBeats;...
                [AimsunLinkID,BeatsLinkIDs(j),from,avgDensityBeats,avgDensityStdDevBeats,avgSpeedBeats,avgSpeedStdDevBeats]];
        end
    end
    
    outputFolder=findFolder.estStateQueue_data;
    dlmwrite(fullfile(outputFolder,'EstimationResultsBeats.csv'), EstimationResultsBeats, 'delimiter', ',', 'precision', 9);
    
    save(fullfile(inputFolder,sprintf('AimsunWithBEATSMapping_%s.mat',DayConfig)),'AimsunWithBEATSMapping');
    save(fullfile(inputFolder,'FreewayEstimationTable.mat'),'EstimationResultsBeats');
    disp('*******************************************************')
    disp('******Done with Freeway Links!*************************')
    disp('*******************************************************')
end

% --- Executes on button press in ViewEstimation.
function ViewEstimation_Callback(hObject, eventdata, handles)
% hObject    handle to ViewEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.ArterialFieldData.Value==1 && handles.FreewayBeats.Value==0)    
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\EstimationTableArterial.m'));
elseif(handles.ArterialFieldData.Value==0 && handles.FreewayBeats.Value==1)
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\EstimationTableFreeway.m'));
elseif(handles.ArterialFieldData.Value==1 && handles.FreewayBeats.Value==1)
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\EstimationTable.m'));
end



%% Initialization
% --- Executes on button press in InitializationVehicle.
function InitializationVehicle_Callback(hObject, eventdata, handles)
% hObject    handle to InitializationVehicle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InitializationVehicle

% --- Executes on button press in InitializationPhase.
function InitializationPhase_Callback(hObject, eventdata, handles)
% hObject    handle to InitializationPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InitializationPhase

% --- Executes on button press in RunInitialization.
function RunInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to RunInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc
disp('*******************************************************')
disp('************Traffic State Initialization!**************')
disp('*******************************************************')

disp('*********************************************')
disp('Step 1/7: Loading the Estimates!')
disp('*********************************************')
% Load the estStateQueue file
dp_StateQueue=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
estStateQueue=dp_StateQueue.parse_csv('aimsun_queue_estimated.csv',dp_StateQueue.folderLocation);

disp('*********************************************')
disp('Step 2/7: Loading the Simulated Vehicles!')
disp('*********************************************')
% simVehicle data provider
inputFolderLocation=findFolder.temp_aimsun_whole();
dp_vehicle=simVehicle_data_provider(inputFolderLocation);

disp('*********************************************')
disp('Step 3/7: Loading the Signal Data Providers!')
disp('*********************************************')
% simSignal data provider
dp_signal_sim=simSignal_data_provider;
dp_signal_field=fieldSignal_data_provider;

disp('*********************************************')
disp('Step 4/7: Collecting active control plans!')
disp('*********************************************')
DayConfig=get(handles.DayConfig,'String');
currentTime=str2double(get(handles.TimeStampConfig,'String'))*3600;
type=struct(...
    'ControlPlanSource',        'FromAimsun',...
    'LastCycleInformation',     'None');
dp_signal_field.timeStamp=currentTime;
dp_signal_field.day=DayConfig;
dp_signal_field.source=type.ControlPlanSource;
dp_signal_field.LastCycleInformation=type.LastCycleInformation;
[dp_signal_field.activeControlPlans]=dp_signal_field...
    .get_active_control_plans_for_given_day_and_time(DayConfig,currentTime,type.ControlPlanSource);

% Generate vehicles
disp('*********************************************')
disp('Step 5/7: Collecting default parameters!')
disp('*********************************************')
VehicleLength=str2double(get(handles.VehicleLength,'String'));
JamSpacing=str2double(get(handles.JamSpacing,'String'));
Headway=str2double(get(handles.Headway,'String'));

defaultParams=struct(... % Default parameters
    'VehicleLength', VehicleLength,...
    'JamSpacing', JamSpacing,...
    'Headway', Headway);

SearchInitializationConfig=str2double(get(handles.SearchInitializationConfig,'String'));
DistanceToEnd=str2double(get(handles.DistanceToEnd,'String'));
querySetting=struct(... % Query settings
    'SearchTimeDuration', SearchInitializationConfig,...
    'Distance', DistanceToEnd);

disp('*********************************************')
disp('Step 6/7: Generating Vehicles!')
disp('*********************************************')
inputFolder=findFolder.objects();
outputLocation=findFolder.aimsun_initialization();
load(fullfile(inputFolder,'recAimsunNet.mat'))
dp_initialization=initialization_in_aimsun(recAimsunNet.networkData,estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan); % Currently missing field signal data provider
vehicleList=dp_initialization.generate_vehicle(querySetting);
set(handles.InitializationTable,'Data',vehicleList);
dlmwrite(fullfile(outputLocation,'VehicleInfEstimation.csv'), vehicleList, 'delimiter', ',', 'precision', 9);

disp('*********************************************')
disp('Step 7/7: Determining Signal Phases!')
disp('*********************************************')
[phaseListTable,phaseListAimsun]=dp_initialization.determine_phases(type);
set(handles.PhaseDeterminationTable,'Data',phaseListTable);
dlmwrite(fullfile(outputLocation,'SignalInfEstimation.csv'), phaseListAimsun, 'delimiter', ',', 'precision', 9);

disp('*********************************************')
disp('Done!')
disp('*********************************************')
clc
disp('*******************************************************')
disp('***************Running State Estimation!***************')
disp('*******************************************************')

inputFolder=findFolder.objects();
load(fullfile(inputFolder,'recAimsunNet.mat'))

% Generate the configuration of approaches for traffic state estimation
appDataForEstimation=recAimsunNet.get_approach_config_for_estimation(recAimsunNet.networkData);

%% Run state estimation
%Get the data provider
ptr_sensor=sensor_count_provider;
ptr_midlink=midlink_count_provider;
ptr_turningCount=turning_count_provider;

% Default settings
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
DayConfig=get(handles.DayConfig,'String');
SelectedDayID=find(ismember(days,DayConfig)==1);
from=str2double(get(handles.TimeStampConfig,'String'))*3600;
to=from;  % Ending time
interval=str2double(get(handles.SearchEstimationConfig,'String'));
Median=get(handles.MedianConfig,'String');
switch Median
    case 'Yes'
        UseMedianOrNot=1;
    case 'No'
        UseMedianOrNot=0;
end

% Run state estimation
est=state_estimation(appDataForEstimation,ptr_sensor,ptr_midlink,ptr_turningCount);
appStateEst=[];
folderLocation='C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\data\estStateQueueData\';
fileName='aimsun_queue_estimated.csv';
for i=1:size(appDataForEstimation,1) % Loop for all approaches
    for t=from:interval:to % Loop for all prediction intervals
        queryMeasures=struct(...
            'year',     nan,...
            'month',    nan,...
            'day',      nan,...
            'dayOfWeek',SelectedDayID-1,...
            'median', UseMedianOrNot,...
            'timeOfDay', [t t+interval]); % Use a longer time interval to obtain more reliable data
        
        tmp_approach=appDataForEstimation(i);
        [tmp_approach.turning_count_properties.proportions]=est.update_vehicle_proportions(tmp_approach,queryMeasures);
        [tmp_approach]=est.get_sensor_data_for_approach(tmp_approach,queryMeasures);
        [tmp_approach.decision_making]=est.get_traffic_condition_by_approach(tmp_approach,queryMeasures);
        if (t==from)
            approach=tmp_approach;
        else
            approach.decision_making=[approach.decision_making;tmp_approach.decision_making];
        end
    end
    appStateEst=[appStateEst;approach];
end
sheetName=DayConfig;
Table=est.extract_to_csv(appStateEst,folderLocation,fileName);
save(sprintf('appStateEst_%s.mat',DayConfig),'appStateEst');



%% Load the network information file
% Aimsun
InputFolder=findFolder.aimsunNetwork_data_whole();
dp_network_Aimsun=load_aimsun_network_files(InputFolder); 
if(exist(fullfile(InputFolder,'SectionInf.txt'),'file'))
    sectionData=dp_network_Aimsun.parse_sectionInf_txt('SectionInf.txt');
else
    error('Cannot find the section information file in the folder!')
end

%BEATS
dp_network_BEATS=load_BEATS_network;
data.XMLNetwork=dp_network_BEATS.parse_BEATS_network_files('210E_for_estimation_v5_links_fixed.xml');
data.XMLMapping=dp_network_BEATS.parse_BEATS_network_files('link_id_map_450.csv');
data.BEATSWithAimsunMapping=dp_network_BEATS.parse_BEATS_network_files('BEATSLinkTable.csv');
data.AimsunWithBEATSMapping=dp_network_BEATS.transfer_beats_to_aimsun(data.BEATSWithAimsunMapping,sectionData,data.XMLMapping,data.XMLNetwork);

%% Initialization
% Beats data provider
ptr_beats=simBEATS_data_provider; 

% simVehicle data provider
inputFileLoc=findFolder.temp_aimsun_whole;
dp_vehicle=simVehicle_data_provider(inputFileLoc); 

defaultParams=struct(... % Default parameters
    'VehicleLength', 17,...
    'JamSpacing', 24,...
    'Headway', 2);

querySetting=struct(... % Query settings
    'SearchTimeDuration', 30*60,...
    'Distance', 60);

dp_initialization_beats=initialization_in_aimsun_with_beats(data,dp_vehicle,ptr_beats,defaultParams,nan);

% Default settings
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'}; 
from=7.5*3600; % Starting time
to=7.5*3600;  % Ending time
interval=300;

aimsunWithBeatsInitialization=dp_initialization_beats.networkData.AimsunWithBEATSMapping;
vehListWithBeats=[];
for day=8:8 % Weekday   
    for i=1:size(aimsunWithBeatsInitialization,1) % Loop for all approaches 
        for t=from:interval:to % Loop for all prediction intervals
            queryMeasures=struct(...
                'year',     nan,...
                'month',    nan,...
                'day',      nan,...
                'dayOfWeek',day,...
                'median', 1,...
                'timeOfDay', [t t+interval]); % Use a longer time interval to obtain more reliable data
            
            [tmpVehList]=dp_initialization_beats.generate_vehicles_for_a_link...
                (aimsunWithBeatsInitialization(i),queryMeasures,querySetting,t);
            vehListWithBeats=[vehListWithBeats;tmpVehList];                
        end
    end
end
outputFolder=findFolder.aimsun_initialization;
dlmwrite(fullfile(outputFolder,'VehicleInfEstimation.csv'), vehListWithBeats, 'delimiter', ',', 'precision', 9); 

handles.appStateEst=appStateEst;
handles.recAimsunNet=recAimsunNet;
guidata(hObject, handles)
set(handles.EstimationTable,'Data',Table);

% --- Executes on button press in ViewInitialization.
function ViewInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to ViewInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



%% Run Aimsun Replication
% --- Executes on button press in RunAimsun.
function RunAimsun_Callback(hObject, eventdata, handles)
% hObject    handle to RunAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

FileLocation=get(handles.AimsunFileLocation,'String');
NameOfPythonCode='AimsunReplication.py';
AimsunFile=get(handles.AimsunProjectName,'String');
ReplicationID=get(handles.ReplicationID,'String');
dos(sprintf('aimsun.exe -script %s %s %s',fullfile(FileLocation,NameOfPythonCode),...
    fullfile(FileLocation,AimsunFile),ReplicationID));

% --- Executes on button press in SetReplicationID.
function SetReplicationID_Callback(hObject, eventdata, handles)
% hObject    handle to SetReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\SetReplicationID.m'));
