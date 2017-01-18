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
            print 'Extract signal information!'



        print 'Done with network extraction!'
        print 'Exit the Aimsun model!'
        gui.closeDocument(model)
        gui.forceQuit()
    else:
        gui.showMessage(GGui.eCritical,"Open error", "Cannot load the network")

def ExtractJunctionInformation(model,outputLocation):

    #####################Get the junction information#####################
    junctionInfFileName=outputLocation+'\JunctionInf.txt'
    print junctionInfFileName
    junctionInfFile = open(junctionInfFileName, 'a')

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

            # Write the turn information
            junctionInfFile.write(
                "Turning movements:turnID,origSectionID,destSectionID,origFromLane,origToLane,destFromLane,destToLane, description\n")
            for j in range(numTurn):
                turnObj = turns[j]
                origin=turnObj.getOrigin()
                destination=turnObj.getDestination()
                junctionInfFile.write("%i,%i,%i,%i,%i,%i,%i,%s\n" % (
                    turnObj.getId(), origin.getId(), destination.getId(), turnObj.getOriginFromLane(),
                    turnObj.getOriginToLane(), turnObj.getDestinationFromLane(), turnObj.getDestinationToLane(),
                    turnObj.getDescription()))

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

def ExtractSectionInformation(model,outputLocation):

    ####################Get the section information#####################
    sectionInfFileName=outputLocation+'\SectionInf.txt'
    sectionInfFile = open(sectionInfFileName, 'a')

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
            sectionInfFile.write('Section ID,Name,External ID,# of lanes\n')
            sectionInfFile.write('%i,%s,%s,%i\n' % (sectionID, sectionName, sectionExtID, totLane))

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

            sectionInfFile.write("\n")
    return 0

def ExtractDetectorInformation(model,outputLocation):

    ####################Get the detector information#####################
    detectorInfFileName = outputLocation+'\DetectorInf.csv'
    detectorInfFile = open(detectorInfFileName, 'a')

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
            endPos = startPos - detectorObj.getLength() * 3.28084
            section = detectorObj.getSection()

            if (detectorExtID.isEmpty()):
                detectorExtID='NA'
            if (description.isEmpty()):
                description = 'NA'

            detectorInfFile.write('%d,%s,%d,%s,%d,%d,%.4f,%.4f\n' % (
                detectorID, detectorExtID, section.getId(), description, detectorObj.getFromLane(),
                detectorObj.getToLane(), startPos, endPos))
    return 0


main(sys.argv)