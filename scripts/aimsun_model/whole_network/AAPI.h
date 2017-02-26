//DO NOT MODIFY THIS FILE
#ifndef _AAPI_h_
#define _AAPI_h_

#ifdef _WIN32
	#define DLLE __declspec(dllexport)
#else
	#define DLLE 
#endif

extern "C" {
	DLLE int AAPILoad();
	DLLE int AAPIInit();
	DLLE int AAPIManage(double time, double timeSta, double timTrans, double acicle);
	DLLE int AAPIPostManage(double time, double timeSta, double timTrans, double acicle);
	DLLE int AAPIFinish();
	DLLE int AAPIUnLoad();

	DLLE int AAPIEnterVehicle(int idveh, int idsection);
	DLLE int AAPIExitVehicle(int idveh, int idsection);
	DLLE int AAPIEnterPedestrian(int idPedestrian, int originCentroid);
	DLLE int AAPIExitPedestrian(int idPedestrian, int destinationCentroid);
	DLLE int AAPIEnterVehicleSection(int idveh, int idsection, double atime);
	DLLE int AAPIExitVehicleSection(int idveh, int idsection, double time);
	
	DLLE int AAPIPreRouteChoiceCalculation(double time, double timeSta);
}

#endif
