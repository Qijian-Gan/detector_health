function varargout = VehicleTable(varargin)
% VEHICLETABLE MATLAB code for VehicleTable.fig
%      VEHICLETABLE, by itself, creates a new VEHICLETABLE or raises the existing
%      singleton*.
%
%      H = VEHICLETABLE returns the handle to a new VEHICLETABLE or the handle to
%      the existing singleton*.
%
%      VEHICLETABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in VEHICLETABLE.M with the given input arguments.
%
%      VEHICLETABLE('Property','Value',...) creates a new VEHICLETABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before VehicleTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to VehicleTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help VehicleTable

% Last Modified by GUIDE v2.5 26-Feb-2017 17:09:32

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @VehicleTable_OpeningFcn, ...
                   'gui_OutputFcn',  @VehicleTable_OutputFcn, ...
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


% --- Executes just before VehicleTable is made visible.
function VehicleTable_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to VehicleTable (see VARARGIN)

% Choose default command line output for VehicleTable
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.VehicleTableOnly.ColumnName = {'Aimsun Section ID','Lane ID','Vehicle Type','Origin ID',...
    'Destination ID','Distance To End (ft)','Speed (mph)','Track Or Not'};
inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'VehicleListTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.VehicleTableOnly,'Data',VehicleListTable);
else
    error('Can not find the file of vehicles generated for simulation!')
end

% --- Outputs from this function are returned to the command line.
function varargout = VehicleTable_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes on button press in CloseVehicleTable.
function CloseVehicleTable_Callback(hObject, eventdata, handles)
% hObject    handle to CloseVehicleTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);
