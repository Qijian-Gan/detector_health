classdef load_BEATS_result
    properties
        folderLocationResult                       % Location of the folder that stores the BEATS result
        outputFolderLocation                       % Location of the output folder for temporary files

        fileListResult                             % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_BEATS_result(folderResult,outputFolder)
            %% This function is to load the BEATS output files
            
            % Get the default settings first
            this.folderLocationResult=findFolder.BEATS_result();            
            this.outputFolderLocation=findFolder.BEATS_temp();
           
            % Get result file location
            if nargin>0
                this.folderLocationResult=folderResult;
            end
            
            % Get the output file location
            if nargin==2
                this.outputFolderLocation=outputFolder;
            end
            
            if(nargin>2)
                error('Too many inputs!')
            end

            % Get the names of the result files
            tmpResult=dir(this.folderLocationResult);
            this.fileListResult=tmpResult(3:end);
            
        end
        
        function [data]=parse_BEATS_simulation_results(this,file)
            %% This function is to parse the BEAT simulation output files
            
            location=this.folderLocationResult;
            
            % Open the file
            fileID = fopen(fullfile(location,file));
            
            data=[];
            symbol=1;
            networkScenarioTask=[];
            while(symbol)
                tline=fgetl(fileID);
                
                if(tline<0)
                    symbol=0;     
                    
                elseif(strfind(tline,'<linkStates><linkStates>')) % Starting of one simulation step
%                     disp(tline)
                    str=strsplit(tline,'<linkStates><linkStates>');
                    strSetting=strsplit(str{1,1},{'<','<\','>'});
                    strLinkData=strsplit(str{1,2},{','});
                    
                    networkID=(strSetting{1,4});
                    scenarioID=(strSetting{1,7});
                    taskID=(strSetting{1,11});
                    timeStep=str2double(strSetting{1,14})/1000;
                    dateTime=strsplit(datestr(timeStep/86400+datenum(1970,1,1)));
                    if(length(dateTime)==1)
                        date=dateTime{1,1};
                        time='00:00:00';
                    else
                        date=dateTime{1,1};
                        time=dateTime{1,2};
                    end                    
                    
                    if(isempty(networkScenarioTask)) % If it is initially empty
                        % Create a new one
                        tmpData=load_BEATS_result.dataFormatNetworkScenarioTaskResult...
                            (networkID,scenarioID,taskID,date,time,[]);
                        networkScenarioTask=[networkID,scenarioID,taskID,date,time];
                        idx=0;
                    else % If not empty
                        idx=ismember(networkScenarioTask,[networkID,scenarioID,taskID,date,time],'rows');
                        if(sum(idx)) % Find the same scenario and task
                            tmpData=data(idx,:); % Add data to the old one
                        else % If not found
                            % Create a new one
                            tmpData=load_BEATS_result.dataFormatNetworkScenarioTaskResult...
                                (networkID,scenarioID,taskID,date,time,[]);
                            networkScenarioTask=[networkScenarioTask;[networkID,scenarioID,taskID,date,time]];
                        end
                    end     
                    
                    % Get the first line
                    tmpDataResults=[];
                    tmpDataResults=[tmpDataResults;load_BEATS_result.dataFormatResult(strLinkData{1,1},...
                        strLinkData{1,2},strLinkData{1,3},strLinkData{1,4},strLinkData{1,5},...
                        strLinkData{1,6},strLinkData{1,7},strLinkData{1,8},strLinkData{1,9})];
                    
                elseif(strfind(tline,'</linkStates></linkStates>')) % End of the simulation step
                    str=strsplit(tline,'</linkStates></linkStates>');
                    strLinkData=strsplit(str{1,1},{','});
                    
                    % Get the last line
                    tmpDataResults=[tmpDataResults;load_BEATS_result.dataFormatResult(strLinkData{1,1},...
                        strLinkData{1,2},strLinkData{1,3},strLinkData{1,4},strLinkData{1,5},...
                        strLinkData{1,6},strLinkData{1,7},strLinkData{1,8},strLinkData{1,9})];
                    
                    % Add the data
                    tmpData.Results=[tmpData.Results;tmpDataResults];
                    
                    if(sum(idx)) % Update the old data
                        data(idx,:)=tmpData;
                    else % Add the new data to the end
                        data=[data;tmpData];
                    end
                    
                    % Get the empty line
                    tline=fgetl(fileID);
                    
                else % In between
                    strLinkData=strsplit(tline,{','});                    
                    
                    tmpDataResults=[tmpDataResults;load_BEATS_result.dataFormatResult(strLinkData{1,1},...
                        strLinkData{1,2},strLinkData{1,3},strLinkData{1,4},strLinkData{1,5},...
                        strLinkData{1,6},strLinkData{1,7},strLinkData{1,8},strLinkData{1,9})];
                end
                
            end
            
            fclose(fileID);
        end
                
        function save_data(this,data)
            %% This function is to save the simulation data
            
            dataBEATSResult=[];
            curLinkIDs=[];
            
            % Save by individual BEATS link (ID is the simulation ID)
            for i=1:size(data,1) % Loop for each row
                fprintf('Date=%s and Time=%s\n',data(i).Date,data(i).Time);
                
                results=data(i).Results;
                linkIDAll=[results.LinkID]';
                
                if(isempty(curLinkIDs)) % At the beginning, it is empty
                    for j=1:length(linkIDAll) % Loop for each link contained in the results
                        curLinkIDs=[curLinkIDs;linkIDAll(j)];
                        dataBEATSResult=[dataBEATSResult;struct(...
                            'LinkID', linkIDAll(j),...
                            'Results',struct(...
                                'NetworkID',data(i).NetworkID,...
                                'ScenarioID',data(i).ScenarioID,...
                                'TaskID',data(i).TaskID,...
                                'Date',data(i).Date,...
                                'Time',data(i).Time,...
                                'Result',results(j,:)))];
                    end
                else                    
                    for j=1:length(linkIDAll) % Loop for each link contained in the results
                        idx=ismember(curLinkIDs,linkIDAll(j));
                        if(sum(idx)==0) % A new link ID
                            curLinkIDs=[curLinkIDs;linkIDAll(j)];
                            dataBEATSResult=[dataBEATSResult;struct(...
                            'LinkID', linkIDAll(j),...
                            'Results',struct(...
                                'NetworkID',data(i).NetworkID,...
                                'ScenarioID',data(i).ScenarioID,...
                                'TaskID',data(i).TaskID,...
                                'Date',data(i).Date,...
                                'Time',data(i).Time,...
                                'Result',results(j,:)))];
                        else % If found
                            dataBEATSResult(idx).Results=[dataBEATSResult(idx).Results;struct(...
                                'NetworkID',data(i).NetworkID,...
                                'ScenarioID',data(i).ScenarioID,...
                                'TaskID',data(i).TaskID,...
                                'Date',data(i).Date,...
                                'Time',data(i).Time,...
                                'Result',results(j,:))];
                        end
                    end
                end
            end
            
            % Save the total data
            fileName=fullfile(this.outputFolderLocation,'BEATS_simulation_result.mat');
            save(fileName,'dataBEATSResult');
            

            % Save the data by individual links
            for i=1:size(dataBEATSResult) % Loop for each link                
                fileName=fullfile(this.outputFolderLocation,sprintf('BEATS_simulation_link_%d.mat',dataBEATSResult(i).LinkID));
                
                if(exist(fileName,'file')) % If the file exists
                    load(fileName);
                    dataBEATSLinkResult=[dataBEATSLinkResult;dataBEATSResult(i).Results];
                    networkID={dataBEATSLinkResult.NetworkID}';
                    scenarioID={dataBEATSLinkResult.ScenarioID}';
                    taskID={dataBEATSLinkResult.TaskID}';
                    date={dataBEATSLinkResult.Date}';
                    time={dataBEATSLinkResult.Time}';
                    networkScenarioTaskDateTime=strcat(networkID,scenarioID,taskID,date,time);
                    [~,idx]=unique(networkScenarioTaskDateTime,'rows');
                    dataBEATSLinkResult=dataBEATSLinkResult(idx,:);
                else
                    % If it is the first time
                    dataBEATSLinkResult=dataBEATSResult(i).Results;
                end
                
                % Save the health report
                save(fileName,'dataBEATSLinkResult');
            end   
        end
    end
    
    methods ( Static)
        function [dataFormat]=dataFormatNetworkScenarioTaskResult(networkID,scenarioID,taskID,date,time,results)
            % This function is used to return the structure of data format
            
            % Time reference: 1970,1,1
            if(nargin==0)
                dataFormat=struct(...
                    'NetworkID',                nan,...
                    'ScenarioID',               nan,...
                    'TaskID',                   nan,...
                    'Date',                     nan,...
                    'Time',                     nan,...
                    'Results',                  []);
            else
                dataFormat=struct(...
                    'NetworkID',                networkID,...
                    'ScenarioID',               scenarioID,...
                    'TaskID',                   taskID,...
                    'Date',                     date,...
                    'Time',                     time,...
                    'Results',                  results);
            end
        end
        
        function [dataFormat]=dataFormatResult(linkID,densityMean,densityStdDev,velocityMean,velocityStdDev,inflowMean,...
                inflowStdDev,outflowMean,outflowStdDev)
            % This function is used to return the structure of data format
            
            if(nargin==0)
                dataFormat=struct(...
                    'LinkID',                       nan,...
                    'DensityMean',                  nan,...
                    'DensityStdDev',                nan,...
                    'VelocityMean',                 nan,...
                    'VelocityStdDev',               nan,...
                    'InflowMean',                   nan,...
                    'InflowStdDev',                 nan,...
                    'OutflowMean',                  nan,...
                    'OutflowStdDev',                nan);
            else
                dataFormat=struct(...
                    'LinkID',                       str2double(linkID),...
                    'DensityMean',                  str2double(densityMean),...
                    'DensityStdDev',                str2double(densityStdDev),...
                    'VelocityMean',                 str2double(velocityMean),...
                    'VelocityStdDev',               str2double(velocityStdDev),...
                    'InflowMean',                   str2double(inflowMean),...
                    'InflowStdDev',                 str2double(inflowStdDev),...
                    'OutflowMean',                  str2double(outflowMean),...
                    'OutflowStdDev',                str2double(outflowStdDev));
            end
        end
        
    end
end

