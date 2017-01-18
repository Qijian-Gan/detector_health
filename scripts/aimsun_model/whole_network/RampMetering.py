from AAPI import *
from PyANGKernel import *
import datetime
import sys
import csv
import os

#----------------------------------------------------------------------------------------------------------------------
# This API enables the simulation of the SATMS 3.0 ramp metering logic used by Caltrans District 7 in the Los Angeles
# region.  It allows more specifically the simulation of local Time-of-Day (TOD) and Linear Mainline Responsive (LMR)
# control logic, as well as of the Q1 and Q2 queue override logic, and the freeway priority override mode.
#
# Use of the API requires two setup CSV files:
#   - RampMeteringData.csv: file containing the SATMS parameters for each ramp metering location (US units)
#   - RampMeterTODTable.csv: file containing the start times and metering rates used in TOD operations
#
# Limitations:
#   - In its current form, the API can only be used for freeways that have no more than 6 mainline traffic lanes and
#     for metered ramps with no more than 2 traffic lanes.  Future revisions could increase these limits if needed.
#
# Modeling notes:
#   - Control options: 0 - TOD control;  1 - LMR
#   - User must specific the number of detectors used for mainline, Q1, and Q2 detectors
#   - For each location, the use must specify for each location the Aimsun detector ID corresponding to the detectors
#     used using the standard Caltrans lane numbering approach (leftmost lane is lane #1).  Where there are fewer than
#     6 mainline detectors and 2 Q1 or Q2 ramp detectors, a "-1" should be entered for the detector ID.  The application
#     will recognize a negative number as an absence of detector.
#
# Application developer:
#   - Francois Dion, Senior Development Engineering, PATH Program, University of California, Berkeley, CA, USA
#
# Release date:
#    - August 8, 2016
#----------------------------------------------------------------------------------------------------------------------


#-------------------------------------------------------------------------
# Global Variables
#-------------------------------------------------------------------------

FilePath                 = os.path.dirname(os.path.realpath(__file__))
DebugFileName            = 'DebugFile.dat'
DataFileName             = 'RampMeteringData.csv'
TODTableFileName         = 'RampMeterTODTable.csv'

ControlCycle             = 30.  #interval between queue checks
OccupancyThreshold       = 50.  #percentage detector occupancy corresponding to full occupancy
GreenBallRate            = 3000.#assumed vehicle flow under green ball metering operation (veh/hr/lane)
NumDataPoints3Min        = 1    #number of data points to use in average calculation over 3 minutes
NumDataPoints1Min        = 1    #number of data points to use in average Qcalculation over 1 minute

NumQ1Dets                = []   #Number of Q1 detectors
NumQ2Dets                = []   #Number of Q2 detectors
NumMainDets              = []   #Number of mainline detectors
hasMainLaneDet           = []   #For each lane: 1 if a lane detector exists, 0 otherwise
hasQ1LaneDet             = []
hasQ2LaneDet             = []

MainDetLn1               = []   #ID of associated mainline Lane 1 detector
MainDetLn2               = []   #ID of associated mainline Lane 2 detector
MainDetLn3               = []   #ID of associated mainline Lane 3 detector
MainDetLn4               = []   #ID of associated mainline Lane 4 detector
MainDetLn5               = []   #ID of associated mainline Lane 5 detector
MainDetLn6               = []   #ID of associated mainline Lane 6 detector
Q1DetLn1                 = []   #ID of associated Q1 Lane 1 detector
Q1DetLn2                 = []   #ID of associated Q1 Lane 2 detector
Q2DetLn1                 = []   #ID of associated Q2 Lane 1 detector
Q2DetLn2                 = []   #ID of associated Q2 Lane 2 detector

MainDetsInSim            = []   #True if mainline detector is within simulated area, false otherwise
Q1DetsInSim              = []   #True if Q1 detector is within simulated area, false otherwise
Q2DetsInSim              = []   #True if Q2 detector is within simulated area, false otherwise

PastMainDetLn1Speeds     = []   #Record of mainline lane 1 detection speeds over past 3 minutes
PastMainDetLn2Speeds     = []   #Record of mainline lane 2 detection speeds over past 3 minutes
PastMainDetLn3Speeds     = []   #Record of mainline lane 3 detection speeds over past 3 minutes
PastMainDetLn4Speeds     = []   #Record of mainline lane 4 detection speeds over past 3 minutes
PastMainDetLn5Speeds     = []   #Record of mainline lane 5 detection speeds over past 3 minutes
PastMainDetLn6Speeds     = []   #Record of mainline lane 6 detection speeds over past 3 minutes

PastMainDetLn1Counts     = []   #Record of mainline lane 1 detection counts over past 3 minutes
PastMainDetLn2Counts     = []   #Record of mainline lane 2 detection counts over past 3 minutes
PastMainDetLn3Counts     = []   #Record of mainline lane 3 detection counts over past 3 minutes
PastMainDetLn4Counts     = []   #Record of mainline lane 4 detection counts over past 3 minutes
PastMainDetLn5Counts     = []   #Record of mainline lane 5 detection counts over past 3 minutes
PastMainDetLn6Counts     = []   #Record of mainline lane 6 detection counts over past 3 minutes

PastMainDetLn1Occups     = []   #Record of mainline lane 1 detection occupancy over past 1 minute
PastMainDetLn2Occups     = []   #Record of mainline lane 2 detection occupancy over past 1 minute
PastMainDetLn3Occups     = []   #Record of mainline lane 3 detection occupancy over past 1 minute
PastMainDetLn4Occups     = []   #Record of mainline lane 4 detection occupancy over past 1 minute
PastMainDetLn5Occups     = []   #Record of mainline lane 5 detection occupancy over past 1 minute
PastMainDetLn6Occups     = []   #Record of mainline lane 6 detection occupancy over past 1 minute

PastQ1DetLn1Occups       = []   #Record of Q1 lane 1 detection occupancy over past 1 minute
PastQ1DetLn2Occups       = []   #Record of Q1 lane 2 detection occupancy over past 1 minute
PastQ2DetLn1Occups       = []   #Record of Q2 lane 1 detection occupancy over past 1 minute
PastQ2DetLn2Occups       = []   #Record of Q2 lane 2 detection occupancy over past 1 minute

Avg3MinMainDetLn1Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 1 detector
Avg3MinMainDetLn2Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 2 detector
Avg3MinMainDetLn3Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 3 detector
Avg3MinMainDetLn4Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 4 detector
Avg3MinMainDetLn5Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 5 detector
Avg3MinMainDetLn6Speed   = []   #Average 3-minute speed (mph or km/h) for mainline lane 6 detector
Avg3MinMainDetSpeed      = []   #Average 3-minute speed (mph or km/h) across all mainline detectors

Sum3MinMainDetLn1Volume  = []   #3-minute vehicle count (vehs) for mainline lane 1 detector
Sum3MinMainDetLn2Volume  = []   #3-minute vehicle count (vehs) for mainline lane 2 detector
Sum3MinMainDetLn3Volume  = []   #3-minute vehicle count (vehs) for mainline lane 3 detector
Sum3MinMainDetLn4Volume  = []   #3-minute vehicle count (vehs) for mainline lane 4 detector
Sum3MinMainDetLn5Volume  = []   #3-minute vehicle count (vehs) for mainline lane 5 detector
Sum3MinMainDetLn6Volume  = []   #3-minute vehicle count (vehs) for mainline lane 6 detector
Avg3MinMainDetLaneVolume = []   #3-minute average lane vehicle count (veh/lane) across all mainline detectors

Avg1MinMainDetLn1Occup   = []   #Average 1-minute occupancy (%) for mainline lane 1 detector
Avg1MinMainDetLn2Occup   = []   #Average 1-minute occupancy (%) for mainline lane 2 detector
Avg1MinMainDetLn3Occup   = []   #Average 1-minute occupancy (%) for mainline lane 3 detector
Avg1MinMainDetLn4Occup   = []   #Average 1-minute occupancy (%) for mainline lane 4 detector
Avg1MinMainDetLn5Occup   = []   #Average 1-minute occupancy (%) for mainline lane 5 detector
Avg1MinMainDetLn6Occup   = []   #Average 1-minute occupancy (%) for mainline lane 6 detector
Avg1MinMainDetOccup      = []   #Average 1-minute occupancy (%) at mainline detectors

#Avg1MinQ1DetLn1Occup     = []  #Average 1-minute occupancy (%) for Q1 lane 1 detector
#Avg1MinQ1DetLn2Occup     = []  #Average 1-minute occupancy (%) for Q1 lane 2 detector
#Avg1MinQ1DetOccup        = []  #Average 1-minute occupancy (%) for Q1 detectors
#Avg1MinQ2DetLn1Occup     = []  #Average 1-minute occupancy (%) for Q2 lane 1 detector
#Avg1MinQ2DetLn2Occup     = []  #Average 1-minute occupancy (%) for Q2 lane 2 detector
#Avg1MinQ2DetOccup        = []  #Average 1-minute occupancy (%) for Q2 detectors

Avg5sQ1DetLn1Occup       = []   #Average 5-second occupancy (%) for Q1 lane 1 detector
Avg5sQ1DetLn2Occup       = []   #Average 5-second occupancy (%) for Q1 lane 2 detector
Avg5sQ1DetOccup          = []   #Average 5-second occupancy (%) for Q1 detectors
Avg5sQ2DetLn1Occup       = []   #Average 5-second occupancy (%) for Q2 lane 1 detector
Avg5sQ2DetLn2Occup       = []   #Average 5-second occupancy (%) for Q2 lane 2 detector
Avg5sQ2DetOccup          = []   #Average 5-second occupancy (%) for Q2 detectors

QueueControlTimer        = []   #Timer tracking position within ramp metering Control Cycle
DecisionPoint            = []   #True/False flag to active queue control checks once every cycle only
ControlOption            = []   #Ramp metering control option: 0 for default (TOD)- 1 for LMR
CriticalOccupA           = []   #Critical 1-minute mainline occupancy for LMR Plan A (veh/1 min/lane)
CriticalOccupB           = []   #Critical 1-minute mainline occupancy for LMR Plan B (veh/1 min/lane)
CriticalVolumeA          = []   #Critical 3-minute mainline volume for LMR Plan A (veh/3 min/lane)
CriticalVolumeB          = []   #Critical 3-minute mainline volume for LMR Plan B (veh/3 min/lane)
CriticalSpeeds           = []   #Mainline speed at which queue control is activated
NumMeteringLanes         = []   #Number of metered lanes on ramp
RateMin                  = []   #Minimum ramp metering rate (veh/h)
RateMax                  = []   #Maximum ramp metering rate (veh/h)
RateStep                 = []   #Ramp metering increment (veh/h)
Q1OccupThreshold         = []   #Full occupnacy time interval triggering the activation of Q1 control
Q2OccupThreshold         = []   #Full occupancy time interval triggering the activation of Q2 control
Q1FullOccupancyTimer     = []   #Time interval Q1 detector has occupancy greater than Occupancy Threshold
Q2FullOccupancyTimer     = []   #Time interval Q2 detector has occupancy greater than Occupancy Threshold
ActiveQ1Control          = []   #True/False flag to indicate whether Q1 control is active
ActiveQ2Control          = []   #True/False flag to indicate whether Q2 control is active
EndQ1Control             = []   #True/False flag to end Q1 queue control
EndQ2Control             = []   #True/False flag to end Q2 queue control
CongestionOverride       = []   #True/False flag to indicate congested conditions on freeway mainline

#-------------------------------------------------------------------------
# Aimsun Hooks
#-------------------------------------------------------------------------

def AAPILoad():
    #AKIPrintString( "AAPILoad" )
    return 0

def AAPIInit():
    AKIPrintString("Ramp metering queue control API loaded")

    #Open debug file
    Results = open(FilePath + '\\' + DebugFileName,'w')
    Results.write('Ramp Metering API Debug File\n\n')

    #determine number of rows needed in arrays for 1-min and 3-min data samples
    NumDataPoints3Min = int((3 * 60) / AKIDetGetCycleInstantDetection())
    NumDataPoints1Min = int(60 / AKIDetGetCycleInstantDetection())
    NumDataPoints5s = int(5 / AKIDetGetCycleInstantDetection())

    #Build ramp meter data arrays
    NumMeters = ECIGetNumberMeterings()
    if NumMeters > 0:
        Results.write("Number of ramp meters = %i\n" % (NumMeters))
        print "Ramp API - Number of ramp meters = %i" % (NumMeters)

        #Initialize ramp metering data arrays
        for n in range(0,NumMeters):
            NumQ1Dets.append(0)
            NumQ2Dets.append(0)
            NumMainDets.append(0)

            MainLaneArray = []
            Q1LaneArray = []
            Q2LaneArray = []
            for m in range(0,7):
                MainLaneArray.append(0)
            for m in range(0,3):
                Q1LaneArray.append(0)
                Q2LaneArray.append(0)
            hasMainLaneDet.append(MainLaneArray)
            hasQ1LaneDet.append(Q1LaneArray)
            hasQ2LaneDet.append(Q2LaneArray)

            MainDetLn1.append(-1)
            MainDetLn2.append(-1)
            MainDetLn3.append(-1)
            MainDetLn4.append(-1)
            MainDetLn5.append(-1)
            MainDetLn6.append(-1)
            Q1DetLn1.append(-1)
            Q1DetLn2.append(-1)
            Q2DetLn1.append(-1)
            Q2DetLn2.append(-1)

            MainDetsInSim.append(False)
            Q1DetsInSim.append(False)
            Q2DetsInSim.append(False)

            PastOccupLn1Data = []
            PastOccupLn2Data = []
            PastOccupLn3Data = []
            PastOccupLn4Data = []
            PastOccupLn5Data = []
            PastOccupLn6Data = []
            PastQ1OccupLn1Data = []
            PastQ1OccupLn2Data = []
            PastQ2OccupLn1Data = []
            PastQ2OccupLn2Data = []

            for m in range (0,NumDataPoints1Min):
                PastOccupLn1Data.append(0.)
                PastOccupLn2Data.append(0.)
                PastOccupLn3Data.append(0.)
                PastOccupLn4Data.append(0.)
                PastOccupLn5Data.append(0.)
                PastOccupLn6Data.append(0.)

            for m in range(0, NumDataPoints5s):
                PastQ1OccupLn1Data.append(0.)
                PastQ1OccupLn2Data.append(0.)
                PastQ2OccupLn1Data.append(0.)
                PastQ2OccupLn2Data.append(0.)

            PastMainDetLn1Occups.append(PastOccupLn1Data)
            PastMainDetLn2Occups.append(PastOccupLn2Data)
            PastMainDetLn3Occups.append(PastOccupLn3Data)
            PastMainDetLn4Occups.append(PastOccupLn4Data)
            PastMainDetLn5Occups.append(PastOccupLn5Data)
            PastMainDetLn6Occups.append(PastOccupLn6Data)
            PastQ1DetLn1Occups.append(PastQ1OccupLn1Data)
            PastQ1DetLn2Occups.append(PastQ1OccupLn2Data)
            PastQ2DetLn1Occups.append(PastQ2OccupLn1Data)
            PastQ2DetLn2Occups.append(PastQ2OccupLn2Data)

            PastLn1SpeedData = []
            PastLn2SpeedData = []
            PastLn3SpeedData = []
            PastLn4SpeedData = []
            PastLn5SpeedData = []
            PastLn6SpeedData = []
            PastLn1CountData = []
            PastLn2CountData = []
            PastLn3CountData = []
            PastLn4CountData = []
            PastLn5CountData = []
            PastLn6CountData = []
            for m in range (0,NumDataPoints3Min):
                PastLn1SpeedData.append(-1.)
                PastLn2SpeedData.append(-1.)
                PastLn3SpeedData.append(-1.)
                PastLn4SpeedData.append(-1.)
                PastLn5SpeedData.append(-1.)
                PastLn6SpeedData.append(-1.)
                PastLn1CountData.append(0.)
                PastLn2CountData.append(0.)
                PastLn3CountData.append(0.)
                PastLn4CountData.append(0.)
                PastLn5CountData.append(0.)
                PastLn6CountData.append(0.)

            PastMainDetLn1Speeds.append(PastLn1SpeedData)
            PastMainDetLn2Speeds.append(PastLn2SpeedData)
            PastMainDetLn3Speeds.append(PastLn3SpeedData)
            PastMainDetLn4Speeds.append(PastLn4SpeedData)
            PastMainDetLn5Speeds.append(PastLn5SpeedData)
            PastMainDetLn6Speeds.append(PastLn6SpeedData)
            PastMainDetLn1Counts.append(PastLn1CountData)
            PastMainDetLn2Counts.append(PastLn2CountData)
            PastMainDetLn3Counts.append(PastLn3CountData)
            PastMainDetLn4Counts.append(PastLn4CountData)
            PastMainDetLn5Counts.append(PastLn5CountData)
            PastMainDetLn6Counts.append(PastLn6CountData)

            Avg3MinMainDetLn1Speed.append(-1.)
            Avg3MinMainDetLn2Speed.append(-1.)
            Avg3MinMainDetLn3Speed.append(-1.)
            Avg3MinMainDetLn4Speed.append(-1.)
            Avg3MinMainDetLn5Speed.append(-1.)
            Avg3MinMainDetLn6Speed.append(-1.)
            Avg3MinMainDetSpeed.append(-1.)

            Sum3MinMainDetLn1Volume.append(0.)
            Sum3MinMainDetLn2Volume.append(0.)
            Sum3MinMainDetLn3Volume.append(0.)
            Sum3MinMainDetLn4Volume.append(0.)
            Sum3MinMainDetLn5Volume.append(0.)
            Sum3MinMainDetLn6Volume.append(0.)
            Avg3MinMainDetLaneVolume.append(0.)

            Avg1MinMainDetLn1Occup.append(0.)
            Avg1MinMainDetLn2Occup.append(0.)
            Avg1MinMainDetLn3Occup.append(0.)
            Avg1MinMainDetLn4Occup.append(0.)
            Avg1MinMainDetLn5Occup.append(0.)
            Avg1MinMainDetLn6Occup.append(0.)
            Avg1MinMainDetOccup.append(0.)

            # Avg1MinQ1DetLn1Occup.append(0.)
            # Avg1MinQ1DetLn2Occup.append(0.)
            # Avg1MinQ1DetOccup.append(0.)
            # Avg1MinQ2DetLn1Occup.append(0.)
            # Avg1MinQ2DetLn2Occup.append(0.)
            # Avg1MinQ2DetOccup.append(0.)

            Avg5sQ1DetLn1Occup.append(0.)
            Avg5sQ1DetLn2Occup.append(0.)
            Avg5sQ1DetOccup.append(0.)
            Avg5sQ2DetLn1Occup.append(0.)
            Avg5sQ2DetLn2Occup.append(0.)
            Avg5sQ2DetOccup.append(0.)

            DecisionPoint.append(False)
            ControlOption.append(0)
            CriticalOccupA.append(0)
            CriticalOccupB.append(0)
            CriticalVolumeA.append(0)
            CriticalVolumeB.append(0)
            NumMeteringLanes.append(0)
            QueueControlTimer.append(0)
            Q1OccupThreshold.append(-1.)
            Q2OccupThreshold.append(-1.)
            RateMin.append(-1.)
            RateMax.append(-1.)
            RateStep.append(-1.)
            CriticalSpeeds.append(-1)
            Q1FullOccupancyTimer.append(0.)
            Q2FullOccupancyTimer.append(0.)
            ActiveQ1Control.append(False)
            ActiveQ2Control.append(False)
            EndQ1Control.append(False)
            EndQ2Control.append(False)
            CongestionOverride.append(False)

        #Open and read input data file
        InputFile = open(FilePath + '\\' + DataFileName,'r')
        CSV_InputFile = csv.reader(InputFile)
        NumRows = 0
        for Row in CSV_InputFile:
            if (NumRows > 0):
                InputMeterID = int(Row[0])
                for i in range (0,NumMeters):
                    ModelMeterID = ECIGetMeteringIdByPosition(i)
                    if(ModelMeterID == InputMeterID):
                        NumQ1Dets[i]         = int(Row[1])
                        Q1DetLn1[i]          = int(Row[2])
                        Q1DetLn2[i]          = int(Row[3])
                        NumQ2Dets[i]         = int(Row[4])
                        Q2DetLn1[i]          = int(Row[5])
                        Q2DetLn2[i]          = int(Row[6])
                        NumMainDets[i]       = int(Row[7])
                        MainDetLn1[i]        = int(Row[8])
                        MainDetLn2[i]        = int(Row[9])
                        MainDetLn3[i]        = int(Row[10])
                        MainDetLn4[i]        = int(Row[11])
                        MainDetLn5[i]        = int(Row[12])
                        MainDetLn6[i]        = int(Row[13])
                        ControlOption[i]     = int(Row[14])
                        CriticalOccupA[i]    = float(Row[15])
                        CriticalOccupB[i]    = float(Row[16])
                        CriticalVolumeA[i]   = float(Row[17])
                        CriticalVolumeB[i]   = float(Row[18])
                        NumMeteringLanes[i]  = int(Row[19])
                        CriticalSpeeds[i]    = float(Row[20])
                        Q1OccupThreshold[i]  = float(Row[21])
                        Q2OccupThreshold[i]  = float(Row[22])
                        RateMin[i]           = float(Row[23]) * 60.0    #converts veh/min to veh/hr
                        RateMax[i]           = float(Row[24]) * 60.0    #converts veh/min to veh/hr
                        RateStep[i]          = float(Row[25]) * 60.0    #converts veh/min to veh/hr
                        break
            NumRows = NumRows + 1

        #map mainline detectors
        for n in range (0,NumMeters):
            if(MainDetLn6[n] > 0):
                hasMainLaneDet[n][6] = 1
            if(MainDetLn5[n] > 0):
                hasMainLaneDet[n][5] = 1
            if(MainDetLn4[n] > 0):
                hasMainLaneDet[n][4] = 1
            if(MainDetLn3[n] > 0):
                hasMainLaneDet[n][3] = 1
            if(MainDetLn2[n] > 0):
                hasMainLaneDet[n][2] = 1
            if(MainDetLn1[n] > 0):
                hasMainLaneDet[n][1] = 1
                hasMainLaneDet[n][0] = 1

            if(Q1DetLn2[n] > 0):
                hasQ1LaneDet[n][2] = 1
            if(Q1DetLn1[n] > 0):
                hasQ1LaneDet[n][1] = 1
                hasQ1LaneDet[n][0] = 1

            if (Q2DetLn2[n] > 0):
                hasQ2LaneDet[n][2] = 1
            if (Q2DetLn1[n] > 0):
                hasQ2LaneDet[n][1] = 1
                hasQ2LaneDet[n][0] = 1

        for n in range (0,NumMeters):
            #set up intial values for mainline detectors
            MainDetData = AKIDetGetPropertiesDetectorById(MainDetLn1[n])
            Q1DetData = AKIDetGetPropertiesDetectorById(Q1DetLn1[n])
            Q2DetData = AKIDetGetPropertiesDetectorById(Q2DetLn1[n])
            LinkData = AKIInfNetGetSectionANGInf(MainDetData.IdSection)

            if(MainDetData.report < 0):
                MainDetsInSim[n] = False
                for m in range(0, NumDataPoints3Min):
                    PastMainDetLn1Speeds[n][m] = 99.
                    PastMainDetLn2Speeds[n][m] = 99.
                    PastMainDetLn3Speeds[n][m] = 99.
                    PastMainDetLn4Speeds[n][m] = 99.
                    PastMainDetLn5Speeds[n][m] = 99.
                    PastMainDetLn6Speeds[n][m] = 99.
            else:
                MainDetsInSim[n] = True
                for m in range(0, NumDataPoints3Min):
                    PastMainDetLn1Speeds[n][m] = -1.
                    PastMainDetLn2Speeds[n][m] = -1.
                    PastMainDetLn3Speeds[n][m] = -1.
                    PastMainDetLn4Speeds[n][m] = -1.
                    PastMainDetLn5Speeds[n][m] = -1.
                    PastMainDetLn6Speeds[n][m] = -1.

            #set up intial values for Q1 and Q2 detectors
            if (Q1DetData.report >= 0): Q1DetsInSim[n] = True
            if (Q2DetData.report >= 0): Q2DetsInSim[n] = True

            Avg3MinMainDetLn1Speed[i] = LinkData.speedLimit
            Avg3MinMainDetLn2Speed[i] = LinkData.speedLimit
            Avg3MinMainDetLn3Speed[i] = LinkData.speedLimit
            Avg3MinMainDetLn4Speed[i] = LinkData.speedLimit
            Avg3MinMainDetLn5Speed[i] = LinkData.speedLimit
            Avg3MinMainDetLn6Speed[i] = LinkData.speedLimit
            Avg3MinMainDetSpeed[i] = LinkData.speedLimit

        #Close input file
        InputFile.close()
    else:
        Results.write('No ramp meter\n')

    #Write result to debug file
    Results.write("\n")
    Results.write("Ramp metering queue detector association table\n\n")
    Results.write("Num     Meter    Q1DetLn1  Q1DetLn2  Q2Detln1  Q2Detln2  MainDetLn1  MainDetLn2  MainDetLn3  MainDetLn4  MainDetLn5  MainDetLn6  Control   CritOccA   CritOccB   CritVolA   CritVolB  CritSpeed   Q1Thresh   Q2Thresh   RateStep    RateMin    RateMax\n")
    for i in range(0,NumMeters):
        Results.write("%3i   %7i     %7i   %7i   %7i   %7i     %7i     %7i     %7i     %7i     %7i     %7i  %7i   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f   %8.2f\n" % (i,ECIGetMeteringIdByPosition(i),
                             Q1DetLn1[i],Q1DetLn2[i],Q2DetLn1[i],Q2DetLn2[i],MainDetLn1[i],MainDetLn2[i],MainDetLn3[i],MainDetLn4[i],MainDetLn5[i],MainDetLn6[i],ControlOption[i],CriticalOccupA[i],
                             CriticalOccupB[i],CriticalVolumeA[i],CriticalVolumeB[i],CriticalSpeeds[i],
                             Q1OccupThreshold[i],Q2OccupThreshold[i],RateStep[i],RateMin[i],RateMax[i]))

    #Close opened files
    Results.close()
    return 0

def AAPIManage(time, timeSta, timeTrans, acycle):
    #AKIPrintString( "AAPIManage")

    NumDataPoints3Min = int((3 * 60) / AKIDetGetCycleInstantDetection())
    NumDataPoints1Min = int(60. / AKIDetGetCycleInstantDetection())
    NumDataPoints5s   = int(5. / AKIDetGetCycleInstantDetection())

    NumMeters = ECIGetNumberMeterings()
    for i in range(0, NumMeters):
        MeterID = ECIGetMeteringIdByPosition(i)

        if(ECIGetControlType(MeterID) == 2):
            #only execute if ramp meter is set to Type 2: External Control

            #variables needed to execute some Aimsun commands
            CurrentRate = doublep()
            MinRate = doublep()
            MaxRate = doublep()

            # -----------------------------------------------------------------------------------------------------------
            # update mainline detection data
            # -----------------------------------------------------------------------------------------------------------
            if(MainDetsInSim[i]):
                #update mainline data arrays
                for m in range(NumDataPoints1Min-1, 0, -1):
                    PastMainDetLn1Occups[i][m] = PastMainDetLn1Occups[i][m - 1]
                    PastMainDetLn2Occups[i][m] = PastMainDetLn2Occups[i][m - 1]
                    PastMainDetLn3Occups[i][m] = PastMainDetLn3Occups[i][m - 1]
                    PastMainDetLn4Occups[i][m] = PastMainDetLn4Occups[i][m - 1]
                    PastMainDetLn5Occups[i][m] = PastMainDetLn5Occups[i][m - 1]
                    PastMainDetLn6Occups[i][m] = PastMainDetLn6Occups[i][m - 1]

                for m in range(NumDataPoints3Min-1, 0, -1):
                    PastMainDetLn1Counts[i][m] = PastMainDetLn1Counts[i][m - 1]
                    PastMainDetLn2Counts[i][m] = PastMainDetLn2Counts[i][m - 1]
                    PastMainDetLn3Counts[i][m] = PastMainDetLn3Counts[i][m - 1]
                    PastMainDetLn4Counts[i][m] = PastMainDetLn4Counts[i][m - 1]
                    PastMainDetLn5Counts[i][m] = PastMainDetLn5Counts[i][m - 1]
                    PastMainDetLn6Counts[i][m] = PastMainDetLn6Counts[i][m - 1]

                    PastMainDetLn1Speeds[i][m] = PastMainDetLn1Speeds[i][m - 1]
                    PastMainDetLn2Speeds[i][m] = PastMainDetLn2Speeds[i][m - 1]
                    PastMainDetLn3Speeds[i][m] = PastMainDetLn3Speeds[i][m - 1]
                    PastMainDetLn4Speeds[i][m] = PastMainDetLn4Speeds[i][m - 1]
                    PastMainDetLn5Speeds[i][m] = PastMainDetLn5Speeds[i][m - 1]
                    PastMainDetLn6Speeds[i][m] = PastMainDetLn6Speeds[i][m - 1]

                if(AKIDetGetCounterCyclebyId(MainDetLn1[i],0) > 0):
                    PastMainDetLn1Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn1[i], 0)
                else:
                    PastMainDetLn1Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn2[i],0) > 0):
                    PastMainDetLn2Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn2[i], 0)
                else:
                    PastMainDetLn2Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn3[i],0) > 0):
                    PastMainDetLn3Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn3[i], 0)
                else:
                    PastMainDetLn3Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn4[i],0) > 0):
                    PastMainDetLn4Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn4[i], 0)
                else:
                    PastMainDetLn4Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn5[i],0) > 0):
                    PastMainDetLn5Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn5[i], 0)
                else:
                    PastMainDetLn5Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn6[i],0) > 0):
                    PastMainDetLn6Speeds[i][0] = AKIDetGetSpeedCyclebyId(MainDetLn6[i], 0)
                else:
                    PastMainDetLn6Speeds[i][0] = -1.

                if(AKIDetGetCounterCyclebyId(MainDetLn1[i],0) >= 0):
                    PastMainDetLn1Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn1[i], 0)
                    PastMainDetLn2Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn2[i], 0)
                    PastMainDetLn3Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn3[i], 0)
                    PastMainDetLn4Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn4[i], 0)
                    PastMainDetLn5Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn5[i], 0)
                    PastMainDetLn6Counts[i][0] = AKIDetGetCounterCyclebyId(MainDetLn6[i], 0)
                    
                    PastMainDetLn1Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn1[i], 0)
                    PastMainDetLn2Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn2[i], 0)
                    PastMainDetLn3Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn3[i], 0)
                    PastMainDetLn4Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn4[i], 0)
                    PastMainDetLn5Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn5[i], 0)
                    PastMainDetLn6Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(MainDetLn6[i], 0)
                else:
                    PastMainDetLn1Counts[i][0] = 0
                    PastMainDetLn2Counts[i][0] = 0
                    PastMainDetLn3Counts[i][0] = 0
                    PastMainDetLn4Counts[i][0] = 0
                    PastMainDetLn5Counts[i][0] = 0
                    PastMainDetLn6Counts[i][0] = 0
                    
                    PastMainDetLn1Occups[i][0] = 0.
                    PastMainDetLn2Occups[i][0] = 0.
                    PastMainDetLn3Occups[i][0] = 0.
                    PastMainDetLn4Occups[i][0] = 0.
                    PastMainDetLn5Occups[i][0] = 0.
                    PastMainDetLn6Occups[i][0] = 0.

                #calculate average statistics
                Sum3MinMainDetLn1Volume[i] = 0.
                Sum3MinMainDetLn2Volume[i] = 0.
                Sum3MinMainDetLn3Volume[i] = 0.
                Sum3MinMainDetLn4Volume[i] = 0.
                Sum3MinMainDetLn5Volume[i] = 0.
                Sum3MinMainDetLn6Volume[i] = 0.
                Avg3MinMainDetLaneVolume[i] = 0.

                Avg1MinMainDetLn1Occup[i] = 0.
                Avg1MinMainDetLn2Occup[i] = 0.
                Avg1MinMainDetLn3Occup[i] = 0.
                Avg1MinMainDetLn4Occup[i] = 0.
                Avg1MinMainDetLn5Occup[i] = 0.
                Avg1MinMainDetLn6Occup[i] = 0.
                Avg1MinMainDetOccup[i] = 0.

                Avg3MinMainDetLn1Speed[i] = 0.
                Avg3MinMainDetLn2Speed[i] = 0.
                Avg3MinMainDetLn3Speed[i] = 0.
                Avg3MinMainDetLn4Speed[i] = 0.
                Avg3MinMainDetLn5Speed[i] = 0.
                Avg3MinMainDetLn6Speed[i] = 0.
                Avg3MinMainDetSpeed[i] = 0.

                NumSpeedsLn1 = 0
                NumSpeedsLn2 = 0
                NumSpeedsLn3 = 0
                NumSpeedsLn4 = 0
                NumSpeedsLn5 = 0
                NumSpeedsLn6 = 0

                for m in range(0, NumDataPoints1Min):
                    Avg1MinMainDetLn1Occup[i] = Avg1MinMainDetLn1Occup[i] + PastMainDetLn1Occups[i][m]
                    Avg1MinMainDetLn2Occup[i] = Avg1MinMainDetLn2Occup[i] + PastMainDetLn2Occups[i][m]
                    Avg1MinMainDetLn3Occup[i] = Avg1MinMainDetLn3Occup[i] + PastMainDetLn3Occups[i][m]
                    Avg1MinMainDetLn4Occup[i] = Avg1MinMainDetLn4Occup[i] + PastMainDetLn4Occups[i][m]
                    Avg1MinMainDetLn5Occup[i] = Avg1MinMainDetLn5Occup[i] + PastMainDetLn5Occups[i][m]
                    Avg1MinMainDetLn6Occup[i] = Avg1MinMainDetLn6Occup[i] + PastMainDetLn6Occups[i][m]

                Avg1MinMainDetLn1Occup[i] = Avg1MinMainDetLn1Occup[i] / NumDataPoints1Min
                Avg1MinMainDetLn2Occup[i] = Avg1MinMainDetLn2Occup[i] / NumDataPoints1Min
                Avg1MinMainDetLn3Occup[i] = Avg1MinMainDetLn3Occup[i] / NumDataPoints1Min
                Avg1MinMainDetLn4Occup[i] = Avg1MinMainDetLn4Occup[i] / NumDataPoints1Min
                Avg1MinMainDetLn5Occup[i] = Avg1MinMainDetLn5Occup[i] / NumDataPoints1Min
                Avg1MinMainDetLn6Occup[i] = Avg1MinMainDetLn6Occup[i] / NumDataPoints1Min

                Avg1MinMainDetOccup[i] = (Avg1MinMainDetLn1Occup[i] * hasMainLaneDet[i][1] +
                                          Avg1MinMainDetLn2Occup[i] * hasMainLaneDet[i][2] +
                                          Avg1MinMainDetLn3Occup[i] * hasMainLaneDet[i][3] +
                                          Avg1MinMainDetLn4Occup[i] * hasMainLaneDet[i][4] +
                                          Avg1MinMainDetLn5Occup[i] * hasMainLaneDet[i][5] +
                                          Avg1MinMainDetLn6Occup[i] * hasMainLaneDet[i][6]) / NumMainDets[i]

                for m in range(0, NumDataPoints3Min):
                    Sum3MinMainDetLn1Volume[i] = Sum3MinMainDetLn1Volume[i] + PastMainDetLn1Counts[i][m]
                    Sum3MinMainDetLn2Volume[i] = Sum3MinMainDetLn2Volume[i] + PastMainDetLn2Counts[i][m]
                    Sum3MinMainDetLn3Volume[i] = Sum3MinMainDetLn3Volume[i] + PastMainDetLn3Counts[i][m]
                    Sum3MinMainDetLn4Volume[i] = Sum3MinMainDetLn4Volume[i] + PastMainDetLn4Counts[i][m]
                    Sum3MinMainDetLn5Volume[i] = Sum3MinMainDetLn5Volume[i] + PastMainDetLn5Counts[i][m]
                    Sum3MinMainDetLn6Volume[i] = Sum3MinMainDetLn6Volume[i] + PastMainDetLn6Counts[i][m]

                    if(PastMainDetLn1Counts[i][m] > 0):
                        NumSpeedsLn1 = NumSpeedsLn1 + 1
                        Avg3MinMainDetLn1Speed[i] = Avg3MinMainDetLn1Speed[i] + PastMainDetLn1Speeds[i][m]
                    if(PastMainDetLn2Counts[i][m] > 0):
                        NumSpeedsLn2 = NumSpeedsLn2 + 1
                        Avg3MinMainDetLn2Speed[i] = Avg3MinMainDetLn2Speed[i] + PastMainDetLn2Speeds[i][m]
                    if(PastMainDetLn3Counts[i][m] > 0):
                        NumSpeedsLn3 = NumSpeedsLn3 + 1
                        Avg3MinMainDetLn3Speed[i] = Avg3MinMainDetLn3Speed[i] + PastMainDetLn3Speeds[i][m]
                    if(PastMainDetLn4Counts[i][m] > 0):
                        NumSpeedsLn4 = NumSpeedsLn4 + 1
                        Avg3MinMainDetLn4Speed[i] = Avg3MinMainDetLn4Speed[i] + PastMainDetLn4Speeds[i][m]
                    if(PastMainDetLn5Counts[i][m] > 0):
                        NumSpeedsLn5 = NumSpeedsLn5 + 1
                        Avg3MinMainDetLn5Speed[i] = Avg3MinMainDetLn5Speed[i] + PastMainDetLn5Speeds[i][m]
                    if(PastMainDetLn6Counts[i][m] > 0):
                        NumSpeedsLn6 = NumSpeedsLn6 + 1
                        Avg3MinMainDetLn6Speed[i] = Avg3MinMainDetLn6Speed[i] + PastMainDetLn6Speeds[i][m]

                NumSpeeds = NumSpeedsLn1 + NumSpeedsLn2 + NumSpeedsLn3 + NumSpeedsLn4 + NumSpeedsLn5 + NumSpeedsLn6

                Avg3MinMainDetLaneVolume[i] = (Sum3MinMainDetLn1Volume[i] * hasMainLaneDet[i][1] +
                                               Sum3MinMainDetLn2Volume[i] * hasMainLaneDet[i][2] +
                                               Sum3MinMainDetLn3Volume[i] * hasMainLaneDet[i][3] +
                                               Sum3MinMainDetLn4Volume[i] * hasMainLaneDet[i][4] +
                                               Sum3MinMainDetLn5Volume[i] * hasMainLaneDet[i][5] +
                                               Sum3MinMainDetLn6Volume[i] * hasMainLaneDet[i][6]) / NumMainDets[i]

                DetectorData = AKIDetGetPropertiesDetectorById(MainDetLn1[i])
                LinkData = AKIInfNetGetSectionANGInf(DetectorData.IdSection)
                if(NumMainDets > 5):
                    if(NumSpeedsLn6 > 0): Avg3MinMainDetLn6Speed[i] = Avg3MinMainDetLn6Speed[i] / NumSpeedsLn6
                    else:                 Avg3MinMainDetLn6Speed[i] = LinkData.speedLimit

                if(NumMainDets > 4):
                    if(NumSpeedsLn5 > 0): Avg3MinMainDetLn5Speed[i] = Avg3MinMainDetLn5Speed[i] / NumSpeedsLn5
                    else:                 Avg3MinMainDetLn5Speed[i] = LinkData.speedLimit

                if(NumMainDets > 3):
                    if(NumSpeedsLn4 > 0): Avg3MinMainDetLn4Speed[i] = Avg3MinMainDetLn4Speed[i] / NumSpeedsLn4
                    else:                 Avg3MinMainDetLn4Speed[i] = LinkData.speedLimit

                if(NumMainDets > 2):
                    if(NumSpeedsLn3 > 0): Avg3MinMainDetLn3Speed[i] = Avg3MinMainDetLn3Speed[i] / NumSpeedsLn3
                    else:                 Avg3MinMainDetLn3Speed[i] = LinkData.speedLimit

                if(NumMainDets > 1):
                    if(NumSpeedsLn2 > 0): Avg3MinMainDetLn2Speed[i] = Avg3MinMainDetLn2Speed[i] / NumSpeedsLn2
                    else:                 Avg3MinMainDetLn2Speed[i] = LinkData.speedLimit

                if(NumSpeedsLn1 > 0): Avg3MinMainDetLn1Speed[i] = Avg3MinMainDetLn1Speed[i] / NumSpeedsLn1
                else:                 Avg3MinMainDetLn1Speed[i] = LinkData.speedLimit

                if(NumSpeeds > 0):
                    Avg3MinMainDetSpeed[i] = (Avg3MinMainDetLn1Speed[i] * hasMainLaneDet[i][1] +
                                              Avg3MinMainDetLn2Speed[i] * hasMainLaneDet[i][2] +
                                              Avg3MinMainDetLn3Speed[i] * hasMainLaneDet[i][3] +
                                              Avg3MinMainDetLn4Speed[i] * hasMainLaneDet[i][4] +
                                              Avg3MinMainDetLn5Speed[i] * hasMainLaneDet[i][5] +
                                              Avg3MinMainDetLn6Speed[i] * hasMainLaneDet[i][6]) / NumMainDets[i]
                else:
                    DetectorData = AKIDetGetPropertiesDetectorById(MainDetLn1[i])
                    LinkData = AKIInfNetGetSectionANGInf(DetectorData.IdSection)
                    Avg3MinMainDetSpeed[i] = LinkData.speedLimit

                # # for debugging purposes
                # if (MeterID == 25301):
                #     print "------- AVG SPEED: %.2f - %i - %.2f - (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #     Avg3MinMainDetSpeed[i], NumSpeeds, Avg3MinMainDetLn1Speed[i], PastMainDetLn1Speeds[i][0],
                #     PastMainDetLn1Speeds[i][1], PastMainDetLn1Speeds[i][2], PastMainDetLn1Speeds[i][3],
                #     PastMainDetLn1Speeds[i][4], PastMainDetLn1Speeds[i][5], PastMainDetLn1Speeds[i][6])
                #
                #     print "------- AVG OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #     Avg1MinMainDetOccup[i],PastMainDetLn1Occups[i][0], PastMainDetLn1Occups[i][1],
                #     PastMainDetLn1Occups[i][2], PastMainDetLn1Occups[i][3], PastMainDetLn1Occups[i][4],
                #     PastMainDetLn1Occups[i][5], PastMainDetLn1Occups[i][6])
                #
                #     print "------- AVG COUNT: %i (%.2f) - (%i)(%i)(%i)(%i)(%i)(%i)(%i)" % (Avg3MinMainDetLaneVolume[i],
                #     Avg3MinMainDetCount[i]*20., PastMainDetLn1Counts[i][0], PastMainDetLn1Counts[i][1],
                #     PastMainDetLn1Counts[i][2],PastMainDetLn1Counts[i][3], PastMainDetLn1Counts[i][4],
                #     PastMainDetLn1Counts[i][5], PastMainDetLn1Counts[i][6])

            # ---------------------------------------------------------------------------------------------------------
            # update Q1 ramp detection data
            # ---------------------------------------------------------------------------------------------------------
            if (Q1DetsInSim[i]):
                #update past Q1 data arrays
                for m in range(NumDataPoints5s - 1, 0, -1):
                    PastQ1DetLn1Occups[i][m] = PastQ1DetLn1Occups[i][m - 1]
                    PastQ1DetLn2Occups[i][m] = PastQ1DetLn2Occups[i][m - 1]

                if (AKIDetGetCounterCyclebyId(Q1DetLn1[i], 0) >= 0):
                    PastQ1DetLn1Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(Q1DetLn1[i], 0)
                    PastQ1DetLn2Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(Q1DetLn2[i], 0)
                else:
                    PastQ1DetLn1Occups[i][0] = 0.
                    PastQ1DetLn2Occups[i][0] = 0.

                #calculate current 1-minute Q1 average occupancy
                # Avg1MinQ1DetLn1Occup[i] = 0.
                # Avg1MinQ1DetLn2Occup[i] = 0.
                # for m in range(0, NumDataPoints1Min):
                #     Avg1MinQ1DetLn1Occup[i] = Avg1MinQ1DetLn1Occup[i] + PastQ1DetLn1Occups[i][m]
                #     Avg1MinQ1DetLn2Occup[i] = Avg1MinQ1DetLn2Occup[i] + PastQ1DetLn2Occups[i][m]
                # Avg1MinQ1DetLn1Occup[i] = Avg1MinQ1DetLn1Occup[i] / NumDataPoints1Min
                # Avg1MinQ1DetLn2Occup[i] = Avg1MinQ1DetLn2Occup[i] / NumDataPoints1Min
                #
                # Avg1MinQ1DetOccup[i] = (Avg1MinQ1DetLn1Occup[i] * hasQ1LaneDet[i][1] +
                #                         Avg1MinQ1DetLn2Occup[i] * hasQ1LaneDet[i][2])/ NumQ1Dets[i]

                # calculate current 5-second Q1 average occupancy
                Avg5sQ1DetLn1Occup[i] = 0.
                Avg5sQ1DetLn2Occup[i] = 0.
                for m in range (0,NumDataPoints5s):
                    Avg5sQ1DetLn1Occup[i] = Avg5sQ1DetLn1Occup[i] + PastQ1DetLn1Occups[i][m]
                    Avg5sQ1DetLn2Occup[i] = Avg5sQ1DetLn2Occup[i] + PastQ1DetLn2Occups[i][m]
                Avg5sQ1DetLn1Occup[i] = Avg5sQ1DetLn1Occup[i] / NumDataPoints5s
                Avg5sQ1DetLn2Occup[i] = Avg5sQ1DetLn2Occup[i] / NumDataPoints5s

                Avg5sQ1DetOccup[i] = (Avg5sQ1DetLn1Occup[i] * hasQ1LaneDet[i][1] +
                                      Avg5sQ1DetLn2Occup[i] * hasQ1LaneDet[i][2]) / NumQ1Dets[i]

                #update Q1 detector occupancy tracker
                if(Avg5sQ1DetOccup[i] > OccupancyThreshold):
                    Q1FullOccupancyTimer[i] = Q1FullOccupancyTimer[i] + acycle
                else:
                    Q1FullOccupancyTimer[i] = 0.

                # for debugging purposes
                # if (MeterID == 25301 and DecisionPoint[i]):
                #     print "------- AVG Q1 Ln1 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ1DetLn1Occup[i], PastQ1DetLn1Occups[i][0], PastQ1DetLn1Occups[i][1],
                #         PastQ1DetLn1Occups[i][2], PastQ1DetLn1Occups[i][3], PastQ1DetLn1Occups[i][4],
                #         PastQ1DetLn1Occups[i][5], PastQ1DetLn1Occups[i][6])
                #
                #     print "------- AVG Q1 Ln2 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ1DetLn2Occup[i], PastQ1DetLn2Occups[i][0], PastQ1DetLn2Occups[i][1],
                #         PastQ1DetLn2Occups[i][2], PastQ1DetLn2Occups[i][3], PastQ1DetLn2Occups[i][4],
                #         PastQ1DetLn2Occups[i][5], PastQ1DetLn2Occups[i][6])
                #
                #     print "------- AVG Q1 Ln1 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ1DetLn1Occup[i], PastQ1DetLn1Occups[i][0], PastQ1DetLn1Occups[i][1],
                #         PastQ1DetLn1Occups[i][2], PastQ1DetLn1Occups[i][3], PastQ1DetLn1Occups[i][4],
                #         PastQ1DetLn1Occups[i][5], PastQ1DetLn1Occups[i][6])
                #
                #     print "------- AVG Q1 Ln2 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ1DetLn2Occup[i], PastQ1DetLn2Occups[i][0], PastQ1DetLn2Occups[i][1],
                #         PastQ1DetLn2Occups[i][2], PastQ1DetLn2Occups[i][3], PastQ1DetLn2Occups[i][4],
                #         PastQ1DetLn2Occups[i][5], PastQ1DetLn2Occups[i][6])
                #
                #     print "------- Q1 OCCUP (%i %i %i): %.2f (%.2f - %.2f) - Q2 OCCUP (%i %i %i): %.2f (%.2f - %.2f)" % (
                #         hasQ1LaneDet[i][0],hasQ1LaneDet[i][1],hasQ1LaneDet[i][2],
                #         Avg5sQ1DetOccup[i], Avg5sQ1DetLn1Occup[i], Avg5sQ1DetLn2Occup[i],
                #         hasQ2LaneDet[i][0], hasQ2LaneDet[i][1], hasQ2LaneDet[i][2],
                #         Avg5sQ2DetOccup[i], Avg5sQ2DetLn1Occup[i], Avg5sQ2DetLn2Occup[i])

            # ---------------------------------------------------------------------------------------------------------
            # update Q2 ramp detection data
            # ---------------------------------------------------------------------------------------------------------
            if (Q2DetsInSim[i]):
                #update past Q2 data arrays
                for m in range(NumDataPoints5s - 1, 0, -1):
                    PastQ2DetLn1Occups[i][m] = PastQ2DetLn1Occups[i][m - 1]
                    PastQ2DetLn2Occups[i][m] = PastQ2DetLn2Occups[i][m - 1]

                if (AKIDetGetCounterCyclebyId(Q2DetLn1[i], 0) >= 0):
                    PastQ2DetLn1Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(Q2DetLn1[i], 0)
                else:
                    PastQ2DetLn1Occups[i][0] = 0.

                if (AKIDetGetCounterCyclebyId(Q2DetLn2[i], 0) >= 0):
                    PastQ2DetLn2Occups[i][0] = AKIDetGetTimeOccupedCyclebyId(Q2DetLn2[i], 0)
                else:
                    PastQ2DetLn2Occups[i][0] = 0.

                #calculate current 1-minute Q2 average occupancy
                # Avg1MinQ2DetLn1Occup[i] = 0.
                # Avg1MinQ2DetLn2Occup[i] = 0.
                # for m in range(0, NumDataPoints1Min):
                #     Avg1MinQ2DetLn1Occup[i] = Avg1MinQ2DetLn1Occup[i] + PastQ2DetLn1Occups[i][m]
                #     Avg1MinQ2DetLn2Occup[i] = Avg1MinQ2DetLn2Occup[i] + PastQ2DetLn2Occups[i][m]
                # Avg1MinQ2DetLn1Occup[i] = Avg1MinQ2DetLn1Occup[i] / NumDataPoints1Min
                # Avg1MinQ2DetLn2Occup[i] = Avg1MinQ2DetLn2Occup[i] / NumDataPoints1Min
                #
                # Avg1MinQ2DetOccup[i] = (Avg1MinQ2DetLn1Occup[i] * hasQ2LaneDet[i][1] +
                #                         Avg1MinQ2DetLn2Occup[i] * hasQ2LaneDet[i][2]) / NumQ2Dets[i]

                #calculate current 5-second Q2 average occupancy
                Avg5sQ2DetLn1Occup[i] = 0.
                Avg5sQ2DetLn2Occup[i] = 0.
                for m in range (0,NumDataPoints5s):
                    Avg5sQ2DetLn1Occup[i] = Avg5sQ2DetLn1Occup[i] + PastQ2DetLn1Occups[i][m]
                    Avg5sQ2DetLn2Occup[i] = Avg5sQ2DetLn2Occup[i] + PastQ2DetLn2Occups[i][m]
                Avg5sQ2DetLn1Occup[i] = Avg5sQ2DetLn1Occup[i] / NumDataPoints5s
                Avg5sQ2DetLn2Occup[i] = Avg5sQ2DetLn2Occup[i] / NumDataPoints5s

                Avg5sQ2DetOccup[i] = (Avg5sQ2DetLn1Occup[i] * hasQ2LaneDet[i][1] +
                                      Avg5sQ2DetLn2Occup[i] * hasQ2LaneDet[i][2]) / NumQ2Dets[i]

                #update Q2 detector occupancy tracker
                if(Avg5sQ2DetOccup[i] > OccupancyThreshold):
                    Q2FullOccupancyTimer[i] = Q2FullOccupancyTimer[i] + acycle
                else:
                    Q2FullOccupancyTimer[i] = 0.

                # for debugging purposes
                # if (MeterID == 25301):
                #     print "------- AVG Q2 Ln1 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ2DetLn1Occup[i], PastQ2DetLn1Occups[i][0], PastQ2DetLn1Occups[i][1],
                #         PastQ2DetLn1Occups[i][2], PastQ2DetLn1Occups[i][3], PastQ2DetLn1Occups[i][4],
                #         PastQ2DetLn1Occups[i][5], PastQ2DetLn1Occups[i][6])
                #
                #     print "------- AVG Q2 Ln2 OCCUP: %.2f (%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)(%.2f)" % (
                #         Avg5sQ2DetLn2Occup[i], PastQ2DetLn2Occups[i][0], PastQ2DetLn2Occups[i][1],
                #         PastQ2DetLn2Occups[i][2], PastQ2DetLn2Occups[i][3], PastQ2DetLn2Occups[i][4],
                #         PastQ2DetLn2Occups[i][5], PastQ2DetLn2Occups[i][6])
                #
                #     print "-------- Q1 OCCUP (%i %i %i): %.2f (%.2f - %.2f) - Q2 OCCUP (%i %i %i): %.2f (%.2f - %.2f)" % (
                #         hasQ1LaneDet[i][0],hasQ1LaneDet[i][1],hasQ1LaneDet[i][2],
                #         Avg5sQ1DetOccup[i], Avg5sQ1DetLn1Occup[i], Avg5sQ1DetLn2Occup[i],
                #         hasQ2LaneDet[i][0], hasQ2LaneDet[i][1], hasQ2LaneDet[i][2],
                #         Avg5sQ2DetOccup[i], Avg5sQ2DetLn1Occup[i], Avg5sQ2DetLn2Occup[i])

            #-------------------------------------------------------------------------------------
            #Check whether freeway mainline speed is below congestion threshold (typically 35 mph)
            #-------------------------------------------------------------------------------------
            MainlineCongestion = False
            if(AKIInfNetGetUnits()):
                if (Avg3MinMainDetSpeed[i] < (CriticalSpeeds[i] * 1.60934)): MainlineCongestion = True    #Metric units
            else:
                if (Avg3MinMainDetSpeed[i] < CriticalSpeeds[i]): MainlineCongestion = True		        #US measurements

            if(DecisionPoint[i]):

                # if (MeterID == 25301):
                #     # print "******* Decision Point **********"
                #     # print "NumDets: %i MainDets: (%i) %i - %i - %i - %i - %i - %i" % (
                #     #     NumMainDets[i], hasMainLaneDet[i][0], hasMainLaneDet[i][1], hasMainLaneDet[i][2],
                #     #     hasMainLaneDet[i][3], hasMainLaneDet[i][4], hasMainLaneDet[i][5], hasMainLaneDet[i][6])
                #
                #     print "CountAvg: (%.2f) - %.2f - %.2f - %.2f - %.2f - %.2f - %.2f" % (
                #         Avg3MinMainDetLaneVolume[i],
                #         Sum3MinMainDetLn1Volume[i], Sum3MinMainDetLn2Volume[i], Sum3MinMainDetLn3Volume[i],
                #         Sum3MinMainDetLn4Volume[i], Sum3MinMainDetLn5Volume[i], Sum3MinMainDetLn6Volume[i])
                #
                #     print "OccupAvg: (%.2f) - %.2f - %.2f - %.2f - %.2f - %.2f - %.2f" % (Avg1MinMainDetOccup[i],
                #         Avg1MinMainDetLn1Occup[i], Avg1MinMainDetLn2Occup[i], Avg1MinMainDetLn3Occup[i],
                #         Avg1MinMainDetLn4Occup[i], Avg1MinMainDetLn5Occup[i], Avg1MinMainDetLn6Occup[i])
                #
                #     print "SpeedAvg: (%.2f) - %.2f - %.2f - %.2f - %.2f - %.2f - %.2f" % (Avg3MinMainDetSpeed[i],
                #         Avg3MinMainDetLn1Speed[i], Avg3MinMainDetLn2Speed[i], Avg3MinMainDetLn3Speed[i],
                #         Avg3MinMainDetLn4Speed[i], Avg3MinMainDetLn5Speed[i], Avg3MinMainDetLn6Speed[i])

                if(MainlineCongestion):
                    #------------------------------------------------------------------------------
                    #congestion exists on the freeway mainline --> suspend all active queue control
                    #------------------------------------------------------------------------------
                    if(ActiveQ1Control[i]):
                        if(CongestionOverride[i]):
                            #2nd congestion call ---> reset metering rate to normal operations
                            # if (MeterID == 25301): print "******* Q1 Terminated - Congestion Override Activated **********"
                            TODRate = getCurrentTODMeteringRate(timeSta, MeterID)
                            setCurrentScheduledMeterRate(i, MeterID, 1, TODRate, timeSta, acycle)
                            ActiveQ1Control[i]    = False
                            ActiveQ2Control[i]    = False
                            CongestionOverride[i] = False
                        else:
                            #1st congestion call ---> wait to next control interval to check mainline speed again
                            # if (MeterID == 25301): print "******* Q1 Active - Congestion Override Flag **********"
                            CongestionOverride[i] = True
                    else:
                        # if (MeterID == 25301): print "******* Congestion Override - Normal Metering **********"
                        TODRate = getCurrentTODMeteringRate(timeSta, MeterID)
                        setCurrentScheduledMeterRate(i, MeterID, 1, TODRate, timeSta, acycle)
                        ActiveQ1Control[i] = False
                        ActiveQ2Control[i] = False
                        CongestionOverride[i] = False
                else:
                    #--------------------------------------------------------------------------------
                    #no congestion on the freeway mainline --> check Q1 and Q2 control options
                    #--------------------------------------------------------------------------------
                    CongestionOverride[i] = False

                    if (Q2FullOccupancyTimer[i] > Q2OccupThreshold[i]):
                        #Q2 control triggered --> set meter to green ball regardless of Q1 control
                        if (ActiveQ2Control[i]):
                            #existing current Q2 control --> continue Q2 control
                            # if (MeterID == 25301): print "******* Continue Q2 Control **********"
                            EndQ1Control[i] = False
                            EndQ2Control[i] = False
                        else:
                            #no current Q2 control --> activate Q2 control
                            # if (MeterID == 25301): print "******* Q2 Control Activated **********"

                            #ECIChangeStateMeteringById(MeterID, 1, timeSta, acycle, 0)
                            GreenBallMeteringRate = NumMeteringLanes[i] * GreenBallRate
                            Error = ECIGetParametersFlowMeteringById(MeterID, timeSta, MaxRate, CurrentRate, MinRate)
                            Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, GreenBallMeteringRate,
                                                                        GreenBallMeteringRate, MinRate.value(), time, acycle)
                            ActiveQ1Control[i] = True
                            ActiveQ2Control[i] = True
                            EndQ1Control[i] = False
                            EndQ2Control[i] = False

                    elif (Q1FullOccupancyTimer[i] > Q1OccupThreshold[i]):
                        #Q2 control not triggered, but Q1 control triggered

                        if(ActiveQ2Control[i]):
                            #Q2 control currently in place --> initiate or execute Q2 control removal
                            if(EndQ2Control[i]):
                                # if (MeterID == 25301): print "******* Q1 Control Active - Q2 Control Removal **********"
                                #end of Q2 control already activated --> Set Q1 control with TOD rate
                                TODRate = getCurrentTODMeteringRate(timeSta, MeterID)
                                setCurrentScheduledMeterRate(i, MeterID, 1, TODRate, timeSta, acycle)
                                ActiveQ1Control[i] = True
                                ActiveQ2Control[i] = False
                                EndQ1Control[i] = False
                                EndQ2Control[i] = False
                            else:
                                #flag end of Q2 control for next decision point
                                # if (MeterID == 25301): print "******* Q1 Control Active - Q2 Control Removal Flag **********"
                                EndQ2Control[i] = True

                        elif(ActiveQ1Control[i]):
                            #no active Q2 control, Q1 control altready in place --> increase Q1 metering rate
                            # if (MeterID == 25301): print "******* Q1 Control Rate Increase **********"
                            Error = ECIGetParametersFlowMeteringById(MeterID, timeSta, MaxRate, CurrentRate,MinRate)
                            Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, MaxRate.value(),
                                                    CurrentRate.value()+RateStep[i], MinRate.value(),time,acycle)
                            EndQ1Control[i] = False
                            EndQ2Control[i] = False

                        else:
                            #no active Q2 control and no active Q1 control --> initiate new Q1 control
                            # if (MeterID == 25301): print "******* New Q1 Control **********"
                            Error = ECIGetParametersFlowMeteringById(MeterID, timeSta, MaxRate, CurrentRate,MinRate)
                            Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, MaxRate.value(),
                                                    CurrentRate.value()+RateStep[i], MinRate.value(),time,acycle)
                            ActiveQ1Control[i] = True
                            ActiveQ2Control[i] = False
                            EndQ1Control[i] = False
                            EndQ2Control[i] = False

                    else:
                        #-------------------------------------------------------------------
                        #no queue over both Q1 or Q2 detectors --> Normal metering operation
                        #-------------------------------------------------------------------

                        #terminate any active Q1 or Q2 control
                        if(ActiveQ1Control[i]):
                            if(EndQ1Control[i]):
                                #terminate Q1 control
                                # if (MeterID == 25301): print "******* Terminate Q1 Control **********"
                                TODRate = getCurrentTODMeteringRate(timeSta, MeterID)
                                setCurrentScheduledMeterRate(i, MeterID, 1, TODRate, timeSta, acycle)
                                ActiveQ1Control[i] = False
                                ActiveQ2Control[i] = False
                                EndQ1Control[i] = False
                                EndQ2Control[i] = False
                            else:
                                #flag Q1 or Q2 control for termination at next decision point
                                # if (MeterID == 25301): print "******* Terminate Q1 Control Flag**********"
                                EndQ1Control[i] = True
                                EndQ2Control[i] = True

                        else:
                            #calculate normal metering rate (TOD or LMR)
                            TODRate = getCurrentTODMeteringRate(timeSta, MeterID)
                            setCurrentScheduledMeterRate(i, MeterID, 0, TODRate, timeSta, acycle)

            #for debugging purpose
            # if (MeterID == 25301 and DecisionPoint[i]):
            #     Error = ECIGetParametersFlowMeteringById(MeterID, timeSta, MaxRate, CurrentRate, MinRate)
            #     print "%8.2f - Meter %7i - [Main %i] %8.2f mph (%8.2f mph) - %8.2f vphpl - %8.2f occ  [Q1 %i] %8.2f - %8.1f s (%.1f) [Q2 %i] %8.2f - %8.1f s (%.1f) " \
            #                   "- Active: %i/%i (%8.1f) - Rates: %d-%d-%d (%d)" % (
            #                  time,MeterID,MainDetLn1[i],Avg3MinMainDetSpeed[i], CriticalSpeeds[i], Avg3MinMainDetLaneVolume[i]*20.,
            #                  Avg1MinMainDetOccup[i], Q1DetLn1[i], Avg5sQ1DetOccup[i], Q1FullOccupancyTimer[i],
            #                  Q1OccupThreshold[i], Q2DetLn1[i],Avg5sQ2DetOccup[i], Q2FullOccupancyTimer[i],
            #                  Q2OccupThreshold[i], ActiveQ1Control[i],ActiveQ2Control[i],QueueControlTimer[i],
            #                  MinRate.value(),CurrentRate.value(),MaxRate.value(),RateStep[i],)

            #--------------------------------------------------------------
            #update ramp meter's queue control timer (signal cycle counter)
            #--------------------------------------------------------------
            QueueControlTimer[i] = QueueControlTimer[i] + acycle
            if(QueueControlTimer[i] > (ControlCycle-0.00001)):
                QueueControlTimer[i] = QueueControlTimer[i] - ControlCycle
                if(QueueControlTimer[i] < 0.):
                    QueueControlTimer[i] = 0.
                DecisionPoint[i] = True
            else:
                DecisionPoint[i] = False

            #--------------------------
            #delete temporary variables
            #--------------------------
            del CurrentRate
            del MinRate
            del MaxRate

    return 0


def AAPIPostManage(time, timeSta, timeTrans, acycle):
    #AKIPrintString( "AAPIPostManage" )
    return 0

def AAPIFinish():
    #AKIPrintString( "AAPIFinish" )
    return 0

def AAPIUnLoad():
    #AKIPrintString( "AAPIUnLoad" )
    return 0

def AAPIPreRouteChoiceCalculation(time, timeSta):
    #AKIPrintString( "AAPIPreRouteChoiceCalculation" )
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

#-------------------------------------------------------------------------
# Subroutines
#-------------------------------------------------------------------------

def getCurrentTODMeteringRate(timeSta, MeterID):
    # retrieve current TOD rate from external TOD table
    TODTable = open(FilePath + '\\' + TODTableFileName, 'r')
    TODTable.seek(0)
    CSV_TODTable = csv.reader(TODTable)
    NumRows = 0
    TODRate = -1.
    for Row in CSV_TODTable:
        if (NumRows > 0):
            if (int(Row[0]) == MeterID):
                Time2 = float(Row[4]) * 3600.
                Time3 = float(Row[7]) * 3600.
                Time4 = float(Row[10]) * 3600.
                Time5 = float(Row[13]) * 3600.
                Time6 = float(Row[16]) * 3600.

                if (Time2 > timeSta):   TODRate = float(Row[2])
                elif (Time3 > timeSta): TODRate = float(Row[5])
                elif (Time4 > timeSta): TODRate = float(Row[8])
                elif (Time5 > timeSta): TODRate = float(Row[11])
                elif (Time6 > timeSta): TODRate = float(Row[14])
                else:                   TODRate = float(Row[17])

                if (TODRate > 0):       TODRate = TODRate * 60.
                break
        NumRows = NumRows + 1
    TODTable.close()
    return TODRate


def getCurrentPlanType(timeSta, MeterID):
    # retrieve current TOD rate from external TOD table
    TODTable = open(FilePath + '\\' + TODTableFileName, 'r')
    TODTable.seek(0)
    CSV_TODTable = csv.reader(TODTable)
    NumRows = 0
    Plan = "X"
    for Row in CSV_TODTable:
        if (NumRows > 0):
            if (int(Row[0]) == MeterID):
                Time2 = float(Row[4]) * 3600.
                Time3 = float(Row[7]) * 3600.
                Time4 = float(Row[10]) * 3600.
                Time5 = float(Row[13]) * 3600.
                Time6 = float(Row[16]) * 3600.

                if (Time2 > timeSta):   Plan = Row[3]
                elif (Time3 > timeSta): Plan = Row[6]
                elif (Time4 > timeSta): Plan = Row[9]
                elif (Time5 > timeSta): Plan = Row[12]
                elif (Time6 > timeSta): Plan = Row[15]
                else:                   Plan = Row[18]
                break
        NumRows = NumRows + 1
    TODTable.close()
    return Plan


def setCurrentScheduledMeterRate(ArrayPos, MeterID, ChangeCode, TODRate, timeSta, acycle):
    if (TODRate > 0):
        #ramp metering rate defined for period of day

        if(ControlOption[ArrayPos] == 1):
            #--------------------------
            #control option set to LMR
            #--------------------------
            PlanType = getCurrentPlanType(timeSta, MeterID)
            CriticalOccup = CriticalOccupA[ArrayPos]
            CriticalVolume = CriticalVolumeA[ArrayPos]
            if (PlanType == "B"):
                CriticalOccup = CriticalOccupB[ArrayPos]
                CriticalVolume = CriticalVolumeB[ArrayPos]

            if(Avg1MinMainDetOccup[ArrayPos] < CriticalOccup):
                #1-min average mainline occupancy < critical occupancy
                LMRRate = (NumMainDets[ArrayPos] * (CriticalVolume - Avg3MinMainDetLaneVolume[ArrayPos])/3.) * 60.
                TempLMR = LMRRate
                if(LMRRate < TODRate):
                    LMRRate = TODRate

                if(LMRRate > RateMax[ArrayPos]):
                    #LMR rate greater than maximum metering rate permissible --> go to full green
                    GreenBallMeteringRate = NumMeteringLanes[ArrayPos] * GreenBallRate
                    Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, GreenBallMeteringRate, GreenBallMeteringRate,
                                                                RateMin[ArrayPos], timeSta, acycle)
                    # if (MeterID == 25301):
                    #     print "******* LMR Green Ball: MAX(%.0f,%.0f) - MainLanes: %i - RampLanes: %i - CRVOL: %.2f - 3minVol: %.2f" % (
                    #         TODRate, TempLMR, NumMainDets[ArrayPos], NumMeteringLanes[ArrayPos], CriticalVolume,
                    #         Avg3MinMainDetLaneVolume[ArrayPos])
                else:
                    #LMR rate is within permitted values --> implement calculated value
                    Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, RateMax[ArrayPos], LMRRate, RateMin[ArrayPos],
                                                                timeSta, acycle)
                    # if (MeterID == 25301):
                    #     print "******* LMR Regular: MAX(%.0f,%.0f) - MainLanes: %i - RampLanes: %i - CRVOL: %.2f - 3minVol: %.2f" % (
                    #             TODRate, TempLMR, NumMainDets[ArrayPos], NumMeteringLanes[ArrayPos], CriticalVolume,
                    #             Avg3MinMainDetLaneVolume[ArrayPos])
            else:
                #1-minute average mainline occupancy >= critical occupancy ---> implement TOD rate
                Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, RateMax[ArrayPos], TODRate, RateMin[ArrayPos],
                                                            timeSta, acycle)
                # if (MeterID == 25301): print "******* LMR Control - Occup (%.2f) greater CritOccupA (%.2f): - Set TOD Rate: %.2f - Min: %.2f - Max: %.2f" % (
                #     Avg1MinMainDetOccup[ArrayPos], CriticalOccup, TODRate, RateMin[ArrayPos], RateMax[ArrayPos])

        elif (ControlOption[ArrayPos] == 0):
            #---------------------------------
            #control option set to TOD control
            #---------------------------------
            if(ChangeCode):
                Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, RateMax[ArrayPos], TODRate, RateMin[ArrayPos],
                                                            timeSta, acycle)
                # if (MeterID == 25301): print "******* TOD Control: Set TOD Rate: %.2f - Min: %.2f - Max: %.2f" % (TODRate,
                #                               RateMin[ArrayPos], RateMax[ArrayPos])

        else:
            #-----------------------------------
            #default control option: TOD control
            #-----------------------------------
            if(ChangeCode):
                Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, RateMax[ArrayPos], TODRate,
                                                            RateMin[ArrayPos], timeSta, acycle)
                # if (MeterID == 25301): print "******* Default Control %i: Set TOD Rate - TOD: %.2f - Min: %.2f - Max: %.2f" % (
                #     ControlOption[ArrayPos], TODRate, RateMin[ArrayPos], RateMax[ArrayPos])
    else:
        if(ChangeCode):
            # no ramp metering rate defined for period of day --> set meter to green
            #Error = ECIChangeStateMeteringById(MeterID, 1, timeSta, acycle, 0)
            GreenBallMeteringRate = NumMeteringLanes[ArrayPos] * GreenBallRate
            Error = ECIChangeParametersFlowMeteringById(MeterID, timeSta, GreenBallMeteringRate, GreenBallMeteringRate,
                                                        RateMin[ArrayPos], timeSta, acycle)
            # if (MeterID == 25301): print "******* No ramp metering defined - Set green ball operation"