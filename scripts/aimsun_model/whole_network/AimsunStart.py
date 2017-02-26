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

DefaultAngle=8

def main(argv):
    if len(argv)<9:
        print "Usage: aimsun.exe -script %s ANG_FILE" % argv[2]
        return -1
    # Get GUI
    gui=GKGUISystem.getGUISystem().getActiveGui()

    # Load a network
    if gui.loadNetwork(argv[3]):
        model = gui.getActiveModel()
        print('Load the network successfully!')

        # Get the output folder for the network files
        outputLocation=argv[8]
        print outputLocation

        # Call to extract junction information
        if int(argv[4])==1:
            print 'Extract junction information!'
            ExtractJunctionInformation(model,outputLocation)

        # Call to extract Section information
        if int(argv[5]) == 1:
            print 'Extract section information!'
            ExtractSectionInformation(model,outputLocation)

        # Call to extract Detector information
        if int(argv[6]) == 1:
            print 'Extract detector information!'
            ExtractDetectorInformation(model, outputLocation)

            # Call to extract Signal information
        if int(argv[7]) == 1:
            print 'Extract control plans loaded in the Aimsun model!'
            ExtractControlPlanInformation(model, outputLocation)
            # Call to extract signal information using master control plan

            print 'Extract control plans to be used in simulation!'
            ExtractMasterControlPlanInformation(model, outputLocation)

        #gui.save()

        print 'Done with network extraction!'
        print 'Exit the Aimsun model!'
        gui.closeDocument(model)
        gui.forceQuit()
    else:
        gui.showMessage(GGui.eCritical,"Open error", "Cannot load the network")

def ExtractJunctionInformation(model,outputLocation):

    #####################Get the junction information#####################
    junctionInfFileName=outputLocation+'\JunctionInf.txt'
    #print junctionInfFileName
    junctionInfFile = open(junctionInfFileName, 'w')

    global DefaultAngle

    # Get the number of nodes
    numJunction=0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKNode")):
        numJunction = numJunction+ len(types)
    junctionInfFile.write('Number of junctions:\n')
    junctionInfFile.write(('%i\n') % numJunction)
    junctionInfFile.write('\n')

    # Loop for each junction
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKNode")):
        for junctionObj in types.itervalues():
            junctionInfFile.write(
                'Junction ID,Name, External ID, Signalized,# of incoming sections,# of outgoing sections, # of turns\n')

            junctionID = junctionObj.getId()  # Get the junction ID
            junctionExtID = junctionObj.getExternalId()  # Get the external ID
            junctionName = junctionObj.getName()  # Get name of the junction

            numEntranceSections = junctionObj.getNumEntranceSections()  # Get the number of entrance sections
            numExitSections = junctionObj.getNumExitSections()  # Get the number of exit sections
            entranceSections = junctionObj.getEntranceSections()  # Get the list of GKSection objects
            exitSections = junctionObj.getExitSections()

            turns=junctionObj.getTurnings()
            numTurn = len(turns)  # Get the number of turns

            signalGroupList = junctionObj.getSignals()  # Check whether a junction is signalzied or not
            if len(signalGroupList) == 0:
                signalized = 0
            else:
                signalized = 1

            # Write the first line
            junctionInfFile.write('%i,%s,%s,%i,%i,%i,%i\n' % (
            junctionID, junctionName, junctionExtID, signalized, numEntranceSections, numExitSections, numTurn))
            # Write the entrance sections
            junctionInfFile.write("Entrances links:\n")
            for j in range(numEntranceSections - 1):
                junctionInfFile.write(("%i,") % entranceSections[j].getId())
            junctionInfFile.write(("%i\n") % entranceSections[numEntranceSections - 1].getId())
            # Write the exit sections
            junctionInfFile.write("Exit links:\n")
            for j in range(numExitSections - 1):
                junctionInfFile.write(("%i,") % exitSections[j].getId())
            junctionInfFile.write(("%i\n") % exitSections[numExitSections - 1].getId())

            ## Update the turning description
            UpdateTurningDescription(numEntranceSections, entranceSections, junctionObj, DefaultAngle)

            # Write the turn information
            junctionInfFile.write(
                "Turning movements:turnID,origSectionID,destSectionID,origFromLane,origToLane,destFromLane,destToLane, description, turn speed\n")
            for j in range(numTurn):
                turnObj = turns[j]
                origin=turnObj.getOrigin()
                destination=turnObj.getDestination()

                originObj = model.getCatalog().find(origin.getId())  # Get the section object
                numLanesOrigin=len(originObj.getLanes())
                destinationObj = model.getCatalog().find(destination.getId())  # Get the section object
                numLanesDest = len(destinationObj.getLanes())

                turnAngle=turnObj.calcAngleBridge()
                # FromLane: leftmost lane number (GKTurning)/ rightmost lane number (API/our definition)
                # ToLane: rightmost lane number /leftmost lane number (API/our definition)
                # Note: lanes are organized from right to left in our output!!
                # It is different from the definition in the GKSection function
                junctionInfFile.write("%i,%i,%i,%i,%i,%i,%i,%s,%i,%.4f\n" % (
                    turnObj.getId(), origin.getId(), destination.getId(), numLanesOrigin-turnObj.getOriginToLane(),
                    numLanesOrigin-turnObj.getOriginFromLane(),numLanesDest-turnObj.getDestinationToLane(),
                    numLanesDest-turnObj.getDestinationFromLane(), turnObj.getDescription(),turnObj.getSpeed()*0.621371,turnAngle))

            # Write the turn orders by section from left to right
            junctionInfFile.write(
                "Turning movements ordered from left to right in a give section: section ID, # of turns, [turn IDs]\n")
            for j in range(numEntranceSections):
                string = str(entranceSections[j].getId()) + ','
                turnInfSection = junctionObj.getFromTurningsOrderedFromLeftToRight(entranceSections[j])
                string = string + str(len(turnInfSection)) + ','
                for k in range(len(turnInfSection) - 1):
                    string = string + str(turnInfSection[k].getId()) + ','
                string = string + str(turnInfSection[len(turnInfSection) - 1].getId()) + '\n'
                junctionInfFile.write(string)
            junctionInfFile.write("\n")
    return 0

def UpdateTurningDescription(numEntranceSections,entranceSections,junctionObj,DefaultAngle):
    # This function is used to update the turning description in Aimsun
    # Francois has added descriptions to some turning movements
    # (pertected left, permissive left, U turn, two way stopbar)

    for j in range(numEntranceSections):
        turnInfSection = junctionObj.getFromTurningsOrderedFromLeftToRight(entranceSections[j])
        # Get the turning movements from left to right


        #Returns the angle, in degrees, between the last segment of the origin section and
        #  the turn line. When going clockwise the angle will be negative and when going
        # counterclockwise the angle will be positive

        # Get the turn with the minumum angle
        curAddr = 0
        minAngle = abs(turnInfSection[0].calcAngleBridge())
        descriptions=[]
        leftTurnIdx=[]
        lastLeftIdx=[]
        for k in range(len(turnInfSection)):
            individualDescription=turnInfSection[k].getDescription()
            descriptions.append(individualDescription)
            if(individualDescription is not None): # If we have additional descriptions from the model
                # Check whether it is a left-turn movement or not
                idxLeft=individualDescription.contains('Left')
                idxUTurn = individualDescription.contains('U Turn')
                if(idxLeft or idxUTurn): # If yes
                    leftTurnIdx.append(1)
                    lastLeftIdx=k # Get the index of the last left turn movement
                else: # If no
                    leftTurnIdx.append(0)
            else: # No additional description
                leftTurnIdx.append(0)

            # Get the minimum angle
            if(minAngle>abs(turnInfSection[k].calcAngleBridge())):
                curAddr=k
                minAngle = abs(turnInfSection[k].calcAngleBridge())

        if(sum(leftTurnIdx)==0): # No additional description to help?
            if minAngle <=DefaultAngle: # Through movement
                turnInfSection[curAddr].setDescription('Through'+':'+descriptions[curAddr])
                for t in range(curAddr): # Set turns on the left to be Left Turn
                    turnInfSection[t].setDescription('Left Turn'+':'+descriptions[t])
                for t in range(curAddr+1,len(turnInfSection)): # Set turns on the right to be Right Turn
                    turnInfSection[t].setDescription('Right Turn'+':'+descriptions[t])
            else:
                if len(turnInfSection)==3:
                    # It is possible for some special case that Through movement has
                    # a big turning angle, then Overwrite it
                    # In the case of three movements, we consider they are left, through, and right
                    turnInfSection[0].setDescription('Left Turn'+':'+descriptions[0])
                    turnInfSection[1].setDescription('Through'+':'+descriptions[1])
                    turnInfSection[2].setDescription('Right Turn'+':'+descriptions[2])

                elif (turnInfSection[curAddr].calcAngleBridge()>DefaultAngle): # Have a bigger angle to the left
                    for t in range(curAddr+1): # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn'+':'+descriptions[t])
                    for t in range(curAddr+1,len(turnInfSection)): # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn'+':'+descriptions[t])

                elif (turnInfSection[curAddr].calcAngleBridge()<-DefaultAngle): # Have a bigger angle to the right
                    for t in range(curAddr): # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn'+':'+descriptions[t])
                    for t in range(curAddr,len(turnInfSection)): # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn'+':'+descriptions[t])
        else: # Has additional descriptions
            if minAngle <= DefaultAngle: # It is probably a through movement
                if lastLeftIdx<curAddr: # Yes, it is!
                    for t in range(curAddr):  # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn' + ':' + descriptions[t])
                    turnInfSection[curAddr].setDescription('Through' + ':' + descriptions[curAddr])
                    for t in range(curAddr+1,len(turnInfSection)):  # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn' + ':' + descriptions[t])
                else: # If, it is not! No through movements!
                    for t in range(lastLeftIdx+1):  # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn' + ':' + descriptions[t])
                    for t in range(lastLeftIdx+1,len(turnInfSection)):  # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn' + ':' + descriptions[t])
            else:
                if len(turnInfSection)==3 and lastLeftIdx==0:
                    # It is possible for some special case that Through movement has
                    # a big turning angle, then Overwrite it
                    # In the case of three movements, we consider they are left, through, and right
                    turnInfSection[0].setDescription('Left Turn'+':'+descriptions[0])
                    turnInfSection[1].setDescription('Through'+':'+descriptions[1])
                    turnInfSection[2].setDescription('Right Turn'+':'+descriptions[2])

                elif (turnInfSection[curAddr].calcAngleBridge() > DefaultAngle):  # Have a bigger angle to the left
                    if lastLeftIdx>curAddr:
                        curAddr=lastLeftIdx

                    for t in range(curAddr+1):  # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn' + ':' + descriptions[t])
                    for t in range(curAddr+1,len(turnInfSection)):  # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn' + ':' + descriptions[t])

                elif (turnInfSection[curAddr].calcAngleBridge() < -DefaultAngle):  # Have a bigger angle to the right
                    if lastLeftIdx >=curAddr:
                        curAddr = lastLeftIdx+1

                    for t in range(curAddr):  # Set turns on the left to be Left Turn
                        turnInfSection[t].setDescription('Left Turn' + ':' + descriptions[t])
                    for t in range(curAddr, len(turnInfSection)):  # Set turns on the right to be Right Turn
                        turnInfSection[t].setDescription('Right Turn' + ':' + descriptions[t])

def ExtractSectionInformation(model,outputLocation):

    ####################Get the section information#####################
    sectionInfFileName=outputLocation+'\SectionInf.txt'
    sectionInfFile = open(sectionInfFileName, 'w')

    translator=GKCoordinateTranslator(model)

    # Get the number of sections
    numSection=0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKSection")):
        numSection=numSection+len(types)
    sectionInfFile.write('Number of sections:\n')
    sectionInfFile.write(('%i\n') % numSection)
    sectionInfFile.write('\n')

    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKSection")):
        for sectionObj in types.itervalues():
            sectionID = sectionObj.getId()  # Get the section ID
            sectionExtID = sectionObj.getExternalId()  # Get the section external ID
            sectionName = sectionObj.getName()  # Get the section name

            # Write the first line
            lanes=sectionObj.getLanes()
            totLane=len(lanes)
            points = sectionObj.getPoints()  # Get the shape files
            totPoint = len(points)
            sectionInfFile.write('Section ID,Name,External ID,# of lanes,# of points\n')
            sectionInfFile.write('%i,%s,%s,%i,%i\n' % (sectionID, sectionName, sectionExtID, totLane,totPoint))

            # Write the lane lengths
            sectionInfFile.write("Lane lengths:\n")
            for j in range(totLane - 1):  # Loop for each lane: from leftmost to rightmost
                length = float(sectionObj.getLaneLength(j)) * 3.28084
                sectionInfFile.write(("%.4f,") % length)  # Get the lane length in feet
            length = float(sectionObj.getLaneLength(totLane - 1)) * 3.28084
            sectionInfFile.write(("%.4f\n") % length)

            # Write the lane properties
            sectionInfFile.write("Is full lane:\n")
            for j in range(totLane - 1):  # Loop for each lane: from leftmost to rightmost
                sectionLane = sectionObj.getLane(j)  # Get the section_lane object
                sectionInfFile.write(("%i,") % sectionLane.isFullLane())  # Get the lane status
            sectionLane = sectionObj.getLane(totLane - 1)  # Get the section_lane object
            sectionInfFile.write(("%i\n") % sectionLane.isFullLane())  # Get the lane status: To find whether it is a full lane: use to identify left-turn and right-turn pockets

            # Write the shape files
            sectionInfFile.write("Shape points:\n")
            for j in range(totPoint-1):
                point= translator.toDegrees(points[j])
                sectionInfFile.write(("%.6f,%.6f,") % (point.x,point.y))
            point = translator.toDegrees(points[totPoint-1])
            sectionInfFile.write(("%.6f,%.6f\n") % (point.x, point.y))

            sectionInfFile.write("\n")
    return 0

def ExtractDetectorInformation(model,outputLocation):

    AddAttributeToDetector(model, outputLocation)
    ####################Get the detector information#####################
    detectorInfFileName = outputLocation+'\DetectorInf.csv'
    detectorInfFile = open(detectorInfFileName, 'w')

    # Get the number of detectors
    numDetector = 0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
        numDetector = numDetector + len(types)

    detectorInfFile.write(
        'Detector ID,External ID, Section ID, Description,First Lane, Last Lane, Initial Position, Final Position\n')
    # Loop for each detector
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
        for detectorObj in types.itervalues():
            detectorID = detectorObj.getId()  # Get the detector ID
            detectorExtID = detectorObj.getExternalId()  # Get the external ID
            description = detectorObj.getDescription()  # Get the description

            startPos = detectorObj.getPosition() * 3.28084
            endPos = startPos + detectorObj.getLength() * 3.28084
            section = detectorObj.getSection()
            sectionObj = model.getCatalog().find(section.getId())  # Get the section object
            numLanes = len(sectionObj.getLanes())

            if (detectorExtID.isEmpty()):
                detectorExtID='NA'
            if (description.isEmpty()):
                description = 'NA'

            # Note: lanes are labeled from rightmost to leftmost in our output file
            # FromLane: leftmost lane number (GKTurning)/ rightmost lane number (API/our definition)
            # ToLane: rightmost lane number /leftmost lane number (API/our definition)
            detectorInfFile.write('%d,%s,%d,%s,%d,%d,%.4f,%.4f\n' % (
                detectorID, detectorExtID, section.getId(), description,
                numLanes-detectorObj.getToLane(), numLanes-detectorObj.getFromLane(),startPos, endPos))
    return 0

def AddAttributeToDetector(model,outputLocation):

    gui = GKGUISystem.getGUISystem().getActiveGui()

    detectorConfigFileName=os.path.join(outputLocation,'detector_movement_config.csv')

    detectorIDFull = []
    movements = []

    #####################Get the detector configuration information#####################
    with open(detectorConfigFileName, 'rb') as csvfile:
        spamreader = csv.reader(csvfile, delimiter=',')
        next(spamreader, None)
        for row in spamreader:
            if row[0] != "":
                intID = int(row[0])
                sensorID = int(row[1])
                detectorIDFull.append(intID * 100 + sensorID)
                movements.append(str(row[2]))

    # for i in range(len(detectorIDFull)):
    #	print("IntID=%s, Movement=%s\n"%(detectorIDFull[i],movements[i]))

    # Get the number of detectors
    numDetector = 0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
        numDetector = numDetector + len(types)
    # print numDetector

    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKDetector")):
        for detectorObj in types.itervalues():
            detectorID = detectorObj.getId()
            detectorExtID = detectorObj.getExternalId()  # Get the external ID
            symbol = 0
            for j in range(len(detectorIDFull)):
                if (detectorExtID.toInt() == int(detectorIDFull[j])):
                    detectorObj.setDescription(movements[j])
                    symbol = 1
                    break
                else:
                    detectorObj.setDescription("")

            description = detectorObj.getDescription()
            print ("detectorID=%d,detectorExtID=%s,Movement=%s" % (detectorID, detectorExtID, description))


def ExtractControlPlanInformation(model,outputLocation):
    # Creat and open the output file
    ControlPlanFileName = outputLocation + '\ControlPlanInf.txt'
    ControlPlanFile = open(ControlPlanFileName, 'w')

    # Load the model
    model = GKSystem.getSystem().getActiveModel()

    # Get the total number of control plans
    numControlPlans = 0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKControlPlan")):
        numControlPlans = numControlPlans + len(types)
    print numControlPlans
    ControlPlanFile.write('Number of control plans:\n')
    ControlPlanFile.write(('%i\n') % numControlPlans)
    ControlPlanFile.write('\n')

    # Loop for each control plan
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKControlPlan")):
        for plan in types.itervalues():
            planID = plan.getId()  # Get the plan ID
            planExtID = plan.getExternalId()  # Get the external ID
            planName = plan.getName()  # Get name of the control plan
            # print (("ID=%i, ExtID=%s, Name=%s \n")% (planID, planExtID, planName))
            controlJunctions = plan.getControlJunctions()
            controlPlanOffset=plan.getOffset()
            #print ("ID=%d,Offset=%d"%(planID,controlPlanOffset))

            # print len(controlJunctions)
            ControlPlanFile.write('Plan ID, Plan ExtID, Plan Name, Number of control junction, Plan Offset:\n')
            ControlPlanFile.write(("%i,%s,%s,%i,%i \n") %
                                  (planID, planExtID, planName, len(controlJunctions),controlPlanOffset))

            if len(controlJunctions) == 0:  # This may happen for Ramp Metering
                ControlPlanFile.write('\n')
                continue

            # Loop for each control junction
            for junction in controlJunctions.itervalues():
                # Get the junction information
                node = junction.getNode()
                id = node.getId()
                name = node.getName()
                # print (("ID=%i, ExtID=%s, Name=%s ,Junction ID=%i, Junction Name=%s \n") % (planID, planExtID, planName, id, name))

                controlType = junction.getControlJunctionType()  # 0: Unspecified; 1: Uncontrolled; 2: FixedControl; 3: External; 4: Actuated
                if controlType == 0:
                    type = 'Unspecified'
                elif controlType == 1:
                    type = 'Uncontrolled'
                elif controlType == 2:
                    type = 'FixedControl'
                elif controlType == 3:
                    type = 'External'
                else:
                    type = 'Actuated'

                offset = junction.getOffset()  # Get the offset
                numBarriers = junction.getNbBarriers()  # Get the number of barriers
                cycle = junction.getCycle()  # Get the cycle and the actual cycle
                numRings = junction.getNbRings()  # Get the number of rings
                phases = junction.getPhases()  # Get the phase information
                numPhases = len(phases)
                signalInJunction = node.getSignals()  # Get the signal information
                numSignals = len(signalInJunction)
                ControlPlanFile.write(
                    'Junction ID, Junction Name, Control Type, Offset(s), NumBarriers, Cycle(s),NumRings,NumPhases,numSignals:\n')
                ControlPlanFile.write(("%i,%s,%s,%i,%i,%i,%i,%i,%i \n") % (
                id, name, type, offset, numBarriers, cycle, numRings, numPhases, numSignals))

                ##########Extract the phaseInRing information ###################
                ControlPlanFile.write(
                    'Phase ID, Ring ID, StartTime(s), Duration(s), isInterphase(1/0), permissiveStartTime(s),permissiveEndTime,numSignalInPhase,phaseSignalID[...]:\n')
                for i in range(numPhases):
                    phaseRing = []

                    phaseIDInCycle = phases[i].getId()  # Get the phase ID in the cycle
                    phaseInRing = phases[i].getIdRing()  # Get the corresponding ring ID
                    startTime = phases[i].getFrom()  # Get the starting time of the phase
                    duration = phases[i].getDuration()  # Get the phase duration
                    isInterphase = phases[i].getInterphase()  # Determine whether the phase is an interphase or not
                    permissiveStartTime = phases[i].getPermissivePeriodFrom()  # Get the permissive starting time
                    permissiveEndTime = phases[i].getPermissivePeriodTo()  # Get the permissive ending time

                    phaseSignals = phases[i].getSignals()
                    numSignalInPhase = len(phaseSignals)
                    phaseSignalID = []

                    phaseRing = str(phaseIDInCycle) + ',' + str(phaseInRing) + ',' + str(startTime) + ',' + str(
                        duration) + ',' + str(isInterphase) \
                                + ',' + str(permissiveStartTime) + ',' + str(permissiveEndTime) + ',' + str(
                        numSignalInPhase)
                    for j in range(numSignalInPhase):
                        phaseRing = phaseRing + ',' + str(phaseSignals[j].signal)
                    ControlPlanFile.write(('%s\n') % phaseRing)

                ##########Extract the signalTurning information ###################
                ControlPlanFile.write(
                    'Signal ID, NumTurnings, Turning IDS[] :\n')
                for i in range(numSignals):
                    signalTurning = []
                    signalID = signalInJunction[i].getId()
                    turnings = signalInJunction[i].getTurnings()
                    numTurnings = len(turnings)
                    signalTurning = str(signalID) + ',' + str(numTurnings)
                    for j in range(numTurnings):
                        signalTurning = signalTurning + ',' + str(turnings[j].getId())
                    ControlPlanFile.write(('%s\n') % signalTurning)

                ##########Extract the coordination information ###################
                ControlPlanFile.write(
                    'Ring ID, Coordinated Phase, Offset, getMatchesOffsetWithEndOfPhase :\n')
                for i in range (numRings):
                    coordinatedPhase=junction.getCoordinatedPhase(i+1)
                    # For actuated junctions with coordinated phases, the coordinated
                    # point can be the end of the coordinated phase (true) or the
                    # beginning of the coordinated phase (false)
                    if(coordinatedPhase is None):
                        phaseID=-1
                        offset=-1
                        matchOffsetWithEndOfPhase=-1
                    else:
                        phaseID=coordinatedPhase.getId()
                        offset=junction.getOffset()
                        matchOffsetWithEndOfPhase=junction.getMatchesOffsetWithEndOfPhase()
                    ControlPlanFile.write(('%i,%i,%i,%i\n') % (i+1,phaseID,offset,matchOffsetWithEndOfPhase))
            ControlPlanFile.write("\n")

def ExtractMasterControlPlanInformation(model, outputLocation):
    # Creat and open the output file
    ControlPlanFileName = outputLocation + '\MasterControlPlanInf.txt'
    ControlPlanFile = open(ControlPlanFileName, 'w')

    # Load the model
    model = GKSystem.getSystem().getActiveModel()

    # Get the total number of master control plans
    numMasterControlPlans = 0
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKMasterControlPlan")):
        numMasterControlPlans = numMasterControlPlans + len(types)
    # print numMasterControlPlans

    # Loop for each control plan
    ControlPlanFile.write('Master Plan ID, Name, Control Plan ID, Starting Time, Duration, Zone\n')
    for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKMasterControlPlan")):
        for plan in types.itervalues():
            masterPlanID = plan.getId()
            masterPlanName = plan.getName()
            # print (('%i,%s')%(masterPlanID,masterPlanName))

            listOfSchedule = plan.getSchedule()
            for i in range(len(listOfSchedule)):
                controlPlan = listOfSchedule[i].getControlPlan()
                controlPlanID = controlPlan.getId()
                startingTime = listOfSchedule[i].getFrom()
                duration = listOfSchedule[i].getDuration()
                zone = listOfSchedule[i].getZone()
                ControlPlanFile.write(('%i,%s,%i,%i,%i,%i\n') % (
                masterPlanID, masterPlanName, controlPlanID, startingTime, duration, zone))
                # print(('MasterID=%i,Name=%s,PlanID=%i,StartingTime=%i,Duration=%i,Zone=%i')
                #	  %(masterPlanID,masterPlanName,controlPlanID,startingTime,duration,zone))


main(sys.argv)