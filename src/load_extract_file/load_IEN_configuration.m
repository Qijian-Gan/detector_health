classdef load_IEN_configuration
    properties
        folderLocationOrganization          % Location of the folder that stores the IEN configuration files
        folderLocationDetector              % Location of the folder that stores the IEN configuration files
        outputFolderLocation                % Location of the output folder for temporary files

        fileListOrganization                % Obtain the file list inside the folder:folderLocationOrganization
        fileListDetector                    % Obtain the file list inside the folder:folderLocationDetector
    end
    
    methods ( Access = public )
        
        function [this]=load_IEN_configuration(folderOrganization,folderDetector,outputFolder)
            %% This function is to load the IEN configuration files
            this.folderLocationOrganization=findFolder.IEN_organization();
            this.folderLocationDetector=findFolder.IEN_detector();
            this.outputFolderLocation=findFolder.IEN_temp();
            
            if nargin>0
                this.folderLocationOrganization=folderOrganization;
            end
            
            if nargin>1
                this.folderLocationDetector=folderDetector;
            end
            
            if nargin==3
                this.outputFolderLocation=outputFolder;
            end
            
            if(nargin>3)
                error('Too many inputs!')
            end
            
            tmpOrganization=dir(this.folderLocationOrganization);
            this.fileListOrganization=tmpOrganization(3:end);
            
            tmpDetector=dir(this.folderLocationDetector);
            this.fileListDetector=tmpDetector(3:end);
            
        end
        
        function [data]=parse_txt_organization(this,file)
            %% This function is to parse the organization configuration file (txt format)
            
            location=this.folderLocationOrganization;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            % Ignore the empty lines (Organization list)
            tline=fgetl(fileID);
            tline=fgetl(fileID);
            
            % Ignore the first line (Organization list)
            tline=fgetl(fileID);
            
            % Ignore the second line (Org ID, Org Name, Function, Location, Description)
            tline=fgetl(fileID);
            
            % Process the data starting from the third line
            data=[];
            tline=fgetl(fileID);
            while(tline>0)
                disp(tline)
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
        
        function [data]=parse_txt_detector(this,file)
            %% This function is to parse the organization configuration file (txt format)
            
            location=this.folderLocationDetector;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            % Ignore the empty lines (Organization list)
            symbol=1;
            while(symbol)
                tline=fgetl(fileID);
                if(strcmp(tline,'Device Inventory list'))
                    % Ignore the first line (Org ID, Device ID, Last Update,
                    % Description, Roadway Name, Cross Street, Latitude, Longitude,
                    % Direction, Averaging Period, Associated Intersection ID)
                    tline=fgetl(fileID);
                    
                    data=[];
                    tline=fgetl(fileID);
                    while(1)
                        if(tline>0)
                            disp(tline)
                            str=strsplit(tline,','); % Split strings
                            orgID=str{1,1};
                            detID=str{1,2};
                            lastUpdate=str{1,3};
                            if(length(str)==11)
                                description=str{1,4};
                                roadName=str{1,5};
                                crossStreet=str{1,6};
                                latitute=str{1,7};
                                longitute=str{1,8};
                                direction=str{1,9};
                                avgPeriod=str{1,10};
                                associatedIntersectionID=str{1,11};
                            elseif(length(str)==12)
                                description=strcat(str{1,4},'&',str{1,5});
                                roadName=str{1,6};
                                crossStreet=str{1,7};
                                latitute=str{1,8};
                                longitute=str{1,9};
                                direction=str{1,10};
                                avgPeriod=str{1,11};
                                associatedIntersectionID=str{1,12};
                            elseif(length(str)==13)
                                description=strcat(str{1,4},'&',str{1,5},'&',str{1,6});
                                roadName=str{1,7};
                                crossStreet=str{1,8};
                                latitute=str{1,9};
                                longitute=str{1,10};
                                direction=str{1,11};
                                avgPeriod=str{1,12};
                                associatedIntersectionID=str{1,13};
                            end
                            
                            [dataFormat]=load_IEN_configuration.dataFormatDet(orgID,detID,lastUpdate,description,roadName,crossStreet,...
                            latitute,longitute,direction,avgPeriod,associatedIntersectionID);
                            data=[data;dataFormat];
                            
                            tline=fgetl(fileID); % Ignore the third line
                        else
                            symbol=0;
                            break;
                        end
                    end
                end
            end
            
            
            
            
            
            
            
            % Close the file
            fclose(fileID);
        end
        
        
        function save_data(this,data,type)
            
            switch type
                case 'Organization'
                    % Get the file name
                    fileName=fullfile(this.outputFolderLocation,'IEN_Organization_Config.mat');
                    
                    if(exist(fileName,'file')) % If the file exists
                        load(fileName);
                        dataOrg=[dataOrg;data];
                        orgIDs={dataOrg.OrgID}';
                        [~,idx]=unique(orgIDs);
                        dataOrg=dataOrg(idx,:);
                    else
                        % If it is the first time
                        dataOrg=data;
                    end
                    
                    % Save the health report
                    save(fileName,'dataOrg');
                    
                case 'Detector'
                    % Get the file name
                    fileName=fullfile(this.outputFolderLocation,'IEN_Detector_Config.mat');
                    
                    if(exist(fileName,'file')) % If the file exists
                        load(fileName);
                        dataDet=[dataDet;data];
                        deviceIDs={dataDet.DetID}';
                        orgIDs={dataDet.OrgID}';
                        [~,idx]=unique(strcat(orgIDs,deviceIDs),'rows');
                        dataDet=dataDet(idx,:);
                    else
                        % If it is the first time
                        dataDet=data;
                    end
                    
                    % Save the health report
                    save(fileName,'dataDet');
            end
        end
    end
    
    methods ( Static)
       
        function [dataFormat]=dataFormatOrg(orgID,orgName,func,loc,descrip)
            % This function is used to return the structure of data format
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
        
        function [dataFormat]=dataFormatDet(orgID,detID,lastUpdate,description,roadName,crossStreet,...
                            latitute,longitute,direction,avgPeriod,associatedIntersectionID)
            % This function is used to return the structure of data format
            if(nargin==0)
                dataFormat=struct(...
                    'OrgID',                        nan,...
                    'DetID',                        nan,...
                    'LastUpdate',                   nan,...
                    'Description',                  nan,...
                    'RoadName',                     nan,...
                    'CrossStreet',                  nan,...
                    'Latitute',                     nan,...
                    'Longitute',                    nan,...
                    'Direction',                    nan,...
                    'AvgPeriod',                    nan,...
                    'AssociatedIntersectionID',     nan);
            else
                dataFormat=struct(...
                    'OrgID',                        orgID,...
                    'DetID',                        detID,...
                    'LastUpdate',                   lastUpdate,...
                    'Description',                  description,...
                    'RoadName',                     roadName,...
                    'CrossStreet',                  crossStreet,...
                    'Latitute',                     latitute,...
                    'Longitute',                    longitute,...
                    'Direction',                    direction,...
                    'AvgPeriod',                    avgPeriod,...
                    'AssociatedIntersectionID',     associatedIntersectionID);
            end
        end
    end
end

