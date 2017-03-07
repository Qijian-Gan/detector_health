/**
 * Created by Vincent Q. Lin on 07/12/2016.
 */
//This JS file contains the global variables shared by both the real-time and historical appplication
//and the functions that initialize them

var isRealtime;
var isStation;
var isTrafficMode;

var vehClassName2Id;
var vehClassId2Name;
var laneName2Id;
var laneId2Name;
var pollutantName2Id;
var pollutantId2Name;

var curVehClassScheme;
var curLane;
var curStn;
var curMeasure;
var curInterval;
var curPollutant;

//instance to store the data pulled from DB
var savedData = {};

//1. Initialize realtime flag and station flag
//Initially: staton,real-time,traffic mode
isRealtime = true;
isStation = true;
isTrafficMode = true;
//Update isRealtime whenever realtime-historical tab is clicked
$("#station-tabs").click(function (e) {
  var target = getEventTarget(e);
  var mode = target.text.trim();
  if (mode = "Real-Time") isRealtime = true;
  else isRealtime = false;
});
//Update isTrafficMode whenever the Application dropdown is selected
$("#application-list").click(function (e) {
  var target = getEventTarget(e);
  var mode = target.text.trim();
  if (mode = "Traffic Monitoring") isTrafficMode = true;
  else isTrafficMode = false;
});
//Update isStation
$("#station-section-tabs").click(function (e) {
  var target = getEventTarget(e);
  var mode = target.text.trim();
  if (mode = "Stations") isStation = true;
  else isStation = false;
});
  /*$("#application-list").empty();

  var begining = "<li><a href='#' data-toggle='collapse' data-target='.navbar-collapse.in'>";
  var okay = "<i class='glyphicon glyphicon-ok'></i>&nbsp;&nbsp;&nbsp;";
  var nonOkay = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
  var trafficModeText = "<i class='glyphicon glyphicon-eye-open'></i>&nbsp;Traffic Monitoring";
  var EmissionModeText = "<i class='glyphicon glyphicon-eye-open'></i>&nbsp;Emission Monitoring";
  var ending = "</a></li>";
  if (mode === "Traffic Monitoring") {
    trafficMode = true;
    $("#application-list-href").text('Traffic Monitoring');
    $("#application-list").append(begining + okay + trafficModeText + ending);
    $("#application-list").append(begining + nonOkay + EmissionModeText + ending);
  }
  else if (mode === "Emission Monitoring") {
    trafficMode = false;
    $("#application-list-href").text('Emission Monitoring');
    $("#application-list").append(begining + nonOkay + trafficModeText + ending);
    $("#application-list").append(begining + okay + EmissionModeText + ending);
  }
  makeVehClassSchemeSelector("realtime-vehclassscheme-selector", null);
  makeVehClassSchemeSelector("historical-vehscheme-select", "historical-vehclass-select");*/


//2. Initialize vehicle class info, lane info, and pollutant info


//3. Get the current class, lane, measure, station/section id, interval and pollutant type

$("#station-tabs").click(function (e) {
  var target = getEventTarget(e);
  var mode = target.text.trim();
  return 0;
  /*$("#application-list").empty();

  var begining = "<li><a href='#' data-toggle='collapse' data-target='.navbar-collapse.in'>";
  var okay = "<i class='glyphicon glyphicon-ok'></i>&nbsp;&nbsp;&nbsp;";
  var nonOkay = "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;";
  var trafficModeText = "<i class='glyphicon glyphicon-eye-open'></i>&nbsp;Traffic Monitoring";
  var EmissionModeText = "<i class='glyphicon glyphicon-eye-open'></i>&nbsp;Emission Monitoring";
  var ending = "</a></li>";
  if (mode === "Traffic Monitoring") {
    trafficMode = true;
    $("#application-list-href").text('Traffic Monitoring');
    $("#application-list").append(begining + okay + trafficModeText + ending);
    $("#application-list").append(begining + nonOkay + EmissionModeText + ending);
  }
  else if (mode === "Emission Monitoring") {
    trafficMode = false;
    $("#application-list-href").text('Emission Monitoring');
    $("#application-list").append(begining + nonOkay + trafficModeText + ending);
    $("#application-list").append(begining + okay + EmissionModeText + ending);
  }
  makeVehClassSchemeSelector("realtime-vehclassscheme-selector", null);
  makeVehClassSchemeSelector("historical-vehscheme-select", "historical-vehclass-select");*/
});