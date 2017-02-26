function varargout = DataQueryParameter(varargin)
%DATAQUERYPARAMETER MATLAB code file for DataQueryParameter.fig
%      DATAQUERYPARAMETER, by itself, creates a new DATAQUERYPARAMETER or raises the existing
%      singleton*.
%
%      H = DATAQUERYPARAMETER returns the handle to a new DATAQUERYPARAMETER or the handle to
%      the existing singleton*.
%
%      DATAQUERYPARAMETER('Property','Value',...) creates a new DATAQUERYPARAMETER using the
%      given property value pairs. Unrecognized properties are passed via
%      varargin to DataQueryParameter_OpeningFcn.  This calling syntax produces a
%      warning when there is an existing singleton*.
%
%      DATAQUERYPARAMETER('CALLBACK') and DATAQUERYPARAMETER('CALLBACK',hObject,...) call the
%      local function named CALLBACK in DATAQUERYPARAMETER.M with the given input
%      arguments.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help DataQueryParameter

% Last Modified by GUIDE v2.5 23-Feb-2017 21:23:58

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @DataQueryParameter_OpeningFcn, ...
                   'gui_OutputFcn',  @DataQueryParameter_OutputFcn, ...
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


% --- Executes just before DataQueryParameter is made visible.
function DataQueryParameter_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   unrecognized PropertyName/PropertyValue pairs from the
%            command line (see VARARGIN)

% Choose default command line output for DataQueryParameter
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes DataQueryParameter wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = DataQueryParameter_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function DaySetting_Callback(hObject, eventdata, handles)
% hObject    handle to DaySetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of DaySetting as text
%        str2double(get(hObject,'String')) returns contents of DaySetting as a double


% --- Executes during object creation, after setting all properties.
function DaySetting_CreateFcn(hObject, eventdata, handles)
% hObject    handle to DaySetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TimeSetting_Callback(hObject, eventdata, handles)
% hObject    handle to TimeSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TimeSetting as text
%        str2double(get(hObject,'String')) returns contents of TimeSetting as a double


% --- Executes during object creation, after setting all properties.
function TimeSetting_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TimeSetting (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function UseMedian_Callback(hObject, eventdata, handles)
% hObject    handle to UseMedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of UseMedian as text
%        str2double(get(hObject,'String')) returns contents of UseMedian as a double


% --- Executes during object creation, after setting all properties.
function UseMedian_CreateFcn(hObject, eventdata, handles)
% hObject    handle to UseMedian (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in SaveDataQueryParameter.
function SaveDataQueryParameter_Callback(hObject, eventdata, handles)
% hObject    handle to SaveDataQueryParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
DataQueryParameter=struct(...
    'DaySetting',handles.DaySetting.String,...
    'TimeSetting',handles.TimeSetting.String,...
    'UseMedian',handles.UseMedian.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'DataQueryParameter.mat'),'DataQueryParameter');


% --- Executes on button press in ExitDataQueryParameter.
function ExitDataQueryParameter_Callback(hObject, eventdata, handles)
% hObject    handle to ExitDataQueryParameter (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)