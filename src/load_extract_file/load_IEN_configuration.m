classdef load_IEN_configuration
    properties
        folderLocationOrganization          % Location of the folder that stores the IEN organization files
        folderLocationData                  % Location of the folder that stores the IEN data files
        outputFolderLocation                % Location of the output folder for temporary files
        
        fileListOrganization                % File list of organizations
        fileListData                        % File list of IEN Data
    end
    
    methods ( Access = public )
        
        function [this]=load_IEN_configuration(folderOrganization,folderData,outputFolder)
            %% This function is to load the IEN configuration and data files
            this.folderLocationOrganization=findFolder.IEN_organization();
            this.folderLocationData=findFolder.IEN_data();
            this.outputFolderLocation=findFolder.IEN_temp();
            
            if (nargin>0 && ~isempty(folderOrganization))
                this.folderLocationOrganization=folderOrganization;
            end
            
            if (nargin>1 && ~isempty(folderData))
                this.folderLocationData=folderData;
            end
            
            if (nargin==3 && ~isempty(outputFolder))
                this.outputFolderLocation=outputFolder;
            end
            
            if(nargin>3)
                error('Too many inputs!')
            end
            
            % Get the file list for organizations
            tmpOrganization=dir(this.folderLocationOrganization);
            idx=strmatch('organizations',{tmpOrganization.name});
            this.fileListOrganization=tmpOrganization(idx,:);
            
            % Get the file list for IEN data
            tmpData=dir(this.folderLocationData);
            idx=strmatch('ienData',{tmpData.name});
            this.fileListData=tmpData(idx,:);
            
        end
        
        function [data]=parse_txt_organization(this,file)
            %% This function is to parse the organization configuration file (txt format)
            
            location=this.folderLocationOrganization;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            % Ignore the two empty lines (Organization list)
            tline=fgetl(fileID);
            tline=fgetl(fileID);
            
            % Ignore the first line ("Organization list")
            tline=fgetl(fileID);
            
            % Ignore the second line ("Org ID", "Org Name", "Function", "Location", "Description")
            tline=fgetl(fileID);
            
            % Process the data starting from the third line
            data=[];
            tline=fgetl(fileID);
            while(tline>0)
                %                 disp(tline)
                str=strsplit(tline,','); % Split strings
                orgID=str{1,1};
                orgName=str{1,2};
                func=str{1,3};
                loc=str{1,4};
                descrip=str{1,5};
                
                [dataFormat]=load_IEN_configuration.dataFormatOrg(orgID,orgName,func,loc,descrip);
                data=[data;dataFormat];
                
                tline=fgetl(fileID); % Ignore the third line
            end
            
            % Close the file
            fclose(fileID);
        end
        
        function [DevInv,DevData,SigInv,SigData,PlanPhase,LastCyclePhase]=parse_txt_detector(this,file)
            %% This function is to parse the organization configuration file (txt format)
            
            location=this.folderLocationData;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            DevInv=[];
            DevData=[];
            SigInv=[];
            SigData=[];
            PlanPhase=[];
            LastCyclePhase=[];
            
            DevInvEnable=1;
            DevDataEnable=1;
            SigInvEnable=1;
            SigDataEnable=1;
            PlanPhaseEnable=1;
            LastCyclePhaseEnable=1;
            
            % Ignore the empty lines (Organization list)
            
            while(1)
                tline=fgetl(fileID);
                if(~isempty(tline))
                    if(tline<0)
                        break;
                    end
                end
                
                %% First: try to get the device inventory list
                if(strcmp(tline,'Device Inventory list') && DevInvEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update, Description,
                    % Roadway Name, Cross Street, Latitude, Longitude, Direction, Averaging Period,
                    % Associated Intersection ID)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1) % Entering the loop to read data
                        if(tline>0) % Not empty
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            if(length(str)==11)
                                description=str{1,4};
                                roadName=str{1,5};
                                crossStreet=str{1,6};
                                latitude=str{1,7};
                                longitude=str{1,8};
                                direction=str{1,9};
                                avgPeriod=str{1,10};
                                associatedIntersectionID=str{1,11};
                            elseif(length(str)==12)
                                description=strcat(str{1,4},'&',str{1,5});
                                roadName=str{1,6};
                                crossStreet=str{1,7};
                                latitude=str{1,8};
                                longitude=str{1,9};
                                direction=str{1,10};
                                avgPeriod=str{1,11};
                                associatedIntersectionID=str{1,12};
                            elseif(length(str)==13)
                                description=strcat(str{1,4},'&',str{1,5},'&',str{1,6});
                                roadName=str{1,7};
                                crossStreet=str{1,8};
                                latitude=str{1,9};
                                longitude=str{1,10};
                                direction=str{1,11};
                                avgPeriod=str{1,12};
                                associatedIntersectionID=str{1,13};
                            else
                                error('String is too long!')
                            end
                            
                            [dataFormat]=load_IEN_configuration.dataFormatDevInv(orgID,devID,lastUpdate,lastUpdateDate,...
                                lastUpdateTime,description,roadName,crossStreet,...
                                latitude,longitude,direction,avgPeriod,associatedIntersectionID);
                            DevInv=[DevInv;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
                
                %% Second: try to get the device data
                if(strcmp(tline,'Device Data') && DevDataEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update, Detector State, Speed,
                    % Occupancy, Volume, Avg Speed, Avg Occupancy, Avg Volume)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            if(length(str)==10)
                                state=str{1,4};
                                speed=str2double(str{1,5});
                                occupancy=str2double(str{1,6});
                                volume=str2double(str{1,7});
                                avgSpeed=str2double(str{1,8});
                                avgOccupancy=str2double(str{1,9});
                                avgVolume=str2double(str{1,10});
                            elseif(length(str)==11)
                                state=strcat(str{1,4},'&',str{1,5});
                                speed=str2double(str{1,6});
                                occupancy=str2double(str{1,7});
                                volume=str2double(str{1,8});
                                avgSpeed=str2double(str{1,9});
                                avgOccupancy=str2double(str{1,10});
                                avgVolume=str2double(str{1,11});
                            elseif(length(str)==12)
                                state=strcat(str{1,4},'&',str{1,5},'&',str{1,6});
                                speed=str2double(str{1,7});
                                occupancy=str2double(str{1,8});
                                volume=str2double(str{1,9});
                                avgSpeed=str2double(str{1,10});
                                avgOccupancy=str2double(str{1,11});
                                avgVolume=str2double(str{1,12});
                            else
                                error('String is too long!')
                            end
                            
                            [dataFormat]=load_IEN_configuration.dataFormatDevData(orgID,devID,lastUpdate,lastUpdateDate,...
                                lastUpdateTime,state,speed,occupancy,volume,avgSpeed,avgOccupancy,avgVolume);
                            DevData=[DevData;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
                %% Third: try to get the intersection signal inventory list
                if(strcmp(tline,'Intersection Signal Inventory list') && SigInvEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update, Signal Type,
                    % Description, Main Street, Cross Street, Latitude, Longitude)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            if(length(str)==9)
                                signalType=str{1,4};
                                description=str{1,5};
                                mainStreet=str{1,6};
                                crossStreet=str{1,7};
                                latitude=str{1,8};
                                longitude=str{1,9};
                            elseif(length(str)==10)
                                signalType=str{1,4};
                                description=strcat(str{1,5},'&',str{1,6});
                                mainStreet=str{1,7};
                                crossStreet=str{1,8};
                                latitude=str{1,9};
                                longitude=str{1,10};
                            elseif(length(str)==11)
                                signalType=str{1,4};
                                description=strcat(str{1,5},'&',str{1,6},'&',str{1,7});
                                mainStreet=str{1,8};
                                crossStreet=str{1,9};
                                latitude=str{1,10};
                                longitude=str{1,11};
                            else
                                error('String is too long!')
                            end
                            
                            [dataFormat]=load_IEN_configuration.dataFormatSigInv(orgID,devID,lastUpdate,...
                                lastUpdateDate,lastUpdateTime,signalType,description,mainStreet,crossStreet,latitude,longitude);
                            SigInv=[SigInv;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
                
                %% Fourth: try to get the intersection signal data
                if(strcmp(tline,'Intersection Signal Data') && SigDataEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update, Comm State, Signal State,
                    % Timing Plan, Desired Cycle Length, Desired Offset, Actual Offset, Control Mode)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            if(length(str)==10)
                                commState=str{1,4};
                                signalState=str{1,5};
                                timingPlan=str2double(str{1,6});
                                desiredCycleLength=str2double(str{1,7});
                                desiredOffset=str2double(str{1,8});
                                actualOffset=str2double(str{1,9});
                                controlMode=str{1,10};
                            else
                                error('String is too long!')
                            end
                            
                            [dataFormat]=load_IEN_configuration.dataFormatSigData(orgID,devID,lastUpdate,lastUpdateDate,...
                                lastUpdateTime,commState,signalState,timingPlan,desiredCycleLength,desiredOffset,actualOffset,controlMode);
                            SigData=[SigData;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
                
                %% Fifth: try to get the planned phases
                if(strcmp(tline,'Intersection Signal Planned Phases') && PlanPhaseEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update, List of Phase ID:Time)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            plannedPhaseTime=load_IEN_configuration.getPhaseTime(str{1,4});
                            
                            [dataFormat]=load_IEN_configuration.dataFormatPhase(orgID,devID,lastUpdate,...
                                lastUpdateDate,lastUpdateTime,plannedPhaseTime);
                            PlanPhase=[PlanPhase;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
                %% Sixth: try to get the last cycle phases
                if(strcmp(tline,'Intersection Signal Last Cycle Phases') && LastCyclePhaseEnable)
                    % Ignore the first line (Org ID, Device ID, Last Update,
                    % Last Cycle Length, List of Green Phase ID:Time)
                    tline=fgetl(fileID);
                    
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            %                             disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            devID=str{1,2};
                            
                            lastUpdate=str{1,3};
                            tmp=strsplit(str{1,3},' ');
                            lastUpdateDate=tmp{1,end-1};
                            lastUpdateTime=tmp{1,end};
                            
                            lastCycle=str2double(str{1,4});
                            lastCyclePhaseTime=load_IEN_configuration.getPhaseTime(str{1,5});
                            
                            [dataFormat]=load_IEN_configuration.dataFormatPhaseLastCycle(orgID,devID,lastUpdate,...
                                lastUpdateDate,lastUpdateTime,lastCycle,lastCyclePhaseTime);
                            LastCyclePhase=[LastCyclePhase;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            break;
                        end
                    end
                end
                
            end
            
            % Close the file
            fclose(fileID);
        end
        
        function save_data(this,data,type)
            %% This function is used to save different types of data
            
            switch type
                case 'Organization'
                    % Save organization configuration
                    % Get the file name
                    fileName=fullfile(this.outputFolderLocation,'IEN_Organization_Config.mat');
                    
                    if(exist(fileName,'file')) % If the file exists
                        load(fileName);
                        dataOrg=[dataOrg;data];
                        
                        % Reconstruct the strings
                        tmpData=[];
                        for i=1:size(dataOrg)
                            tmpData=[tmpData;{strcat(dataOrg(i).OrgID,dataOrg(i).OrgName,dataOrg(i).Function,...
                                dataOrg(i).Location,dataOrg(i).Description)}];
                        end
                        [~,idx]=unique(tmpData);
                        
                        dataOrg=dataOrg(idx,:);
                    else
                        % If it is the first time
                        dataOrg=data;
                    end
                    save(fileName,'dataOrg');
                    
                    
                otherwise 
                    % save the device/signal/phase data
                    orgIDs={data.OrgID}';
                    deviceIDs={data.DeviceID}';
                    orgDevide=strcat(orgIDs,deviceIDs);
                    [uniqueOrgDevice,~]=unique(orgDevide);
                    numDevice=size(uniqueOrgDevice,1);
                    folderLocation=this.outputFolderLocation;
                                        
                    parfor i=1:numDevice
                        load_IEN_configuration.update_and_save_data_by_type(data,uniqueOrgDevice,orgDevide,i...
                            ,folderLocation,type);
                    end
            end
        end
        
        function save_data_by_year_month(this,data,type,strYearMonth)
            %% This function is used to save different types of data
            
            switch type
                case 'Organization'
                    % Save organization configuration
                    % Get the file name
                    fileName=fullfile(this.outputFolderLocation,'IEN_Organization_Config.mat');
                    
                    if(exist(fileName,'file')) % If the file exists
                        load(fileName);
                        dataOrg=[dataOrg;data];
                        
                        % Reconstruct the strings
                        tmpData=[];
                        for i=1:size(dataOrg)
                            tmpData=[tmpData;{strcat(dataOrg(i).OrgID,dataOrg(i).OrgName,dataOrg(i).Function,...
                                dataOrg(i).Location,dataOrg(i).Description)}];
                        end
                        [~,idx]=unique(tmpData);
                        
                        dataOrg=dataOrg(idx,:);
                    else
                        % If it is the first time
                        dataOrg=data;
                    end
                    save(fileName,'dataOrg');
                    
                    
                otherwise 
                    % save the device/signal/phase data
                    orgIDs={data.OrgID}';
                    deviceIDs={data.DeviceID}';
                    orgDevide=strcat(orgIDs,deviceIDs);
                    [uniqueOrgDevice,~]=unique(orgDevide);
                    numDevice=size(uniqueOrgDevice,1);
                    folderLocation=this.outputFolderLocation;
                                        
                    parfor i=1:numDevice
                        load_IEN_configuration.update_and_save_data_by_type_year_month...
                            (data,uniqueOrgDevice,orgDevide,i,folderLocation,type,strYearMonth);
                    end
            end
        end
        
    end
    
    methods ( Static)

         function update_and_save_data_by_type_year_month(dataAll,uniqueOrgDevice,orgDevide,address,...
                 outputFolderLocation,type,strYearMonth)
            %% This function is used to save device data by type, year, month
            
            % Get the data
            idx=ismember(orgDevide,uniqueOrgDevice{address,:});
            data=dataAll(idx);

            if(sum(idx))
                % Get the file name
                OrgID=data(1).OrgID;
                City=load_IEN_configuration.findCityWithOrgID(OrgID);
                DeviceID=data(1).DeviceID;
                DeviceID=replace(DeviceID,' ',''); 
                [fileName]=load_IEN_configuration.create_file_name_by_type_year_month...
                    (outputFolderLocation,City,DeviceID,type,strYearMonth);
                
                
                DateAll={data.Date}'; % Get the dates inside the input data
                uniqueDate=unique(DateAll); % Get the unique dates
                    
                if(exist(fileName,'file')) % If the file exists
                    [dataByType]=load_IEN_configuration.load_data_by_type(fileName,type);
                    DateAllFromFile={dataByType.Date}'; % Get all Dates                   
                    
                    for i=1:size(uniqueDate,1) % Loop for each unique date
                        
                        Date=uniqueDate{i,:};                        
                        idxDate=ismember(DateAll,Date);
                        dataByDate=data(idxDate,:);
                        
                        idxDate=ismember(DateAllFromFile,Date); % Get the corresponding date
                        
                        if(sum(idxDate)) % If find the right date
                            TimeAll={dataByType(idxDate).Data.Time}'; % Get all Times
                            
                            for j=1:size(dataByDate,1)
                                Time=dataByDate(j).Time;
                                idxTime=ismember(TimeAll,Time);
                                
                                if(~sum(idxTime)) % A new last updated time?
                                    [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                                    dataByType(idxDate).Data=[dataByType(idxDate).Data;dataStructure];
                                end
                            end
                        else % A new Date?
                            
                            % Create a temporary data structure
                            tmpData=struct(...
                                'Date', Date,...
                                'Data', []);      
                            
                            for j=1:size(dataByDate,1) % Loop for each time stamp
                                [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                                tmpData.Data=[tmpData.Data;dataStructure];
                            end                            
                            dataByType=[dataByType;tmpData];
                            
                        end
                    end
                else % If it is the first time
                       
                    % Create the data file
                    dataByType=repmat(struct(...
                        'Date',nan,...
                        'Data',[]),size(uniqueDate,1),1);
                    
                    for i=1:size(uniqueDate,1) % Loop for each unique date
                        Date=uniqueDate{i,:};
                        dataByType(i).Date=Date;
                        
                        idxDate=ismember(DateAll,Date);
                        dataByDate=data(idxDate,:);                            
                        for j=1:size(dataByDate,1) % Loop for each time stamp
                            [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                            dataByType(i).Data=[dataByType(i).Data;dataStructure];
                        end
                    end
                end
                
                load_IEN_configuration.save_data_by_type(dataByType,fileName,type);
            end           
        end
   
        function [fileNameByYearMonth]=categorize_file_name_by_year_month(fileName)
            %% This function is used to categorize the file name by year and month
            
            stringYearMonth=[];
            for i=1:size(fileName,1)
                str=strsplit(fileName{i,:},'-');
                stringYearMonth=[stringYearMonth;strcat(str{1,2},str{1,3})];
            end
            uniqueStringYearMonth=unique(stringYearMonth,'rows');
            
            fileNameByYearMonth=[];
            for i=1:size(uniqueStringYearMonth,1)
                idx=ismember(stringYearMonth,uniqueStringYearMonth(i,:),'rows');
                fileNameByYearMonth=[fileNameByYearMonth;struct(...
                    'YearMonth',uniqueStringYearMonth(i,:),...
                    'Files', {fileName(idx,:)}')];
            end
        end        
        
        function [fileName,deviceName]=create_file_name_by_type_year_month...
                (outputFolderLocation,City,DeviceID,type,strYearMonth)
            %% This function is used to create the file name and device name by the input type, year and month
            
            switch type
                case 'DevInv'
                    deviceName=strcat('Detector_Inv_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\device_inventory\',deviceName);
                case 'DevData'
                    deviceName=strcat('Detector_Data_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\device_data\',deviceName);
                case 'SigInv'
                    deviceName=strcat('Int_Sig_Inv_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\intersection_signal_inventory\',deviceName);
                case 'SigData'
                    deviceName=strcat('Int_Sig_Data_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\intersection_signal_data\',deviceName);
                case 'PlanPhase'
                    deviceName=strcat('PlannedPhase_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\planned_phase\',deviceName);
                case 'LastCyclePhase'
                    deviceName=strcat('LastCyclePhase_',strYearMonth,'_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\last_cycle_phase\',deviceName);
                otherwise
                    error('No such a data type!')
            end
        end
        
        function [fileName]=create_file_name_by_type(outputFolderLocation,City,DeviceID,type)
            %% This function is used to create the file name by the input type
            
            switch type
                case 'DevInv'
                    deviceName=strcat('Detector_Inv_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\device_inventory\',deviceName);
                case 'DevData'
                    deviceName=strcat('Detector_Data_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\device_data\',deviceName);
                case 'SigInv'
                    deviceName=strcat('Int_Sig_Inv_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\intersection_signal_inventory\',deviceName);
                case 'SigData'
                    deviceName=strcat('Int_Sig_Data_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\intersection_signal_data\',deviceName);
                case 'PlanPhase'
                    deviceName=strcat('PlannedPhase_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\planned_phase\',deviceName);
                case 'LastCyclePhase'
                    deviceName=strcat('LastCyclePhase_',City,'_',DeviceID,'.mat');
                    fileName=fullfile(outputFolderLocation,'\last_cycle_phase\',deviceName);
                otherwise
                    error('No such a data type!')
            end
        end
        
        function [dataByType]=load_data_by_type(fileName,type)
            %% This function is used to load the data by type
            
            load(fileName);
            switch type
                case 'DevInv'
                    dataByType=dataDevInv;
                case 'DevData'
                    dataByType=dataDevData;
                case 'SigInv'
                    dataByType=dataSigInv;
                case 'SigData'
                    dataByType=dataSigData;
                case 'PlanPhase'
                    dataByType=dataPlanPhase;
                case 'LastCyclePhase'
                    dataByType=dataLastCyclePhase;
                otherwise
                    error('No such a data type!')
            end
        end
        
        function save_data_by_type(dataByType,fileName,type)
            %% This function is used to save the data by type
            
            switch type
                case 'DevInv'
                    dataDevInv=dataByType;
                    save(fileName,'dataDevInv');
                case 'DevData'
                    dataDevData=dataByType;
                    save(fileName,'dataDevData');
                case 'SigInv'
                    dataSigInv=dataByType;
                    save(fileName,'dataSigInv');
                case 'SigData'
                    dataSigData=dataByType;
                    save(fileName,'dataSigData');
                case 'PlanPhase'
                    dataPlanPhase=dataByType;
                    save(fileName,'dataPlanPhase');
                case 'LastCyclePhase'
                    dataLastCyclePhase=dataByType;
                    save(fileName,'dataLastCyclePhase');
                otherwise
                    error('No such a data type!')
            end
        end
        
        function [dataStructure]=get_struct_data_by_type(dataByDate,type)
            %% This function is used to get structure data by type
            
            switch type
                case 'DevInv'
                    dataStructure=struct(...
                        'Time',                             dataByDate.Time,...
                        'Description',                      dataByDate.Description,...
                        'RoadName',                         dataByDate.RoadName,...
                        'CrossStreet',                      dataByDate.CrossStreet,...
                        'Latitude',                         dataByDate.Latitude,...
                        'Longitude',                        dataByDate.Longitude,...
                        'Direction',                        dataByDate.Direction,...
                        'AvgPeriod',                        dataByDate.AvgPeriod,...
                        'AssociatedIntersectionID',         dataByDate.AssociatedIntersectionID);
                                
                case 'DevData'
                    dataStructure=struct(...
                        'Time',                       dataByDate.Time,...
                        'State',                      dataByDate.State,...
                        'Speed',                      dataByDate.Speed,...
                        'Occupancy',                  dataByDate.Occupancy,...
                        'Volume',                     dataByDate.Volume,...
                        'AvgSpeed',                   dataByDate.AvgSpeed,...
                        'AvgOccupancy',               dataByDate.AvgOccupancy,...
                        'AvgVolume',                  dataByDate.AvgVolume);
                                    
                case 'SigInv'
                    dataStructure=struct(...
                        'Time',                       dataByDate.Time,...
                        'SignalType',                 dataByDate.SignalType,...
                        'Description',                dataByDate.Description,...
                        'MainStreet',                 dataByDate.MainStreet,...
                        'CrossStreet',                dataByDate.CrossStreet,...
                        'Latitude',                   dataByDate.Latitude,...
                        'Longitude',                  dataByDate.Longitude);

                case 'SigData'
                    dataStructure=struct(...
                        'Time',                         dataByDate.Time,...
                        'CommState',                    dataByDate.CommState,...
                        'SignalState',                  dataByDate.SignalState,...
                        'TimingPlan',                   dataByDate.TimingPlan,...
                        'DesiredCycleLength',           dataByDate.DesiredCycleLength,...
                        'DesiredOffset',                dataByDate.DesiredOffset,...
                        'ActualOffset',                 dataByDate.ActualOffset,...
                        'ControlMode',                  dataByDate.ControlMode);
                    
                case 'PlanPhase'
                    dataStructure=struct(...
                        'Time',                         dataByDate.Time,...
                        'PhaseTime',                    dataByDate.PhaseTime);

                case 'LastCyclePhase'
                    dataStructure=struct(...
                        'Time',                         dataByDate.Time,...
                        'LastCycle',                    dataByDate.LastCycle,...
                        'PhaseTime',                    dataByDate.PhaseTime);
                otherwise
                    error('No such a data type!')
            end
            
        end
        
        function update_and_save_data_by_type(dataAll,uniqueOrgDevice,orgDevide,address,outputFolderLocation,type)
            %% This function is used to save intersection signal data
            
            % Get the data
            idx=ismember(orgDevide,uniqueOrgDevice{address,:});
            data=dataAll(idx);

            if(sum(idx))
                % Get the file name
                OrgID=data(1).OrgID;
                City=load_IEN_configuration.findCityWithOrgID(OrgID);
                DeviceID=data(1).DeviceID;
                DeviceID=replace(DeviceID,' ',''); 
                [fileName]=load_IEN_configuration.create_file_name_by_type(outputFolderLocation,City,DeviceID,type);
                
                
                DateAll={data.Date}'; % Get the dates inside the input data
                uniqueDate=unique(DateAll); % Get the unique dates
                    
                if(exist(fileName,'file')) % If the file exists
                    [dataByType]=load_IEN_configuration.load_data_by_type(fileName,type);
                    DateAllFromFile={dataByType.Date}'; % Get all Dates                   
                    
                    for i=1:size(uniqueDate,1) % Loop for each unique date
                        
                        Date=uniqueDate{i,:};                        
                        idxDate=ismember(DateAll,Date);
                        dataByDate=data(idxDate,:);
                        
                        idxDate=ismember(DateAllFromFile,Date); % Get the corresponding date
                        
                        if(sum(idxDate)) % If find the right date
                            TimeAll={dataByType(idxDate).Data.Time}'; % Get all Times
                            
                            for j=1:size(dataByDate,1)
                                Time=dataByDate(j).Time;
                                idxTime=ismember(TimeAll,Time);
                                
                                if(~sum(idxTime)) % A new last updated time?
                                    [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                                    dataByType(idxDate).Data=[dataByType(idxDate).Data;dataStructure];
                                end
                            end
                        else % A new Date?
                            
                            % Create a temporary data structure
                            tmpData=struct(...
                                'Date', Date,...
                                'Data', []);      
                            
                            for j=1:size(dataByDate,1) % Loop for each time stamp
                                [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                                tmpData.Data=[tmpData.Data;dataStructure];
                            end                            
                            dataByType=[dataByType;tmpData];
                            
                        end
                    end
                else % If it is the first time
                       
                    % Create the data file
                    dataByType=repmat(struct(...
                        'Date',nan,...
                        'Data',[]),size(uniqueDate,1),1);
                    
                    for i=1:size(uniqueDate,1) % Loop for each unique date
                        Date=uniqueDate{i,:};
                        dataByType(i).Date=Date;
                        
                        idxDate=ismember(DateAll,Date);
                        dataByDate=data(idxDate,:);                            
                        for j=1:size(dataByDate,1) % Loop for each time stamp
                            [dataStructure]=load_IEN_configuration.get_struct_data_by_type(dataByDate(j),type);
                            dataByType(i).Data=[dataByType(i).Data;dataStructure];
                        end
                    end
                end
                
                load_IEN_configuration.save_data_by_type(dataByType,fileName,type);
            end           
        end
   
        function [City]=findCityWithOrgID(OrgID)
            %% This function returns the City name by OrgID
            switch OrgID
                case '16:1'
                    City='SantaClarita';
                case '3:1'
                    City='Pasadena';
                case '22:2'
                    City='LongBeach';
                case '19:1'
                    City='Pomona';
                case '6:1'
                    City='Inglewood';
                case '8:1'
                    City='Burbank';
                case '27:1'
                    City='SantaMonica';
                case '7:1'
                    City='WestHollywood';
                case '13:1'
                    City='Gardena';
                case '18:1'
                    City='WestCovina';
                case '5:1'
                    City='Arcadia';
                case '17:1'
                    City='Alhambra';
                case '9:1'
                    City='Glendale';
                case '22:1'
                    City='LongBeach';
                case '29:1'
                    City='LACO';
                case '10:1'
                    City='DiamondBar';
                otherwise
                    error('Wrong organization ID!')
            end
        end
        
        function [phaseTime]=getPhaseTime(phaseTimeCombined)
            %% This function is used to parse the combined phase and time
            
            phaseTime=[];
            
            if(~isempty(phaseTimeCombined))
                str=strsplit(phaseTimeCombined,'[');
                str=strsplit(str{1,2},']');
                if(~strcmp(str{1,1},' null '))
                    str=strsplit(str{1,1},';');
                    
                    numPhase=size(str,2)-1;
                    
                    phaseTime=repmat(struct(...
                        'PhaseID', nan,...
                        'Duration', nan)...
                        ,numPhase,1);
                    
                    for i=1:numPhase
                        tmpStr=strsplit(str{1,i},':');
                        phaseTime(i).PhaseID=str2double(tmpStr{1,1});
                        phaseTime(i).Duration=str2double(tmpStr{1,2});
                    end
                end
            end
        end
        
        function [dataFormat]=dataFormatOrg(orgID,orgName,func,loc,descrip)
            %% This function is used to return the structure of data format: organization config
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',            nan,...
                    'OrgName',          nan,...
                    'Function',         nan,...
                    'Location',         nan,...
                    'Description',      nan);
            else
                dataFormat=struct(...
                    'OrgID',            orgID,...
                    'OrgName',          orgName,...
                    'Function',         func,...
                    'Location',         loc,...
                    'Description',      descrip);
            end
        end
        
        function [dataFormat]=dataFormatDevInv(orgID,devID,lastUpdate,lastUpdateDate,lastUpdateTime,...
                description,roadName,crossStreet,latitude,longitude,direction,avgPeriod,associatedIntersectionID)
            %% This function is used to return the structure of data format: device inventory
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'Description',                  nan,...
                    'RoadName',                     nan,...
                    'CrossStreet',                  nan,...
                    'Latitude',                     nan,...
                    'Longitude',                    nan,...
                    'Direction',                    nan,...
                    'AvgPeriod',                    nan,...
                    'AssociatedIntersectionID',     nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'Description',                  description,...
                    'RoadName',                     roadName,...
                    'CrossStreet',                  crossStreet,...
                    'Latitude',                     latitude,...
                    'Longitude',                    longitude,...
                    'Direction',                    direction,...
                    'AvgPeriod',                    avgPeriod,...
                    'AssociatedIntersectionID',     associatedIntersectionID);
            end
        end
        
        function [dataFormat]=dataFormatDevData(orgID,devID,lastUpdate,lastUpdateDate,lastUpdateTime,...
                state, speed, occupancy, volume,...
                avgSpeed,avgOccupancy,avgVolume)
            %% This function is used to return the structure of data format: Device data
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'State',                        nan,...
                    'Speed',                        nan,...
                    'Occupancy',                    nan,...
                    'Volume',                       nan,...
                    'AvgSpeed',                     nan,...
                    'AvgOccupancy',                 nan,...
                    'AvgVolume',                    nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'State',                        state,...
                    'Speed',                        speed,...
                    'Occupancy',                    occupancy,...
                    'Volume',                       volume,...
                    'AvgSpeed',                     avgSpeed,...
                    'AvgOccupancy',                 avgOccupancy,...
                    'AvgVolume',                    avgVolume);
            end
        end
        
        function [dataFormat]=dataFormatSigInv(orgID,devID,lastUpdate,lastUpdateDate,lastUpdateTime,...
                signalType,description,mainStreet,crossStreet,latitude,longitude)
            %% This function is used to return the structure of data format: signal inventory
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'SignalType',                   nan,...
                    'Description',                  nan,...
                    'MainStreet',                   nan,...
                    'CrossStreet',                  nan,...
                    'Latitude',                     nan,...
                    'Longitude',                    nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'SignalType',                   signalType,...
                    'Description',                  description,...
                    'MainStreet',                   mainStreet,...
                    'CrossStreet',                  crossStreet,...
                    'Latitude',                     latitude,...
                    'Longitude',                    longitude);
            end
        end
        
        function [dataFormat]=dataFormatSigData(orgID,devID,lastUpdate,lastUpdateDate,...
                lastUpdateTime,commState,signalState,timingPlan,desiredCycleLength,desiredOffset,actualOffset,controlMode)
            %% This function is used to return the structure of data format: signal data
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'CommState',                    nan,...
                    'SignalState',                  nan,...
                    'TimingPlan',                   nan,...
                    'DesiredCycleLength',           nan,...
                    'DesiredOffset',                nan,...
                    'ActualOffset',                 nan,...
                    'ControlMode',                  nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'CommState',                    commState,...
                    'SignalState',                  signalState,...
                    'TimingPlan',                   timingPlan,...
                    'DesiredCycleLength',           desiredCycleLength,...
                    'DesiredOffset',                desiredOffset,...
                    'ActualOffset',                 actualOffset,...
                    'ControlMode',                  controlMode);
            end
        end
        
        function [dataFormat]=dataFormatPhase(orgID,devID,lastUpdate,...
                lastUpdateDate,lastUpdateTime,phaseTime)
            %% This function is used to return the structure of data format: planned phases
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'PhaseTime',                    nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'PhaseTime',                    phaseTime);
            end
        end
        
        function [dataFormat]=dataFormatPhaseLastCycle(orgID,devID,lastUpdate,...
                lastUpdateDate,lastUpdateTime,lastCycle,phaseTime)
            %% This function is used to return the structure of data format: planned phases
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DeviceID',                     nan,...
                    'LastUpdate',                   nan,...
                    'Date',                         nan,...
                    'Time',                         nan,...
                    'LastCycle',                    nan,...
                    'PhaseTime',                    nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DeviceID',                     devID,...
                    'LastUpdate',                   lastUpdate,...
                    'Date',                         lastUpdateDate,...
                    'Time',                         lastUpdateTime,...
                    'LastCycle',                    lastCycle,...
                    'PhaseTime',                    phaseTime);
            end
        end
        
    end
end

