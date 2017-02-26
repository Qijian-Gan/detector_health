function varargout = EstimationTableArterial(varargin)
% ESTIMATIONTABLEARTERIAL MATLAB code for EstimationTableArterial.fig
%      ESTIMATIONTABLEARTERIAL, by itself, creates a new ESTIMATIONTABLEARTERIAL or raises the existing
%      singleton*.
%
%      H = ESTIMATIONTABLEARTERIAL returns the handle to a new ESTIMATIONTABLEARTERIAL or the handle to
%      the existing singleton*.
%
%      ESTIMATIONTABLEARTERIAL('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESTIMATIONTABLEARTERIAL.M with the given input arguments.
%
%      ESTIMATIONTABLEARTERIAL('Property','Value',...) creates a new ESTIMATIONTABLEARTERIAL or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EstimationTableArterial_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EstimationTableArterial_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EstimationTableArterial

% Last Modified by GUIDE v2.5 25-Feb-2017 23:44:28

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EstimationTableArterial_OpeningFcn, ...
                   'gui_OutputFcn',  @EstimationTableArterial_OutputFcn, ...
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


% --- Executes just before EstimationTableArterial is made visible.
function EstimationTableArterial_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EstimationTableArterial (see VARARGIN)

% Choose default command line output for EstimationTableArterial
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.EstimationTableArterialOnly.ColumnName = {'Junction ID','Junction Name','Junction ExtID','Signalized',...
    'Direction (Section ID)','Section Name','Section ExtID','Time',...
    'Left Turn Status','Through movement Status','Right Turn Status',...
    'Left Turn Queue','Through movement Queue','Right Turn Queue'};

inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'ArterialEstimationTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.EstimationTableArterialOnly,'Data',ArterialEstimationTable);
else
    error('Can not find the estimated results for arterial links!')
end

% --- Outputs from this function are returned to the command line.
function varargout = EstimationTableArterial_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes on button press in CloseArterialTable.
function CloseArterialTable_Callback(hObject, eventdata, handles)
% hObject    handle to CloseArterialTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);
