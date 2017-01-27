from AAPI import *
import sys
from PyANGKernel import *
import datetime
import pickle
import gc

model = GKSystem.getSystem().getActiveModel()
stepSize=5 # How many steps of acycle
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
			# Write vehicle information inside sections
			numSection = AKIInfNetNbSectionsANG() # Get the total number of sections
			for i in range(numSection): # Loop for each section
				id = AKIInfNetGetSectionANGId(i) # Get the section ID
				nb = AKIVehStateGetNbVehiclesSection(id,True) # Read the number of vehicles in a section
				for j in range(nb):  # Loop for each vehicle
					infVeh = AKIVehStateGetVehicleInfSection(id,j)	# Dynamic information				
					infVehStatic = AKIVehGetVehicleStaticInfSection(id,j) # Static information

					infVehPath =AKIVehInfPathSection(id,j)
					nextSection= AKIVehInfPathGetNextSection(infVehPath.idVeh,id)

					infVehGeo=AKIVehGetVehicleGraphicInfSection(id,j)
					statusLeft=infVehGeo.leftTurnSignal
					statusRight=infVehGeo.rightTurnSignal
					if infVeh.PreviousSpeed<=0.01:
						statusStop=1
					else:
						statusStop=0

					tmpdata=[timeSta, infVeh.idVeh, infVeh.type, infVeh.idSection, infVeh.segment, infVeh.numberLane\
							,infVeh.CurrentPos, infVeh.CurrentSpeed, infVehStatic.centroidOrigin, infVehStatic.centroidDest\
							,infVeh.distance2End, statusLeft, statusRight, statusStop, nextSection]
					vehInfData.append(tmpdata)
					del infVeh, infVehStatic, infVehPath, nextSection, statusLeft,\
						statusRight, statusStop,tmpdata
				del id, nb

			####################Get the phase information as time elapses #####################
			numJunction = ECIGetNumberJunctions()  # Get the number of signalized junctions
			for i in range(numJunction): # Loop for each junction
				junctionID=ECIGetJunctionId(i)	# Get the junction ID
				controlType=ECIGetControlType(junctionID)#- >= 0: 0 Uncontrolled, 1Fixed, 2 External, 3 Actuated
				curControlPlan=ECIGetNumberCurrentControl (junctionID)
				numRing=ECIGetCurrentNbRingsJunction(junctionID) # Get the number of rings in the current control plan

				tmpdata=[time, timeSta, junctionID, controlType, curControlPlan, numRing]
				if (numRing==1):
					curPhase=ECIGetCurrentPhase(junctionID) # Read the current phase of a junction
					tmpdata.append(curPhase)

					startTimePhase=ECIGetStartingTimePhase(junctionID) # Get the time when the phase is activated
					tmpdata.append(startTimePhase)

					del curPhase, startTimePhase

				else:	# More than one ring			
					for j in range(numRing):
						curPhase=ECIGetCurrentPhaseInRing(junctionID, j) # Get current phase in ring
						tmpdata.append(curPhase)

						startTimePhaseInRing=ECIGetStartingTimePhaseInRing(junctionID, j)
						tmpdata.append(startTimePhaseInRing)

						del curPhase, startTimePhaseInRing

				sigInfData.append(tmpdata)
				del junctionID, controlType, curControlPlan, numRing, tmpdata

	step = round((time - timeTrans) / maxDuration)
	if ((time - timeTrans) >= maxDuration * step - delta and
		(time - timeTrans) <= maxDuration * step + delta and step >= 1):

		vehInfFileName = folderLocationVeh + 'VehicleInf_' + str(int(timeSta)) + '.csv'
		signalInfFileName = folderLocationSig + 'SimSignalPhasingInf_' + str(int(timeSta)) + '.txt'
		WriteData(vehInfData, 1, vehInfFileName)
		WriteData(sigInfData, 2, signalInfFileName)
		del vehInfData, sigInfData

		gc.collect()
		gc.garbage[:]

		vehInfData = []
		sigInfData = []
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
