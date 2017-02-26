function varargout = InitializationParameters(varargin)
%INITIALIZATIONPARAMETERS MATLAB code file for InitializationParameters.fig
%      INITIALIZATIONPARAMETERS, by itself, creates a new INITIALIZATIONPARAMETERS or raises the existing
%      singleton*.
%
%      H = INITIALIZATIONPARAMETERS returns the handle to a new INITIALIZATIONPARAMETERS or the handle to
%      the existing singleton*.
%
%      INITIALIZATIONPARAMETERS('Property','Value',...) creates a new INITIALIZATIONPARAMETERS using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to InitializationParameters_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      INITIALIZATIONPARAMETERS('CALLBACK') and INITIALIZATIONPARAMETERS('CALLBACK',hObject,...) call the
%      local function named CALLBACK in INITIALIZATIONPARAMETERS.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help InitializationParameters

% Last Modified by GUIDE v2.5 24-Feb-2017 16:23:30

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @InitializationParameters_OpeningFcn, ...
                   'gui_OutputFcn',  @InitializationParameters_OutputFcn, ...
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


% --- Executes just before InitializationParameters is made visible.
function InitializationParameters_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for InitializationParameters
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes InitializationParameters wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = InitializationParameters_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


function SearchIntervalInitialization_Callback(hObject, eventdata, handles)
% hObject    handle to SearchIntervalInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of SearchIntervalInitialization as text
%        str2double(get(hObject,'String')) returns contents of SearchIntervalInitialization as a double


% --- Executes during object creation, after setting all properties.
function SearchIntervalInitialization_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SearchIntervalInitialization (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function DistanceToEndTurning_Callback(hObject, eventdata, handles)
% hObject    handle to DistanceToEndTurning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DistanceToEndTurning as text
%        str2double(get(hObject,'String')) returns contents of DistanceToEndTurning as a double

% --- Executes during object creation, after setting all properties.
function DistanceToEndTurning_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DistanceToEndTurning (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes on button press in SaveInitializationParameters.
function SaveInitializationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to SaveInitializationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
InitializationParameters=struct(...
    'SearchIntervalInitialization',handles.SearchIntervalInitialization.String,...
    'DistanceToEndTurning',handles.DistanceToEndTurning.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'InitializationParameters.mat'),'InitializationParameters');

% --- Executes on button press in ExitInitializationParameters.
function ExitInitializationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to ExitInitializationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)
