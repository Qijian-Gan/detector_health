from AAPI import *
import sys
from PyANGKernel import *
import datetime
import pickle
import gc

model = GKSystem.getSystem().getActiveModel()
stepSize=1 # How many steps of acycle
maxDuration=60 # In each output file: 5-minute data
delta=0.0001 # Small pertubation
vehInfData=[]
sigInfData=[]
folderLocationVeh=\
	'C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis/detector_health/data/aimsun_simVehData_whole/'
folderLocationSig=\
	'C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis/detector_health/data/aimsun_simSigData_whole/'

def AAPILoad():
	return 0

def AAPIInit():
	return 0

def AAPIManage(time, timeSta, timeTrans, acycle):
	# Time: absolute time of simulation in seconds, and it takes the value zero at the beginning
	# timeSta: time of simulation in stationary period, in seconds
	# TimeTrans: duration of warm-up period, in seconds
	# acycle: duration of each simulation step in seconds
	
	########## Create the vehInfFile output file ##########
	global stepSize, delta
	global maxDuration
	global vehInfData
	global sigInfData
	global folderLocationVeh, folderLocationSig
	global curTime, preTime

	dt=acycle*stepSize # Time duration of each output step

	if time-timeTrans>=0: # Finish the warm-up period

		####################Get the vehicle information as time elapses #####################
		curTime=time 
		if time-timeTrans ==0:	# At the beginning	
			preTime=curTime
		#print "preTime="+str(preTime)+" curTime="+str(curTime)
		#print curTime-preTime - dt
		if curTime-preTime >= dt-delta and curTime-preTime < dt+delta: # For each defined interval: there is a small error introduced by the computer, not exactly zero
			preTime=curTime
			# Loop for the vehicles inside the network
			SimVehType = model.getType("GKSimVehicle")  # Get the simulated vehicle object

			for types in model.getCatalog().getUsedSubTypesFromType(SimVehType):
				for vehicle in types.itervalues():
					vehID=vehicle.getAimsunId()
					type=vehicle.getVehicleType()
					typeID=AKIVehGetVehTypeInternalPosition(type.getId())

					GKObject=vehicle.getCurrentObject() # It can be a junction or a section, or even empty
					if GKObject is None:
						print ("vehID=%i, typeID=%i, is empty"%(vehID,typeID))
					else:
						type=GKObject.getType()
						if type.getName() =="GKNode":
							print ("vehID=%i, typeID=%i, objectID=%i,Name=%s, type=%s" % (
								vehID, typeID, GKObject.getId(), GKObject.getName(), type.getName()))
						else: # Only save vehicles belonging to GKSection
							#print ("vehID=%i, typeID=%i, objectID=%i,Name=%s, type=%s" % (
							#	vehID, typeID, GKObject.getId(), GKObject.getName(), type.getName()))
							objectID=GKObject.getId() # Section or Junction ID
							objectSegment=0 # Is not needed in putting vehicles back to Aimsun

							prePos=vehicle.getLastPosition()
							curPos=vehicle.getCurrentMidPos()
							distance=curPos.distance2D(prePos)
							curSpeed=distance/acycle * 2.23694

							speedAKI=AKIVehGetInf(vehID)
							veh=model.getCatalog().find(vehID)
							print veh.getId()

							print (("%f,%f")%(curSpeed, speedAKI.PreviousSpeed))





					centroidDestination=vehicle.getDestinationCentroid()
					centroidOrigin=vehicle.getOriginCentroid()
					statusLeft = vehicle.isTurningLeft()
					statusRight = vehicle.isTurningRight()
					statusStop = vehicle.isLastStopped()

					#print (("%i,%i,%.4f,%i,%i,%i,%i,%i\n")%(vehID,typeID,0,centroidOrigin,centroidDestination,
					#									  statusLeft,statusRight,statusStop))




	return 0

def AAPIPostManage(time, timeSta, timeTrans, acycle):
	return 0

def AAPIFinish():
	return 0

def AAPIUnLoad():
	return 0
	
def AAPIPreRouteChoiceCalculation(time, timeSta):
	return 0

def AAPIEnterVehicle(idveh, idsection):
	return 0

def AAPIExitVehicle(idveh, idsection):
	return 0

def AAPIEnterPedestrian(idPedestrian, originCentroid):
	return 0

def AAPIExitPedestrian(idPedestrian, destinationCentroid):
	return 0

def AAPIEnterVehicleSection(idveh, idsection, atime):
	return 0

def AAPIExitVehicleSection(idveh, idsection, atime):
	return 0

def WriteData(data,type,filename):
	dataFile = open(filename, 'w')
	if type==1:
		dataFile.write(
		'Time,VehicleID,Type,SectionID,SegmentID,NumLane,CurPosition,CurrentSpeed(mph), CentroidOrigin, CentroidDest,Distance2End,statusLeft,statusRight,statusStop,nextSection\n')
		for i in range(len(data)):
			dataFile.write(("%f,%i,%i,%i,%i,%i,%.4f,%.4f,%i,%i,%.4f,%i,%i,%i,%i\n") % (\
				data[i][0],data[i][1],data[i][2],data[i][3],data[i][4],data[i][5],data[i][6],\
				data[i][7],data[i][8],data[i][9],data[i][10],data[i][11],data[i][12],data[i][13],data[i][14]))
			#dataFile.write(("%s\n") % data[i])
	elif type==2:
		dataFile.write(
		"time, timeSta,junction ID, control type, current phase, number of rings, start time of ring 1, ... \n")
		for i in range(len(data)):
			string=str(data[i][0])
			for j in range(len(data[i])-1):
				string=string+','+str(data[i][j+1])
			dataFile.write(("%s\n") % string)
			#dataFile.write(("%s\n") % data[i])
		dataFile.close()
	return 0
