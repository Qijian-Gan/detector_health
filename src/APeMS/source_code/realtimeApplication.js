
var realtime_data;
var vehClassScheme;
var VehClassName2Id;
var VehClassId2Name;
var LaneInfo;
var pollutantList;
var pollutantId2Name;
var savedData = {};
var clickedSection = null;
var interval;
var metric;
var secstnID;
function getInterval_rt() {
    var intervals = $("input[name=interval-rt]");
    var interval;
    for (var index in intervals) {
        if (intervals[index].checked) {
            interval = intervals[index].value;
            break;
        }
    }
    return interval;
}
interval = getInterval_rt();

//makeVehClassSchemeSelector("realtime-vehclassscheme-selector", null);
makeVehClassSchemeSelector("realtime-vehclassscheme-selector", "class-selector");
getPollutantList();

function prepareRealtimeData() {
    var geoObjId = clickedSection ? clickedSectionID : clickedStationID;
    secstnID = geoObjId;
    var text = getOptionNameFromSelectId("realtime-vehclassscheme-selector");
    var curVehClassSchemeId = vehClassScheme[text];
    text = getOptionNameFromSelectId("metrics-selector");
    var metric = convertFull2Abbr(text);
    $("#chartLegend-realtime").hide();

    var allData = null,
        retData = {
            "type": SectionStr,
            "colNames": {},
            "metric": metric,
            "data": [],
            "volume": []
        };
    if (clickedCorridorID) {
        loadRealtimeData(clickedCorridorID);
    } else {
        loadRealtimeData("1");
    }

    if (clickedSection) {
        allData = realtime_data["result"]["sections"]["features"];
    } else {
        allData = realtime_data["result"]["stations"]["features"];
        retData["type"] = StationStr;
        /*if (metric == "speed"){
            for (var i in allData){
                for (var j in allData[i]["properties"].speed){
                    var vc = parseInt(allData[i]["properties"].speed[j].vehclass_id);
                    var sp = parseInt(allData[i]["properties"].speed[j].speed);
                    if (vc < 4){
                        if (sp >80) {allData[i]["properties"].speed[j].speed =80; }
                    }
                    else{
                        if (sp >65) {allData[i]["properties"].speed[j].speed =65; }
                    }
                }
            }
        }*/
    }
    geoObjId = geoObjId.toString();
    var arrayLength = allData.length;
    for (var i = 0; i < arrayLength; i++) {
        if (allData[i]["id"] === geoObjId) {
            retData["data"] = allData[i]["properties"][metric];
            retData["volume"] = allData[i]["properties"].volume;
            break;
        }
    }

    // HPMS data is aggregated from FHWA
    reloadVehClassList(curVehClassSchemeId);
    retData['data'] = HPMSAggregater(retData, curVehClassSchemeId);

    if (curVehClassSchemeId == 2 && retData.metric == "speed"){
        retData["data"] = emissionSpeedFilter(retData);
    }
    else{
        retData["data"] = filterByVehClassScheme(retData["data"], curVehClassSchemeId);
    }
    if (retData["data"].length === 0) {
            return retData;
    }

    var laneInfo = getLaneId2Name(retData["data"], retData.type);

    retData['colNames'] = getColumnName(laneInfo);
    retData['laneInfo'] = laneInfo;
    LaneInfo = laneInfo;
    retData['laneName2Id'] = getLaneName2Id(laneInfo);

    makeLaneSelect(retData.laneInfo);

    savedData = $.extend(true, {}, retData);
    return retData;
}

function emissionSpeedFilter(retData){
    var speedData = retData.data;
    for (i in speedData){
        if (speedData[i].vehclass_id == "13"){
            speedData.splice(i,2);
        }
    }
    for (i in speedData){
        speedData[i].vehclass_id = FHWA_to_EMFAC[speedData[i].vehclass_id];
    }
    speedData.sort( function(a,b){
        if (Number(a.lane_id) > Number(b.lane_id)){
            return 1;
        }
        else if (Number(a.lane_id) < Number(b.lane_id)){
            return -1;
        }
        else{
            if (Number(a.vehclass_id) > Number(b.vehclass_id)){
                return 1;
            }
            else if (Number(a.vehclass_id) < Number(b.vehclass_id)){
                return -1;
            }
            else{
                return 0;
            }
        }
    });
    return speedData;
}

function makeTable(tableData) {
    var table = document.getElementById("realtime-table");
    clearTable(table);
    createTableHeader(table, tableData["colNames"]);
    createTableRows(table, tableData);
}

function getColumnName(data) {
    var colNames = {};
    var colIndex = 1;
    for (var key in data) {
        colNames[data[key]] = colIndex;
        colIndex += 1;
    }
    if (isEmpty(colNames)) {
        // make empty data notification
        colNames[NoDataFoundStr] = NoDataFoundStr;
    }
    return colNames;
}

function filterByVehClassScheme(data, curVehClassSchemeId) {
    var retData = [];

    for (var index in data) {
        if (data[index].vehclass_scheme === undefined) {
            data[index].vehclass_scheme = curVehClassSchemeId;
            data[index].vehclass_id = "0";
        }
        if (data[index].vehclass_scheme === curVehClassSchemeId) {
            retData.push(data[index]);
        }
    }

    return retData;
}

function reloadVehClassList(curVehClassSchemeId) {
// get vehicle class list
    $.ajaxSettings.async = false;
    VehClassName2Id = {};
    $.getJSON(generateJsonPath("getVehClassList"), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        VehClassId2Name = data["result"][curVehClassSchemeId];
        for (var id in VehClassId2Name) {
            VehClassName2Id[VehClassId2Name[id]] = id;
        }
    });
    $.ajaxSettings.async = true;
}

function HPMSAggregater(allData, curVehClassSchemeId) {
    var data = allData.data;
    var metric = allData.metric;
    var volume = allData.volume;

    if (curVehClassSchemeId !== HPMS_ID) {
        return data;
    }

    // key: vehclass_id, value: object: {key: lane_id, datum}
    var midData = {};
    var volumeData = {};
    var occupancyData = {};
    var speedData = {}; 
    var retData = {};
    var index_vD = -1;
    /*for (var id in VehClassId2Name) {
        midData[id] = {};
        volumeData[id] = {};
    }*/
    if (metric === "volume"){
        var pre_vehId = -2;
        if (volume !== undefined || volume !== null) {
            for (index in volume) {
                var datum = volume[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (volumeData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.volume = parseFloat(datum.volume);
                        volumeData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        volumeData[index_vD].vehclass_scheme = '3'; 
                    } else {
                        //console.log(index, datum.volume);
                        volumeData[index_vD].volume += parseFloat(datum.volume);
                    }
                }
            }
        }
        return volumeData;
    }
    if (metric === "occupancy"){
        var occupancy = allData.data;
        var pre_vehId = -2;
        if (occupancy !== undefined || occupancy !== null) {
            for (index in occupancy) {
                var datum = occupancy[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (occupancyData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.occupancy = parseFloat(datum.occupancy);
                        occupancyData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        occupancyData[index_vD].vehclass_scheme = '3'; 
                        var temp = parseFloat(occupancyData[index_vD].occupancy);
                        occupancyData[index_vD].occupancy = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        occupancyData[index_vD].occupancy += parseFloat(datum.occupancy);
                        var temp = parseFloat(occupancyData[index_vD].occupancy);
                        occupancyData[index_vD].occupancy = temp.toFixed(1);
                    }
                }
            }
        }
        return occupancyData;
    }
    if (metric === "speed"){
        var speed = allData.data;
        var pre_vehId = -2;
        if (speed !== undefined || speed !== null) {
            for (index in speed) {
                var datum = speed[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (speedData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.speed = parseFloat(datum.speed);
                        speedData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        speedData[index_vD].vehclass_scheme = '3'; 
                        var temp = parseFloat(speedData[index_vD].speed);
                        speedData[index_vD].speed = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        speedData[index_vD].speed += parseFloat(datum.speed);
                        var temp = parseFloat(speedData[index_vD].speed);
                        speedData[index_vD].speed = temp.toFixed(1);
                    }
                }
            }
        }
        return speedData;
    }
    if (metric == "travel_time_index" || metric == "lcim"){
        return data;
    }
    if (metric === "vmt"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.vmt = parseFloat(datum.vmt);
                        datum.volume = parseFloat(datum.volume);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                        //var temp = parseFloat(retData[index_vD].vmt);
                        //retData[index_vD].vmt = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        retData[index_vD].vmt += parseFloat(datum.vmt);
                        var temp = parseFloat(retData[index_vD].vmt);
                        if (temp > 0){
                            retData[index_vD].matching_rate = temp.toFixed(2);
                        }
                        //speedData[index_vD].speed = temp.toFixed(1);
                    }
                }
            }
        }
        return retData;
    }
    if (metric === "vht"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.vht = parseFloat(datum.vht);
                        datum.volume = parseFloat(datum.volume);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                        //var temp = parseFloat(retData[index_vD].vmt);
                        //retData[index_vD].vmt = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        retData[index_vD].vht += parseFloat(datum.vht);
                        var temp = parseFloat(retData[index_vD].vht);
                        if (temp > 0){
                            retData[index_vD].matching_rate = temp.toFixed(2);
                        }
                        //var temp = parseFloat(speedData[index_vD].speed);
                        //speedData[index_vD].speed = temp.toFixed(1);
                    }
                }
            }
        }
        return retData;
    }
    if (metric === "matching_rate"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD += 1;
                    }
                    pre_vehId = vehId;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.matching_rate = parseFloat(datum.matching_rate);
                        datum.volume = parseFloat(datum.volume);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                        //var temp = parseFloat(retData[index_vD].vmt);
                        //retData[index_vD].vmt = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        if (parseFloat(datum.volume)+retData[index_vD].volume > 0){
                            retData[index_vD].matching_rate = ((parseFloat(datum.matching_rate)*parseFloat(datum.volume)+retData[index_vD].matching_rate*retData[index_vD].volume)/(parseFloat(datum.volume)+retData[index_vD].volume));
                            var temp = parseFloat(retData[index_vD].matching_rate);
                            if (temp > 0){
                                retData[index_vD].matching_rate = temp.toFixed(2);
                            }
                            
                        }
                        else{
                            retData[index_vD].matching_rate = 0;
                        }
                        //var temp = parseFloat(speedData[index_vD].speed);
                        //speedData[index_vD].speed = temp.toFixed(1);
                    }
                }
            }
        }
        return retData;
    }
    /*function getVolume(vehId, laneId) {
        var ret = volume === undefined || volumeData[vehId][laneId].volume === 0.0
            ? 1.0
            : volumeData[vehId][laneId].volume;
        return ret === undefined || ret === null
            ? 1.0
            : ret;
    }*/

    /*for (var index in data) {
        var datum = data[index];
        if (datum.vehclass_scheme === FHWA_ID) {
            var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
            var laneId = datum.lane_id;
            if (midData[vehId][laneId] === undefined) {
                datum.num = getVolume(vehId, laneId);
                datum.vehclass_scheme = curVehClassSchemeId;
                datum.vehclass_id = vehId;
                datum[metric] = parseFloat(datum[metric]);
                midData[vehId][laneId] = datum;
            } else {
                var value = midData[vehId][laneId][metric];
                var num = midData[vehId][laneId].num;
                value = (value * num + parseFloat(datum[metric])) / (num + getVolume(vehId, laneId));
                //value = Math.round( value );
                midData[vehId][laneId][metric] = value;
                midData[vehId][laneId].num = num + getVolume(vehId, laneId);
            }
        }
    }

    var retData = [];
    for (var vehId in midData) {
        for (var laneId in midData[vehId]) {
            midData[vehId][laneId][metric] = parseFloat(midData[vehId][laneId][metric]).toFixed(2);
            retData.push(midData[vehId][laneId]);
        }
    }*/

    //return retData;
}

function getLaneName2Id(laneInfo) {
    var ret = {};
    for (var id in laneInfo) {
        /*if (id === 24){
            ret["All"] = id;
        }
        else{
            ret[laneInfo[id]] = id;
        }*/
        ret[laneInfo[id]] = id;
    }
    return ret;
}

function getLaneId2Name(data, type) {
    var laneId2ColName = {};
    if (data === null || data.length === 0) {
        return laneId2ColName;
    }
    if (data[0].vmt !== undefined){
        laneId2ColName = {"0":"Volume", "1":"Vehicle Miles Travled"};
        return laneId2ColName;
    }
    if (data[0].vht !== undefined){
        laneId2ColName = {"0":"Volume","1":"Vehicle Hours Travled"};
        return laneId2ColName;
    }
    if (data[0].matching_rate !== undefined){
        laneId2ColName = {"0":"Volume","1":"REID Matching Rate (%)"};
        return laneId2ColName;
    }
    if (data[0].usLane !== undefined){
        laneId2ColName = {"0":"DS Lane"};
    }
    var laneNameCount = {}, laneNameMinId = {};
    $.each(data, function (key, val) {
        var laneName = getLaneTypeName(val, type);
        val["lane_id"] = val["lane_id"] === undefined ? "0" : val["lane_id"];
        var lane_id = val["lane_id"];
        if (laneNameCount[laneName] === undefined) {
            laneNameCount[laneName] = {};
            laneNameCount[laneName][lane_id] = true;
            laneNameMinId[laneName] = parseInt(lane_id);
        } else {
            laneNameCount[laneName][lane_id] = true;
            laneNameMinId[laneName] = Math.min(laneNameMinId[laneName], parseInt(lane_id));
        }
    });

    for (var laneName in laneNameCount) {
        for (var id in laneNameCount[laneName]) {
            /*var name = (id === "0"
                ? laneName
                : laneName + (parseInt(id) - laneNameMinId[laneName] + 1).toString()
            );*/
            var text = getOptionNameFromSelectId("realtime-vehclassscheme-selector");
            var curVehClassSchemeId = vehClassScheme[text];
            if ((curVehClassSchemeId === "2" && data[0].speed == "undefined") || data[0].vmt !== undefined || data[0].vht !== undefined || data[0].matching_rate !== undefined){
                var name = laneName;
            }
            else if ((curVehClassSchemeId === "2" && data[0].emission !== undefined) || (curVehClassSchemeId === "2" && data[0].emission_rate !== undefined))  {
                var name = laneName;
            }
            else if (interval === '1day' && type == "station"){
                var name = laneName;
            }
            else if (type == "station" && interval === '1day' && data[0].speed !== undefined){
                var name = laneName;
            }
            else if (type == "station" && interval === '1day' && data[0].travel_time !== undefined){
                var name = laneName;
            }
            else{
                var name = (laneName === "All"
                    ? laneName
                    : laneName + (parseInt(id) - laneNameMinId[laneName] + 1).toString()
                );
            }
            laneId2ColName[id] = name;
        }
    }
    return laneId2ColName;
}

function makeVehClassSchemeSelector(selectId, selectVehClassId) {
    vehClassScheme = {};
    removeAllFromSelectId(selectId);
    $.getJSON(generateJsonPath("getVehClassSchemeList"), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        var vcs = data["result"];
        for (var id in vcs) {
            var inTrafficModeScheme = (trafficMode && vehSchemeClassInTrafficMode[vcs[id]]);
            var inEmissionModeScheme = (!trafficMode && vehSchemeClassInEmissionMode[vcs[id]]);
            if (inTrafficModeScheme || inEmissionModeScheme) {
                vehClassScheme[vcs[id]] = id;
                addOptionToSelectId(selectId, vcs[id]);
            }
        }
        if (trafficMode){
            document.getElementById("historical-vehclass-select").selectedIndex = "14";
        }
        else{
            document.getElementById("historical-vehclass-select").selectedIndex = "13";
        }
    });
    
    if (selectVehClassId === null) {return;}
    
    if (trafficMode) {
        // By default show FHWA
        makeVehClassSelector(selectVehClassId, "1");
    } else {
        // By default show EMFAC2007
        makeVehClassSelector(selectVehClassId, "2");
    }

}

function makeVehClassSelector(selectId, vehClassSchemeId) {
    VehClassName2Id = {};
    VehClassId2Name = {};
    removeAllFromSelectId(selectId);

    $.ajaxSettings.async = false;
    $.getJSON(generateJsonPath("getVehClassList"), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        VehClassId2Name = data["result"][vehClassSchemeId];
        for (var id in VehClassId2Name) {
            VehClassName2Id[VehClassId2Name[id]] = id;
            addOptionToSelectId(selectId, VehClassId2Name[id]);
        }
    });
    if (vehClassSchemeId == "1") document.getElementById(selectId).selectedIndex = "14";
    else if (vehClassSchemeId == "2") document.getElementById(selectId).selectedIndex = "0";
    else if (vehClassSchemeId == "3") document.getElementById(selectId).selectedIndex = "7";
    $.ajaxSettings.async = true;
}

function makeMetricSelector(section_or_station) {
    var selectId = "metrics-selector";
    removeAllFromSelectId(selectId);

    if (section_or_station === SectionStr) {
        var metricMode = trafficMode ? metricInTrafficMode : metricInEmissionMode;
        for (var metric in metricMode) {
            addOptionToSelectId(selectId, metric);
        }
    } else if (section_or_station === StationStr) {
        if (realtime_data.result.stations.features[0].id == "16"){
            addOptionToSelectId(selectId, "Volume");
            addOptionToSelectId(selectId, "Speed");
            addOptionToSelectId(selectId, "Occupancy");
        }
        else{
            addOptionToSelectId(selectId, "Speed");
            addOptionToSelectId(selectId, "Volume");
            addOptionToSelectId(selectId, "Occupancy");
        }
    }
}

function loadRealtimeData(corridorId) {
    $.ajaxSettings.async = false;
    interval = getInterval_rt();
    $.getJSON(generateRealtimeJsonPath(corridorId,interval), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        realtime_data = data;
    });
    $.ajaxSettings.async = true;
    if (corridorId === "3"){
        $(".timestamp").html("<span style='font-weight:bold;'>&nbspLast updated @ " + realtime_data["result"]["time"] + " CT</span>");
    }
    else if (corridorId == "4" || corridorId == "5"){
        $(".timestamp").html("<span style='font weight:bold;'>&nbspLast updated @ " + realtime_data["result"]["time"] + " MT</span>");
    }
    else{
        $(".timestamp").html("<span style='font weight:bold;'>&nbspLast updated @ " + realtime_data["result"]["time"] + " PT</span>");
    }
    $("#loading-notice").fadeOut();
}

function getPollutantList() {
    pollutantList = {};
    pollutantId2Name = {};
    $.getJSON(generateJsonPath("getPollutantList"), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        pollutantList = data["result"];
        for (var pollutantId in pollutantList) {
            pollutantId2Name[pollutantId] = pollutantList[pollutantId];
            Limits["emission_rate"][pollutantId] = 1.0;
            Limits["emission"][pollutantId] = 1.0;
        }
        Limits["emission_rate"]["3"] = 10.0;
        Limits["emission_rate"]["10"] = 1600.0;
        Limits["emission_rate"]["13"] = 0.01;
        Limits["emission"]["3"] = 1.0;
        Limits["emission"]["10"] = 100.0;
        Limits["emission"]["13"] = 0.1;
    });
}

function makeLaneSelect(data) {
    var selectId = "lanes-selector";
    removeAllFromSelectId(selectId);

    for (var index in data) {
        if (data[index] === "All"){
            addOptionToSelectId(selectId, "All");
        }
        else{
            addOptionToSelectId(selectId, data[index]);
        }
        //addOptionToSelectId(selectId, data[index]);
    }
    document.getElementById("lanes-selector").selectedIndex = (index).toString();
}

function makePie(data) {
   // $('.realtime-lane-group').hide(); // no need to show lane selector
    var laneId = data.laneName2Id[getOptionNameFromSelectId("lanes-selector")];
    //var classId = VehClassName2Id[getOptionNameFromSelectId("class-selector")];
    //var laneId = data.laneName2Id["All"];
    var pieData = filterByLaneIdPieData(data.data, data.metric,data.laneName2Id, data.laneInfo);
    //var pieDataCur = filterByLaneId(data.data, laneId, data.metric, data.laneInfo);
    var pieDataCur = filterByLaneIdSpeedBinPieData(data.volume, data.data, laneId, data.metric, data.laneInfo);
    var plot_id = "#realtime-chart2";
    var plot_id_cur = "#realtime-chart"
    $(plot_id).unbind();
    $(plot_id_cur).unbind();
    var width = 800;
    //var width = Math.min($(window).width())*0.5;
    if (document.body.clientWidth < 992) {
        width = Math.min($(window).width(), 600);
    }
    //width = width / 16 * 14.5;
    //$(plot_id).height(width / 16 * 9);
    $(plot_id).height(width / 16 * 6);////reduce plot height for bigger chart legend
    $(plot_id).width(width);
    $(plot_id_cur).height(width / 16 * 6);////reduce plot height for bigger chart legend
    $(plot_id_cur).width(width);
    $("#chartLegend-realtime").hide();
    var chart = new Highcharts.Chart({
            chart: {
                renderTo:'realtime-chart',
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie'
            },
            legend: {
                align: 'right',
                layout: 'vertical',
                verticalAlign: 'top'
            },
            title: {
                text: getChartTitle()
            },
            tooltip: {
                pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false
                    },
                    showInLegend: true
                }
            },
            series: pieDataCur
    });
    $("#realtime-chart2").hide();
    /*if (data.metric == "vht" || data.metric == "vmt" || data.metric == "matching_rate"){
        $("#realtime-chart2").hide();
    }
    var chart = new Highcharts.Chart({
            chart: {
                renderTo:'realtime-chart2',
                plotBackgroundColor: null,
                plotBorderWidth: null,
                plotShadow: false,
                type: 'pie'
            },
            title: {
                text: '----------------------------------------------------------------'
            },
            tooltip: {
                pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
            },
            plotOptions: {
                pie: {
                    allowPointSelect: true,
                    cursor: 'pointer',
                    dataLabels: {
                        enabled: false
                    },
                    showInLegend: false
                }
            },
            series: pieData
    });
    if (interval == "1day") $("#realtime-chart2").hide();*/
    
    /*$.plot(plot_id, pieData, {
        series: {
            pie: {
                show: true
            }
        },
        grid: {
            hoverable: true
        }
    });

    $(plot_id).bind("plothover", function (event, pos, obj) {

        if (!obj) {
            return;
        }

        var percent = parseFloat(obj.series.percent).toFixed(2);
        $("#hover").html("<span style='font-weight:bold;font-size:large; color:" + obj.series.color + "'>" + obj.series.label + " (" + percent + "%)</span>");
    });*/
}

function labelFormatter(label, series) {
    return "<div style='font-size:large; text-align:center; padding:2px; color:white;'>" + label + "<br/>" + Math.round(series.percent) + "%</div>";
}

function filterByLaneId(data, laneId, metric, laneInfo) {
    var retData = [];
    var classTotal = '14';
    if (data[0].vehclass_scheme == HPMS_ID){
        classTotal = '7';
    }
    var pieData = [];
    for (var index in data) {
        var datum = data[index];
        if (metric === "travel_time_index") {
            pieData.push({
                name: LaneInfo[datum.lane_id],
                y: parseFloat(datum[metric])
            });
        } else if (datum.lane_id == laneId &&     // lane id must match
            datum.vehclass_id !== classTotal) { // no aggregated value
            pieData.push({
                name: VehClassId2Name[datum.vehclass_id],
                y: parseFloat(datum[metric])
            });
         }
        else if (metric === "matching_rate" || metric === "vmt" || metric === "vht"){
            if (laneId == "1" && datum.vehclass_id !== classTotal){
                pieData.push({
                    name: VehClassId2Name[datum.vehclass_id],
                    y: parseFloat(datum[metric])
                });
            }
            else if (laneId == "0" && datum.vehclass_id !== classTotal) {
                pieData.push({
                    name: VehClassId2Name[datum.vehclass_id],
                    y: parseFloat(datum["volume"])
                });
            }
        }
    }
    retData.push({name:laneInfo[laneId],
                    colorByPoint:true,
                    data:pieData
    });
    
    return retData;
}

function filterByLaneIdSpeedBinPieData(volume,data,laneId,metric,laneInfo){
    var retData = [];
    var classTotal = '14';
    if (data[0].vehclass_scheme == HPMS_ID){
        classTotal = '7';
    }
    if (data[0].vehclass_scheme === EMFAC2007){
        classTotal = '13';
    }
    if (metric == "speed"){
        //initialize
        var speedBinCount = [];
        for (var id in SpeedBin){
            speedBinCount.push({
                name: SpeedBin[id],
                y:0
            });
        }
        //get the total count of each speedbin volume for the selected lane
        if (laneInfo[laneId] == "All"){
            for (var i in data){
                var datum = data[i];
                var curVolume = volume[i];
                if(datum.lane_id != laneId){
                    if (datum[metric] >= 0 && datum[metric] <= 10){
                        speedBinCount[0].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 10 && datum[metric] <= 20){
                        speedBinCount[1].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 20 && datum[metric] <= 30){
                        speedBinCount[2].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 30 && datum[metric] <= 40){
                        speedBinCount[3].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 40 && datum[metric] <= 50){
                        speedBinCount[4].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 50 && datum[metric] <= 60){
                        speedBinCount[5].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 60 && datum[metric] <= 70){
                        speedBinCount[6].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 70 && datum[metric] <= 80){
                        speedBinCount[7].y += parseInt(curVolume.volume);
                    }
                    else {
                        speedBinCount[8].y += parseInt(curVolume.volume);
                    }
                }
            }
        }
        else{
            for (var i in data){
                var datum = data[i];
                var curVolume = volume[i];
                if(datum.lane_id == laneId){
                    if (datum[metric] >= 0 && datum[metric] <= 10){
                        speedBinCount[0].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 10 && datum[metric] <= 20){
                        speedBinCount[1].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 20 && datum[metric] <= 30){
                        speedBinCount[2].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 30 && datum[metric] <= 40){
                        speedBinCount[3].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 40 && datum[metric] <= 50){
                        speedBinCount[4].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 50 && datum[metric] <= 60){
                        speedBinCount[5].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 60 && datum[metric] <= 70){
                        speedBinCount[6].y += parseInt(curVolume.volume);
                    }
                    else if (datum[metric] > 70 && datum[metric] <= 80){
                        speedBinCount[7].y += parseInt(curVolume.volume);
                    }
                    else {
                        speedBinCount[8].y += parseInt(curVolume.volume);
                    }
                }
            }
        }
        //construct the output
        retData.push({
            name:laneInfo[laneId],
            colorByPoint:true,
            data:speedBinCount
        });
    }
    else{
        var pieData = [];
        for (var index in data) {
            var datum = data[index];
            if (metric === "travel_time_index") {
                pieData.push({
                    name: LaneInfo[datum.lane_id],
                    y: parseFloat(datum[metric])
                });
            } else if (datum.lane_id == laneId &&     // lane id must match
                datum.vehclass_id !== classTotal) { // no aggregated value
                pieData.push({
                    name: VehClassId2Name[datum.vehclass_id],
                    y: parseFloat(datum[metric])
                });
            }
            else if (metric === "matching_rate" || metric === "vmt" || metric === "vht"){
                if (laneId == "1" && datum.vehclass_id !== classTotal){
                    pieData.push({
                        name: VehClassId2Name[datum.vehclass_id],
                        y: parseFloat(datum[metric])
                    });
                }
                else if (laneId == "0" && datum.vehclass_id !== classTotal) {
                    pieData.push({
                        name: VehClassId2Name[datum.vehclass_id],
                        y: parseFloat(datum["volume"])
                    });
                }
            }
        }
        retData.push({name:laneInfo[laneId],
                    colorByPoint:true,
                    data:pieData
        });
    }
    return retData;
}

function filterByLaneIdLineData(data, laneId, metric, laneInfo) {
    var retData = {};
    var return_data = [];
    var measure;
    measure = metric;
    var classTotal = '14';
    if (data[0].vehclass_scheme == HPMS_ID){
        classTotal = '7';
    }
    if (data[0].vehclass_scheme === EMFAC2007){
        classTotal = '13';
    }
    if (metric == "vht" || metric == "vmt" || metric == "matching_rate"){
        retData[0]=[];
        $.each(data, function (index, val) {
            if (new Date().dst()){
                retData[0].push([(val["time"]+3600) * 1000, val[metric]]);
            }
            else{
                retData[0].push([(val["time"]) * 1000, val[metric]]);
            }
        });
        $.each(retData, function (index, metric) {
        return_data.push({
            "name": measure.toString(),
            "data": metric,
            lines: {
                lineWidth: 1
            }
        });
    });
    }
    else{
        for (var i=0; i<=laneId;i++){
            retData[i]=[];
        }
        $.each(data, function (index, val) {
            if (new Date().dst()){
                retData[val["lane_id"]].push([(val["time"]+3600) * 1000, val[metric]]);
            }
            else{
                retData[val["lane_id"]].push([(val["time"]) * 1000, val[metric]]);
            }
        });
        $.each(retData, function (index, metric) {
        return_data.push({
            "name": laneInfo[index],
            "data": metric,
            lines: {
                lineWidth: 1
            }
        });
    });
    }
    
    return return_data;
}

function filterByLaneIdPieData(data, metric, laneName2Id, laneInfo) {
    var retData = [];
    var classTotal = '14';
    if (data[0].vehclass_scheme == HPMS_ID){
        classTotal = '7';
    }
    if (data[0].vehclass_scheme === EMFAC2007){
        classTotal = '13';
    }
    var numCharts = parseInt(laneName2Id["All"])+1;
    var chartSizeStr;
    for (var i=0;i<numCharts;i++){
        var pieData = [];
        laneId = i.toString();
        for (var index in data) {
            var datum = data[index];
            if (metric === "travel_time_index") {
                pieData.push({
                    name: LaneInfo[datum.lane_id],
                    y: parseFloat(datum[metric])
                });
            } else if (datum.lane_id == laneId &&     // lane id must match
                datum.vehclass_id !== classTotal) { // no aggregated value
                pieData.push({
                    name: VehClassId2Name[datum.vehclass_id],
                    y: parseFloat(datum[metric])
                });
            }
            else if (metric === "matching_rate" || metric === "vmt" || metric === "vht"){
                if (laneId == "1" && datum.vehclass_id !== classTotal){
                    pieData.push({
                        name: VehClassId2Name[datum.vehclass_id],
                        y: parseFloat(datum[metric])
                    });
                }
                else if (laneId == "0" && datum.vehclass_id !== classTotal) {
                    pieData.push({
                        name: VehClassId2Name[datum.vehclass_id],
                        y: parseFloat(datum["volume"])
                    });
                }
            }
        }
        var spacingStr = getSpacingPieChart(numCharts, i);
        var chartSizeStr = getPieSize(numCharts, i);
        retData.push({name:laneInfo[laneId],
                      colorByPoint:true,
                      data:pieData,
                      center:spacingStr,
                      size:chartSizeStr
                     });
    }
    
    return retData;
}

function formatterLaneAsXClassAsY(val, axis) {
    if (metric == "travel_time_index"){
        return LaneInfo[val];
    }
    else if (interval == "1day" && val.vehclass_scheme !== "2"){
        return timeSegId2NameAbbr[val];
    }
    return LaneInfo[val];
}

function formatterClassAsXLaneAsY(val, axis) {
    return VehClassId2Name[val];
}

function makeBar(data) {
    // Only show lane selector in AggLaneOnlyMetric
    metric =  data.metric;
    $('.realtime-lane-group').hide();
    if (AggLaneOnlyMetric[data.metric]) {
        $("#chartLegend-realtime").hide();  // no need to show legend for lane since lane is selected
    } else {
        $("#chartLegend-realtime").show();
    }

    /*var barData = AggLaneOnlyMetric[data.metric]
        ? makeBarDataClassAsXLaneAsY(data)
        : makeBarDataLaneAsXClassAsY(data);
    */
    /*var barData = (data.metric == "speed")
        ? makeBarDataClassAsXLaneAsY(data)
        : makeBarDataLaneAsXClassAsY(data);*/
    var barData = makeBarDataClassAsXLaneAsY(data);
    var plot_id = "#realtime-chart";
    $(plot_id).unbind();
    var width = 1015;
    //var width = Math.min($(window).width())*0.6;
    if (document.body.clientWidth < 992) {
        width = Math.min($(window).width(), 600);
    }
    //width = width / 16 * 14.5;
    //$(plot_id).height(width / 16 * 9);
    $(plot_id).height(width / 16 * 6);////reduce plot height for bigger chart legend
    $(plot_id).width(width);
    document.getElementById("realtime-chart").style.padding = "0px 0px 0px 15px";

        $("#realtime-chart").highcharts({
        chart: {
            type: 'column'
        },
        title: {
            text:getChartTitle()
        },
        xAxis:{
            categories:formatterClassAsXLaneAsY
        },
        yAxis:{
            title:{
                text:getUnits(getOptionNameFromSelectId("metrics-selector"), interval)
            }
        },
        tooltip: {
            headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
            pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
                '<td style="padding:0"><b>{point.y}</b></td></tr>',
            footerFormat: '</table>',
            shared: true,
            useHTML: true
        },

        plotOptions: {
            column: {
                pointPadding:0.1,
                borderWidth:0
            }
        },
        series:barData
    });
    /*$.plot(plot_id, barData, {
        legend:{
            container:$("#chartLegend-realtime"),
            noColumns: 5
        },
        series: {
            stack: true,
            lines: {
                show: false,
                fill: true,
                steps: false
            },
            bars: {
                show: true,
                barWidth: 0.8,
                align: 'center'
            }
        },
        yaxes: [{
                axisLabel: getUnits(getOptionNameFromSelectId("metrics-selector"), interval)
            }],
        xaxis: {
            tickFormatter: (data.metric == "speed" )
                            ? formatterClassAsXLaneAsY
                            : formatterLaneAsXClassAsY,
            tickSize: 1
        }
    });*/
}

function makeLine(data) {
    $('.realtime-lane-group').hide(); // no need to show lane selector

    var geoObjId = clickedSection ? clickedSectionID : clickedStationID;
    var text = getOptionNameFromSelectId("realtime-vehclassscheme-selector");
    var curVehClassSchemeId = vehClassScheme[text];
    text = getOptionNameFromSelectId("metrics-selector");
    var metric = convertFull2Abbr(text);
    var section_or_station = (clickedSection)? SectionStr:StationStr;
    var laneId = data.laneName2Id[getOptionNameFromSelectId("lanes-selector")];
    var startTimeStr;
    if (interval == "1day"){
        var d = new Date();
        d.setDate(d.getDate() - 7);
        startTimeStr = formatDate(d);
    }
    else{
        var startHour = new Date().getHours();
        startHour -= 4;
        var startTime = new Date();
        startTime.setHours(startHour);
        if (geoObjId == "16" || geoObjId == "17" ||geoObjId == "18"){
            startTime.setHours(startTime.getHours() + 1);
        }
        else if (geoObjId == "10" || geoObjId == "11" ||geoObjId == "13"){
            startTime.setHours(startTime.getHours() + 2);
        }
        startTimeStr = formatDate(startTime);
    }
    var endTime = new Date();
    if (geoObjId == "16" || geoObjId == "17"||geoObjId == "18"){
        endTime.setHours(endTime.getHours() + 1);
    }
    else if(geoObjId == "10" || geoObjId == "11"||geoObjId == "13"){
        endTime.setHours(endTime.getHours() + 2);
    }
    var endTimeStr = formatDate(endTime);
    
    var lineData = null;
    if (curVehClassSchemeId == "3"){
        lineData = loadHPMSDataLine(data);
        for (var id in lineData){
            lineData[id][metric] = parseFloat(lineData[id][metric]);
        }
    }
    else{
        var curVehClass = VehClassName2Id[getOptionNameFromSelectId("class-selector")];
    /*if (curVehClassSchemeId == FHWA_ID){
        var curVehClass = '14';
    }
    else if (curVehClassSchemeId == HPMS_ID){
        var curVehClass = '7';
    }
    else{
        var curVehClass = '0';
    }*/
    $.ajaxSettings.async = false;
    $.getJSON(
            generateHistoricalJsonPath(
                section_or_station,
                geoObjId,
                metric,
                interval,
                startTimeStr,
                endTimeStr,
                curVehClassSchemeId,
                curVehClass
            ),
            function (redata) {
                lineData = redata;
            }
        );
    $.ajaxSettings.async = true;
        lineData = filterHistoricalDataByAggregate(lineData, metric);
    }
    lineData = filterByLaneIdLineData(lineData, laneId, data.metric, data.laneInfo);
    /*if (metric == "vmt" || metric == "vht" || metric == "matching_rate"){
        var Allidx = 0;
        var GPidx = 0;
        var HOV1idx = 0;
    }
    else{*/
        var Allidx = data.laneName2Id["All"];
    /*
        var GPidx = data.laneName2Id["Lane1"];
        if (GPidx == undefined) GPidx = data.laneName2Id["Through1"];
        var HOV1idx = data.laneName2Id["HOV1"];
        var HOV2idx = data.laneName2Id["HOV2"];
        if (HOV1idx == undefined) HOV1idx = GPidx;
        if (HOV2idx == undefined) HOV2idx = GPidx;
    }*/
    var plot_id = "#realtime-chart";
    $(plot_id).unbind();
    var width = 1015;
    //var width = Math.min($(window).width())*0.6;
    if (document.body.clientWidth < 992) {
        width = Math.min($(window).width(), 600);
    }
    //width = width / 16 * 14.5;
    //$(plot_id).height(width / 16 * 9);
    $(plot_id).height(width / 16 * 6);////reduce plot height for bigger chart legend
    $(plot_id).width(width);
    document.getElementById("realtime-chart").style.padding = "0px 0px 0px 15px";
    $("#realtime-chart").highcharts({
        chart: {
            type: 'line',
            events: {
                load: function(){
                    //this.series[HOV1idx].show();
                    //this.series[GPidx].show();
                    this.series[Allidx].hide();
                }
            }
        },
        title: {
            text: getChartTitle()
        },
        xAxis: {
            type: 'datetime',
            labels: {
                format: '{value:%H:%M}'
            },
            startOnTick: true,
            endOnTick: true
        },
        yAxis: {
            title:{
                text:getUnits(getOptionNameFromSelectId("metrics-selector"), interval)
            }
        },
        tooltip: {
            headerFormat: '<span style="font-size:10px">{point.key}</span><table>',
            pointFormat: '<tr><td style="color:{series.color};padding:0">{series.name}: </td>' +
                '<td style="padding:0"><b>{point.y}</b></td></tr>',
            footerFormat: '</table>',
            shared: true,
            useHTML: true
        },/*
        plotOptions: {
            series: {
                visible: false
            }
        },*/
        series: lineData
    });
   /* var options = {
            xaxis: {
                mode: "time",
                //timeformat: "%m/%d %H:%M",
                autoscaleMargin:0.01,
            },
            yaxis: {
                min: 0
            },
            series: {
                lines: {show: true},
                points: {
                    show: true,
                    radius: 3,
                    fill: true
                }
            },
            yaxes: [{
                axisLabel: getUnits(getOptionNameFromSelectId("metrics-selector"), interval)
            }],
            legend:{
                container:$("#chartLegend-realtime"),
                noColumns: 5
            },
            grid:{
                borderWidth : 3
            }
        };

        $.plot(plot_id,
            lineData,
            options
        );*/
}

function makeBarDataLaneAsXClassAsY(data) {
    var retData = [];
    var classTotal = '14';
    if (data.data[0].vehclass_scheme == HPMS_ID){
        classTotal = '7';
    }
    for (var classId in VehClassId2Name) {
        if (classId.toString() === classTotal) {
            continue;
        }
        retData.push({name: VehClassId2Name[classId], data: []});
    }

    var arrayData = data.data;
    var metric = data.metric;
    var AggLaneId = data.laneName2Id["All"].toString();
    for (var index in arrayData) {
        var datum = arrayData[index];
        if (metric !== "travel_time_index" &&
            datum.vehclass_id.toString() === classTotal) {
            continue;
        }

        // Not Agg Lane Only Metric, filter the aggregated lane data
        if (datum.lane_id.toString() === AggLaneId
        ) {
            continue;
        }

        // for travel time index, veh class is always 0
        var vehclassId = metric !== "travel_time_index"
            ? parseInt(datum.vehclass_id)
            : 1;

        if (metric === "matching_rate" || metric === "vmt" || metric === "vht"){
            retData[vehclassId].data.push(
            [
                parseInt(datum.vehclass_id),
                parseFloat(datum[metric])
            ]
            );
        }
        else{
            retData[vehclassId].data.push(
            [
                data.laneInfo[parseInt(datum.lane_id)],
                parseFloat(datum[metric])
            ]
            );
        }
    }
    return retData;
}

function makeBarDataClassAsXLaneAsY(data) {
    var curLaneId = data.laneName2Id[getOptionNameFromSelectId("lanes-selector")];

    var retData = [];
    for (var laneId in data.laneInfo) {
        if (laneId !== data.laneName2Id["All"]){
            retData.push({name: data.laneInfo[laneId],data: []});
        }
    }
    var arrayData = data.data;
    var metric = data.metric;
    for (var index in arrayData) {
        var datum = arrayData[index];

        // filter the aggregated veh class and lane id according to the current selected lane id
        //|| datum.lane_id !== curLaneId
        if (metric !== "travel_time_index" &&
            (datum.vehclass_id.toString() === AggregatedVal || datum.lane_id.toString() == data.laneName2Id["All"])) {
            continue;
        }
        var laneId = parseInt(datum.lane_id);
        if (laneId.toString() !== data.laneName2Id["All"]){
            retData[laneId].data.push(
                [
                    VehClassId2Name[parseInt(datum.vehclass_id)],
                    parseFloat(datum[metric])
                ]
            );
        }
    }
    return retData;
}

function getChartTitle(){
    var pos = /[A-z]+/.exec(interval).index;
    var text = [
            interval.slice(0, pos), '-',
            interval.charAt(pos).toUpperCase(),
            interval.slice(pos + 1), ' ',
            getOptionNameFromSelectId("metrics-selector")
    ].join('');
    var renderWay = getRenderWay();
    if (renderWay === 'line'){
        var dateObj = new Date();
        var month = dateObj.getMonth() + 1; //months from 1-12
        var day = dateObj.getDate();
        var year = dateObj.getFullYear();
        var dayofweek = weekdays[dateObj.getDay()];
        var newdate = year.toString() + "-" + month.toString() + "-" + day.toString() + " " + dayofweek.toString() + " (last 4 hours)";
        var res = [
            text, ': ',newdate
        ].join('');
        return res;
    }
    else{
        return text;
    }
}

function renderRealtimeData(reloading) {
    if (clickedSection === null) {
        // initializing, no need to render, just return;
        return;
    }
    var section_or_station = (clickedSection)? SectionStr:StationStr;
    $("#hover").html("");
    var data = reloading
        ? prepareRealtimeData()
        : $.extend(true, {}, savedData);
    if (data.data.length === 0) {
        clearTableChart();
        return;
    }
    $("#realtime-download-button").hide();
    var renderWay = getRenderWay();
    removeAllFromElementId("realtime-chart-title");
    $('.realtime-chart-group2').hide();
    var chart_title_id = document.getElementById("realtime-chart-title");
    /*if (secstnID == "16" || secstnID == "17" || secstnID == "18"){
        $("#section-tab-select").hide();
    }
    else{
        $("#section-tab-select").show();
    }*/
    $("#speed-est-clr").hide();
    if (renderWay === 'table') {
        $('.realtime-table-group').show();
        $('.realtime-chart-group').hide();
        $('.realtime-lane-group').hide();
        $('.realtime-class-group').hide();
        $('.realtime-1day-radio').show();
        //addOptionToSelectId("metrics-selector", "Speed");
        addLabel(chart_title_id, getChartTitle(), "chart-title");
        makeTable(data);
    } else if (renderWay === 'pie') {
        $('.realtime-table-group').hide();
        $('.realtime-chart-group').show();
        $('.realtime-1day-radio').show();
        //$('.realtime-chart-group2').show();
        $('.realtime-lane-group').show();
        $('.realtime-class-group').hide();
        //document.getElementById("metrics-selector").selectedIndex = "0";
        makePie(data);
    } else if (renderWay === 'bar') {
        $('.realtime-table-group').hide();
        $('.realtime-chart-group').show();
        $('.realtime-1day-radio').show();
        $('.realtime-class-group').hide();
        $('.realtime-lane-group').hide();
        /*var chart_title_id = document.getElementById("realtime-chart-title");
        var text = [
            interval.slice(0, pos), '-',
            interval.charAt(pos).toUpperCase(),
            interval.slice(pos + 1), ' ',
            getOptionNameFromSelectId("metrics-selector")
        ].join('');
        addLabel(chart_title_id, text, "chart-title");*/
        //addOptionToSelectId("metrics-selector", "Speed");
        makeBar(data);
    } else if (renderWay === 'line') {
        $('.realtime-table-group').hide();
        $('.realtime-chart-group').show();
        $('.realtime-1day-radio').hide();
        $('.realtime-class-group').show();
        //addOptionToSelectId("metrics-selector", "Speed");
        makeLine(data);
    }
    //map.invalidateSize();
     $("#realtime-download-button").show();
    //relocate();
}

$(".do-realtime-render").change(function () {
    renderRealtimeData(true);
});

$("#lanes-selector").change(function () {
    renderRealtimeData(false);
});

$("#class-selector").change(function () {
    renderRealtimeData(false);
});

$("#realtime-vehclassscheme-selector").change(function () {
    var text = getOptionNameFromSelectId("realtime-vehclassscheme-selector");
    var curVehClassSchemeId = vehClassScheme[text];
    makeVehClassSelector("class-selector", curVehClassSchemeId);
    if (curVehClassSchemeId === FHWA_ID){
        document.getElementById("class-selector").selectedIndex = "14";
    }
    if (curVehClassSchemeId === HPMS_ID){
        document.getElementById("class-selector").selectedIndex = "7";
    }
});

function getRenderWay() {
    var ways = $("input[name=realtime-select]");
    var way;
    for (var index in ways) {
        if (ways[index].checked) {
            way = ways[index].value;
            break;
        }
    }
    return way;
}

$("#realtime-line-radio").change(function(){
   if (interval == "1day"){
       interval = "1hour";
       $("#1hour-radio").attr('checked',true);
   } 
    renderRealtimeData(true);
});

function clearTableChart() {
    var table = document.getElementById("realtime-table");
    clearTable(table);
    var plot_id = '#realtime-chart';
    //$.plot(plot_id, []);
    $("#hover").html("");
}

$("#realtime-download-button").click(function () {
    var csv = getDownloadData(savedData, secstnID, realtime_data,interval);
    var csvContent = "data:text/csv;charset=utf-8,";
    csv.forEach(function(infoArray,index){
        dataString = infoArray.join(",");
        csvContent += index < csv.length ? dataString+ "\n":dataString;
    });
    var encodeUri = encodeURI(csvContent);
    //window.open(encodeUri);
    var encodedUri = encodeURI(csvContent);
    var link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    var d = new Date();
    var appendTimeStr = d.getFullYear().toString();
    var mon = d.getMonth() +1;
    if (mon <10) appendTimeStr += "0";
    appendTimeStr += mon.toString()+d.getDate().toString();
    appendTimeStr += "_"+d.getHours().toString()+d.getMinutes().toString()+d.getSeconds().toString();
    var filename = "real-time_data_" + appendTimeStr + ".csv";
    link.setAttribute("download", filename);
    document.body.appendChild(link); // Required for FF
    link.click(); 
    //window.open("data:text/csv;charset=utf-8," + escape(csv));
});
