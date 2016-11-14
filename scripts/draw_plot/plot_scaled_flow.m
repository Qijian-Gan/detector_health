clc
clear
close all

load('C:\Users\Qijian_Gan\Documents\GitHub\L0\arterial_data_analysis\detector_health\output\Scaled_data_test.mat')

day=9;
type='Approach';
for i=1:size(appDataEvl,1)
    
    switch type
        case 'Approach'
            figure
            if(isempty(appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).scaled_data))
                data=0;
                time=0;
            else
                time=appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).scaled_data.time/3600;
                data=appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).scaled_data.data;
            end
            plot(time,data,'r','LineWidth',2)
            clear time data
            hold on
            
            if(isempty(appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).raw_data))
                data=0;
                time=0;
            else
                time=appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).raw_data.time/3600;
                data=appDataEvl(i).data_evaluation.approach_volume.rescaled_flow(day).raw_data.data;
            end
            plot(time,data,'--b')
            clear time data
            
            if(isempty(appDataEvl(i).data_evaluation.approach_volume.midlink_count(day).data))
                data=0;
                time=0;
            else
                time=appDataEvl(i).data_evaluation.approach_volume.midlink_count(day).data.time/3600;
                data=appDataEvl(i).data_evaluation.approach_volume.midlink_count(day).data.data;
            end
            plot(time,data,'-.c')
            clear time data
            
%             if(isempty(appDataEvl(i).data_evaluation.approach_volume.turning_count(day).data))
%                 data=0;
%                 time=0;
%             else
%                 time=appDataEvl(i).data_evaluation.approach_volume.turning_count(day).data.time/3600;
%                 data=appDataEvl(i).data_evaluation.approach_volume.turning_count(day).data.data;
%             end
%             plot(time,data,'-*m')
%             clear time data
            
%             legend('Scaled flow', 'Advanced count','Midlink count','Turning count')
            legend('Scaled flow', 'Advanced count','Midlink count')
            xlabel('Time (hr)','FontSize',13);
            ylabel('Flow-rate (vph)','FontSize',13);
        otherwise
            switch type
                case 'Left Turn'
                    turning_data=appDataEvl(i).data_evaluation.left_turn_volume.turning_count(day).data;
                    rescaled_data=appDataEvl(i).data_evaluation.left_turn_volume.rescaled_flow(day).scaled_data;
                    raw_data=appDataEvl(i).data_evaluation.left_turn_volume.rescaled_flow(day).raw_data;
                case 'Through'
                    turning_data=appDataEvl(i).data_evaluation.through_volume.turning_count(day).data;
                    rescaled_data=appDataEvl(i).data_evaluation.through_volume.rescaled_flow(day).scaled_data;
                    raw_data=appDataEvl(i).data_evaluation.through_volume.rescaled_flow(day).raw_data;
                case 'Right Turn'
                    turning_data=appDataEvl(i).data_evaluation.right_turn_volume.turning_count(day).data;
                    rescaled_data=appDataEvl(i).data_evaluation.right_turn_volume.rescaled_flow(day).scaled_data;
                    raw_data=appDataEvl(i).data_evaluation.right_turn_volume.rescaled_flow(day).raw_data;
                otherwise
                    error('Wrong input of traffic movements!')
            end
            
            figure
            if(isempty(rescaled_data))
                data=0;
                time=0;
            else
                time=rescaled_data.time/3600;
                data=rescaled_data.data;
            end
            plot(time,data,'r','LineWidth',2)
            clear time data
            hold on
            
            if(isempty(raw_data))
                data=0;
                time=0;
            else
                time=raw_data.time/3600;
                data=raw_data.data;
            end
            plot(time,data,'--b')
            clear time data
            
            
            if(isempty(turning_data))
                data=0;
                time=0;
            else
                time=turning_data.time/3600;
                data=turning_data.data;
            end
            plot(time,data,'-*m')
            clear time data
            
            legend('Scaled flow', 'Stopbar count','Turning count')
    end
end