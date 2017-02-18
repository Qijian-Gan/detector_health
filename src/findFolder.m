classdef findFolder
    
    methods(Static)
                
        function [x] = root()
            here = fileparts(mfilename('fullpath'));
            x = fileparts(here);
        end
        
        function [x] = source()
            x = fullfile(findFolder.root,'src');
        end
        
        function [x] = reports()
            x = fullfile(findFolder.root,'reports');
        end
        
        function [x] = data()
            x = fullfile(findFolder.root,'data\detector');
        end
        
        function [x] = midlink_count()
            x = fullfile(findFolder.root,'data\midlink_count');
        end
        
        function [x] = turning_count()
            x = fullfile(findFolder.root,'data\turning_count');
        end
        
        function [x] = bluetooth_travel_time()
            x = fullfile(findFolder.root,'data\bluetooth');
        end
        
        function [x] = aimsunSimVehicle_data()
            x = fullfile(findFolder.root,'data\aimsun_simVehData');
        end
        
        function [x] = aimsunSimVehicle_data_whole()
            x = fullfile(findFolder.root,'data\aimsun_simVehData_whole');
        end
        
        function [x] = aimsunSimSignal_data()
            x = fullfile(findFolder.root,'data\aimsun_simSigData');
        end
        
        function [x] = aimsunSimSignal_data_whole()
            x = fullfile(findFolder.root,'data\aimsun_simSigData_whole');
        end
        
        function [x] = fieldSimSignal_data()
            x = fullfile(findFolder.root,'data\field_signal');
        end
        
        function [x] = aimsunNetwork_data()
            x = fullfile(findFolder.root,'data\aimsun_networkData');
        end
        
        function [x] = aimsunNetwork_data_whole()
            x = fullfile(findFolder.root,'\data\aimsun_networkData_whole');
        end
        
        function [x] = estStateQueue_data()
            x = fullfile(findFolder.root,'data\estStateQueueData');
        end
        
        function [x] = config()
            x = fullfile(findFolder.root,'config');
        end
        
        function [x] = tests()
            x = fullfile(findFolder.source,'tests');
        end
        
        function [x] = temp()
            x = fullfile(findFolder.root,'temp');
        end
        
        function [x] = temp_aimsun()
            x = fullfile(findFolder.root,'temp_aimsun');
        end
        
        function [x] = temp_aimsun_whole()
            x = fullfile(findFolder.root,'temp_aimsun_whole');
        end
        
        function [x] = aimsun_initialization()
            x = fullfile(findFolder.root,'\data\aimsun_initialization');
        end
        
        function [x] = objects()
            x = fullfile(findFolder.root,'obj');
        end
        
        function [x] = outputs()
            x = fullfile(findFolder.root,'output');
        end
        
        function [x] = IEN_organization()
            x = fullfile(findFolder.root,'\data\IEN_feed\organization_inventory');
        end
        
        function [x] = IEN_detector()
            x = fullfile(findFolder.root,'\data\IEN_feed\detector_inventory');
        end
        
        function [x] = IEN_detector_data()
            x = fullfile(findFolder.root,'\data\IEN_feed\detector_data');
        end
        
        function [x] = IEN_temp()
            x = fullfile(findFolder.root,'temp_IEN');
        end
        
        function [x] = BEATS_network()
            x = fullfile(findFolder.root,'\data\BEATS_simulation\network');
        end
        
        function [x] = BEATS_result()
            x = fullfile(findFolder.root,'\data\BEATS_simulation\result');
        end
        
        function [x] = BEATS_temp()
            x = fullfile(findFolder.root,'temp_BEATS');
        end
        
    end
    
end

