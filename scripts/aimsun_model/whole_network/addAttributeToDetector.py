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


model = GKSystem.getSystem().getActiveModel()
gui=GKGUISystem.getGUISystem().getActiveGui()

detectorConfigFileName = 'C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis' \
						 '/detector_health/scripts/aimsun_model/whole_network/detector_movement_config.csv'

detectorIDFull=[]
movements=[]

#####################Get the detector configuration information#####################
with open(detectorConfigFileName, 'rb') as csvfile:
	spamreader = csv.reader(csvfile, delimiter=',')
	next(spamreader, None)
	for row in spamreader:
		intID=int(row[0])
		sensorID=int(row[1])
		detectorIDFull.append(intID*100+sensorID)
		movements.append(str(row[2]))

#for i in range(len(detectorIDFull)):
#	print("IntID=%s, Movement=%s\n"%(detectorIDFull[i],movements[i]))

# Get the number of detectors
numDetector = 0
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
	numDetector = numDetector + len(types)
print numDetector

for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
	for detectorObj in types.itervalues():
		detectorID=detectorObj.getId()
		detectorExtID=detectorObj.getExternalId() # Get the external ID
		symbol=0
		for j in range(len(detectorIDFull)):
			if(detectorExtID.toInt()==int(detectorIDFull[j])):
				detectorObj.setDescription(movements[j])
				symbol=1
				break
			else:
				detectorObj.setDescription("")

		description=detectorObj.getDescription()
		print ("detectorID=%d,detectorExtID=%s,Movement=%s"%(detectorID,detectorExtID,description))

gui.save()
