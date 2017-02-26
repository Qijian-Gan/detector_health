function varargout = AimsunProjectSettings(varargin)
% AIMSUNPROJECTSETTINGS MATLAB code for AimsunProjectSettings.fig
%      AIMSUNPROJECTSETTINGS, by itself, creates a new AIMSUNPROJECTSETTINGS or raises the existing
%      singleton*.
%
%      H = AIMSUNPROJECTSETTINGS returns the handle to a new AIMSUNPROJECTSETTINGS or the handle to
%      the existing singleton*.
%
%      AIMSUNPROJECTSETTINGS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in AIMSUNPROJECTSETTINGS.M with the given input arguments.
%
%      AIMSUNPROJECTSETTINGS('Property','Value',...) creates a new AIMSUNPROJECTSETTINGS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AimsunProjectSettings_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AimsunProjectSettings_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AimsunProjectSettings

% Last Modified by GUIDE v2.5 22-Feb-2017 15:36:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @AimsunProjectSettings_OpeningFcn, ...
                   'gui_OutputFcn',  @AimsunProjectSettings_OutputFcn, ...
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


% --- Executes just before AimsunProjectSettings is made visible.
function AimsunProjectSettings_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AimsunProjectSettings (see VARARGIN)

% Choose default command line output for AimsunProjectSettings
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AimsunProjectSettings wait for user response (see UIRESUME)
% uiwait(handles.figure1);
                                     
% --- Outputs from this function are returned to the command line.
function varargout = AimsunProjectSettings_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function AimsunFileLocation_Callback(hObject, eventdata, handles)
% hObject    handle to AimsunFileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AimsunFileLocation as text
%        str2double(get(hObject,'String')) returns contents of AimsunFileLocation as a double

function AimsunProjectName_Callback(hObject, eventdata, handles)
% hObject    handle to AimsunProjectName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AimsunProjectName as text
%        str2double(get(hObject,'String')) returns contents of AimsunProjectName as a double

% --- Executes during object creation, after setting all properties.
function AimsunProjectName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AimsunProjectName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function OutputFolder_Callback(hObject, eventdata, handles)
% hObject    handle to OutputFolder (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of OutputFolder as text
%        str2double(get(hObject,'String')) returns contents of OutputFolder as a double


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

% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes during object creation, after setting all properties.
function AimsunFileLocation_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AimsunFileLocation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in JunctionYes.
function JunctionYes_Callback(hObject, eventdata, handles)
% hObject    handle to JunctionYes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of JunctionYes


% --- Executes on button press in DetectorYes.
function DetectorYes_Callback(hObject, eventdata, handles)
% hObject    handle to DetectorYes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of DetectorYes


% --- Executes on button press in SectionYes.
function SectionYes_Callback(hObject, eventdata, handles)
% hObject    handle to SectionYes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SectionYes


% --- Executes on button press in SignalYes.
function SignalYes_Callback(hObject, eventdata, handles)
% hObject    handle to SignalYes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of SignalYes



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


% --- Executes on button press in SaveSettings.
function SaveSettings_Callback(hObject, eventdata, handles)
% hObject    handle to SaveSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

AimsunProjectSetting=struct(...
    'FileLocation',get(handles.AimsunFileLocation,'String'),...
    'AimsunFile',get(handles.AimsunProjectName,'String'),...
    'JunctionYes',handles.JunctionYes.Value,...
    'SectionYes',handles.SectionYes.Value,...
    'DetectorYes',handles.DetectorYes.Value,...
    'SignalYes',handles.SignalYes.Value,...
    'MidlinkCountInfFile',get(handles.MidlinkCountInfFile,'String'),...
    'DefaultSigInfFile',get(handles.DefaultSigInfFile,'String'),...
    'OutputFolder',handles.InputFolder.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'AimsunProjectSetting.mat'),'AimsunProjectSetting');

% --- Executes on button press in ExitSettings.
function ExitSettings_Callback(hObject, eventdata, handles)
% hObject    handle to ExitSettings (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)
