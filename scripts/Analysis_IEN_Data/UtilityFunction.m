classdef UtilityFunction   

    methods(Static)
        
        function [stringOutput]=splitIENDescription(stringInput)
            
            DirectionCases={'WA','EA','NA','SA',...
                'WB','EB','NB','SB'};
            DirectionCombinedCases={'EAWA','WAEA','NASA','SANA',...
                'EBWB','WBEB','NBSB','SBNB'};

            stringInput=strrep(stringInput,':','');
            stringOutput=stringInput;
            for i=1:length(DirectionCombinedCases)                
                if(findstr(stringInput,DirectionCombinedCases{i}))
                    stringOutput=strrep(stringInput,DirectionCombinedCases{i},strcat(DirectionCombinedCases{i},'-'));
                end
            end
            
            for i=1:length(DirectionCases)                
                if(findstr(stringInput,DirectionCases{i}))
                    stringOutput=strrep(stringInput,DirectionCases{i},strcat(DirectionCases{i},'-'));
                end
            end
            
        end
        
    end
end