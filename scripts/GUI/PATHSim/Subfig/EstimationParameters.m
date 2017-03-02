function varargout = EstimationParameters(varargin)
%ESTIMATIONPARAMETERS MATLAB code file for EstimationParameters.fig
%      ESTIMATIONPARAMETERS, by itself, creates a new ESTIMATIONPARAMETERS or raises the existing
%      singleton*.
%
%      H = ESTIMATIONPARAMETERS returns the handle to a new ESTIMATIONPARAMETERS or the handle to
%      the existing singleton*.
%
%      ESTIMATIONPARAMETERS('Property','Value',...) creates a new ESTIMATIONPARAMETERS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to EstimationParameters_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      ESTIMATIONPARAMETERS('CALLBACK') and ESTIMATIONPARAMETERS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in ESTIMATIONPARAMETERS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EstimationParameters

% Last Modified by GUIDE v2.5 01-Mar-2017 14:27:25

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @EstimationParameters_OpeningFcn, ...
    'gui_OutputFcn',  @EstimationParameters_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
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


% --- Executes just before EstimationParameters is made visible.
function EstimationParameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for EstimationParameters
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes EstimationParameters wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = EstimationParameters_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function SearchIntervalEstimation_Callback(hObject, eventdata, handles)
% hObject    handle to SearchIntervalEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function SearchIntervalEstimation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SearchIntervalEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveEstimationParameters.
function SaveEstimationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to SaveEstimationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

%% Check input valus

% Stopbar detectors
if(str2double(handles.StopbarForLT_LT.String)~=1)
    handles.StopbarForLT_LT.String='1';
end

if(str2double(handles.StopbarForTh_Th.String)~=1)
    handles.StopbarForTh_Th.String='1';
end

if(str2double(handles.StopbarForRT_RT.String)~=1)
    handles.StopbarForRT_RT.String='1';
end

if(str2double(handles.StopbarForAll_Th.String)+str2double(handles.StopbarForAll_LT.String)...
        +str2double(handles.StopbarForAll_RT.String)~=1)
    handles.StopbarForAll_LT.String='0.15';
    handles.StopbarForAll_Th.String='0.8';
    handles.StopbarForAll_RT.String='0.05';
end

if(str2double(handles.StopbarForThRT_Th.String)+str2double(handles.StopbarForThRT_LT.String)...
        +str2double(handles.StopbarForThRT_RT.String)~=1)
    handles.StopbarForThRT_LT.String='0';
    handles.StopbarForThRT_Th.String='0.85';
    handles.StopbarForThRT_RT.String='0.15';
end

if(str2double(handles.StopbarForLTTh_Th.String)+str2double(handles.StopbarForLTTh_LT.String)...
        +str2double(handles.StopbarForLTTh_RT.String)~=1)
    handles.StopbarForLTTh_LT.String='0.3';
    handles.StopbarForLTTh_Th.String='0.7';
    handles.StopbarForLTTh_RT.String='0';
end

if(str2double(handles.StopbarForLTRT_Th.String)+str2double(handles.StopbarForLTRT_LT.String)...
        +str2double(handles.StopbarForLTRT_RT.String)~=1)
    handles.StopbarForLTRT_LT.String='0.5';
    handles.StopbarForLTRT_Th.String='0';
    handles.StopbarForLTRT_RT.String='0.5';
end

% Stopbar detectors
if(str2double(handles.AdvancedForLT_LT.String)~=1)
    handles.AdvancedForLT_LT.String='1';
end

if(str2double(handles.AdvancedForTh_Th.String)~=1)
    handles.AdvancedForTh_Th.String='1';
end

if(str2double(handles.AdvancedForRT_RT.String)~=1)
    handles.AdvancedForRT_RT.String='1';
end

if(str2double(handles.AdvancedForAll_Th.String)+str2double(handles.AdvancedForAll_LT.String)...
        +str2double(handles.AdvancedForAll_RT.String)~=1)
    handles.AdvancedForAll_LT.String='0.15';
    handles.AdvancedForAll_Th.String='0.8';
    handles.AdvancedForAll_RT.String='0.05';
end

if(str2double(handles.AdvancedForThRT_Th.String)+str2double(handles.AdvancedForThRT_LT.String)...
        +str2double(handles.AdvancedForThRT_RT.String)~=1)
    handles.AdvancedForThRT_LT.String='0';
    handles.AdvancedForThRT_Th.String='0.85';
    handles.AdvancedForThRT_RT.String='0.15';
end

if(str2double(handles.AdvancedForLTTh_Th.String)+str2double(handles.AdvancedForLTTh_LT.String)...
        +str2double(handles.AdvancedForLTTh_RT.String)~=1)
    handles.AdvancedForLTTh_LT.String='0.3';
    handles.AdvancedForLTTh_Th.String='0.7';
    handles.AdvancedForLTTh_RT.String='0';
end

if(str2double(handles.AdvancedForLTRT_Th.String)+str2double(handles.AdvancedForLTRT_LT.String)...
        +str2double(handles.AdvancedForLTRT_RT.String)~=1)
    handles.AdvancedForLTRT_LT.String='0.5';
    handles.AdvancedForLTRT_Th.String='0';
    handles.AdvancedForLTRT_RT.String='0.5';
end

%% Save results


default_params=struct(...
    'cycle',                                     str2double(handles.DefaultCycle.String),...
    'green_left',                                str2double(handles.DefaultGreenTimeForLeft.String),...
    'green_through',                             str2double(handles.DefaultGreenTimeForThrough.String),...
    'green_right',                               str2double(handles.DefaultGreenTimeForRight.String),...
    'speed_threshold_for_advanced_detector',     str2double(handles.SpeedThresholdForAdvanced.String),...
    'occupancy_threshold_for_advanced_detector', str2double(handles.OccThresholdForAdvanced.String),...
    'speed_freeflow_for_advanced_detector',      str2double(handles.FFSpeedForAdvanced.String),...
    'flow_threshold_for_stopline_detector',      str2double(handles.FlowToCapacityThresholdForStopbar.String),...
    'saturation_speed_left',                     str2double(handles.SaturationSpeedLeft.String),...
    'saturation_speed_right',                    str2double(handles.SaturationSpeedRight.String),...
    'saturation_speed_through',                  str2double(handles.SaturationSpeedThrough.String),...
    'distance_advanced_detector',                str2double(handles.DefaultDistanceToEndAdvanced.String),...
    'left_turn_pocket',                          str2double(handles.DefaultLeftTurnPocket.String),...
    'right_turn_pocket',                         str2double(handles.DefaultRightTurnPocket.String));

default_proportions=struct(...
    'Left_Turn',                        [str2double(handles.StopbarForLT_LT.String), 0, 0],...
    'Left_Turn_Queue',                  [0, 0, 0],...
    'Through',                          [0, str2double(handles.StopbarForTh_Th.String), 0],...
    'Right_Turn',                       [0, 0, str2double(handles.StopbarForRT_RT.String)],...
    'Right_Turn_Queue',                 [0, 0, 0],...
    'All_Movements',                    [str2double(handles.StopbarForAll_LT.String), ...
    str2double(handles.StopbarForAll_Th.String), str2double(handles.StopbarForAll_RT.String)],...
    'Through_and_Right',                [0, str2double(handles.StopbarForThRT_Th.String),...
    str2double(handles.StopbarForThRT_RT.String)],...
    'Left_and_Through',                 [str2double(handles.StopbarForLTTh_LT.String),...
    str2double(handles.StopbarForLTTh_Th.String), 0],...
    'Left_and_Right',                   [str2double(handles.StopbarForLTRT_LT.String), 0,...
    str2double(handles.StopbarForLTRT_RT.String)],...
    'Advanced_Left_Turn',               [str2double(handles.AdvancedForLT_LT.String), 0, 0],...
    'Advanced_Through',                 [0, str2double(handles.AdvancedForTh_Th.String), 0],...
    'Advanced_Right_Turn',              [0, 0, str2double(handles.AdvancedForRT_RT.String)],...
    'Advanced',                         [str2double(handles.AdvancedForAll_LT.String), ...
    str2double(handles.AdvancedForAll_Th.String), str2double(handles.AdvancedForAll_RT.String)],...
    'Advanced_Through_and_Right',       [0, str2double(handles.AdvancedForThRT_Th.String),...
    str2double(handles.AdvancedForThRT_RT.String)],...
    'Advanced_Left_and_Through',        [str2double(handles.AdvancedForLTTh_LT.String),...
    str2double(handles.AdvancedForLTTh_Th.String), 0],...
    'Advanced_Left_and_Right',          [str2double(handles.AdvancedForLTRT_LT.String), 0, ...
    str2double(handles.AdvancedForLTRT_RT.String)]);

EstimationParameters=struct(...
    'SearchIntervalEstimation',handles.SearchIntervalEstimation.String,...
    'default_params', default_params,...
    'default_proportions',default_proportions);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'EstimationParameters.mat'),'EstimationParameters');

% --- Executes on button press in ExitEstimationParameters.
function ExitEstimationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to ExitEstimationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)



function DefaultCycle_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultCycle.String)<0)
    handles.DefaultCycle.String='120';
end

% --- Executes during object creation, after setting all properties.
function DefaultCycle_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultCycle (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultGreenTimeForLeft_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultGreenTimeForLeft.String)<0 ||...
        str2double(handles.DefaultGreenTimeForLeft.String)>1)
    handles.DefaultGreenTimeForLeft.String='0.2';
end

% --- Executes during object creation, after setting all properties.
function DefaultGreenTimeForLeft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultGreenTimeForThrough_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForThrough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultGreenTimeForThrough.String)<0 ||...
        str2double(handles.DefaultGreenTimeForThrough.String)>1)
    handles.DefaultGreenTimeForThrough.String='0.35';
end

% --- Executes during object creation, after setting all properties.
function DefaultGreenTimeForThrough_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForThrough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultGreenTimeForRight_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultGreenTimeForRight.String)<0 ||...
        str2double(handles.DefaultGreenTimeForRight.String)>1)
    handles.DefaultGreenTimeForRight.String='0.35';
end

% --- Executes during object creation, after setting all properties.
function DefaultGreenTimeForRight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultGreenTimeForRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FlowToCapacityThresholdForStopbar_Callback(hObject, eventdata, handles)
% hObject    handle to FlowToCapacityThresholdForStopbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.FlowToCapacityThresholdForStopbar.String)<0 ||...
        str2double(handles.FlowToCapacityThresholdForStopbar.String)>1)
    handles.FlowToCapacityThresholdForStopbar.String='0.5';
end

% --- Executes during object creation, after setting all properties.
function FlowToCapacityThresholdForStopbar_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FlowToCapacityThresholdForStopbar (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function OccThresholdForAdvanced_Callback(hObject, eventdata, handles)
% hObject    handle to OccThresholdForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.OccThresholdForAdvanced.String)<0 ||...
        str2double(handles.OccThresholdForAdvanced.String)>1)
    handles.OccThresholdForAdvanced.String='0.15';
end

% --- Executes during object creation, after setting all properties.
function OccThresholdForAdvanced_CreateFcn(hObject, eventdata, handles)
% hObject    handle to OccThresholdForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function FFSpeedForAdvanced_Callback(hObject, eventdata, handles)
% hObject    handle to FFSpeedForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.FFSpeedForAdvanced.String)<0)
    handles.FFSpeedForAdvanced.String='35';
end

% --- Executes during object creation, after setting all properties.
function FFSpeedForAdvanced_CreateFcn(hObject, eventdata, handles)
% hObject    handle to FFSpeedForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SpeedThresholdForAdvanced_Callback(hObject, eventdata, handles)
% hObject    handle to SpeedThresholdForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.SpeedThresholdForAdvanced.String)<0)
    handles.SpeedThresholdForAdvanced.String='5';
end

% --- Executes during object creation, after setting all properties.
function SpeedThresholdForAdvanced_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SpeedThresholdForAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SaturationSpeedLeft_Callback(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.SaturationSpeedLeft.String)<0)
    handles.SaturationSpeedLeft.String='15';
end

% --- Executes during object creation, after setting all properties.
function SaturationSpeedLeft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SaturationSpeedThrough_Callback(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedThrough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.SaturationSpeedThrough.String)<0)
    handles.SaturationSpeedThrough.String='25';
end

% --- Executes during object creation, after setting all properties.
function SaturationSpeedThrough_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedThrough (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function SaturationSpeedRight_Callback(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.SaturationSpeedRight.String)<0)
    handles.SaturationSpeedRight.String='15';
end

% --- Executes during object creation, after setting all properties.
function SaturationSpeedRight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SaturationSpeedRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultRightTurnPocket_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultRightTurnPocket (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultRightTurnPocket.String)<0)
    handles.DefaultRightTurnPocket.String='100';
end

% --- Executes during object creation, after setting all properties.
function DefaultRightTurnPocket_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultRightTurnPocket (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultLeftTurnPocket_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultLeftTurnPocket (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultLeftTurnPocket.String)<0)
    handles.DefaultLeftTurnPocket.String='150';
end

% --- Executes during object creation, after setting all properties.
function DefaultLeftTurnPocket_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultLeftTurnPocket (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultDistanceToEndAdvanced_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultDistanceToEndAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if(str2double(handles.DefaultDistanceToEndAdvanced.String)<0)
    handles.DefaultDistanceToEndAdvanced.String='200';
end

% --- Executes during object creation, after setting all properties.
function DefaultDistanceToEndAdvanced_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultDistanceToEndAdvanced (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function AdvancedForLT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLT_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLT_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function AdvancedForLT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function AdvancedForLT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function AdvancedForLT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLT_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLT_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForTh_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForTh_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForTh_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForTh_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForTh_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForTh_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForTh_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForTh_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForTh_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForTh_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForTh_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForTh_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForRT_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForRT_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForRT_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForRT_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForRT_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForRT_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForThRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForThRT_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForThRT_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForThRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForThRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForThRT_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForThRT_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForThRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForThRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForThRT_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForThRT_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForThRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForThRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTTh_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTTh_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTTh_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTTh_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTTh_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTTh_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTTh_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTTh_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTTh_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTTh_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTTh_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTTh_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTRT_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTRT_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTRT_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTRT_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForLTRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForLTRT_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForLTRT_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForLTRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForLTRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function AdvancedForAll_Th_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForAll_Th as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForAll_Th as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForAll_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForAll_LT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForAll_LT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForAll_LT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForAll_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function AdvancedForAll_RT_Callback(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AdvancedForAll_RT as text
%        str2double(get(hObject,'String')) returns contents of AdvancedForAll_RT as a double


% --- Executes during object creation, after setting all properties.
function AdvancedForAll_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AdvancedForAll_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function StopbarForLT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function StopbarForAll_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function StopbarForAll_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function StopbarForAll_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForAll_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForAll_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForAll_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForAll_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function StopbarForThRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% --- Executes during object creation, after setting all properties.
function StopbarForThRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForThRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForThRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForThRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% --- Executes during object creation, after setting all properties.
function StopbarForThRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForThRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTTh_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTTh_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTTh_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTTh_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTTh_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTTh_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForLTRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function StopbarForLTRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForLTRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForTh_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForTh_Th as text
%        str2double(get(hObject,'String')) returns contents of StopbarForTh_Th as a double


% --- Executes during object creation, after setting all properties.
function StopbarForTh_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForTh_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForTh_RT as text
%        str2double(get(hObject,'String')) returns contents of StopbarForTh_RT as a double


% --- Executes during object creation, after setting all properties.
function StopbarForTh_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForRT_Th_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForRT_Th as text
%        str2double(get(hObject,'String')) returns contents of StopbarForRT_Th as a double


% --- Executes during object creation, after setting all properties.
function StopbarForRT_Th_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_Th (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForRT_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForRT_LT as text
%        str2double(get(hObject,'String')) returns contents of StopbarForRT_LT as a double


% --- Executes during object creation, after setting all properties.
function StopbarForRT_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function StopbarForRT_RT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForRT_RT as text
%        str2double(get(hObject,'String')) returns contents of StopbarForRT_RT as a double


% --- Executes during object creation, after setting all properties.
function StopbarForRT_RT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForRT_RT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end




function StopbarForTh_LT_Callback(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StopbarForTh_LT as text
%        str2double(get(hObject,'String')) returns contents of StopbarForTh_LT as a double


% --- Executes during object creation, after setting all properties.
function StopbarForTh_LT_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StopbarForTh_LT (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
