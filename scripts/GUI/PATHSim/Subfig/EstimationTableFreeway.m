function varargout = EstimationTableFreeway(varargin)
% ESTIMATIONTABLEFREEWAY MATLAB code for EstimationTableFreeway.fig
%      ESTIMATIONTABLEFREEWAY, by itself, creates a new ESTIMATIONTABLEFREEWAY or raises the existing
%      singleton*.
%
%      H = ESTIMATIONTABLEFREEWAY returns the handle to a new ESTIMATIONTABLEFREEWAY or the handle to
%      the existing singleton*.
%
%      ESTIMATIONTABLEFREEWAY('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ESTIMATIONTABLEFREEWAY.M with the given input arguments.
%
%      ESTIMATIONTABLEFREEWAY('Property','Value',...) creates a new ESTIMATIONTABLEFREEWAY or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before EstimationTableFreeway_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to EstimationTableFreeway_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help EstimationTableFreeway

% Last Modified by GUIDE v2.5 26-Feb-2017 00:13:11

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @EstimationTableFreeway_OpeningFcn, ...
                   'gui_OutputFcn',  @EstimationTableFreeway_OutputFcn, ...
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


% --- Executes just before EstimationTableFreeway is made visible.
function EstimationTableFreeway_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to EstimationTableFreeway (see VARARGIN)

% Choose default command line output for EstimationTableFreeway
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.EstimationTableFreewayOnly.ColumnName = {'Aimsun Link ID','BEATS Link ID (involved)','Time (seconds)','Average Density (vhe/mile)',...
    'Std Dev Of Density (veh/mile)','Average Speed (mph)','Std Dev Of Speed (mph)'};

inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'FreewayEstimationTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    EstimationResultsBeats(:,4:5)=EstimationResultsBeats(:,4:5)*0.3048*5280;
    EstimationResultsBeats(:,6:7)=EstimationResultsBeats(:,6:7)*2.23694;
    set(handles.EstimationTableFreewayOnly,'Data',EstimationResultsBeats);
else
    error('Can not find the estimated results for freeway links!')
end

% --- Outputs from this function are returned to the command line.
function varargout = EstimationTableFreeway_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --- Executes on button press in CloseEstimationFreeway.
function CloseEstimationFreeway_Callback(hObject, eventdata, handles)
% hObject    handle to CloseEstimationFreeway (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1)

% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)