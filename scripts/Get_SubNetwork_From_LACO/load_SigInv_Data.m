function [data]=load_SigInv_Data(fileLocation)

load(fileLocation);
data=dataSigInv(1).Data(1,:);