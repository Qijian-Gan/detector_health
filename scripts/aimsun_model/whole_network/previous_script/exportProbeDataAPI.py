from AAPI import *
import sys
from PyANGKernel import *
import datetime

nextCycle = 30.0
groupinglist = [10005971,10005972]

Results = 0

model = GKSystem.getSystem().getActiveModel()
sectionType = model.getType("GKSection")
nodeType = model.getType("GKNode")

def AAPILoad():
	return 0
def AAPIInit():
	return 0
def AAPIManage(time, timeSta, timeTrans, acycle):
	return 0

def AAPIPostManage(time, timeSta, timeTrans, acycle):
	global nextCycle,groupinglist, Results
	if nextCycle<=time and time-nextCycle<acycle:
		print time
		timenew = float(time)
		timeformatted =  str(datetime.timedelta(seconds=nextCycle))
		filename ='ProbeData_%i.csv'%(nextCycle)
		Results = open( filename, 'w')
		Results.write('Vehicle_ID,time,x,y,z,speed(m/sec)\n')
		for i in range(len(groupinglist)):
			listobject = model.getCatalog().find(groupinglist[i])
			probeData = vehiclesInSubpath(listobject,timeformatted)
		nextCycle = nextCycle + 30.0
		Results.close()
	return 0


	
def vehiclesInSubpath(inputObject, timeformatted):
	subpathSections = inputObject.getObjects()
	objectList = []
	nbVehicles = 0
	for object in subpathSections:
		if object.getType() == sectionType:
			sectionId = object.getId()
			objectList.append(sectionId)
		elif object.getType() == nodeType:
			nodeId = object.getId()
			objectList.append(nodeId)
	for object1 in range(len(objectList)):
		object = model.getCatalog().find(objectList[object1])
		if object.getType() == sectionType:
			NbVehiclesSubPath=AKIVehStateGetNbVehiclesSection(objectList[object1],True)
			nbVehicles = nbVehicles + NbVehiclesSubPath
			for veh in range(NbVehiclesSubPath):
				vehicle = AKIVehStateGetVehicleInfSection(objectList[object1], veh)
				SimVehType = model.getType( "GKSimVehicle" )
				for types in model.getCatalog().getUsedSubTypesFromType( SimVehType ):
					for vehicle1 in types.itervalues():
						if vehicle.idVeh == vehicle1.getAimsunId():
							layer = vehicle1.getLayer()
							layer2 = vehicle1.getLength()
							point = GKPoint(vehicle.xCurrentPos, vehicle.yCurrentPos, vehicle.zCurrentPos)
							coord = layer.toDegrees(point)
				Results.write("%i,%s,%.4f,%.4f,%.4f,%.2f \n"%(vehicle.idVeh,timeformatted, coord.x, coord.y, vehicle.zCurrentPos, vehicle.CurrentSpeed*1000/3600))
				
		elif object.getType() == nodeType:
			NbVehiclesJunction = AKIVehStateGetNbVehiclesJunction(objectList[object1])
			for veh in range(NbVehiclesJunction):
				vehicle = AKIVehStateGetVehicleInfJunction(objectList[object1], veh)
				SimVehType = model.getType( "GKSimVehicle" )
				for types in model.getCatalog().getUsedSubTypesFromType( SimVehType ):
					for vehicle1 in types.itervalues():
						if vehicle.idVeh == vehicle1.getAimsunId():
							layer = vehicle1.getLayer()
							point = GKPoint(vehicle.xCurrentPos, vehicle.yCurrentPos, vehicle.zCurrentPos)
							coord = layer.toDegrees(point)
							
				Results.write("%i,%s,%.4f,%.4f,%.4f,%.2f \n"%(vehicle.idVeh,timeformatted, coord.x, coord.y, vehicle.zCurrentPos, vehicle.CurrentSpeed*1000/3600))
		

			
def AAPIFinish():
	return 0
def AAPIUnLoad():
	return 0
def AAPIPreRouteChoiceCalculation(time, timeSta):
	return 0