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
ControlPlanFileName=outputLocation+'/ControlPlanInf.txt'
ControlPlanFile = open(ControlPlanFileName, 'a')

# Load the model
model = GKSystem.getSystem().getActiveModel()

# Get the total number of control plans
numControlPlans=0
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKControlPlan")):
	numControlPlans=numControlPlans+len(types)
print numControlPlans
ControlPlanFile.write('Number of control plans:\n')
ControlPlanFile.write(('%i\n') % numControlPlans)
ControlPlanFile.write('\n')

# Loop for each control plan
for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKControlPlan")):
	for plan in types.itervalues():
		planID=plan.getId() # Get the plan ID
		planExtID=plan.getExternalId() # Get the external ID
		planName = plan.getName()  # Get name of the control plan
		#print (("ID=%i, ExtID=%s, Name=%s \n")% (planID, planExtID, planName))
		controlJunctions=plan.getControlJunctions()
		#print len(controlJunctions)
		ControlPlanFile.write('Plan ID, Plan ExtID, Plan Name, Number of control junction:\n')
		ControlPlanFile.write(("%i,%s,%s,%i \n")% (planID, planExtID, planName,len(controlJunctions)))

		if len(controlJunctions)==0: # This may happen for Ramp Metering
			ControlPlanFile.write('\n')
			continue

		# Loop for each control junction
		for junction in controlJunctions.itervalues():
			# Get the junction information
			node=junction.getNode()
			id=node.getId()
			name=node.getName()
			#print (("ID=%i, ExtID=%s, Name=%s ,Junction ID=%i, Junction Name=%s \n") % (planID, planExtID, planName, id, name))

			controlType=junction.getControlJunctionType() # 0: controlType; 1: Uncontrolled; 2: FixedControl; 3: External; 4: Actuated
			if controlType==0:
				type= 'controlType'
			elif controlType==1:
				type = 'Uncontrolled'
			elif controlType==2:
				type = 'FixedControl'
			elif controlType==3:
				type = 'External'
			else:
				type = 'Actuated'

			offset=junction.getOffset() # Get the offset
			numBarriers=junction.getNbBarriers() # Get the number of barriers
			cycle = junction.getCycle()  # Get the cycle and the actual cycle
			numRings=junction.getNbRings() # Get the number of rings
			phases = junction.getPhases()  # Get the phase information
			numPhases = len(phases)
			signalInJunction = node.getSignals() # Get the signal information
			numSignals = len(signalInJunction)
			ControlPlanFile.write('Junction ID, Junction Name, Control Type, Offset(s), NumBarriers, Cycle(s),NumRings,NumPhases,numSignals:\n')
			ControlPlanFile.write(("%i,%s,%s,%i,%i,%i,%i,%i,%i \n") % (id, name,type, offset, numBarriers, cycle, numRings, numPhases,numSignals))

			##########Extract the phaseInRing information ###################
			ControlPlanFile.write(
				'Phase ID, Ring ID, StartTime(s), Duration(s), isInterphase(1/0), permissiveStartTime(s),permissiveEndTime,numSignalInPhase,phaseSignalID[...]:\n')
			for i in range(numPhases):
				phaseRing = []

				phaseIDInCycle=phases[i].getId() # Get the phase ID in the cycle
				phaseInRing=phases[i].getIdRing() # Get the corresponding ring ID
				startTime=phases[i].getFrom() # Get the starting time of the phase
				duration = phases[i].getDuration() # Get the phase duration
				isInterphase=phases[i].getInterphase() # Determine whether the phase is an interphase or not
				permissiveStartTime=phases[i].getPermissivePeriodFrom() # Get the permissive starting time
				permissiveEndTime=phases[i].getPermissivePeriodTo() # Get the permissive ending time

				phaseSignals=phases[i].getSignals()
				numSignalInPhase=len(phaseSignals)
				phaseSignalID=[]

				phaseRing=str(phaseIDInCycle)+','+str(phaseInRing)+','+str(startTime)+','+str(duration)+','+str(isInterphase)\
						  +','+str(permissiveStartTime)	+',' + str(permissiveEndTime)+',' + str(numSignalInPhase)
				for j in range(numSignalInPhase):
					phaseRing=phaseRing+','+str(phaseSignals[j].signal)
				ControlPlanFile.write(('%s\n') % phaseRing)

			##########Extract the signalTurning information ###################
			ControlPlanFile.write(
				'Signal ID, NumTurnings, Turning IDS[] :\n')
			for i in range(numSignals):
				signalTurning = []
				signalID=signalInJunction[i].getId()
				turnings=signalInJunction[i].getTurnings()
				numTurnings=len(turnings)
				signalTurning=str(signalID)+','+str(numTurnings)
				for j in range(numTurnings):
					signalTurning=signalTurning+','+str(turnings[j].getId())
				ControlPlanFile.write(('%s\n') % signalTurning)
		ControlPlanFile.write("\n")











