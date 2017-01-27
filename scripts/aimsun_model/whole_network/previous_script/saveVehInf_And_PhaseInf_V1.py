from AAPI import *
import sys
from PyANGKernel import *
import datetime
import pickle

model = GKSystem.getSystem().getActiveModel()
stepSize=5 # How many steps of acycle
maxSizeEachFile=400 # In each output file
delta=0.0001 # Small pertubation

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
	global curTime, preTime
	ControlPlanJunction=[]

	dt=acycle*stepSize # Time duration of each output step

	vehInfFileName ='C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis/detector_health/scripts/aimsun_model/whole_network/VehicleInf.csv'
	vehInfFile = open( vehInfFileName, 'a')	
	signalInfFileName ='C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis/detector_health/scripts/aimsun_model/whole_network/SimSignalPhasingInf.txt'
	signalInfFile = open( signalInfFileName, 'a')
		
	if time>=0 and time < acycle:
		# Add the header for the first time 
		vehInfFile.write('Time,VehicleID,Type,SectionID,SegmentID,NumLane,CurPosition,CurrentSpeed(mph), CentroidOrigin, CentroidDest,Distance2End,statusLeft,statusRight,statusStop,nextSection\n')
		signalInfFile.write("time, timeSta,junction ID, control type, current phase, number of rings, start time of ring 1, ... \n")	
	
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
					#print ('Vehicle ID= %i and Current Section= %i and Next Section =%i '% (infVehPath.idVeh,id,nextSection)	)
					
					SimVehType = model.getType( "GKSimVehicle" ) # Get the simulated vehicle object
					for types in model.getCatalog().getUsedSubTypesFromType( SimVehType ):
						for vehicle1 in types.itervalues():
							if infVeh.idVeh == vehicle1.getAimsunId():
								statusLeft=vehicle1.isTurningLeft()
								statusRight=vehicle1.isTurningRight() 
								statusStop=vehicle1.isLastStopped() 	
					vehInfFile.write("%f,%i,%i,%i,%i,%i,%.4f,%.4f,%i,%i,%.4f,%i,%i,%i,%i\n"%(timeSta, infVeh.idVeh, infVeh.type, infVeh.idSection, infVeh.segment, infVeh.numberLane, infVeh.CurrentPos,infVeh.CurrentSpeed, infVehStatic.centroidOrigin, infVehStatic.centroidDest,infVeh.distance2End, statusLeft,statusRight,statusStop,nextSection))			


			numJunction = ECIGetNumberJunctions()  # Get the number of signalized junctions

			####################Get the phase information as time elapses #####################
			for i in range(numJunction): # Loop for each junction
				junctionID=ECIGetJunctionId(i)	# Get the junction ID
				controlType=ECIGetControlType(junctionID)#- >= 0: 0 Uncontrolled, 1Fixed, 2 External, 3 Actuated
				curControlPlan=ECIGetNumberCurrentControl (junctionID)
				numRing=ECIGetCurrentNbRingsJunction(junctionID) # Get the number of rings in the current control plan

				string=str(time)+','+str(timeSta)+','+str(junctionID)+','+str(controlType)+','+str(curControlPlan)+','+str(numRing)
				if (numRing==1):
					curPhase=ECIGetCurrentPhase(junctionID) # Read the current phase of a junction
					string=string+','+str(curPhase)
					
					startTimePhase=ECIGetStartingTimePhase(junctionID) # Get the time when the phase is activated
					string=string+','+str(startTimePhase)
					
				else:	# More than one ring			
					for j in range(numRing):
						curPhase=ECIGetCurrentPhaseInRing(junctionID, j) # Get current phase in ring
						string=string+','+str(curPhase)
						
						startTimePhaseInRing=ECIGetStartingTimePhaseInRing(junctionID, j)
						string=string+','+str(startTimePhaseInRing)
					
				signalInfFile.write(("%s\n")%string)

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
