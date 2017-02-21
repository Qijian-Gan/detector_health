classdef initialization_in_aimsun_with_beats
    properties
        outputFolderLocation    % Location of the output folder
        
        networkData             % Data that contains the link properties of both Aimsun and beats links
        simVehDataProvider      % Data provider that contains the simulated vehicles in Aimsun       
        simBeatsDataProvider    % Data provider that contains the simulation results from beats
        
        defaultParams
    end
    
    methods ( Access = public )
        
        function [this]=initialization_in_aimsun_with_beats(networkData,simVehDataProvider,simBeatsDataProvider,defaultParams,outputFolder)
            %% This function is to generate vehicles for the initialization of aimsun using beats results
            
            this.networkData=networkData; % Get the Beats network data
            this.simVehDataProvider=simVehDataProvider; % Data provider for Aimsun simulation
            this.defaultParams=defaultParams; % Get default parameters
            this.simBeatsDataProvider=simBeatsDataProvider; % Data provider for Beats simulation
            
            if(~isnan(outputFolder))
                this.outputFolderLocation=outputFolder;
            else
                this.outputFolderLocation=findFolder.BEATS_temp;
            end
        end
      
    end
    
    methods ( Static)
       
  
    end
end

