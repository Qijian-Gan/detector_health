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

turnConfigFileName = 'C:/Users/Qijian_Gan/Documents/GitHub/L0/arterial_data_analysis' \
						 '/detector_health/scripts/aimsun_model/whole_network/turn_movement_config.csv'

sectionFull=[]
turningFull=[]

#####################Get the section-turning configuration information#####################
with open(turnConfigFileName, 'rb') as csvfile:
	spamreader = csv.reader(csvfile, delimiter=',')
	next(spamreader, None)
	for row in spamreader:
		sectionFull.append(row)

for i in range(len(sectionFull)):
	print("sectionID=%s, left=%s, through=%s, right=%s\n"%(sectionFull[i][0],sectionFull[i][1],sectionFull[i][2],sectionFull[i][3]))

numJunction=0
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKNode")):
	numJunction = numJunction+ len(types)

for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKNode")):
	for junctionObj in types.itervalues():
		junctionID=junctionObj.getId() # Get the junction ID
		numEntranceSections=junctionObj.getNumEntranceSections() # Get the number of entrance sections
		entranceSections=junctionObj.getEntranceSections() # Get the list of GKSection objects

		numExitSections=junctionObj.getNumExitSections() # Get the number of exit sections

		turns = junctionObj.getTurnings()
		numTurn = len(turns)  # Get the number of turns

		for j in range(numEntranceSections): # Loop for each entrance section
			sectionID=entranceSections[j].getId()
			for k in range(len(sectionFull)): # Loop for each section that wants to add the attribute
				if(sectionID==int(sectionFull[k][0])): # If found
					turnInfSection=junctionObj.getFromTurningsOrderedFromLeftToRight(entranceSections[j]) # Get the turning objects
					for t in range(len(turnInfSection)): # Loop for each turn from left to right
						for p in range(3): # Check the corresponding turning movement
							if(int(sectionFull[k][p+1])==1): # If found
								sectionFull[k][p+1]=0  # Set it to be zero
								break
						if(p==0): # The first movement
							turnInfSection[t].setDescription('Left Turn')
						elif (p==1): # The second movement
							turnInfSection[t].setDescription('Through')
						else: # The third movement
							turnInfSection[t].setDescription('Right Turn')
