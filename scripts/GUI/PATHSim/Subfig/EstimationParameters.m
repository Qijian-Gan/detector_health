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

% Last Modified by GUIDE v2.5 24-Feb-2017 16:22:54

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

% Hints: get(hObject,'String') returns contents of SearchIntervalEstimation as text
%        str2double(get(hObject,'String')) returns contents of SearchIntervalEstimation as a double

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
EstimationParameters=struct(...
    'SearchIntervalEstimation',handles.SearchIntervalEstimation.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'EstimationParameters.mat'),'EstimationParameters');

% --- Executes on button press in ExitEstimationParameters.
function ExitEstimationParameters_Callback(hObject, eventdata, handles)
% hObject    handle to ExitEstimationParameters (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)
