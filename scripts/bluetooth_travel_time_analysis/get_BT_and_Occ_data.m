function [time,tt,occ,flow]=get_BT_and_Occ_data(dp_BT,dp_sensor,fileName,queryMeasures,interval,detector_IDs_from_A_to_B)


%% Get bluetooth data
% days: 0--9
BT_travel_time=dp_BT.clustering(fileName, queryMeasures, interval);

%% Get average occupancy
avg_occ=[];
avg_flow=[];
for i=1:4
    sensor_data=dp_sensor.clustering(detector_IDs_from_A_to_B{i}, queryMeasures);
    tmp_occ=[];
    tmp_flow=[];
    for i=1:length(sensor_data)
        if(strcmp(sensor_data(i).status,'Good Data'))
            tmp_occ=[tmp_occ;sensor_data(i).data.s_occupancy];
            tmp_flow=[tmp_flow;sensor_data(i).data.s_volume];
        end
    end
    sensor_time=sensor_data(1).data.time;
    avg_occ=[avg_occ,mean(tmp_occ,1,'omitnan')'];
    avg_flow=[avg_flow,mean(tmp_flow,1,'omitnan')'];
end
%% Rescale according to BT travel times
time=[];
tt=[];
occ=[];
flow=[];
for i=1:length(BT_travel_time.time)
    idx=(sensor_time==BT_travel_time.time(i));
    if(sum(idx))
        if(~isnan(BT_travel_time.travel_time(i).mean))
            tt=[tt;BT_travel_time.travel_time(i).mean];
            time=[time;BT_travel_time.time(i)/3600];
            occ=[occ;avg_occ(idx,:)/3600*100];
            flow=[flow;avg_flow(idx,:)];
        end
    end
end