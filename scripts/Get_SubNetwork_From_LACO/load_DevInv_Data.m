function [data]=load_DevInv_Data(fileLocation)

load(fileLocation);
data=dataDevInv(1).Data(1,:);