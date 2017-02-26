from PyANGBasic import *
from PyANGKernel import *
from PyANGGui import *
from PyANGAimsun import *

import datetime
import pickle
import sys
import csv
import os

model = GKSystem.getSystem().getActiveModel()
gui=GKGUISystem.getGUISystem().getActiveGui()


for types in model.getCatalog().getUsedSubTypesFromType(model.getType("GKSection")):
	for sectionObj in types.itervalues():
		sectionID=sectionObj.getId()
		points=sectionObj.getPoints()
		print ("sectionID=%d,numPoints=%d"%(sectionID,len(points)))
		print points[0].x,points[0].y,points[0].z
		layer=GKCoordinateTranslator(model)
		point=layer.toDegrees(points[0])
		print point.x, point.y,point.z



