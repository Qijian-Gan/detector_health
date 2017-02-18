classdef load_BEATS_network
    properties
        folderLocationNetwork                      % Location of the folder that stores the BEATS network
        outputFolderLocation                       % Location of the output folder for temporary files

        fileListNetwork                            % Obtain the file list inside the folder
    end
    
    methods ( Access = public )
        
        function [this]=load_BEATS_network(folderNetwork,outputFolder)
            %% This function is to load the BEATS output files
            
            % Get the default settings first
            this.folderLocationNetwork=findFolder.BEATS_network();          
            this.outputFolderLocation=findFolder.objects();
            
            % Get network file location
            if nargin>0
                this.folderLocationNetwork=folderNetwork;
            end
                        
            % Get the output file location
            if nargin==2
                this.outputFolderLocation=outputFolder;
            end
            
            if(nargin>2)
                error('Too many inputs!')
            end
            
            % Get the names of the network files
            tmpNetwork=dir(this.folderLocationNetwork);
            this.fileListNetwork=tmpNetwork(3:end);

        end
        
        function [data,type]=parse_BEATS_network_files(this,file)
            %% This function is to parse the BEATS configuration file (xml, cvs)
            
            location=this.folderLocationNetwork;
            
            if(strfind(file,'xml'))
                pd=ScenarioPtr;
                data=pd.load(fullfile(location,file),false);
                
                type='XMLNetwork';
            elseif(strfind(file,'link_id_map'))
                
                data=[];
                fileID = fopen(fullfile(location,file));
                tline=fgetl(fileID); % Ignore the first line
                tline=fgetl(fileID);
                while (tline>0)
                    strMapping=strsplit(tline,',');
                    
                    data=[data; struct(...
                        'LinkID', str2double(strMapping{1,1}),...
                        'LegacyLink', str2double(strMapping{1,2}),...
                        'NetworkID', str2double(strMapping{1,3}),...
                        'ScenarioID', str2double(strMapping{1,4}),...
                        'RunID', str2double(strMapping{1,5}))];
                    tline=fgetl(fileID);
                end
                
                type='XMLMapping';
                fclose(fileID);
                
            elseif(strfind(file,'BEATSLinkTable'))
                
                data=[];
                fileID = fopen(fullfile(location,file));
                tline=fgetl(fileID); % Ignore the first line
                tline=fgetl(fileID);
                while (tline>0)
                    strMapping=strsplit(tline,',');
                    
                    AimsunLinks=[];
                    for i=6:length(strMapping)
                        if(~isnan(strMapping{1,i}))
                            if(~strcmp(strMapping{1,i},'NA'))
                                AimsunLinks=[AimsunLinks;str2double(strMapping{1,i})];
                            end
                        end
                    end
                    data=[data; struct(...
                        'BEATSLinkID', str2double(strMapping{1,1}),...
                        'Type', (strMapping{1,2}),...
                        'Length', str2double(strMapping{1,3}),...
                        'Latitude', str2double(strMapping{1,4}),...
                        'Longitude', str2double(strMapping{1,5}),...
                        'AimsunLinks', AimsunLinks)];
                    tline=fgetl(fileID);
                end
                
                type='BEATSMapping';
                fclose(fileID);

            end
        end
                
        function save_data(this,networkBEATS)
            
            % Get the file name
            fileName=fullfile(this.outputFolderLocation,'BEATS_Network_Config.mat');            
            save(fileName,'networkBEATS');
            
        end
    end
    
    methods ( Static)
        function [dataIn]=get_portion_BEATS_links(dataIn)
            %% This function is used to get the portions of BEATS links inside a given Aimsun link
            
            h= 0;                                 % // altitude
            SPHEROID = referenceEllipsoid('wgs84', 'm'); % // Reference ellipsoid. You can enter 'km' or 'm'
            
            numSection=size(dataIn,1);
            for i=1:numSection
                beginLongLat=dataIn(i).LinkProperty.ShapePoint(1,:);
                endLongLat=dataIn(i).LinkProperty.ShapePoint(end,:);
                numLane=dataIn(i).LinkProperty.NumLanes;
                laneLengths=dataIn(i).LinkProperty.LaneLengths;
                numBeatsLinks=size(dataIn(i).BEATSLinks,1);
                
                if(numBeatsLinks==1) % If it is only one BEATS link
                    distToEndByBeatsLinkByLane=laneLengths;
                else % If we have more than one BEATS link
                    
                    % Get the longitude and latitude, and the link lengths
                    % (BEATS)
                    longlat=[];
                    lengthBeats=[];
                    for j=1:numBeatsLinks
                       longlat=[longlat;dataIn(i).BEATSLinks(j).Latitude,dataIn(i).BEATSLinks(j).Longitude];
                       lengthBeats=[lengthBeats;dataIn(i).BEATSLinks(j).Length];
                    end
                    
                    % Check the first link portion
                    [N,E]=geodetic2ned(longlat(1,1),longlat(1,2), h, longlat(2,1),longlat(2,2), h, SPHEROID);
                    distanceBeatsToBeats = norm([N, E]);
                    [N,E]=geodetic2ned(beginLongLat.Latitude,beginLongLat.Longitude, h, longlat(2,1),longlat(2,2), h, SPHEROID);
                    distanceAimsunToBeats = norm([N, E]);
                    [N,E]=geodetic2ned(beginLongLat.Latitude,beginLongLat.Longitude, h, longlat(1,1),longlat(1,2), h, SPHEROID);
                    distance= norm([N, E]);                    
                    if(distanceBeatsToBeats<distanceAimsunToBeats) 
                        % Beats link is on the right
                        % Theoretically it should not happen. However, due
                        % to the difference between the coordination
                        % systems of Beats and Aimsun, it is possible to
                        % have this case. In such a case, we increase the
                        % length of the BEATS link
                        lengthBeats(1)=lengthBeats(1)+distance;
                    else % Beats link is on the left
                        % In such a case, we shorten the length of the
                        % BEATS link
                        lengthBeats(1)=lengthBeats(1)-distance;
                    end
                    
                    % Check the last link portion
                    [N,E]=geodetic2ned(endLongLat.Latitude,endLongLat.Longitude, h, longlat(end,1),longlat(end,2), h, SPHEROID);
                    distance= norm([N, E]);  
                    lengthBeats(end)=distance; 
                    
                    distToEndByBeatsLinkByLane=[];
                    currentBoundaries=zeros(numLane,1);
                    portionBeats=lengthBeats./sum(lengthBeats);
                    totalLength=max(laneLengths);
                    
                    for j=1:numBeatsLinks
                        for k=1:numLane
                            currentBoundaries(k)=min(currentBoundaries(k)+totalLength*portionBeats(j),laneLengths(k));
                        end
                        distToEndByBeatsLinkByLane=[distToEndByBeatsLinkByLane,currentBoundaries];
                    end                    
                end
                
                dataIn(i).DistToEndByBeatsLinkByLane=distToEndByBeatsLinkByLane;
            end            
            
        end
        
        function [dataOut]=transfer_beats_to_aimsun(dataIn,sectionIn)
            %% This function is used to transfer the links in beats to aimsun 
            
            sectionIDAll=[sectionIn.SectionID]';
            
            %Note that: the links in BEATS are organized based on the
            %traffic direction
            dataOut=[];
            AimsunLinks=[];
            for i=1:size(dataIn,1)
                if(~isempty(dataIn(i).AimsunLinks))
                    for j=1:length(dataIn(i).AimsunLinks)
                        idx=ismember(sectionIDAll,dataIn(i).AimsunLinks(j));
                        if(sum(idx))
                            sectionData=sectionIn(idx,:);
                        else
                            error('Can not find the Aimsun ID!')
                        end
                        
                        if(~isempty(AimsunLinks))
                            idx=ismember(AimsunLinks,dataIn(i).AimsunLinks(j));
                            if(sum(idx))
                                dataOut(idx).BEATSLinks=[dataOut(idx).BEATSLinks;struct(...
                                    'BEATSLinkID',dataIn(i).BEATSLinkID,...
                                    'Type', dataIn(i).Type,...
                                    'Length', dataIn(i).Length,...
                                    'Latitude', dataIn(i).Latitude,...
                                    'Longitude', dataIn(i).Longitude)];
                            else
                                AimsunLinks=[AimsunLinks;dataIn(i).AimsunLinks(j)];                                
                                dataOut=[dataOut;struct(...
                                    'AimsunlinkID',dataIn(i).AimsunLinks(j),...
                                    'LinkProperty', sectionData,...
                                    'BEATSLinks',struct(...
                                                    'BEATSLinkID',dataIn(i).BEATSLinkID,...
                                                    'Type', dataIn(i).Type,...
                                                    'Length', dataIn(i).Length,...
                                                    'Latitude', dataIn(i).Latitude,...
                                                    'Longitude', dataIn(i).Longitude))];
                            end
                        else
                            AimsunLinks=dataIn(i).AimsunLinks(j);
                                dataOut=struct(...
                                    'AimsunlinkID',dataIn(i).AimsunLinks(j),...
                                    'LinkProperty', sectionData,...
                                    'BEATSLinks',struct(...
                                                    'BEATSLinkID',dataIn(i).BEATSLinkID,...
                                                    'Type', dataIn(i).Type,...
                                                    'Length', dataIn(i).Length,...
                                                    'Latitude', dataIn(i).Latitude,...
                                                    'Longitude', dataIn(i).Longitude));
                        end
                            
                    end
                end
            end
            
            dataOut=load_BEATS_network.get_portion_BEATS_links(dataOut);
        end
        
    end
end

