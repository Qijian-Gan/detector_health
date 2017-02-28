function varargout = SetReplicationID(varargin)
% SETREPLICATIONID MATLAB code for SetReplicationID.fig
%      SETREPLICATIONID, by itself, creates a new SETREPLICATIONID or raises the existing
%      singleton*.
%
%      H = SETREPLICATIONID returns the handle to a new SETREPLICATIONID or the handle to
%      the existing singleton*.
%
%      SETREPLICATIONID('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SETREPLICATIONID.M with the given input arguments.
%
%      SETREPLICATIONID('Property','Value',...) creates a new SETREPLICATIONID or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before SetReplicationID_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to SetReplicationID_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help SetReplicationID

% Last Modified by GUIDE v2.5 24-Feb-2017 10:49:16

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SetReplicationID_OpeningFcn, ...
                   'gui_OutputFcn',  @SetReplicationID_OutputFcn, ...
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


% --- Executes just before SetReplicationID is made visible.
function SetReplicationID_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SetReplicationID (see VARARGIN)

% Choose default command line output for SetReplicationID
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SetReplicationID wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SetReplicationID_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



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


% --- Executes on button press in SaveReplicationID.
function SaveReplicationID_Callback(hObject, eventdata, handles)
% hObject    handle to SaveReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
ReplicationID=str2double(handles.ReplicationID.String);

outputLocation=findFolder.GUI_temp;
save(fullfile(outputLocation,'ReplicationID.mat'),'ReplicationID');

% --- Executes on button press in ExitSetReplicationID.
function ExitSetReplicationID_Callback(hObject, eventdata, handles)
% hObject    handle to ExitSetReplicationID (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)