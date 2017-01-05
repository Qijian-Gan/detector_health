function varargout = Arterial_Estimation_Initialization(varargin)
% ARTERIAL_ESTIMATION_INITIALIZATION MATLAB code for Arterial_Estimation_Initialization.fig
%      ARTERIAL_ESTIMATION_INITIALIZATION, by itself, creates a new ARTERIAL_ESTIMATION_INITIALIZATION or raises the existing
%      singleton*.
%
%      H = ARTERIAL_ESTIMATION_INITIALIZATION returns the handle to a new ARTERIAL_ESTIMATION_INITIALIZATION or the handle to
%      the existing singleton*.
%
%      ARTERIAL_ESTIMATION_INITIALIZATION('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ARTERIAL_ESTIMATION_INITIALIZATION.M with the given input arguments.
%
%      ARTERIAL_ESTIMATION_INITIALIZATION('Property','Value',...) creates a new ARTERIAL_ESTIMATION_INITIALIZATION or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Arterial_Estimation_Initialization_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Arterial_Estimation_Initialization_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Arterial_Estimation_Initialization

% Last Modified by GUIDE v2.5 03-Jan-2017 16:48:00

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Arterial_Estimation_Initialization_OpeningFcn, ...
                   'gui_OutputFcn',  @Arterial_Estimation_Initialization_OutputFcn, ...
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


% --- Executes just before Arterial_Estimation_Initialization is made visible.
function Arterial_Estimation_Initialization_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Arterial_Estimation_Initialization (see VARARGIN)

% Choose default command line output for Arterial_Estimation_Initialization
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Arterial_Estimation_Initialization wait for user response (see UIRESUME)
% uiwait(handles.figure1);
axes(handles.axes1)
matlabImage = imread(...
    'C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\scripts\GUI\UC_Berkeley_Seal_80px.jpg');
image(matlabImage)
axis off
axis image
axes(handles.axes2)
matlabImage = imread(...
    'C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\scripts\GUI\UCBerkeley_wordmark_gold.png');
image(matlabImage)
axis off
axis image

axes(handles.axes3)
matlabImage = imread(...
    'C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\scripts\GUI\Path_logo_0.jpg');
image(matlabImage)
axis off
axis image

handles.EstimationTable.ColumnName = {'Junction ID','Junction Name','Junction ExtID','Signalized',...
                'Direction (Section ID)','Section Name','Section ExtID','Time',...
                'Left Turn Status','Through movement Status','Right Turn Status',...
                'Left Turn Queue','Through movement Queue','Right Turn Queue'};

handles.InitializationTable.ColumnName = {'Aimsun Section ID','Lane ID','Vehicle Type','Origin ID',...
                'Destination ID','Distance To End (ft)','Speed (mph)','Track Or Not'};
            

% --- Outputs from this function are returned to the command line.
function varargout = Arterial_Estimation_Initialization_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in RunEstimation.
function RunEstimation_Callback(hObject, eventdata, handles)
% hObject    handle to RunEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

clc 

disp('*******************************************************')
disp('***************Running State Estimation!***************')
disp('*******************************************************')
%% Load the network information file
% Input folder
InputFolder=get(handles.InputFolder,'String');
if (strcmp(InputFolder,'Default'))
    dp_network=load_aimsun_network_files; % With empty input: Default folder ('data\aimsun_networkData')
else
    dp_network=load_aimsun_network_files(InputFolder); % With empty input: Default folder ('data\aimsun_networkData')
end
% Junction input file
JunctionInfFile=get(handles.JunctionInfFile,'String');     
junctionData=dp_network.parse_junctionInf_txt(JunctionInfFile);
% Section input file
SectionInfFile=get(handles.SectionInfFile,'String');   
sectionData=dp_network.parse_sectionInf_txt(SectionInfFile);
% Detector data file
DetectorInfFile=get(handles.DetectorInfFile,'String');   
detectorData=dp_network.parse_detectorInf_csv(DetectorInfFile);
% Default signal settings
DefaultSigInfFile=get(handles.DefaultSigInfFile,'String');  
defaultSigSettingData=dp_network.parse_defaultSigSetting_csv(DefaultSigInfFile);
% Midlink config data
MidlinkCountInfFile=get(handles.MidlinkCountInfFile,'String');  
midlinkConfigData=dp_network.parse_midlinkCountConfig_csv(MidlinkCountInfFile);

%% Reconstruct the Aimsun network
recAimsunNet=reconstruct_aimsun_network(junctionData,sectionData,detectorData,defaultSigSettingData,midlinkConfigData,nan);
% Reconstruct the network
recAimsunNet.networkData=recAimsunNet.reconstruction();
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

handles.appStateEst=appStateEst;
handles.recAimsunNet=recAimsunNet;
guidata(hObject, handles)
set(handles.EstimationTable,'Data',Table);

% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes on button press in RunInitialization.
function RunInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to RunInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

disp('*******************************************************')
disp('***************Running State Initialization!***************')
disp('*******************************************************')
% Load the estStateQueue file
dp_StateQueue=load_estStateQueue_data; % With empty input: Default folder ('data\estStateQueueData')
estStateQueue=dp_StateQueue.parse_csv('aimsun_queue_estimated.csv',dp_StateQueue.folderLocation);

% simVehicle data provider
dp_vehicle=simVehicle_data_provider; 

% simSignal data provider
dp_signal_sim=simSignal_data_provider;
dp_signal_field=fieldSignal_data_provider;

% Generate vehicles
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

dp_initialization=initialization_in_aimsun(handles.recAimsunNet.networkData,estStateQueue,dp_vehicle,dp_signal_sim,dp_signal_field,defaultParams,nan); % Currently missing field signal data provider
vehicleList=dp_initialization.generate_vehicle(querySetting);

set(handles.InitializationTable,'Data',vehicleList);
dlmwrite('VehicleInfEstimation.csv', vehicleList, 'delimiter', ',', 'precision', 9); 


% --- Executes on button press in RunAimsun.
function RunAimsun_Callback(hObject, eventdata, handles)
% hObject    handle to RunAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

FileLocation=get(handles.FileLocation,'String');
NameOfPythonCode=get(handles.NameOfPythonCode,'String');
AimsunFile=get(handles.AimsunFile,'String');
ReplicationID=get(handles.ReplicationID,'String');
dos(sprintf('aimsun.exe -script %s %s %s',fullfile(FileLocation,NameOfPythonCode),...
    fullfile(FileLocation,AimsunFile),ReplicationID));



function InputFolder_Callback(hObject, eventdata, handles)
% hObject    handle to InputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of InputFolder as text
%        str2double(get(hObject,'String')) returns contents of InputFolder as a double


% --- Executes during object creation, after setting all properties.
function InputFolder_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function JunctionInfFile_Callback(hObject, eventdata, handles)
% hObject    handle to JunctionInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of JunctionInfFile as text
%        str2double(get(hObject,'String')) returns contents of JunctionInfFile as a double


% --- Executes during object creation, after setting all properties.
function JunctionInfFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to JunctionInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SectionInfFile_Callback(hObject, eventdata, handles)
% hObject    handle to SectionInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SectionInfFile as text
%        str2double(get(hObject,'String')) returns contents of SectionInfFile as a double


% --- Executes during object creation, after setting all properties.
function SectionInfFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SectionInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DetectorInfFile_Callback(hObject, eventdata, handles)
% hObject    handle to DetectorInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DetectorInfFile as text
%        str2double(get(hObject,'String')) returns contents of DetectorInfFile as a double


% --- Executes during object creation, after setting all properties.
function DetectorInfFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DetectorInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultSigInfFile_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultSigInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DefaultSigInfFile as text
%        str2double(get(hObject,'String')) returns contents of DefaultSigInfFile as a double


% --- Executes during object creation, after setting all properties.
function DefaultSigInfFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultSigInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MidlinkCountInfFile_Callback(hObject, eventdata, handles)
% hObject    handle to MidlinkCountInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MidlinkCountInfFile as text
%        str2double(get(hObject,'String')) returns contents of MidlinkCountInfFile as a double


% --- Executes during object creation, after setting all properties.
function MidlinkCountInfFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MidlinkCountInfFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in LoadAllFiles.
function LoadAllFiles_Callback(hObject, eventdata, handles)
% hObject    handle to LoadAllFiles (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function DayConfig_Callback(hObject, eventdata, handles)
% hObject    handle to DayConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DayConfig as text
%        str2double(get(hObject,'String')) returns contents of DayConfig as a double


% --- Executes during object creation, after setting all properties.
function DayConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DayConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TimeStampConfig_Callback(hObject, eventdata, handles)
% hObject    handle to TimeStampConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TimeStampConfig as text
%        str2double(get(hObject,'String')) returns contents of TimeStampConfig as a double


% --- Executes during object creation, after setting all properties.
function TimeStampConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TimeStampConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SearchEstimationConfig_Callback(hObject, eventdata, handles)
% hObject    handle to SearchEstimationConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SearchEstimationConfig as text
%        str2double(get(hObject,'String')) returns contents of SearchEstimationConfig as a double


% --- Executes during object creation, after setting all properties.
function SearchEstimationConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SearchEstimationConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SearchInitializationConfig_Callback(hObject, eventdata, handles)
% hObject    handle to SearchInitializationConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SearchInitializationConfig as text
%        str2double(get(hObject,'String')) returns contents of SearchInitializationConfig as a double


% --- Executes during object creation, after setting all properties.
function SearchInitializationConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SearchInitializationConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DistanceToEnd_Callback(hObject, eventdata, handles)
% hObject    handle to DistanceToEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistanceToEnd as text
%        str2double(get(hObject,'String')) returns contents of DistanceToEnd as a double


% --- Executes during object creation, after setting all properties.
function DistanceToEnd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistanceToEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function VehicleLength_Callback(hObject, eventdata, handles)
% hObject    handle to VehicleLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of VehicleLength as text
%        str2double(get(hObject,'String')) returns contents of VehicleLength as a double


% --- Executes during object creation, after setting all properties.
function VehicleLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to VehicleLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function JamSpacing_Callback(hObject, eventdata, handles)
% hObject    handle to JamSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of JamSpacing as text
%        str2double(get(hObject,'String')) returns contents of JamSpacing as a double


% --- Executes during object creation, after setting all properties.
function JamSpacing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to JamSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Headway_Callback(hObject, eventdata, handles)
% hObject    handle to Headway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Headway as text
%        str2double(get(hObject,'String')) returns contents of Headway as a double


% --- Executes during object creation, after setting all properties.
function Headway_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Headway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function MedianConfig_Callback(hObject, eventdata, handles)
% hObject    handle to MedianConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MedianConfig as text
%        str2double(get(hObject,'String')) returns contents of MedianConfig as a double


% --- Executes during object creation, after setting all properties.
function MedianConfig_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MedianConfig (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in UpdateSettings.
function UpdateSettings_Callback(hObject, eventdata, handles)
% hObject    handle to UpdateSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



function FileLocation_Callback(hObject, eventdata, handles)
% hObject    handle to FileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of FileLocation as text
%        str2double(get(hObject,'String')) returns contents of FileLocation as a double


% --- Executes during object creation, after setting all properties.
function FileLocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function NameOfPythonCode_Callback(hObject, eventdata, handles)
% hObject    handle to NameOfPythonCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of NameOfPythonCode as text
%        str2double(get(hObject,'String')) returns contents of NameOfPythonCode as a double


% --- Executes during object creation, after setting all properties.
function NameOfPythonCode_CreateFcn(hObject, eventdata, handles)
% hObject    handle to NameOfPythonCode (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AimsunFile_Callback(hObject, eventdata, handles)
% hObject    handle to AimsunFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AimsunFile as text
%        str2double(get(hObject,'String')) returns contents of AimsunFile as a double


% --- Executes during object creation, after setting all properties.
function AimsunFile_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AimsunFile (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function ReplicationID_Callback(hObject, eventdata, handles)
% hObject    handle to ReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ReplicationID as text
%        str2double(get(hObject,'String')) returns contents of ReplicationID as a double


% --- Executes during object creation, after setting all properties.
function ReplicationID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
