from AAPI import *
import csv
vehInfFileName ='C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis/I-210 Aimsun Model/VehicleInf.csv'
	
def AAPILoad():
	return 0

def AAPIInit():	
	global vehInfFileName
	global asection
	global idLane
	global vehTypePos 
	global idCentroidOr 
	global idCentroidDest
	global initPosition
	global initSpeed 
	global tracking	
	global idVehFirst
	global idVehSecond
	global carPosition

	timeSta=27128
	##########Add vehicles back to Aimsun############################
	with open(vehInfFileName, 'rb') as csvfile:
		spamreader = csv.reader(csvfile, delimiter=',')
		next(spamreader, None)
		for row in spamreader:
			if float(row[0])==timeSta:
				asection=int(row[3])
				idLane=int(row[5])
				vehTypePos=int(row[2])
				idCentroidOr=int(row[8])
				idCentroidDest=int(row[9])
				initPosition=float(row[6])
				initSpeed=float(row[7])
				tracking=True
				#print("%i,%i,%i,%i,%i,%f,%f,%i\n"%(asection,idLane, vehTypePos, idCentroidOr, idCentroidDest, initPosition, initSpeed, tracking))
				idx= AKIPutVehTrafficOD(asection,idLane, vehTypePos, idCentroidOr, idCentroidDest, initPosition, initSpeed, tracking)
				#print("%i\n"%(idx))
				
	return 0

def AAPIManage(time, timeSta, timeTrans, acycle):
	##########Activate traffic signal control############################
	if time==0:
		numJunction=ECIGetNumberJunctions() 
		for i in range(numJunction): # Loop for each junction
			junctionID=ECIGetJunctionId(i)
			numPhase=ECIGetNumberPhases (junctionID)
			#status=ECIEnableEvents(junctionID)
			#status=ECIEnableEventsActivatingPhase(junctionID, 1, 20, timeSta)
			#- idJunction represents a valid junction identifier.
			#- idPhaseToActivateNow is the phase to start the control plan
			#- expiredTime represents the seconds from the beginning of the phase. Note that  it cannot be greater than the idPhaseToActivateNow duration, otherwise it will skip idPhaseToActivateNow.
			#- currentTime is the current simulation time
			
			
			status=ECIChangeDirectPhase(junctionID, 1, timeSta, time, acycle, 10)
			#- idJunction represents a valid junction identifier.
			#- idPhase represents a valid phase identifier. This identifier is defined by the interval [1 ... Total Number of phases]
			#- timeSta represents the absolute time of simulation
			#- time represents a relative time of simulation in seconds.
			#- cycle represents the duration of each simulation step in seconds.
			#- expiredTime represents the seconds from the beginning of the phase. Note that it cannot be greater than the idPhase duration, otherwise it will skip idPhase.
			print ("junctionID=%i, status=%i"%(junctionID,status))
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
