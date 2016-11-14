classdef plot_functions 
    
    methods(Static)
        function plot_BT_travel_time_and_occupancy_flow_with_time(time_BT,BTdata,time_sensor, sensor,str,y1_label, y2_label, titlestr)
            
            figure
            [ax,h1,h2]=plotyy(time_BT,BTdata,time_sensor,sensor);
            
            legend({'BT travel time',str{1:end}},'Location', 'NorthEast')
            h1.LineStyle='-';
            h1.LineWidth=2;
 
            h2(1).LineStyle='-';
            h2(1).LineWidth=1.5;
            h2(2).LineStyle='--';
            h2(2).LineWidth=1.5;
            h2(3).LineStyle='-.';
            h2(3).LineWidth=1.5;
            h2(4).LineStyle=':';
            h2(4).LineWidth=1.5;
            
            xlabel('Time (Hr)','FontSize',13);
            ylabel(ax(1),y1_label,'FontSize',13);   
            ylabel(ax(2),y2_label,'FontSize',13);  
            set(ax,'XTick',[min([time_BT;time_sensor]):2:max([time_BT;time_sensor])]);
            set(ax,'XLim',[min([time_BT;time_sensor]) max([time_BT;time_sensor])]);
            
            set(ax(1),'YLim',[0 max(BTdata)]);
            
            title(titlestr,'FontSize',13);
            grid on
            
        end
        
        function plot_occupancy_flow_relation(occ,flow,str,label_x,label_y)

            for i=1:size(occ,2)
                figure
                scatter(occ(:,i),flow(:,i))
                ylabel(label_y,'FontSize',13);
                xlabel(label_x,'FontSize',13);
                title(str(i),'FontSize',13);
                grid on
            end            
        end
        
        
        function plot_BT_travel_time_speed_and_occupancy_flow_relation(BTdata,sensor_data,str,label_x,label_y,titlestr)
            
            figure
            %             for i=1:size(sensor_data,2)
            %                 scatter(sensor_data(:,i),BTdata)
            %                 hold on
            %             end
            %             legend(str,'Location', 'NorthEast')
            %             ylabel(label_y,'FontSize',13);
            %             xlabel(label_x,'FontSize',13);
            %             title(titlestr,'FontSize',13);
            %             grid on
            %
            for i=1:size(sensor_data,2)
                subplot(ceil(length(str)/2),2,i)
                scatter(sensor_data(:,i),BTdata)
                legend(str(i),'Location', 'NorthEast')
                ylabel(label_y,'FontSize',13);
                xlabel(label_x,'FontSize',13);
                title(titlestr,'FontSize',13);
                grid on
            end
            
        end
        
        
        function plot_BT_travel_time_by_time(BTdata,time,section_length,speed_limit,titlestr)
            % Plot bluetooth travel times by time with: mean, median, 15%ile,
            % 85%ile, and etc.
            % BTdata: 1*n
            % time: 1*n
            
            time_at_limit=section_length/speed_limit*3600;
            time_at_20=section_length/20*3600;
            time_at_10=section_length/10*3600;
            
            plot(time,BTdata,'-ob');
            hold on
            plot(time,time_at_limit*ones(size(time)),'-r')
            plot(time,time_at_20*ones(size(time)),'-.r')
            plot(time,time_at_10*ones(size(time)),'--r')
            legend('BT travel time',sprintf('Travel time at %d mph',speed_limit),'Travel time at 20 mph',...
                'Travel time at 10 mph','Location', 'NorthEast')
            xlabel('Time (Hr)','FontSize',13);
            ylabel('Travel Time (Sec)','FontSize',13);   
            set(gca,'XTick',[0:2:24]);
            set(gca,'XLim',[0 24]);
            set(gca,'YLim',[0 max(time_at_10,max(BTdata))*1.2])
            title(titlestr,'FontSize',13);
            grid on
        end
      
        function boxplot_BT_travel_time_by_time(BTdata,time,section_length,speed_limit,titlestr)
            % Boxplot bluetooth travel times by time
            % BTdata: \sum_i=1^n m_{t,i} *1
            % time: \sum_i=1^n m_{t,i} *1
            
            time_at_limit=section_length/speed_limit*3600;
            time_at_20=section_length/20*3600;
            time_at_10=section_length/10*3600;
            
            width=650;
            height=350;
            f=figure('Position', [450 400 width height],'Visible','on');
            
            h=boxplot(BTdata,time,'symbol','');
            hold on
            legend('BT travel time','Location', 'NorthEast')
            
%             set(h,'LineWidth',2)
            xh=xlabel('Time (Hr)');
            yh=ylabel('Travel Time (Sec)');       
            set([xh,yh],'fontweight','bold', 'fontsize',15);     
            set(gca,'FontSize',11,'fontweight','bold');
            title(titlestr,'FontSize',15,'fontweight','bold');
            grid on            
            
        end
        
    end
end
