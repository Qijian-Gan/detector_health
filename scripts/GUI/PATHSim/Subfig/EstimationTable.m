function varargout = EstimationTable(varargin)
% ESTIMATIONTABLE MATLAB code for EstimationTable.fig
%      ESTIMATIONTABLE, by itself, creates a new ESTIMATIONTABLE or raises the existing
%      singleton*.
%
%      H = ESTIMATIONTABLE returns the handle to a new ESTIMATIONTABLE or the handle to
%      the existing singleton*.
%
%      ESTIMATIONTABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESTIMATIONTABLE.M with the given input arguments.
%
%      ESTIMATIONTABLE('Property','Value',...) creates a new ESTIMATIONTABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EstimationTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EstimationTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EstimationTable

% Last Modified by GUIDE v2.5 26-Feb-2017 00:11:53

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EstimationTable_OpeningFcn, ...
                   'gui_OutputFcn',  @EstimationTable_OutputFcn, ...
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


% --- Executes just before EstimationTable is made visible.
function EstimationTable_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EstimationTable (see VARARGIN)

% Choose default command line output for EstimationTable
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.EstimationTableArterial.ColumnName = {'Junction ID','Junction Name','Junction ExtID','Signalized',...
    'Direction (Section ID)','Section Name','Section ExtID','Time',...
    'Left Turn Status','Through movement Status','Right Turn Status',...
    'Left Turn Queue','Through movement Queue','Right Turn Queue'};
inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'ArterialEstimationTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.EstimationTableArterial,'Data',ArterialEstimationTable);
else
    error('Can not find the estimated results for arterial links!')
end

handles.EstimationTableFreeway.ColumnName = {'Aimsun Link ID','BEATS Link ID (involved)','Time (seconds)','Average Density (vhe/mile)',...
    'Std Dev Of Density (veh/mile)','Average Speed (mph)','Std Dev Of Speed (mph)'};
fileName=fullfile(inputFolder,'FreewayEstimationTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    EstimationResultsBeats(:,4:5)=EstimationResultsBeats(:,4:5)*0.3048*5280;
    EstimationResultsBeats(:,6:7)=EstimationResultsBeats(:,6:7)*2.23694;
    set(handles.EstimationTableFreeway,'Data',EstimationResultsBeats);
else
    error('Can not find the estimated results for freeway links!')
end


% --- Outputs from this function are returned to the command line.
function varargout = EstimationTable_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in CloseEstimation.
function CloseEstimation_Callback(hObject, eventdata, handles)
% hObject    handle to CloseEstimation (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
