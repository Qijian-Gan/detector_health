import sys

from PyANGBasic import *
from PyANGKernel import *
from PyANGGui import *
from PyANGAimsun import *

def main(argv):
    if len(argv)<5:
        print "Usage: aimsun.exe -script %s ANG_FILE" % argv[2]
        return -1
    # Get GUI
    gui=GKGUISystem.getGUISystem().getActiveGui()
    # Load a network
    if gui.loadNetwork(argv[3]):
        model=gui.getActiveModel()

        plugin= GKSystem.getSystem().getPlugin("GGetram")
        simulator=plugin.getCreateSimulator(model)

        if simulator.isBusy()==False:
            replication=model.getCatalog().find(int(argv[4]))
            if replication !=None and replication.isA("GKReplication"):
                if replication.getExperiment().getSimulatorEngine()==GKExperiment.eMicro:
                    simulator.addSimulationTask(GKSimulationTask(replication,GKReplication.eInteractive))
                    simulator.simulate()
    else:
        gui.showMessage(GGui.eCritical,"Open error", "Cannot load the network")

main(sys.argv)
