function varargout = VehiclePhaseTable(varargin)
% VEHICLEPHASETABLE MATLAB code for VehiclePhaseTable.fig
%      VEHICLEPHASETABLE, by itself, creates a new VEHICLEPHASETABLE or raises the existing
%      singleton*.
%
%      H = VEHICLEPHASETABLE returns the handle to a new VEHICLEPHASETABLE or the handle to
%      the existing singleton*.
%
%      VEHICLEPHASETABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VEHICLEPHASETABLE.M with the given input arguments.
%
%      VEHICLEPHASETABLE('Property','Value',...) creates a new VEHICLEPHASETABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VehiclePhaseTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VehiclePhaseTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VehiclePhaseTable

% Last Modified by GUIDE v2.5 26-Feb-2017 17:17:29

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VehiclePhaseTable_OpeningFcn, ...
                   'gui_OutputFcn',  @VehiclePhaseTable_OutputFcn, ...
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


% --- Executes just before VehiclePhaseTable is made visible.
function VehiclePhaseTable_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VehiclePhaseTable (see VARARGIN)

% Choose default command line output for VehiclePhaseTable
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.PhaseTable.ColumnName = {'Aimsun JunctionID','Aimsun Control Plan ID','Control Type','Cycle Length',...
    'Coordinated','Ring ID','Aimsun Phase ID','Phase ID In Cycle', 'Time Has Been Activated'};
handles.VehicleTable.ColumnName = {'Aimsun Section ID','Lane ID','Vehicle Type','Origin ID',...
    'Destination ID','Distance To End (ft)','Speed (mph)','Track Or Not'};

inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'PhaseListTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.PhaseTable,'Data',PhaseListTable);
else
    disp('Can not find the file for activated signal phases!')
end

fileName=fullfile(inputFolder,'VehicleListTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.VehicleTable,'Data',VehicleListTable);
else
    disp('Can not find the file of vehicles generated for simulation!')
end

% --- Outputs from this function are returned to the command line.
function varargout = VehiclePhaseTable_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes on button press in CloseVehiclePhaseTable.
function CloseVehiclePhaseTable_Callback(hObject, eventdata, handles)
% hObject    handle to CloseVehiclePhaseTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);
