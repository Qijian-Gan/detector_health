classdef reconstruct_aimsun_network
    properties
        outputFolderLocation    % Location of the output folder
        
        junctionData            % Data that contains junction information
        sectionData             % Data that contains section information
        detectorData            % Data that contains detector information
        defaultSigSetting       % Data that contains default signal settings
        midlinkCountConfig      % Configuration file that can be used to access the midlink counts
        
        networkData             % Data that contains both junction and section information (reconstructed)
        
        appDataForEstimation    % Data for contains approach information for traffic state estimation
        
    end
    
    methods ( Access = public )
        
        function [this]=reconstruct_aimsun_network(junctionData,sectionData,detectorData,defaultSigSetting,midlinkCountConfig,outputFolder)
            %% This function is to reconstruct the aimsun network
            
            this.junctionData=junctionData;
            this.sectionData=sectionData;
            this.detectorData=detectorData;
            this.defaultSigSetting=defaultSigSetting;
            this.midlinkCountConfig=midlinkCountConfig;
            
            if(~isnan(outputFolder))
                this.outputFolderLocation=outputFolder;
            else
                this.outputFolderLocation=findFolder.temp_aimsun;
            end
            
        end
        
        function [junctionApproachData]=reconstruction(this)
            %% Main function: reconstruction
            
            junctionDataAll=this.junctionData;
            sectionDataAll=this.sectionData;
            numJunction=size(junctionDataAll,1);
            numSection=size(sectionDataAll,1);
            
            [junctionDataNonlinear,junctionDataLinear]=reconstruct_aimsun_network.getNonlinearAndLinearJunction(junctionDataAll);
            numJunctionNonlinear=size(junctionDataNonlinear,1);
            
            
            junctionApproachData=[];
            for i=1:numJunctionNonlinear % Loop for each nonlinear junction
                numEntranceSections=junctionDataNonlinear(i).NumEntranceSection;
                for j=1:numEntranceSections % Loop for each entrance section: approach
                    tmpJunctionApproachData.JunctionInf=junctionDataNonlinear(i); % Save the junction information for latter use
                    
                    % Get the junction name and ID
                    tmpJunctionApproachData.JunctionID=junctionDataNonlinear(i).JunctionID;
                    tmpJunctionApproachData.JunctionName=junctionDataNonlinear(i).Name;
                    
                    if(~isempty(junctionDataNonlinear(i).ExternalID))
                        [ID,City,County]=reconstruct_aimsun_network.find_id_city_county(junctionDataNonlinear(i).ExternalID);
                        tmpJunctionApproachData.JunctionExtID=ID;
                        tmpJunctionApproachData.City=City;
                        tmpJunctionApproachData.County=County;
                    else
                        tmpJunctionApproachData.JunctionExtID=[];
                        tmpJunctionApproachData.City=[];
                        tmpJunctionApproachData.County=[];
                    end
                    
                    tmpJunctionApproachData.Signalized=junctionDataNonlinear(i).Signalized;
                    
                    % Get the approach link name and ID
                    tmpJunctionApproachData.FirstSectionID=junctionDataNonlinear(i).EntranceSections(j);
                    [tmpSectionData]=reconstruct_aimsun_network.findSectionInformation...
                        (sectionDataAll,tmpJunctionApproachData.FirstSectionID);
                    tmpJunctionApproachData.FirstSectionName=tmpSectionData.Name;
                    tmpJunctionApproachData.FirstSectionExtID=tmpSectionData.ExternalID;
                    
                    % Find the links belonging to the same approach:
                    % links connected by linear junction, ordered from
                    % downstream to upstream
                    SectionBelongToApproach=reconstruct_aimsun_network.findUpstreamSections...
                        (junctionDataLinear,tmpJunctionApproachData.FirstSectionID);
                    tmpJunctionApproachData.SectionBelongToApproach.ListOfSections=SectionBelongToApproach;
                    tmpJunctionApproachData.SectionBelongToApproach.Property=reconstruct_aimsun_network.findSectionProperty...
                        (junctionDataAll,sectionDataAll,SectionBelongToApproach);
                    
                    % Turning properties at the downstream section
                    [ListOfTurnings,TurningProperty]=reconstruct_aimsun_network.findTurningsAtFirstSection...
                        (junctionDataNonlinear(i),tmpJunctionApproachData.FirstSectionID);
                    tmpJunctionApproachData.TurningBelongToApproach.TurningsAtFirstSectionFromLeftToRight=ListOfTurnings;
                    tmpJunctionApproachData.TurningBelongToApproach.TurningProperty=TurningProperty;
                    
                    % Lane-turning Properties
                    [LaneTurningProperty]=reconstruct_aimsun_network.findLaneTurningProperty(tmpJunctionApproachData);
                    tmpJunctionApproachData.LaneTurningProperty=LaneTurningProperty;
                    
                    % Get the aggregated road geometry: lanes, length, and turning pockets
                    linkLength=0;
                    for k=1:length(tmpJunctionApproachData.SectionBelongToApproach.ListOfSections)
                        linkLength=linkLength+max( tmpJunctionApproachData.SectionBelongToApproach.Property(k).LaneLengths);
                    end
                    tmpJunctionApproachData.GeoDesign.LinkLength=linkLength;
                    
                    [NumOfLanes,NumOfDownstreamLanes,ExclusiveLeftTurn,ExclusiveRightTurn]=reconstruct_aimsun_network.find_turning_pockets(...
                        tmpJunctionApproachData.SectionBelongToApproach,tmpJunctionApproachData.TurningBelongToApproach,...
                        tmpJunctionApproachData.LaneTurningProperty);
                    tmpJunctionApproachData.GeoDesign.NumOfLanes=NumOfLanes;
                    tmpJunctionApproachData.GeoDesign.NumOfDownstreamLanes=NumOfDownstreamLanes;
                    tmpJunctionApproachData.GeoDesign.ExclusiveLeftTurn=ExclusiveLeftTurn;
                    tmpJunctionApproachData.GeoDesign.ExclusiveRightTurn=ExclusiveRightTurn;
                    
                    % Get the detector information
                    [ExclusiveLeftTurn,ExclusiveRightTurn,AdvancedDetector,GeneralStoplineDetectors]=...
                        reconstruct_aimsun_network.get_detector_config(this.detectorData,tmpJunctionApproachData);
                    tmpJunctionApproachData.DetectorProperty.ExclusiveLeftTurn=ExclusiveLeftTurn;
                    tmpJunctionApproachData.DetectorProperty.ExclusiveRightTurn=ExclusiveRightTurn;
                    tmpJunctionApproachData.DetectorProperty.AdvancedDetector=AdvancedDetector;
                    tmpJunctionApproachData.DetectorProperty.GeneralStoplineDetectors=GeneralStoplineDetectors;
                    
                    % Check the default signal settings
                    tmpJunctionApproachData.DefaultSigSetting=struct(...
                        'CycleLength',            120,...
                        'LeftTurnGreen',    15,...
                        'ThroughGreen',     30,...
                        'RightTurnGreen',   30,...
                        'LeftTurnSetting',  'Protected');
                    junctionSectionID=[tmpJunctionApproachData.JunctionID,tmpJunctionApproachData.FirstSectionID];
                    if(~isempty(this.defaultSigSetting))
                        junctionSectionIDAll=[[this.defaultSigSetting.IntersectionID]',[this.defaultSigSetting.FirstSectionID]'];
                        
                        [~,idx]=ismember(junctionSectionID,junctionSectionIDAll,'rows');
                        if(sum(idx))
                            tmpJunctionApproachData.DefaultSigSetting=struct(...
                                'CycleLength',       this.defaultSigSetting(idx).CycleLength,...
                                'LeftTurnGreen',     this.defaultSigSetting(idx).LeftTurnGreen,...
                                'ThroughGreen',      this.defaultSigSetting(idx).ThroughGreen,...
                                'RightTurnGreen',    this.defaultSigSetting(idx).RightTurnGreen,...
                                'LeftTurnSetting',   this.defaultSigSetting(idx).LeftTurnSetting);
                        end
                    end
                    
                    % Check the midlink config files
                    tmpJunctionApproachData.MidlinkCountConfig=struct(...
                        'Location',    'NAN',...
                        'Approach',    'NAN');
                    if(~isempty(this.midlinkCountConfig))
                        junctionSectionIDAll=[[this.midlinkCountConfig.IntersectionID]',[this.midlinkCountConfig.FirstSectionID]'];
                        
                        [~,idx]=ismember(junctionSectionID,junctionSectionIDAll,'rows');
                        if(sum(idx))
                            tmpJunctionApproachData.MidlinkCountConfig=struct(...
                                'Location',    this.midlinkCountConfig(idx).Location,...
                                'Approach',    this.midlinkCountConfig(idx).Approach);
                        end
                    end
                    
                    junctionApproachData=[junctionApproachData;tmpJunctionApproachData];
                end
            end
            
        end
        
    end
    
    methods ( Static)
        
        function [appForEstimation]=get_approach_config_for_estimation(networkData)
            
            appForEstimation=[];
            for i=1:size(networkData,1)
                if(networkData(i).Signalized)
                    tmpAppForEstimation.intersection_name=networkData(i).JunctionName;
                    tmpAppForEstimation.intersection_id=networkData(i).JunctionID;
                    tmpAppForEstimation.city=networkData(i).City;
                    tmpAppForEstimation.intersection_extID=networkData(i).JunctionExtID;
                    tmpAppForEstimation.signalized=networkData(i).Signalized;
                    tmpAppForEstimation.road_name=networkData(i).FirstSectionName;
                    tmpAppForEstimation.direction=int2str(networkData(i).FirstSectionID);
                    tmpAppForEstimation.road_extID=(networkData(i).FirstSectionExtID);
                    
                    tmpAppForEstimation.exclusive_left_turn=networkData(i).DetectorProperty.ExclusiveLeftTurn;
                    tmpAppForEstimation.exclusive_right_turn=networkData(i).DetectorProperty.ExclusiveRightTurn;
                    tmpAppForEstimation.advanced_detectors=networkData(i).DetectorProperty.AdvancedDetector;
                    tmpAppForEstimation.general_stopline_detectors=networkData(i).DetectorProperty.GeneralStoplineDetectors;
                    
                    % Get the turning movement indicator
                    indicator=[0,0,0];
                    for j=1:size(networkData(i).TurningBelongToApproach.TurningProperty)
                        if(~isempty(networkData(i).TurningBelongToApproach.TurningProperty(j).Description))
                            switch networkData(i).TurningBelongToApproach.TurningProperty(j).Description
                                case 'Left Turn'
                                    indicator(1)=1;
                                case 'Through'
                                    indicator(2)=1;
                                case 'Right Turn'
                                    indicator(3)=1;
                            end
                        end
                    end
                    tmpAppForEstimation.turnIndicator=indicator;
                    
                    tmpAppForEstimation.link_properties=struct(...
                        'LinkLength',networkData(i).GeoDesign.LinkLength,...
                        'NumberOfLanes',networkData(i).GeoDesign.NumOfLanes,...
                        'NumberOfLanesDownstream',networkData(i).GeoDesign.NumOfDownstreamLanes,...
                        'ExclusiveLeftTurnLane', networkData(i).GeoDesign.ExclusiveLeftTurn.NumLane,...
                        'LeftTurnPocket', networkData(i).GeoDesign.ExclusiveLeftTurn.Pocket,...
                        'ExclusiveRightTurnLane', networkData(i).GeoDesign.ExclusiveRightTurn.NumLane,...
                        'RightTurnPocket', networkData(i).GeoDesign.ExclusiveRightTurn.Pocket,...
                        'Capacity', [],...
                        'MaxSpeed', []);
                    
                    tmpAppForEstimation.signal_properties=networkData(i).DefaultSigSetting;
                    tmpAppForEstimation.midlink_properties=networkData(i).MidlinkCountConfig;
                    tmpAppForEstimation.turning_count_properties=[];
                    
                    appForEstimation=[appForEstimation;tmpAppForEstimation];
                end
            end
        end
        
        function [ExclusiveLeftTurn,ExclusiveRightTurn,AdvancedDetector,GeneralStoplineDetectors]=...
                get_detector_config(detectorData,tmpJunctionApproachData)
            %% This function is used to get the aggregated detector configuration
            
            ExclusiveLeftTurn=[];
            ExclusiveRightTurn=[];
            AdvancedDetector=[];
            GeneralStoplineDetectors=[];
            
            ListOfSections=tmpJunctionApproachData.SectionBelongToApproach.ListOfSections;
            Property=tmpJunctionApproachData.SectionBelongToApproach.Property;
            
            SectionIDAll=[detectorData.SectionID]';
            idx=ismember(SectionIDAll,ListOfSections);
            if(sum(idx))
                SelectedDetectorData=detectorData(idx,:);
                Description={SelectedDetectorData.Description}';
                
                % Search for exclusive left turn detectors
                Movement=reconstruct_aimsun_network.traffic_movement_library('Left');
                for i=1:length(Movement)
                    [TurnMovement]=reconstruct_aimsun_network.search_for_a_given_movement_detector...
                        (Description,'Stopbar',Movement{:,i},SelectedDetectorData,Property);
                    if(~isempty(TurnMovement))
                        ExclusiveLeftTurn=[ExclusiveLeftTurn;TurnMovement];
                    end
                end
                
                % Search for exclusive right turn detectors
                Movement=reconstruct_aimsun_network.traffic_movement_library('Right');
                for i=1:length(Movement)
                    [TurnMovement]=reconstruct_aimsun_network.search_for_a_given_movement_detector...
                        (Description,'Stopbar',Movement{:,i},SelectedDetectorData,Property);
                    if(~isempty(TurnMovement))
                        ExclusiveRightTurn=[ExclusiveRightTurn;TurnMovement];
                    end
                end
                
                % Search for general stopbar detectors
                Movement=reconstruct_aimsun_network.traffic_movement_library('General');
                for i=1:length(Movement)
                    [TurnMovement]=reconstruct_aimsun_network.search_for_a_given_movement_detector...
                        (Description,'Stopbar',Movement{:,i},SelectedDetectorData,Property);
                    if(~isempty(TurnMovement))
                        GeneralStoplineDetectors=[GeneralStoplineDetectors;TurnMovement];
                    end
                end
                
                % Search for advanced detectors
                Movement=reconstruct_aimsun_network.traffic_movement_library('Advanced');
                for i=1:length(Movement)
                    [TurnMovement]=reconstruct_aimsun_network.search_for_a_given_movement_detector...
                        (Description,'Advanced',Movement{:,i},SelectedDetectorData,Property);
                    if(~isempty(TurnMovement))
                        AdvancedDetector=[AdvancedDetector;TurnMovement];
                    end
                end
            end
            
        end
        
        function [possibleMovements]=traffic_movement_library(type)
            % This function returns all possible detectors belonging to
            % the same type: exclusive left/exclusive
            % right/advanced/general stopbar
            
            switch(type)
                case 'Left' % Exclusive left-turn detectors
                    possibleMovements={'Left Turn','Left Turn Queue'};
                case 'Right' % Exclusive right-turn detectors
                    possibleMovements={'Right Turn','Right Turn Queue'};
                case 'Advanced' % Advanced detectors: "Advanced" means for all movements
                    possibleMovements={'Advanced','Advanced Left Turn', 'Advanced Right Turn','Advanced Through',...
                        'Advanced Through and Right', 'Advanced Left and Through', 'Advanced Left and Right' };
                case 'General' % General stopline detectors
                    possibleMovements={'All Movements','Through','Left and Right', 'Left and Through', 'Through and Right' };
                otherwise
                    error('Wrong input of movements!')
            end
        end
        
        function [TurnMovement]=search_for_a_given_movement_detector(Description,Type,Movement,SelectedDetectorData,Property)
            
            idx=ismember(Description,{Movement});
            if(sum(idx)) % If found
                tmpDetectorData=SelectedDetectorData(idx,:);
                
                IDs=[];
                DetectorLength=[];
                DistanceToStopbar=[];
                NumberOfLanes=[];
                for i=1:size(tmpDetectorData,1)
                    IDs=[IDs;num2str(tmpDetectorData(i).ExternalID)];
                    DetectorLength=[DetectorLength;tmpDetectorData(i).Length];
                    switch Type
                        case 'Advanced' % For advanced detectors, we need to know the distance to stopbar
                            distance=0;
                            for j=1:size(Property,1) % Search the links from downstream to upstream
                                if(tmpDetectorData(i).SectionID==Property(j).SectionID) % If found
                                    distance=distance+max(0,max(Property(j).LaneLengths)-(tmpDetectorData(i).InitialPosition...
                                        +tmpDetectorData(i).FinalPosition)/2); % Get the distance
                                    break;
                                else
                                    distance=distance+ max(Property(j).LaneLengths); % If not, add up the link lengths
                                end
                            end
                            DistanceToStopbar=[DistanceToStopbar;distance];
                            
                        case 'Stopbar' % For stopbar detectors, we set it to be zero
                            DistanceToStopbar=[DistanceToStopbar;0];
                    end
                    NumberOfLanes=[NumberOfLanes;tmpDetectorData(i).NumOfLanesCovered];
                end
                
                TurnMovement=struct(...
                    'Movement',            Movement,...
                    'IDs',                 IDs,...
                    'DetectorLength',      DetectorLength,...
                    'DistanceToStopbar',   DistanceToStopbar,...
                    'NumberOfLanes',       NumberOfLanes);
            else
                TurnMovement=[];
            end
            
        end
        
        function [NumOfLanes,NumOfDownstreamLanes,ExclusiveLeftTurn,ExclusiveRightTurn]=find_turning_pockets(SectionBelongToApproach,...
                TurningBelongToApproach, LaneTurningProperty)
            
            % Get the number of full GP lanes in the upstream
            NumOfLanes=sum(SectionBelongToApproach.Property(end).IsFullLane);
            
            % Get the number of downstream GP lanes, left-turn and
            % right-turn pockets
            TurningProperty=TurningBelongToApproach.TurningProperty;
            turnIDs=[TurningProperty.TurnID]';
            Description={TurningProperty.Description}';
            
            ExclusiveLeftTurn.NumLane=0;
            ExclusiveLeftTurn.Pocket=0;
            ExclusiveRightTurn.NumLane=0;
            ExclusiveRightTurn.Pocket=0;
            NumOfDownstreamLanes=0;
            for i=1:size(LaneTurningProperty(1).Lanes,1) % Loop for each lane in the downstream section
                if(LaneTurningProperty(1).Lanes(i).IsExclusive) % If it is exclusive
                    [~,idx]=ismember(LaneTurningProperty(1).Lanes(i).TurnMovements,turnIDs);
                    if(sum(idx) && ~isempty(Description{idx,:})) % If has description
                        switch Description{idx,:}
                            case 'Left Turn' % Exclusive left turn
                                ExclusiveLeftTurn.NumLane=ExclusiveLeftTurn.NumLane+1;
                                if(ExclusiveLeftTurn.Pocket==0)
                                    ExclusiveLeftTurn.Pocket=LaneTurningProperty(1).Lanes(i).Length;
                                else
                                    ExclusiveLeftTurn.Pocket=min(ExclusiveLeftTurn.Pocket,LaneTurningProperty(1).Lanes(i).Length);
                                end
                            case 'Right Turn' % Exclusive right turn
                                ExclusiveRightTurn.NumLane=ExclusiveRightTurn.NumLane+1;
                                if(ExclusiveRightTurn.Pocket==0)
                                    ExclusiveRightTurn.Pocket=LaneTurningProperty(1).Lanes(i).Length;
                                else
                                    ExclusiveRightTurn.Pocket=min(ExclusiveRightTurn.Pocket,LaneTurningProperty(1).Lanes(i).Length);
                                end
                            case 'Through' % Through movement
                                NumOfDownstreamLanes=NumOfDownstreamLanes+1;
                        end
                    else % If no description
                        NumOfDownstreamLanes=NumOfDownstreamLanes+1;
                    end
                else % If it is not exclusive
                    NumOfDownstreamLanes=NumOfDownstreamLanes+1;
                end
            end
            
            
        end
        
        function [ID,City,County]=find_id_city_county(ExternalID)
            %% This function is used to get the junction external ID, and the city and county it belongs to
            
            tmp=strsplit(ExternalID,' ');
            
            col=size(tmp,2);
            if col~=2
                ID=[];
                City=[];
                County=[];
            else % Particular format: "City (Space) ID" 
                ID=str2num(tmp{1,2});
                City=[];
                County=[];
                switch tmp{1,1}
                    case 'AR'
                        City='Arcadia';
                        County='Los Angeles';
                    case 'PA'
                        City='Passadena';
                        County='Los Angeles';
                    otherwise
                        ID=[];
                        City=[];
                        County=[];
                end
            end
            
        end
        
        function [junctionDataNonlinear,junctionDataLinear]=getNonlinearAndLinearJunction(junctionDataAll)
            % This function is to get nonliear/linear junction data
            listNumEntranceSections=[junctionDataAll.NumEntranceSection]';
            listNumExitSections=[junctionDataAll.NumExitSection]';
            
            idx=(listNumEntranceSections==1 & listNumExitSections==1);
            junctionDataNonlinear=junctionDataAll(~idx,:);
            junctionDataLinear=junctionDataAll(idx,:);
        end
        
        function [sectionData]=findSectionInformation(sectionDataAll,sectionID)
            % This function is to get the section information with given
            % section ID
            
            sectionIDAll=[sectionDataAll.SectionID]';
            
            idx=(sectionIDAll==sectionID);
            if(sum(idx)==0)
                error('The section ID is not found!')
            else
                sectionData=sectionDataAll(idx,:);
            end
            
        end
        
        function [sectionBelongToApproach]=findUpstreamSections(junctionDataLinear,FirstSectionID)
            % This function is used to find all sections belonging to the
            % same approach
            
            sectionBelongToApproach=[];
            sectionBelongToApproach=[sectionBelongToApproach;FirstSectionID]; % Add the first section
            
            if(~isempty(junctionDataLinear)) % Has linear junctions available
                findStatus=1; % Indicator to end the searching procedure
                numJunctionLinear=size(junctionDataLinear,1);
                exitSection=FirstSectionID; % Initialization
                while(findStatus) % While loop
                    entranceSection=[];
                    for i=1:numJunctionLinear
                        if(junctionDataLinear(i).ExitSections==exitSection) % Find the corresponding section
                            entranceSection=junctionDataLinear(i).EntranceSections;
                            sectionBelongToApproach=[sectionBelongToApproach;entranceSection];
                            exitSection=entranceSection;
                            break;
                        end
                    end
                    
                    if(isempty(entranceSection)) % Can not find anymore
                        findStatus=0;
                    end
                end
            end
            
        end
        
        function [Property]=findSectionProperty(junctionDataAll,sectionDataAll,SectionBelongToApproach)
            % This function is to find the section property
            
            numJunctionAll=size(junctionDataAll,1);
            
            numSectionAll=size(sectionDataAll,1);
            SectionAll=[sectionDataAll.SectionID]';
            
            numSectionApproach=length(SectionBelongToApproach);
            
            Property=[];
            for i=1:numSectionApproach
                idx=(SectionAll==SectionBelongToApproach(i));
                tmpProperty=sectionDataAll(idx,:);
                
                % Look for downstream junction
                tmpProperty.DownstreamJunction=[];
                symbol=1;
                for j=1:numJunctionAll
                    for k=1:junctionDataAll(j).NumEntranceSection
                        if(junctionDataAll(j).EntranceSections(k)==SectionBelongToApproach(i))
                            tmpProperty.DownstreamJunction=junctionDataAll(j);
                            symbol=0;
                            break;
                        end
                    end
                    if(symbol==0)
                        break;
                    end
                end
                
                % Look for upstream junction
                tmpProperty.UpstreamJunction=[];
                symbol=1;
                for j=1:numJunctionAll
                    for k=1:junctionDataAll(j).NumExitSection
                        if(junctionDataAll(j).ExitSections(k)==SectionBelongToApproach(i))
                            tmpProperty.UpstreamJunction=junctionDataAll(j);
                            symbol=0;
                            break;
                        end
                    end
                    if(symbol==0)
                        break;
                    end
                end
                
                Property=[Property;tmpProperty];
            end
            
            
        end
        
        function [ListOfTurnings,TurningProperty]=findTurningsAtFirstSection(junctionData,FirstSectionID)
            % This function is used to get turnings at the first section
            
            SectionIDs=[junctionData.Turnings.TurnsFromLeftToRight.SectionID]';
            idx=ismember(SectionIDs,FirstSectionID);
            ListOfTurnings=junctionData.Turnings.TurnsFromLeftToRight(idx).TurnIDsFromLeftToRight;
            TurningProperty=[];
            TurningAll=[junctionData.Turnings.TurningInf.TurnID]';
            for i=1:length(ListOfTurnings)
                idx=(TurningAll==ListOfTurnings(i));
                TurningProperty=[TurningProperty;junctionData.Turnings.TurningInf(idx,:)];
            end
        end
        
        function [LaneTurningProperty]=findLaneTurningProperty(tmpJunctionApproachData)
            
            LaneTurningProperty=[];
            
            SectionInformation=tmpJunctionApproachData.SectionBelongToApproach;
            TurningFirstSection=tmpJunctionApproachData.TurningBelongToApproach;
            
            % Get the lane-turning property
            for i=1:length(SectionInformation.ListOfSections)
                tmpLaneTurning.SectionID=SectionInformation.ListOfSections(i);
                FirstSectionProperty=SectionInformation.Property(i,:);
                
                tmpLaneTurning.NumLanes=FirstSectionProperty.NumLanes;
                % Note: Lane ID=1:N from rightmost to leftmost
                %       Turn organized from leftmost to rightmost
                %       Each turn: fromLane (rightmost) to toLane (Leftmost)
                %       Lane Length: from leftmost to rightmost
                tmpLaneTurning.Lanes=[];
                for j=tmpLaneTurning.NumLanes:-1:1
                    tmpLane.LaneID=j;
                    [IsExclusive,TurnMovements,Proportions]=reconstruct_aimsun_network.findTurnInLane(j,TurningFirstSection.TurningProperty);
                    tmpLane.IsExclusive=IsExclusive;
                    tmpLane.TurnMovements=TurnMovements;
                    tmpLane.Proportions=Proportions; % Proportion to the number of lanes occupied by the turns
                    tmpLane.Length=FirstSectionProperty.LaneLengths(tmpLaneTurning.NumLanes-j+1);
                    
                    tmpLaneTurning.Lanes=[tmpLaneTurning.Lanes;tmpLane];
                end
                LaneTurningProperty=[LaneTurningProperty;tmpLaneTurning];
                
            end
            
        end
        
        function [IsExclusive,TurnMovements,Proportions]=findTurnInLane(LaneID,TurnProperty)
            TurnMovements=[];
            for i=1:size(TurnProperty,1)
                if(TurnProperty(i).OrigFromLane<=LaneID && TurnProperty(i).OrigToLane >= LaneID )
                    TurnMovements=[TurnMovements;TurnProperty(i).TurnID];
                end
            end
            
            numLaneByTurn=[];
            TurnAll=[TurnProperty.TurnID]';
            for i=1:length(TurnMovements)
                idx=(TurnAll==TurnMovements(i));
                numLane=TurnProperty(idx).OrigToLane-TurnProperty(idx).OrigFromLane+1;
                numLaneByTurn=[numLaneByTurn;numLane];
            end
            Proportions=numLaneByTurn./sum(numLaneByTurn);
            
            if(length(TurnMovements)>1)
                IsExclusive=0;
            else
                IsExclusive=1;
            end
            
        end
        
        function [dataFormat]=dataFormatJunction
            % This function is used to return the structure of data
            % format: Junction
            
            dataFormat=struct(...
                'JunctionID',               nan,...
                'Name',                     nan,...
                'ExternalID',               nan,...
                'Signalized',               nan,...
                'NumEntranceSection',       nan,...
                'NumExitSection',           nan,...
                'NumTurn',                  nan,...
                'EntranceSections',         nan,...
                'ExitSections',             nan,...
                'Turnings',                 nan);
        end
        
        function [dataFormat]=dataFormatSection
            % This function is used to return the structure of data
            % format: Section
            
            dataFormat=struct(...
                'SectionID',                nan,...
                'Name',                     nan,...
                'ExternalID',               nan,...
                'NumLanes',                 nan,...
                'LaneLengths',              nan,...
                'IsFullLane',               nan);
        end
        
        function [dataFormat]=dataFormatTurning
            dataFormat=struct(...
                'TurnID',           nan,...
                'OrigSectionID',    nan,...
                'DestSectionID',    nan,...
                'OrigFromLane',     nan,...
                'OrigToLane',       nan,...
                'DestFromLane',     nan,...
                'DestToLane',       nan);
        end
        
    end
end

