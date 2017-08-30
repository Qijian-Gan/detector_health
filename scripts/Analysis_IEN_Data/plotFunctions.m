classdef plotFunctions   

    methods(Static)
        
        function plotFlowOccupancy(flow,occupancy,titleString,legendString,saveOrNot,outputFolder,fileName)
            
            f=figure('Position', [216.2000 186.6000 785.6000 543.2000]);
            scatter(occupancy,flow,'b');
            xlabel('Occupancy (%)','FontSize',13);
            ylabel('Flow rate (vph)','FontSize',13);
            set(gca,'YLim',[0 max(100,max(flow)*1.2)])
            grid on
            title(titleString,'FontSize',13)
            legend(legendString)
            
            switch saveOrNot
                case 'Yes'
                    saveas(f,fullfile(outputFolder,sprintf('%s.png',fileName)));
                    close(f);
            end
            
        end
        
        function plotFlowOccupancyMultiDay(DataArray,titleString,lineScheme,legendStringArray,saveOrNot,outputFolder,fileName)
            
            f=figure('Position', [216.2000 186.6000 785.6000 543.2000]);
            maxFlow=100;
            for i=1:size(DataArray,1)
                scatter(DataArray(i).Occupancy,DataArray(i).Flow,lineScheme{i,:});
                maxFlow=max(maxFlow,max(DataArray(i).Flow));
                hold on
            end
            xlabel('Occupancy (%)','FontSize',13);
            ylabel('Flow rate (vph)','FontSize',13);
            set(gca,'YLim',[0 maxFlow*1.2])
            grid on
            title(titleString,'FontSize',13)
            legend(legendStringArray)
            
            switch saveOrNot
                case 'Yes'
                    saveas(f,fullfile(outputFolder,sprintf('%s.png',fileName)));
                    close(f);
            end
            
        end
    end
end