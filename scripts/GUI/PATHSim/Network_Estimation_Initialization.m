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

% Last Modified by GUIDE v2.5 26-Feb-2017 15:29:10

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
disp('*******************************************************')
disp('******Runing Estimation********************************')
disp('*******************************************************')
disp('*******************************************************')
disp('******Collecting Data!*********************************')
disp('*******************************************************')

inputFolder=findFolder.GUI_temp(); % This folder stores all temporary inputs from the Matlab GUI
if(exist(fullfile(inputFolder,'recAimsunNet.mat'),'file')) % Load the aimsun network file
    load(fullfile(inputFolder,'recAimsunNet.mat'));
    disp('Finish loading the Aimsun network files!')
else
    error('Please extract and reconstruct the Aimsun network first!')
end
if(exist(fullfile(inputFolder,'DataQueryParameter.mat'),'file')) % Loading data query settings
    load(fullfile(inputFolder,'DataQueryParameter.mat'));
    disp('Finish loading the data query settings!')
else
    error('Please set the data query parameters first!')
end
if(exist(fullfile(inputFolder,'EstimationParameters.mat'),'file')) % Loading estimation parameters
    load(fullfile(inputFolder,'EstimationParameters.mat'));
    disp('Finish loading the estimation parameters!')
else
    error('Please set the estimation parameters first!')
end
if(exist(fullfile(inputFolder,'VehicleParameters.mat'),'file')) % Loading vehicle parameters
    load(fullfile(inputFolder,'VehicleParameters.mat'));
    disp('Finish loading the vehicle parameters!')
else
    error('Please set the vehicle parameters first!')
end
if(exist(fullfile(inputFolder,'InitializationParameters.mat'),'file')) % Loading initialization parameters
    load(fullfile(inputFolder,'InitializationParameters.mat'));
    % Need to use this to define the turning
    DistanceToEnd=str2double(InitializationParameters.DistanceToEndTurning);
else
    DistanceToEnd=60;
end

% Construct the query parameters
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

% Get the default parameters
default_params=EstimationParameters.default_params;
default_params.vehicle_length=str2double(VehicleParameters.DefaultVehicleLength);
default_params.saturation_headway=str2double(VehicleParameters.DefaultHeadway);
default_params.start_up_lost_time=str2double(VehicleParameters.StartUpLostTime);
default_params.jam_spacing=str2double(VehicleParameters.DefaultJamSpacing);
default_params.distanceToEnd=DistanceToEnd;

% Get the default proportions
default_proportions=EstimationParameters.default_proportions;

%Get the data provider
dp_sensor=sensor_count_provider; % Sensor data
dp_midlink=midlink_count_provider; % Midlink count data
dp_turningCount=turning_count_provider; % Field observed turning count data

inputFolderLocation=findFolder.temp_aimsun_whole(); % This folder stores the simulated data from Aimsun
dp_simVehicle=simVehicle_data_provider(inputFolderLocation); % Get the simulated vehicle data provider

dp_beats=simBEATS_data_provider; % Beats data provider

dp_signal_sim=simSignal_data_provider; % Simulation signal data provider (currently not used)
dp_signal_field=fieldSignal_data_provider(inputFolder); % Field signal data provider
type=struct(...
    'ControlPlanSource',        'FromAimsun',...
    'LastCycleInformation',     'None');
dp_signal_field.timeStamp=from;
dp_signal_field.day=DayConfig;
dp_signal_field.source=type.ControlPlanSource;
dp_signal_field.LastCycleInformation=type.LastCycleInformation;
[dp_signal_field.activeControlPlans]=dp_signal_field...
    .get_active_control_plans_for_given_day_and_time(DayConfig,from,type.ControlPlanSource);

outputFolder=findFolder.estStateQueue_data; % Output folder for estimation results
disp('Finish loading the data providers!')


if(handles.ArterialFieldData.Value==1) % If arterial estimation is enabled!
    
    disp('*******************************************************')
    disp('******Estimation For Arterial links!*******************')
    disp('*******************************************************')
    
    %% Run state estimation
    
    % Generate the configuration of approaches for traffic state estimation
    appDataForEstimation=recAimsunNet.get_approach_config_for_estimation(recAimsunNet.networkData);
    
    % Run state estimation
    est=state_estimation(appDataForEstimation,dp_sensor,dp_midlink,dp_turningCount,dp_simVehicle,...
        dp_signal_sim, dp_signal_field);
    
    % Overwrite the default parameters using the ones from the GUI inputs
    est.default_params=default_params;
    est.default_proportions=default_proportions;
    
    ApproachStateEstimation=[];
    fileName='AimsunQueueEstimated.csv';
    for i=1:size(appDataForEstimation,1) % Loop for all approaches
        fprintf('Intersection: %d && Road: %s && Direction (section): %s \n', appDataForEstimation(i).intersection_id,...
            appDataForEstimation(i).road_name,appDataForEstimation(i).direction);
        tmp_approach=appDataForEstimation(i);
        %         [tmp_approach.turning_count_properties.proportions]=est.update_vehicle_proportions(tmp_approach,queryMeasures);
        [tmp_approach.turning_count_properties.proportions]=...
            est.update_vehicle_proportions_with_multiple_data_sources(tmp_approach,queryMeasures);

        [tmp_approach]=est.get_sensor_data_for_approach(tmp_approach,queryMeasures);
        [tmp_approach.decision_making]=est.get_traffic_condition_by_approach(tmp_approach,queryMeasures);
        ApproachStateEstimation=[ApproachStateEstimation;tmp_approach];
    end
    ArterialEstimationTable=est.extract_to_csv(ApproachStateEstimation,outputFolder,fileName);
    save(fullfile(inputFolder,sprintf('ApproachStateEstimation_%s.mat',DayConfig)),'ApproachStateEstimation');
    save(fullfile(inputFolder,'ArterialEstimationTable.mat'),'ArterialEstimationTable');
    
    disp('*******************************************************')
    disp('******Done with Arterial Links!************************')
    disp('*******************************************************')
end

if(handles.FreewayBeats.Value==1)
    disp('*******************************************************')
    disp('******Estimation For Freeway links!********************')
    disp('*******************************************************')
    %% Load the network information file
    % Aimsun
    fileName=fullfile(inputFolder,'BeatsNetwork.mat');
    if(exist(fileName,'file'))
        load(fileName); % Variable: BeatsNetwork
        dp_network_BEATS=BeatsNetwork.DataProvider;
        data=BeatsNetwork.Data;
    else
        error('Please load and reconstruct the BEATS network first!')
    end
    
    %% Estimation
    EstimationResultsBeats=[];
    AimsunWithBEATSMapping=data.AimsunWithBEATSMapping;
    for i=1:size(AimsunWithBEATSMapping,1) % Loop for each Aimsun link
        AimsunLinkID=AimsunWithBEATSMapping(i).AimsunLinkID;
        BeatsLinks=AimsunWithBEATSMapping(i).BEATSLinks; % In each Aimsun link, there can be several BEATS links
        BeatsLinkIDs=[BeatsLinks.SimLinkID]'; % This is the simulation IDs for BEATS links
        % Note: Aimsun ID <--Mapping--> BEATS Link ID <--Mapping--> BEAT Link ID In Simulation
        
        % Obtain the simulated BEATS data
        beatsLinkData=initialization_in_aimsun_with_beats.get_estimates_from_beats_simulation...
            (BeatsLinkIDs,dp_beats,queryMeasures);
        AimsunWithBEATSMapping(i).BEATSLinkData=beatsLinkData;
        
        for j=1:size(beatsLinkData,1) % Loop for each BEATS Link
            fprintf('Aimsun Link ID:%d && BEATS Link ID: %d\n', AimsunLinkID, BeatsLinkIDs(j))
            [avgDensityBeats,avgDensityStdDevBeats,avgSpeedBeats,avgSpeedStdDevBeats]=...
                initialization_in_aimsun_with_beats.get_averages(beatsLinkData(j));
            EstimationResultsBeats=[EstimationResultsBeats;...
                [AimsunLinkID,BeatsLinkIDs(j),from,avgDensityBeats,avgDensityStdDevBeats,avgSpeedBeats,avgSpeedStdDevBeats]];
        end
    end
    dlmwrite(fullfile(outputFolder,'EstimationResultsBeats.csv'), ...
        EstimationResultsBeats, 'delimiter', ',', 'precision', 9);
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

if(handles.InitializationVehicle.Value==1)
    set(handles.VehicleFromAimsun,'Value',1)
else
    set(handles.VehicleFromAimsun,'Value',0)
    set(handles.VehicleFromField,'Value',0)
    set(handles.VehicleFromBEATS,'Value',0)
end

% --- Executes on button press in InitializationPhase.
function InitializationPhase_Callback(hObject, eventdata, handles)
% hObject    handle to InitializationPhase (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of InitializationPhase

% --- Executes on button press in VehicleFromField.
function VehicleFromField_Callback(hObject, eventdata, handles)
% hObject    handle to VehicleFromField (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VehicleFromField


% --- Executes on button press in VehicleFromBEATS.
function VehicleFromBEATS_Callback(hObject, eventdata, handles)
% hObject    handle to VehicleFromBEATS (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VehicleFromBEATS


% --- Executes on button press in VehicleFromAimsun.
function VehicleFromAimsun_Callback(hObject, eventdata, handles)
% hObject    handle to VehicleFromAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VehicleFromAimsun


% --- Executes on button press in RunInitialization.
function RunInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to RunInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc
disp('*******************************************************')
disp('************Traffic State Initialization!**************')
disp('*******************************************************')
%% Collecting data
disp('*******************************************************')
disp('******Collecting Data!*********************************')
disp('*******************************************************')
% Load network files: Aimsun Network an BEATS Network
inputFolder=findFolder.GUI_temp();
if(exist(fullfile(inputFolder,'recAimsunNet.mat'),'file'))
    load(fullfile(inputFolder,'recAimsunNet.mat'));
else
    error('Please extract and reconstruct the Aimsun network first!')
end
if(exist(fullfile(inputFolder,'BeatsNetwork.mat'),'file'))
    load(fullfile(inputFolder,'BeatsNetwork.mat'));
else
    error('Please extract and reconstruct the BEATS network first!')
end

% Initialization parameters
if(exist(fullfile(inputFolder,'InitializationParameters.mat'),'file'))
    load(fullfile(inputFolder,'InitializationParameters.mat'));
else
    error('Please set the initialization parameters first!')
end
SearchInitializationConfig=str2double(InitializationParameters.SearchIntervalInitialization);
DistanceToEnd=str2double(InitializationParameters.DistanceToEndTurning);
querySetting=struct(... % Query settings
    'SearchTimeDuration', SearchInitializationConfig,...
    'Distance', DistanceToEnd);

% Load data query parameters
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
days={'All','Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Weekday','Weekend'};
DayConfig=DataQueryParameter.DaySetting; % Day
currentTime=str2double(DataQueryParameter.TimeSetting)*3600; % Time
SelectedDayID=find(ismember(days,DayConfig)==1);
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
    'timeOfDay', [currentTime-interval currentTime]); % Use a longer time interval to obtain more reliable data

% Signal data providers
dp_signal_sim=simSignal_data_provider; % Simulation signal
dp_signal_field=fieldSignal_data_provider(inputFolder); % Field signal
type=struct(...
    'ControlPlanSource',        'FromAimsun',...
    'LastCycleInformation',     'None');
dp_signal_field.timeStamp=currentTime;
dp_signal_field.day=DayConfig;
dp_signal_field.source=type.ControlPlanSource;
dp_signal_field.LastCycleInformation=type.LastCycleInformation;
[dp_signal_field.activeControlPlans]=dp_signal_field...
    .get_active_control_plans_for_given_day_and_time(DayConfig,currentTime,type.ControlPlanSource);

% simVehicle data provider
inputFolderLocation=findFolder.temp_aimsun_whole();
dp_vehicle=simVehicle_data_provider(inputFolderLocation);

% Beats data provider
ptr_beats=simBEATS_data_provider;

% Vehicle parameters
if(exist(fullfile(inputFolder,'VehicleParameters.mat'),'file'))
    load(fullfile(inputFolder,'VehicleParameters.mat'));
else
    error('Please set the vehicle parameters first!')
end
VehicleLength=str2double(VehicleParameters.DefaultVehicleLength);
JamSpacing=str2double(VehicleParameters.DefaultJamSpacing);
Headway=str2double(VehicleParameters.DefaultHeadway);
defaultParams=struct(... % Default parameters
    'VehicleLength', VehicleLength,...
    'JamSpacing', JamSpacing,...
    'Headway', Headway);

% Load the estStateQueue file
dp_StateQueue=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
% Estimated queues
estStateQueue=dp_StateQueue.parse_csv('AimsunQueueEstimated.csv',dp_StateQueue.folderLocation);
% BEATS Simulation;
beatsEstimates=csvread(fullfile(dp_StateQueue.folderLocation,'EstimationResultsBeats.csv'));

%% Get the activated signal phases
if(handles.InitializationPhase.Value==1)
    disp('*********************************************')
    disp('*****Determining Signal Phases***************')
    disp('*********************************************')
    
    outputLocation=findFolder.aimsun_initialization();
    dp_initialization=initialization_in_aimsun(recAimsunNet.networkData,...
        estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan);
    [PhaseListTable,phaseListAimsun]=dp_initialization.determine_phases(type);
    save(fullfile(inputFolder,'PhaseListTable.mat'),'PhaseListTable'); % Saved for View
    dlmwrite(fullfile(outputLocation,'SignalInfEstimation.csv'), phaseListAimsun,...
        'delimiter', ',', 'precision', 9);
    
    disp('*********************************************')
    disp('Done!')
    disp('*********************************************')
    
end

%% Generate simulated vehicles
if(handles.InitializationVehicle.Value==1)
    disp('*********************************************')
    disp('*****Generating Simulated Vehicles***********')
    disp('*********************************************')
    dp_initialization=initialization_in_aimsun...
        (recAimsunNet.networkData,estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan);
    dp_initialization_beats=initialization_in_aimsun_with_beats...
        (BeatsNetwork.Data,dp_vehicle,ptr_beats,defaultParams,nan);
    VehicleListTable=[];
    % By default: VehicleFromSimulation==1
    if(handles.VehicleFromField.Value==0 && handles.VehicleFromBEATS.Value==0)
        % Only use aimsun simulation
        for i=1:size(recAimsunNet.networkData,1) % Loop for each approach
            junctionSectionInf=recAimsunNet.networkData(i);
            [statisticsSection]=dp_initialization.get_vehicle_statistics_from_simulation...
                (junctionSectionInf,dp_vehicle,querySetting,currentTime);
            for j=1:size(statisticsSection,1)
                [tmpVehicleList]=dp_initialization.generate_vehicle_without_fieldEstimation...
                    (junctionSectionInf,statisticsSection(j).data,currentTime);
                VehicleListTable=[VehicleListTable;tmpVehicleList];
            end
        end
    elseif(handles.VehicleFromField.Value==1 && handles.VehicleFromBEATS.Value==0)
        % Use field data and Aimsun results
        VehicleListTable=dp_initialization.generate_vehicle(querySetting);
        
    elseif(handles.VehicleFromField.Value==0 && handles.VehicleFromBEATS.Value==1)
        % If use BEATS and Aimsun results
        % Get the BEATS network
        AimsunWithBEATSMapping=BeatsNetwork.Data.AimsunWithBEATSMapping;
        sectionsAimsunInBeats=[AimsunWithBEATSMapping.AimsunLinkID]';
        
        for i=1:size(recAimsunNet.networkData,1) % Loop for each approach
            junctionSectionInf=recAimsunNet.networkData(i);
            sections=junctionSectionInf.SectionBelongToApproach.ListOfSections;
            [idx,address]=ismember(sections,sectionsAimsunInBeats);
            [statisticsSection]=dp_initialization.get_vehicle_statistics_from_simulation...
                (junctionSectionInf,dp_vehicle,querySetting,currentTime);
            
            for j=1:size(statisticsSection,1)
                if(idx(j)==0)
                    [tmpVehicleList]=dp_initialization.generate_vehicle_without_fieldEstimation...
                        (junctionSectionInf,statisticsSection(j).data,currentTime);
                else
                    [tmpVehicleList]=dp_initialization_beats.generate_vehicles_for_a_link...
                        (AimsunWithBEATSMapping(address(j),:),queryMeasures,querySetting,currentTime);
                    if(isempty(tmpVehicleList))
                        fprintf('No simulated vehicles generated from BEATS for link %d, use Aimsun simulation results instead\n',sections(j));
                        [tmpVehicleList]=dp_initialization.generate_vehicle_without_fieldEstimation...
                            (junctionSectionInf,statisticsSection(j).data,currentTime);
                    end
                end
                VehicleListTable=[VehicleListTable;tmpVehicleList];
            end
        end
    else
        % If use BEATS, Field data, and Aimsun results
        % Get the BEATS network
        AimsunWithBEATSMapping=BeatsNetwork.Data.AimsunWithBEATSMapping;
        sectionsAimsunInBeats=[AimsunWithBEATSMapping.AimsunLinkID]';
        
        % Divided the network data to two parts: signalized and
        % unsignalized
        junctionSignalizedIdx=[recAimsunNet.networkData.Signalized]';
        networkDataSignalized=recAimsunNet.networkData(junctionSignalizedIdx==1,:);
        networkDataUnsignalized=recAimsunNet.networkData(junctionSignalizedIdx~=1,:);
        
        dp_initialization.networkData=networkDataSignalized;
        
        VehicleListTable=dp_initialization.generate_vehicle(querySetting);
        
        for i=1:size(networkDataUnsignalized,1) % Loop for each approach
            junctionSectionInf=networkDataUnsignalized(i);
            sections=junctionSectionInf.SectionBelongToApproach.ListOfSections;
            [idx,address]=ismember(sections,sectionsAimsunInBeats);
            [statisticsSection]=dp_initialization.get_vehicle_statistics_from_simulation...
                (junctionSectionInf,dp_vehicle,querySetting,currentTime);
            
            for j=1:size(statisticsSection,1)
                if(idx(j)==0)
                    [tmpVehicleList]=dp_initialization.generate_vehicle_without_fieldEstimation...
                        (junctionSectionInf,statisticsSection(j).data,currentTime);
                else
                    [tmpVehicleList]=dp_initialization_beats.generate_vehicles_for_a_link...
                        (AimsunWithBEATSMapping(address(j),:),queryMeasures,querySetting,currentTime);
                    if(isempty(tmpVehicleList))
                        fprintf('No simulated vehicles generated from BEATS for link %d, use Aimsun simulation results instead\n',sections(j));
                        [tmpVehicleList]=dp_initialization.generate_vehicle_without_fieldEstimation...
                            (junctionSectionInf,statisticsSection(j).data,currentTime);
                    end
                end
                VehicleListTable=[VehicleListTable;tmpVehicleList];
            end
        end
    end
    
    save(fullfile(inputFolder,'VehicleListTable.mat'),'VehicleListTable'); % Saved for View
    outputFolder=findFolder.aimsun_initialization;
    dlmwrite(fullfile(outputFolder,'VehicleInfEstimation.csv'), VehicleListTable, 'delimiter', ',', 'precision', 9);
    disp('*********************************************')
    disp('Done!')
    disp('*********************************************')
end

% --- Executes on button press in ViewInitialization.
function ViewInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to ViewInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(handles.InitializationPhase.Value==1 && handles.InitializationVehicle.Value==1)
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\VehiclePhaseTable.m'));
elseif(handles.InitializationPhase.Value==1 && handles.InitializationVehicle.Value==0)
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\PhaseTable.m'));
elseif(handles.InitializationPhase.Value==0 && handles.InitializationVehicle.Value==1)
    here = fileparts(mfilename('fullpath'));
    run(fullfile(here,'\Subfig\VehicleTable.m'));
end


%% Run Aimsun Replication
% --- Executes on button press in RunAimsun.
function RunAimsun_Callback(hObject, eventdata, handles)
% hObject    handle to RunAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%Aimsun
tmpFileFolder=findFolder.GUI_temp();
fileName=fullfile(tmpFileFolder,'AimsunProjectSetting.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: AimsunProjectSetting
else
    error('Can not find the Aimsun project settings!')
end
fileName=fullfile(tmpFileFolder,'ReplicationID.mat');
if(exist(fileName,'file'))
    load(fileName); % Variable: ReplicationID
else
    error('Can not find the setting of replication ID!')
end

FileLocation=AimsunProjectSetting.FileLocation;
NameOfPythonCode='AimsunReplication.py';
AimsunFile=AimsunProjectSetting.AimsunFile;
dos(sprintf('aimsun.exe -script %s %s %d',fullfile(FileLocation,NameOfPythonCode),...
    fullfile(FileLocation,AimsunFile),ReplicationID));

% --- Executes on button press in SetReplicationID.
function SetReplicationID_Callback(hObject, eventdata, handles)
% hObject    handle to SetReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
here = fileparts(mfilename('fullpath'));
run(fullfile(here,'\Subfig\SetReplicationID.m'));


