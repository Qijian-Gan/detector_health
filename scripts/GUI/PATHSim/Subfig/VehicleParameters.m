function varargout = VehicleParameters(varargin)
%VEHICLEPARAMETERS MATLAB code file for VehicleParameters.fig
%      VEHICLEPARAMETERS, by itself, creates a new VEHICLEPARAMETERS or raises the existing
%      singleton*.
%
%      H = VEHICLEPARAMETERS returns the handle to a new VEHICLEPARAMETERS or the handle to
%      the existing singleton*.
%
%      VEHICLEPARAMETERS('Property','Value',...) creates a new VEHICLEPARAMETERS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to VehicleParameters_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      VEHICLEPARAMETERS('CALLBACK') and VEHICLEPARAMETERS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in VEHICLEPARAMETERS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VehicleParameters

% Last Modified by GUIDE v2.5 01-Mar-2017 15:43:13

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VehicleParameters_OpeningFcn, ...
                   'gui_OutputFcn',  @VehicleParameters_OutputFcn, ...
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


% --- Executes just before VehicleParameters is made visible.
function VehicleParameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for VehicleParameters
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes VehicleParameters wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = VehicleParameters_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function DefaultVehicleLength_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultVehicleLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DefaultVehicleLength as text
%        str2double(get(hObject,'String')) returns contents of DefaultVehicleLength as a double


% --- Executes during object creation, after setting all properties.
function DefaultVehicleLength_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultVehicleLength (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultJamSpacing_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultJamSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DefaultJamSpacing as text
%        str2double(get(hObject,'String')) returns contents of DefaultJamSpacing as a double


% --- Executes during object creation, after setting all properties.
function DefaultJamSpacing_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultJamSpacing (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function DefaultHeadway_Callback(hObject, eventdata, handles)
% hObject    handle to DefaultHeadway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DefaultHeadway as text
%        str2double(get(hObject,'String')) returns contents of DefaultHeadway as a double


% --- Executes during object creation, after setting all properties.
function DefaultHeadway_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DefaultHeadway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveVehicleParameters.
function SaveVehicleParameters_Callback(hObject, eventdata, handles)
% hObject    handle to SaveVehicleParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
VehicleParameters=struct(...
    'DefaultVehicleLength',handles.DefaultVehicleLength.String,...
    'DefaultJamSpacing',handles.DefaultJamSpacing.String,...
    'DefaultHeadway',handles.DefaultHeadway.String,...
    'StartUpLostTime', handles.StartUpLostTime.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'VehicleParameters.mat'),'VehicleParameters');

% --- Executes on button press in ExitVehicleParameters.
function ExitVehicleParameters_Callback(hObject, eventdata, handles)
% hObject    handle to ExitVehicleParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)



function StartUpLostTime_Callback(hObject, eventdata, handles)
% hObject    handle to StartUpLostTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of StartUpLostTime as text
%        str2double(get(hObject,'String')) returns contents of StartUpLostTime as a double


% --- Executes during object creation, after setting all properties.
function StartUpLostTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to StartUpLostTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
