classdef reconstruct_aimsun_network
    properties
        outputFolderLocation    % Location of the output folder

        junctionData         % Data that contains junction information
        sectionData          % Data that contains section information
        
        networkData          % Data that contains both junction and section information (reconstructed)
        
    end
    
    methods ( Access = public )
        
        function [this]=reconstruct_aimsun_network(junctionData,sectionData,outputFolder)
            % This function is to reconstruct the aimsun network
            
            this.junctionData=junctionData;
            this.sectionData=sectionData;
            if(~isnan(outputFolder))
                this.outputFolderLocation=outputFolder;
            else
                this.outputFolderLocation=findFolder.temp_aimsun;
            end
            
        end
        
        function [junctionApproachData]=reconstruction(this)
            % Main function: reconstruction
            
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
                    tmpJunctionApproachData.JunctionExtID=junctionDataNonlinear(i).ExternalID;
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
                    
                    junctionApproachData=[junctionApproachData;tmpJunctionApproachData];
                end
            end      
                        
        end
        
    end
    
     methods ( Static)
           
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

