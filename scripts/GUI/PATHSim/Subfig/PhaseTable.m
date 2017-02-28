function varargout = PhaseTable(varargin)
% PHASETABLE MATLAB code for PhaseTable.fig
%      PHASETABLE, by itself, creates a new PHASETABLE or raises the existing
%      singleton*.
%
%      H = PHASETABLE returns the handle to a new PHASETABLE or the handle to
%      the existing singleton*.
%
%      PHASETABLE('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in PHASETABLE.M with the given input arguments.
%
%      PHASETABLE('Property','Value',...) creates a new PHASETABLE or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before PhaseTable_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to PhaseTable_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help PhaseTable

% Last Modified by GUIDE v2.5 26-Feb-2017 16:54:19

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PhaseTable_OpeningFcn, ...
                   'gui_OutputFcn',  @PhaseTable_OutputFcn, ...
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


% --- Executes just before PhaseTable is made visible.
function PhaseTable_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to PhaseTable (see VARARGIN)

% Choose default command line output for PhaseTable
handles.output = hObject;

% Update handles structure
% Output the table formats
handles.PhaseTableOnly.ColumnName = {'Aimsun JunctionID','Aimsun Control Plan ID','Control Type','Cycle Length',...
    'Coordinated','Ring ID','Aimsun Phase ID','Phase ID In Cycle', 'Time Has Been Activated'};

inputFolder=findFolder.GUI_temp();
fileName=fullfile(inputFolder,'PhaseListTable.mat');
if(exist(fileName,'file'))
    load(fileName);
    guidata(hObject, handles)
    set(handles.PhaseTableOnly,'Data',PhaseListTable);
else
    error('Can not find the file for activated signal phases!')
end

% --- Outputs from this function are returned to the command line.
function varargout = PhaseTable_OutputFcn(hObject, eventdata, handles) 
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

% --- Executes on button press in ClosePhaseTable.
function ClosePhaseTable_Callback(hObject, eventdata, handles)
% hObject    handle to ClosePhaseTable (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
close(handles.figure1);
