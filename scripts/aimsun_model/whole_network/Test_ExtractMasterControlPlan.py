from PyANGBasic import *
from PyANGKernel import *
from PyANGGui import *
from PyANGAimsun import *
#from AAPI import *

import datetime
import pickle
import sys
import csv
import os

# Creat and open the output file
outputLocation='C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis' \
						 '/detector_health/scripts/aimsun_model/whole_network'
ControlPlanFileName=outputLocation+'/MasterControlPlanInf.txt'
ControlPlanFile = open(ControlPlanFileName, 'w')

# Load the model
model = GKSystem.getSystem().getActiveModel()

# Get the total number of master control plans
numMasterControlPlans=0
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKMasterControlPlan")):
	numMasterControlPlans=numMasterControlPlans+len(types)
#print numMasterControlPlans

# Loop for each control plan
ControlPlanFile.write('Master Plan ID, Name, Control Plan ID, Starting Time, Duration, Zone\n')
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKMasterControlPlan")):
	for plan in types.itervalues():
		masterPlanID=plan.getId()
		masterPlanName=plan.getName()
		#print (('%i,%s')%(masterPlanID,masterPlanName))

		listOfSchedule=plan.getSchedule()
		for i in range(len(listOfSchedule)):
			controlPlan=listOfSchedule[i].getControlPlan()
			controlPlanID=controlPlan.getId()
			startingTime=listOfSchedule[i].getFrom()
			duration=listOfSchedule[i].getDuration()
			zone=listOfSchedule[i].getZone()
			ControlPlanFile.write(('%i,%s,%i,%i,%i,%i\n')%(masterPlanID,masterPlanName,controlPlanID,startingTime,duration,zone))
			#print(('MasterID=%i,Name=%s,PlanID=%i,StartingTime=%i,Duration=%i,Zone=%i')
			#	  %(masterPlanID,masterPlanName,controlPlanID,startingTime,duration,zone))











