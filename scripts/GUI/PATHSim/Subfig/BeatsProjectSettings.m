function varargout = BeatsProjectSettings(varargin)
% BEATSPROJECTSETTINGS MATLAB code for BeatsProjectSettings.fig
%      BEATSPROJECTSETTINGS, by itself, creates a new BEATSPROJECTSETTINGS or raises the existing
%      singleton*.
%
%      H = BEATSPROJECTSETTINGS returns the handle to a new BEATSPROJECTSETTINGS or the handle to
%      the existing singleton*.
%
%      BEATSPROJECTSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in BEATSPROJECTSETTINGS.M with the given input arguments.
%
%      BEATSPROJECTSETTINGS('Property','Value',...) creates a new BEATSPROJECTSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before BeatsProjectSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to BeatsProjectSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help BeatsProjectSettings

% Last Modified by GUIDE v2.5 23-Feb-2017 13:50:38

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @BeatsProjectSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @BeatsProjectSettings_OutputFcn, ...
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


% --- Executes just before BeatsProjectSettings is made visible.
function BeatsProjectSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to BeatsProjectSettings (see VARARGIN)

% Choose default command line output for BeatsProjectSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes BeatsProjectSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);
                                     
% --- Outputs from this function are returned to the command line.
function varargout = BeatsProjectSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function BeatsFileLocation_Callback(hObject, eventdata, handles)
% hObject    handle to BeatsFileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of BeatsFileLocation as text
%        str2double(get(hObject,'String')) returns contents of BeatsFileLocation as a double

function XMLFileName_Callback(hObject, eventdata, handles)
% hObject    handle to XMLFileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of XMLFileName as text
%        str2double(get(hObject,'String')) returns contents of XMLFileName as a double

% --- Executes during object creation, after setting all properties.
function XMLFileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to XMLFileName (see GCBO)
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


% --- Executes during object creation, after setting all properties.
function BeatsFileLocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to BeatsFileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function MapingBeatsSimulationID_Callback(hObject, eventdata, handles)
% hObject    handle to MapingBeatsSimulationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MapingBeatsSimulationID as text
%        str2double(get(hObject,'String')) returns contents of MapingBeatsSimulationID as a double


% --- Executes during object creation, after setting all properties.
function MapingBeatsSimulationID_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MapingBeatsSimulationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveSettings.
function SaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

BeatsProjectSetting=struct(...
    'FileLocation',get(handles.BeatsFileLocation,'String'),...
    'XMLNetwork',get(handles.XMLFileName,'String'),...
    'XMLMapping',handles.MapingBeatsSimulationID.String,...
    'BEATSWithAimsunMapping',handles.MappingBeatsAimsun.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'BeatsProjectSetting.mat'),'BeatsProjectSetting');

% --- Executes on button press in ExitSettings.
function ExitSettings_Callback(hObject, eventdata, handles)
% hObject    handle to ExitSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)



function MappingBeatsAimsun_Callback(hObject, eventdata, handles)
% hObject    handle to MappingBeatsAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of MappingBeatsAimsun as text
%        str2double(get(hObject,'String')) returns contents of MappingBeatsAimsun as a double


% --- Executes during object creation, after setting all properties.
function MappingBeatsAimsun_CreateFcn(hObject, eventdata, handles)
% hObject    handle to MappingBeatsAimsun (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
