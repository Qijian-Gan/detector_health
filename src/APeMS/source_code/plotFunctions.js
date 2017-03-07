/**
 * Created by Siming on 11/6/2014.
 */

var firstTimeStartCounter = 0;
var startTimeStr;
var endTimeStr;

$(function () {
    $('#datetimepicker1').datetimepicker();
    $('#datetimepicker2').datetimepicker();
    dateInit();
});
var interval_ht;
getInterval();
makeVehClassSchemeSelector("historical-vehscheme-select", "historical-vehclass-select");

var origFirstData = null, origSecondData = null;
var measureOneData = null, measureTwoData = null;
var laneTypeId2Name = {}, laneTypeName2Id = {}, laneInfo = {}, laneId2Name = {}, lastChecked = {};
var pollutantInfo = {}, lastCheckPollutants = {};
getLaneTypeList();

function getLaneTypeList() {
    $.ajaxSettings.async = false;
    $.getJSON(generateJsonPath("getLaneTypeList"), function (data) {
        if (data["status"] !== 200) {
            return;
        }
        laneTypeId2Name = data["result"];
        for (var id in laneTypeId2Name) {
            laneTypeName2Id[laneTypeId2Name[id]] = id;
        }
    });
    $.ajaxSettings.async = true;
}
function makeSelect(section_or_station) {
    var selectOneId = "historical-measure-select-one";
    var selectTwoId = "historical-measure-select-two";
    removeAllFromSelectId(selectOneId);
    removeAllFromSelectId(selectTwoId);

    if (section_or_station === SectionStr) {
        /*
         'speed', 'density', 'vmt', 'vht', 'matching_rate', 'tti', 'emission', 'emission_rate'
         */
        addOptionToSelectId(selectTwoId, NoneMeasureTwo);
        var metricMode = trafficMode ? metricInTrafficMode : metricInEmissionMode;
        for (var metric in metricMode) {
            addOptionToSelectId(selectOneId, metric);
            addOptionToSelectId(selectTwoId, metric);
        }
    } else if (section_or_station === StationStr) {
        addOptionToSelectId(selectOneId, "Volume");
        addOptionToSelectId(selectOneId, "Occupancy");
        addOptionToSelectId(selectOneId, "Speed");
        document.getElementById("historical-measure-select-one").selectedIndex = "0";

        addOptionToSelectId(selectTwoId, NoneMeasureTwo);
        addOptionToSelectId(selectTwoId, "Volume");
        addOptionToSelectId(selectTwoId, "Occupancy");
        addOptionToSelectId(selectTwoId, "Speed");
    }
}

function getInterval() {
    var intervals = $("input[name=interval]");
    for (var index in intervals) {
        if (intervals[index].checked) {
            interval = intervals[index].value;
            break;
        }
    }
    interval_ht=interval;
    return interval;
}

function PreprocessLoadedData(reloadLaneInfo) {
    // decide the lane information
    if (reloadLaneInfo) {
        delete laneInfo;
        laneInfo = {};
        laneId2Name = {};
        laneInfo = getLanesInfo(measureOneData, laneInfo);
        laneInfo = getLanesInfo(measureTwoData, laneInfo);

        // make lane check boxes
        var text = getOptionNameFromSelectId("historical-vehscheme-select");
        var curVehClassSchemeId = vehClassScheme[text];
        if (curVehClassSchemeId === FHWA_ID) {
            makeLanesSelect(laneInfo);
        }
    }

    if (!trafficMode) {
        getPollutantInfo(measureOneData);
        getPollutantInfo(measureTwoData);
        makePollutantSelect();
        $("#pollutant-check-box").show();
    } else {
        $("#pollutant-check-box").hide();
    }
}
function loadHistoricalMeasures(section_or_station, geoObjId,
                                reloadDataOne, reloadDataTwo,
                                curVehScheme, curVehClass) {
    // get start / end time stamp
    var startTime = getDateTime('datetimepicker1');
    var endTime = getDateTime('datetimepicker2');
    startTimeStr = formatDate(startTime);
    endTimeStr = formatDate(endTime);
    //startTime /= 1000;
    //endTime /= 1000;

    // get interval
    //var interval = Interval2NoSpace[getOptionNameFromSelectId("station-agg-level")];
    getInterval();
    // get measure
    var measureOne = getOptionNameFromSelectId("historical-measure-select-one");
    var measureTwo = getOptionNameFromSelectId("historical-measure-select-two");

    // get measure data
    if (reloadDataOne) {
        delete origFirstData;
        delete measureOneData;
        measureOneData = null;
        origFirstData = null;

        $.ajaxSettings.async = false;
        $.getJSON(
            generateHistoricalJsonPath(
                section_or_station,
                geoObjId,
                Full2Abbr[measureOne],
                interval_ht,
                startTimeStr,
                endTimeStr,
                curVehScheme,
                curVehClass
            ),
            function (data) {
                measureOneData = data;
            }
        );
        $.ajaxSettings.async = true;
        origFirstData = $.extend(true, {}, measureOneData);
    } else {
        // no need to reload data
        measureOneData = $.extend(true, {}, origFirstData);
    }
    if (reloadDataTwo) {
        delete origSecondData;
        delete measureTwoData;
        measureTwoData = null;
        origSecondData = null;
        $.ajaxSettings.async = false;
        if (measureTwo !== NoneMeasureTwo) {
            $.getJSON(
                generateHistoricalJsonPath(
                    section_or_station,
                    geoObjId,
                    Full2Abbr[measureTwo],
                    interval,
                    startTimeStr,
                    endTimeStr,
                    curVehScheme,
                    curVehClass
                ),
                function (data) {
                    measureTwoData = data;
                }
            );
        }
        origSecondData = $.extend(true, {}, measureTwoData);
        $.ajaxSettings.async = true;
    } else {
        // no need to reload data
        measureTwoData = isEmpty(origSecondData)
            ? null
            : $.extend(true, {}, origSecondData);
    }

    // filter the data, leave the aggregated ones.
    measureOneData = filterHistoricalDataByAggregate(measureOneData, Full2Abbr[measureOne]);
    measureTwoData = filterHistoricalDataByAggregate(measureTwoData, Full2Abbr[measureTwo]);
}

function filterHistoricalDataByAggregate(data, measure) {
    var offset = new Date().getTimezoneOffset() * 60;
    if (new Date().dst()) offset += 3600;
    var retData = [];
    if (data === null || data.length === 0) {
        return retData;
    }

    $.each(data.result, function (key, val) {
        val.timeStr = val.time;
        var d = parseDate(val.time);
        val.time = d.getTime() / 1000 - offset;
        //val.time = d.getTime() / 1000;
        val[measure] = parseFloat(val[measure]);
        retData.push(val);
    });
    return retData;
}

function getLaneTypeName(val, type) {
    if (val.lane_id === undefined) {
        if (val.vmt !== undefined){
            return "Vehicle Miles Traveled";
        }
        else if (val.vht !== undefined){
            return "Vehicle Hours Traveled";
        }
        else if (val.matching_rate !== undefined){
            return "REID Matching Rate (%)";
        }
        else{
            return AggStr;
        }
    }
    if(val.vehclass_scheme === "2"){
        return pollutantId2Name[val.lane_id];
    }
    else{
        if (interval === "1day" || interval_ht === "1day"){
            if (val.vmt !== undefined){
                return "Vehicle Miles Traveled";
            }
            else if (val.vht !== undefined){
                return "Vehicle Hours Traveled";
            }
            else if (val.matching_rate !== undefined){
                return "REID Matching Rate (%)";
            }
            else if ((val.vehclass_scheme == "2" && val.speed !== undefined) || (val.vehclass_scheme == "2" && val.travel_time_index !== undefined) || val.travel_time_index !== undefined || (val.speed !== undefined && type == "section")|| val.travel_time !== undefined){
                return (val.lane_type === "0"
                    ? "All"
                    : laneName2CommoNname[laneTypeId2Name[val.lane_type]]
                );
            }
            else if (val.lcim !== undefined){
                return "DS Lane";
            }
            else{
                return timeSegId2NameAbbr[val.lane_id];
            }
        }
        else{
            if (val.vmt !== undefined){
                return "Vehicle Miles Traveled";
            }
            else if (val.vht !== undefined){
                return "Vehicle Hours Traveled";
            }
            else if (val.matching_rate !== undefined){
                return "REID Matching Rate (%)";
            }
            else if (val.dsLane !== undefined){
                return "DS Lane";
            }
            else{
                return (val.lane_type === "0"
                    ? "All"
                    : laneName2CommoNname[laneTypeId2Name[val.lane_type]]
                );
            }
        }
    }
}

function getLanesInfo(data, laneInfo) {
    if (data === undefined || data === null || data.length === 0) {
        return laneInfo;
    }
    var laneNameCount = {}, laneNameMinId = {};
    $.each(data, function (key, val) {
        var laneName = getLaneTypeName(val);
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
            /*var name = (laneName === "Total"
                ? laneName
                : laneName + (parseInt(id) - laneNameMinId[laneName] + 1).toString()
            );*/
            if (vehClassScheme === "2" || laneName == "Vehicle Miles Traveled" || laneName == "Vehicle Hours Traveled" || laneName == "REID Matching Rate (%)"){
                var name = laneName;
            }
            else{
                if (interval_ht === "1day"){
                    var name = laneName;
                }
                else{
                    var name = (laneName === "All"
                        ? laneName
                        : laneName + (parseInt(id) - laneNameMinId[laneName] + 1).toString()
                    );
                }
            }
            laneInfo[name] = id;
            laneId2Name[id] = name;
        }
    }
    return laneInfo;
}

function makeLanesSelect(laneInfo) {
    var lanesCheckBox = removeAllFromElementId("lanes-check-box");
    var noDataNotification = removeAllFromElementId("no-data-notification");
    if (isEmpty(laneInfo)) {
        noDataNotification.innerHTML = "<h4><strong>No Data Found</strong></h4>";
    }
    // Add Lanes Label
    if (interval_ht === "1day"){
        addLabel(lanesCheckBox, 'Start Hr:', "col-xs-1");
    }
    else{
        addLabel(lanesCheckBox, 'Lanes:', "col-xs-1");
    }

    // Add check boxes
    $.each(laneInfo, function (key, val) {
        var checked;
        if (lastChecked[val] === undefined) {
            // by default, initially, we check the checkbox
            lastChecked[val] = true;
            checked = true;
        } else {
            // otherwise, use the last saved results.
            // The result is updated each time the checkbox is changed
            checked = lastChecked[val];
        }
        if (key === "All"){
            addCheckBox(lanesCheckBox, key.replace(/ /g, '_'), key, "do-plot", "col-xs-2", false);
        }else{
            addCheckBox(lanesCheckBox, key.replace(/ /g, '_'), key, "do-plot", "col-xs-2", checked);
        }
    });
}

function getPollutantInfo(data) {
    if (trafficMode) {
        return;
    }
    if (data === null || data.length === 0) {
        return;
    }

    pollutantInfo = {};
    $.each(data, function (key, val) {
        var pollutant_id = val.pollutant_id;
        pollutantInfo[pollutantId2Name[pollutant_id]] = pollutant_id;
    });
}

function makePollutantSelect() {
    var pollutantsCheckBox = removeAllFromElementId("pollutant-check-box");
    var noDataNotification = removeAllFromElementId("no-data-notification");
    if (isEmpty(pollutantInfo)) {
        noDataNotification.innerHTML = "<h4><strong>No Data Found</strong></h4>";
    }
    // Add Lanes Label
    addLabel(pollutantsCheckBox, 'Pollutants:', "col-xs-1");

    // Add check boxes
    $.each(pollutantInfo, function (key, val) {
        var checked;
        if (lastCheckPollutants[val] === undefined) {
            // by default, initially, we check the checkbox
            lastCheckPollutants[val] = true;
            checked = true;
        } else {
            // otherwise, use the last saved results.
            // The result is updated each time the checkbox is changed
            checked = lastCheckPollutants[val];
        }
        addCheckBox(pollutantsCheckBox, key.replace(/ /g, '_'), key, "do-plot", "col-xs-2", checked);
    });
}

function filterTime(data, startTime, endTime, selectedDay) {
    var ret = [];
    var offset = new Date().getTimezoneOffset() * 60000;
    if (new Date().dst()){
        offset += 60 * 60000;
    }
    $.each(data, function (index, metric) {
        var day = new Date(metric.time * 1000 + offset).getDay();
        if (selectedDay[day]) { // metric.time >= startTime && metric.time <= endTime &&
            ret.push(metric);
        }
    });
    return ret;
}

function filterLaneJson2plotdata(data, selectedLanes, measure) {
    var ret = {};
    if (trafficMode) {
        $.each(selectedLanes, function (index, selectedLane) {
            if (selectedLane) {
                ret[index] = [];
            }
        });
        $.each(data, function (index, val) {
            var laneName = laneId2Name[val.lane_id];
            laneName = laneName === undefined ? "Agg" : laneName;
            if (selectedLanes[laneName]) {
                if (new Date(data[0].time*1000).dst()){
                    ret[laneName].push([(val["time"]+3600) * 1000, val[measure]]);
                }
                else{
                     ret[laneName].push([(val["time"]) * 1000, val[measure]]);
                }
            }
        });
    } else {
        $.each(data, function (index, val) {
            var pollutantName = pollutantId2Name[val.pollutant_id];
            var laneName = laneId2Name[val.lane_id];
            if (selectedLanes[laneName] || laneName === undefined) {
                if (ret[pollutantName] === undefined) {
                    ret[pollutantName] = [];
                }
                if (new Date(data[0].time*1000).dst()){
                    ret[laneName].push([(val["time"]+3600) * 1000, val[measure]]);
                }
                else{
                     ret[laneName].push([(val["time"]) * 1000, val[measure]]);
                }
            }
        });
    }

    var return_data = [];
    $.each(ret, function (index, metric) {
        return_data.push({
            "data": metric,
            "name": index,
            lines: {
                lineWidth: 1
            }
        });
    });
    return return_data;
}

function joinTwoMeaures(data_one, data_two) {
    var retData = [];
    for (var lane in data_one) {
        if (data_two[lane] !== undefined && data_two[lane].data.length > 0
            && data_one[lane].data.length > 0) {
            retData[lane] = [];
        }
    }

    for (var lane in retData) {
        var laneDataOne = data_one[lane]["data"];
        var laneDataTwo = data_two[lane]["data"];
        var data = {data: [], name: data_one[lane]["name"], lines: {}};
        for (var index in laneDataOne) {
            data["data"].push([laneDataTwo[index][1], laneDataOne[index][1]]);
        }
        retData[lane] = data;
    }

    return retData;
}

function filterPollutantData(data, selectedPollutants) {
    var retData = [];

    $.each(data, function (index, val) {
        if (selectedPollutants[val.pollutant_id]) {
            retData.push(val);
        }
    });

    return retData;
}



function appendArray(target, source) {
    if (source.length === 0) {
        return;
    }
    for (var index in source) {
        target.push($.extend(true, {}, source[index]));
    }
}

function HPMS_HistoricalAggregater(allData) {
    if (allData.data.length === 0) {
        return;
    }
    var data = allData.data;
    var metric = allData.metric;
    var volume = allData.volume;
    var retData = {};
    var index_vD = -1;
    /*for (var id in VehClassId2Name) {
        midData[id] = {};
        volumeData[id] = {};
    }*/
    if (metric === "volume"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD = -1;
                        pre_vehId = vehId;
                    }
                    index_vD += 1;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.volume = parseFloat(datum.volume);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                    } else {
                        //console.log(index, datum.volume);
                        retData[index_vD].volume += parseFloat(datum.volume);
                    }
                }
            }
        }
    }
    if (metric === "occupancy"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD = -1;
                        pre_vehId = vehId;
                    }
                    index_vD += 1;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.occupancy = parseFloat(datum.occupancy);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                        var temp = parseFloat(retData[index_vD].occupancy);
                        retData[index_vD].occupancy = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        retData[index_vD].occupancy += parseFloat(datum.occupancy);
                        var temp = parseFloat(retData[index_vD].occupancy);
                        retData[index_vD].occupancy = temp.toFixed(1);
                    }
                }
            }
        }
    }
    if (metric === "speed"){
        var pre_vehId = -2;
        if (data !== undefined || data !== null) {
            for (index in data) {
                var datum = data[index];
                if (datum.vehclass_scheme === FHWA_ID) {
                    var vehId = VehClass_FHWA2HPMS[datum.vehclass_id];
                    var laneId = datum.lane_id;
                    if (pre_vehId !== vehId){
                        index_vD = -1;
                        pre_vehId = vehId;
                    }
                    index_vD += 1;
                    if (retData[index_vD] === undefined) {
                        datum.vehclass_id = vehId;
                        datum.speed = parseFloat(datum.speed);
                        retData[index_vD] = datum;
                        //volumeData[vehId][laneId].vehclass_scheme = '3';
                        retData[index_vD].vehclass_scheme = '3'; 
                        var temp = parseFloat(retData[index_vD].speed);
                        retData[index_vD].speed = temp.toFixed(1);
                    } else {
                        //console.log(index, datum.volume);
                        retData[index_vD].speed += parseFloat(datum.speed);
                        var temp = parseFloat(retData[index_vD].speed);
                        retData[index_vD].speed = temp.toFixed(1);
                    }
                }
            }
        }
    }
    if (metric == "travel_time_index" || metric == "lcim"){
        return data;
    }
    return retData;
    

    // key: time str, value: object: {key: lane_id, datum}
    /*var midData = {};
    var volumeData = {};
    
    if (volume !== undefined || volume !== null) {
        for (index in volume) {
            var datum = volume[index];
            var timeStr = datum.timeStr === undefined ? datum.time : datum.timeStr;
            var laneId = datum.lane_id;
            if (volumeData[timeStr] === undefined) {
                volumeData[timeStr] = {};
            }
            if (volumeData[timeStr][laneId] === undefined) {
                datum.volume = parseFloat(datum.volume);
                volumeData[timeStr][laneId] = datum;
            } else {
                //console.log(index, datum.volume);
                volumeData[timeStr][laneId].volume += parseFloat(datum.volume);
            }
        }
    }

    function getVolume(timeStr, laneId) {
        var ret = volume === undefined || volumeData[timeStr][laneId].volume === 0.0
            ? 1.0
            : volumeData[timeStr][laneId].volume;
        return ret === undefined || ret === null
            ? 1.0
            : ret;
    }

    for (var index in data) {
        var datum = data[index];
        var timeStr = datum.timeStr;
        var laneId = datum.lane_id;
        if (midData[timeStr] === undefined) {
            midData[timeStr] = {};
        }
        if (midData[timeStr][laneId] === undefined) {
            datum.num = getVolume(timeStr, laneId);
            datum[metric] = parseFloat(datum[metric]);
            midData[timeStr][laneId] = datum;
        } else {
            var value = midData[timeStr][laneId][metric];
            var num = midData[timeStr][laneId].num;
            value = (value * num + parseFloat(datum[metric])) / (num + getVolume(timeStr, laneId));
            midData[timeStr][laneId][metric] = value;
            midData[timeStr][laneId].num = num + getVolume(timeStr, laneId);
        }
    }

    var retData = [];
    for (var timeStr in midData) {
        for (var laneId in midData[timeStr]) {
            midData[timeStr][laneId][metric] = parseFloat(midData[timeStr][laneId][metric]).toFixed(8);
            retData.push(midData[timeStr][laneId]);
        }
    }

    return retData;*/
}

function loadHPMSData(section_or_station, geoObjId,
                      reloadDataOne, reloadDataTwo) {
    reloadVehClassList(HPMS_ID);
    // get load veh class ids
    var text = getOptionNameFromSelectId("historical-vehclass-select");
    var curVehClassId = VehClassName2Id[text];
    var loadVehClassIds = VehClass_HPMS2FHWA[curVehClassId];

    if (reloadDataOne === true || reloadDataTwo === true) {
        var firstMetricDataLoaded = [];
        var secondMetricDataLoaded = [];
        for (var vehClassId in loadVehClassIds) {
            loadHistoricalMeasures(section_or_station, geoObjId,
                true, true, FHWA_ID, loadVehClassIds[vehClassId]);
            appendArray(firstMetricDataLoaded, measureOneData);
            appendArray(secondMetricDataLoaded, measureTwoData);
        }
        measureOneData = [], measureTwoData = [];
        origFirstData = [], origSecondData = [];
        appendArray(measureOneData, firstMetricDataLoaded);
        appendArray(measureTwoData, secondMetricDataLoaded);
        appendArray(origFirstData, firstMetricDataLoaded);
        appendArray(origSecondData, secondMetricDataLoaded);
    } else {
        measureOneData = [], measureTwoData = [];
        appendArray(measureOneData, origFirstData);
        appendArray(measureTwoData, origSecondData);
    }

    // get measure
    var measureOne = getOptionNameFromSelectId("historical-measure-select-one");
    var measureTwo = getOptionNameFromSelectId("historical-measure-select-two");
    var measureOneAbbr = Full2Abbr[measureOne];
    var measureTwoAbbr = Full2Abbr[measureTwo];

    var allDataOne = {data: measureOneData, metric: measureOneAbbr};
    var allDataTwo = {data: measureTwoData, metric: measureTwoAbbr};

    function loadVolumeData() {
        if (clickedSection === true) {
            return;
        } else {
            if (measureOneAbbr === 'volume') {
                allDataOne.volume = measureOneData;
                allDataTwo.volume = measureOneData;
            } else if (measureTwoAbbr === 'volume') {
                allDataOne.volume = measureTwoData;
                allDataTwo.volume = measureTwoData;
            } else {
                allDataOne.volume = [];
                // get start / end time stamp
                var startTime = getDateTime('datetimepicker1');
                var endTime = getDateTime('datetimepicker2');
                var startTimeStr = formatDate(startTime);
                var endTimeStr = formatDate(endTime);
                for (var vehClassId in loadVehClassIds) {
                    $.ajaxSettings.async = false;
                    $.getJSON(
                        generateHistoricalJsonPath(
                            section_or_station,
                            geoObjId,
                            'volume',
                            getInterval(),
                            startTimeStr,
                            endTimeStr,
                            FHWA_ID,
                            vehClassId
                        ),
                        function (data) {
                            appendArray(allDataOne.volume, data.result);
                        }
                    );
                    $.ajaxSettings.async = true;
                }
                allDataTwo.volume = allDataOne.volume;
            }
        }
    }

    // load volume data
    loadVolumeData(allDataOne, allDataTwo);

    // aggregate data
    measureOneData = HPMS_HistoricalAggregater(allDataOne);
    measureTwoData = HPMS_HistoricalAggregater(allDataTwo);
}

// entrance
function plotHistoricalMeasures(section_or_station, geoObjId, reloadLaneInfo,
                                reloadDataOne, reloadDataTwo) {
    $("#loading-modal").show();
    $("#lanes-check-box").hide();
    $("#download-button").hide();
    getInterval();
    var text = getOptionNameFromSelectId("historical-vehscheme-select");
    var curVehClassSchemeId = vehClassScheme[text];
    //removeAllFromElementId("historical-chart-title");
    //removeAllFromElementId("historical-chart-time");
    var measureOne = getOptionNameFromSelectId("historical-measure-select-one");
    var measureTwo = getOptionNameFromSelectId("historical-measure-select-two");
    /*var chart_title_id = document.getElementById("historical-chart-title");
    var pos = /[A-z]+/.exec(interval_ht).index;
    if (measureTwo == "None"){
        var text = [
            interval_ht.slice(0, pos), '-',
            interval_ht.charAt(pos).toUpperCase(),
            interval_ht.slice(pos + 1), ' ',
            measureOne,' Figure'
        ].join('');
    }
    else{
        var text = [
            interval_ht.slice(0, pos), '-',
            interval_ht.charAt(pos).toUpperCase(),
            interval_ht.slice(pos + 1), ' ',
            measureOne,' vs. ', measureTwo, ' Figure'
        ].join('');
    }
    addLabel(chart_title_id, text, "chart-title");
    var chart_time_id = document.getElementById("historical-chart-time");
    var text = [
            //getDateTime("datetimepicker1"), '-',
            //getDateTime("datetimepicker2")
            $('#datetimepicker1').data().date, ' PT -- ',
            $('#datetimepicker2').data().date, ' PT'
        ].join('');
    addLabel(chart_time_id, text, "chart-title");*/
    if (curVehClassSchemeId === FHWA_ID ||
        curVehClassSchemeId === EMFAC2007) {
        var text = getOptionNameFromSelectId("historical-vehclass-select");
        var curVehClassId = VehClassName2Id[text];
        loadHistoricalMeasures(section_or_station, geoObjId,
            reloadDataOne, reloadDataTwo, FHWA_ID, curVehClassId);
    } else if (curVehClassSchemeId === HPMS_ID) {
        loadHPMSData(section_or_station, geoObjId,
            reloadDataOne, reloadDataTwo);
    } else {
        // this case is impossible
        $("#loading-modal").hide();
        return;
    }
    PreprocessLoadedData(reloadLaneInfo);

    // begin plot
    var plot_id = "#station-plot";
    var width = 1015;
    //var width = Math.min($(window).width())*0.6;
    if (document.body.clientWidth < 992) {
        width = Math.min($(window).width(), 800);
    }
    //width = width / 16 * 14.5;
    $(plot_id).height(width / 16 * 7);////reduce plot height for bigger chart legend
    $(plot_id).width(width);

    // get selected days: starting from Sunday
    var selectedDay = [];
    selectedDay.push(document.getElementById('SunCheckBox').checked);
    selectedDay.push(document.getElementById('MonCheckBox').checked);
    selectedDay.push(document.getElementById('TueCheckBox').checked);
    selectedDay.push(document.getElementById('WedCheckBox').checked);
    selectedDay.push(document.getElementById('ThuCheckBox').checked);
    selectedDay.push(document.getElementById('FriCheckBox').checked);
    selectedDay.push(document.getElementById('SatCheckBox').checked);

    // get selected lanes
    var selectedLanes = {};
    if (curVehClassSchemeId === EMFAC2007){
        $.each(laneInfo, function (key, val) {
            var id = key.replace(/ /g, '_');
            selectedLanes[key] = "Passenger Cars";
        });
    }
    else{
        $.each(laneInfo, function (key, val) {
        var id = key.replace(/ /g, '_');
        //selectedLanes[key] = document.getElementById(id).checked;
        selectedLanes[key] = true;
    });
    }
    

    // get selected pollutants
    if (!trafficMode) {
        var selectedPollutants = {};
        $.each(pollutantInfo, function (key, val) {
            var id = key.replace(/ /g, '_');
            selectedPollutants[val] = document.getElementById(id).checked;
        });
        measureOneData = filterPollutantData(measureOneData, selectedPollutants);
        measureTwoData = filterPollutantData(measureTwoData, selectedPollutants);
    }

    // get measure
    var measureOne = getOptionNameFromSelectId("historical-measure-select-one");
    var measureTwo = getOptionNameFromSelectId("historical-measure-select-two");
    var measureOneAbbr = Full2Abbr[measureOne];
    var measureTwoAbbr = Full2Abbr[measureTwo];
    
    // get start time and end time
    var startTime = getDateTime('datetimepicker1') / 1000;
    var endTime = getDateTime('datetimepicker2') / 1000;

    // filter data
    measureOneData = filterTime(measureOneData, startTime, endTime, selectedDay);
    measureOneData = filterLaneJson2plotdata(measureOneData, selectedLanes, measureOneAbbr);
    /*var colNames = {}
    for (var i in laneId2Name){
        colNames[laneId2Name[i]] = parseInt(i)+1;
    }
    measureOneData.push({colNames: colNames});
    measureOneData.push({metric: measureOne});
    if (document.getElementById("historical-table-radio").checked){
        $("#historical-table").show();
         makeTable_hs(measureOneData);
    }
    else{
        $("#historical-table").hide();
    }*/
    $("#historical-table").hide();
    // plot
    if (measureTwo === NoneMeasureTwo || measureTwo === "" || measureTwo === undefined || measureTwo === null) {
        /*if (metric == "vmt" || metric == "vht" || metric == "matching_rate"){
            var GPidx = 0;
            var HOV1idx = 0;
        }
        else{
            var GPidx = laneInfo["Lane1"];
            if (GPidx == undefined) GPidx = laneInfo["Through1"];
            var HOV1idx = laneInfo["HOV1"];
            var HOV2idx = laneInfo["HOV2"];
            if (HOV1idx == undefined) HOV1idx = GPidx;
            if (HOV2idx == undefined) HOV2idx = GPidx;
        }*/
        $("#station-plot").highcharts({
        chart: {
            type: 'line',
            events: {
                load: function(){
                    this.series[measureOneData.length-1].hide();
                }
            }
        },
        title: {
            text: getChartTitleHS()
        },
        subtitle: {
            text: getSubTitle()
        },
        xAxis: {
            type: 'datetime',
            labels: {
                format: '{value:%m/%d<br>%H:%M}'
            }
            //startOnTick: true,
            //endOnTick: true
        },
        yAxis: {
            title:{
                text:getUnits(measureOne, interval_ht)
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
        series: measureOneData
    });
        /*
        // set the option
        var options = {
            xaxis: {mode: "time"},
            yaxis: {
                min: 0
            },
            series: {
                lines: {show: true},
                points: {show: false}
            },
            yaxes: [{
                position: 'left',
                axisLabel: getUnits(measureOne, interval_ht)
            }],
            legend: {
                noColumns: 10,
                container: $("#chartLegend")
            },
            grid:{
                borderWidth : 3
            }
        };

        $.plot(plot_id,
            measureOneData,
            options
        );
        */
    } else {
        measureTwoData = filterTime(measureTwoData, startTime, endTime, selectedDay);
        measureTwoData = filterLaneJson2plotdata(measureTwoData, selectedLanes, measureTwoAbbr);
        measureOneData = joinTwoMeaures(measureOneData, measureTwoData);
        
        $("#station-plot").highcharts({
            chart: {
                type: 'scatter',
                events: {
                    load: function(){
                        this.series[measureOneData.length-1].hide();
                    }
                }
            },
            title: {
                text: getChartTitleHS()
            },
            subtitle: {
                text: getSubTitle()
            },
            xAxis: {
                title:{
                    text: getUnits(measureTwo, interval_ht)
                }
            },
            yAxis: {
                title:{
                    text:getUnits(measureOne, interval_ht)
                }
            },
            plotOptions: {
                scatter: {
                    marker: {
                        radius: 3,
                        states: {
                            hover: {
                                enabled: true,
                                lineColor: 'rgb(100,100,100)'
                            }
                        }
                    },
                    states: {
                        hover: {
                            marker: {
                                enabled: false
                            }
                        }
                    },
                    tooltip: {
                        headerFormat: '<b>{series.name}</b><br>',
                        pointFormat: measureTwo + ':{point.x}, ' + measureOne + ':{point.y}'
                    }
                }
            },
            series: measureOneData
        });
        
        // set the option
        /*var options = {
            axisLabels: {
                show: true
            },
            xaxes: [{
                axisLabel: getUnits(measureTwo, interval_ht)
            }],
            yaxes: [{
                position: 'left',
                axisLabel: getUnits(measureOne, interval_ht)
            }],
            series: {
                lines: {show: false},
                points: {show: true}
            },
            legend: {
                noColumns: 10,
                container: $("#chartLegend")
            },
            grid:{
                borderWidth : 3
            }
        };

        $.plot(plot_id,
            measureOneData,
            options
        );*/
    }
    
    //removeAllFromElementId("lanes-check-box");
    $("#loading-modal").hide();
    $("#download-button").show();
}

$("#plot-button").click(function () {
    $("#press-plot-btn").addClass('hidden');
    if (clickedSection) {
        plotHistoricalMeasures(SectionStr, clickedSectionID, true, true, true);
    } else {
        plotHistoricalMeasures(StationStr, clickedStationID, true, true, true);
    }
});

function getChartTitleHS(){
    var pos = /[A-z]+/.exec(interval_ht).index;
    var text = [
            interval_ht.slice(0, pos), '-',
            interval_ht.charAt(pos).toUpperCase(),
            interval_ht.slice(pos + 1), ' ',
            getOptionNameFromSelectId("historical-measure-select-one")
    ].join('');
    var metric2 = getOptionNameFromSelectId("historical-measure-select-two");
    if (metric2 !== "None"){
        text = [
            text, ' vs. ',
            metric2
        ].join('');
    }
    return text;  
}

function getSubTitle(){
    var res = [
        startTimeStr, ' -- ',
        endTimeStr
    ].join('');
    return res;
}

function examDateTimeInput() {
    if (this.id === "datetimepicker1" || this.id === "datetimepicker2") {
        // never allow start time is bigger than end time
        var startTime = getDateTime('datetimepicker1');
        var endTime = getDateTime('datetimepicker2');

        if (startTime >= endTime) {
            this.id.indexOf("datetimepicker1") > -1
                ? setDateTime(adjustHours(startTime, 1), 'datetimepicker2')
                : setDateTime(adjustHours(endTime, -1), 'datetimepicker1')
        }

        // get the intervals
        var interval = getInterval();

        if (endTime - startTime > IntervalTimeSpan[interval]) {
            measureOneData = [];
            measureTwoData = [];

            alert("You can only query no more than " +
                IntervalTimeSpanStr[interval] +
                " for the interval " + Interval2Space[interval]
            );
            return false;
        }
    }

    return true;
}

$("#datetimepicker1").on("dp.change", function (e) {
    if (firstTimeStartCounter <= 1) {
        firstTimeStartCounter += 1;
        return;
    }
    examDateTimeInput.call(this);
    $("#press-plot-btn").removeClass('hidden');
});

$("#datetimepicker2").on("dp.change", function (e) {
    if (firstTimeStartCounter <= 1) {
        firstTimeStartCounter += 1;
        return;
    }
    examDateTimeInput.call(this);
    $("#press-plot-btn").removeClass('hidden');
});

function replot() {
    $("#press-plot-btn").addClass('hidden');

    var validatedDateTime = examDateTimeInput.call(this);
    if (validatedDateTime === false) {
        return;
    }

    var reloadDataOne, reloadDataTwo;
    reloadDataOne = isEmpty(origFirstData);
    reloadDataOne = reloadDataOne || this.id === "historical-measure-select-one" || changeSectionStation;
    reloadDataTwo = (this.id === "historical-measure-select-two") || changeSectionStation;
    changeSectionStation = false;
    if (this.id === "datetimepicker1" || this.id === "datetimepicker2" ||
        this.name === "interval" ||
        this.id === "historical-vehclass-select"
    ) {
        reloadDataOne = true;
        reloadDataTwo = true;
    }
    if (clickedSection) {
        plotHistoricalMeasures(SectionStr, clickedSectionID, true, reloadDataOne, reloadDataTwo);
    } else {
        plotHistoricalMeasures(StationStr, clickedStationID, true, reloadDataOne, reloadDataTwo);
    }
}

function makeTable_hs(tableData) {
    var table = document.getElementById("historical-table");
    clearTable(table);
    createTableHeader(table, tableData["colNames"]);
    createTableRows(table, tableData);
}

$(".do-plot").change(replot);

$("#historical-vehscheme-select").change(function () {
    var text = getOptionNameFromSelectId("historical-vehscheme-select");
    var curVehClassSchemeId = vehClassScheme[text];
    makeVehClassSelector("historical-vehclass-select", curVehClassSchemeId);
    if (curVehClassSchemeId === FHWA_ID){
        document.getElementById("historical-vehclass-select").selectedIndex = "14";
    }
    if (curVehClassSchemeId === HPMS_ID){
        document.getElementById("historical-vehclass-select").selectedIndex = "7";
    }
    if (clickedSection) {
        plotHistoricalMeasures(SectionStr, clickedSectionID, true, true, true);
    } else {
        plotHistoricalMeasures(StationStr, clickedStationID, true, true, true);
    }
});

function rePlotWithoutChangeLaneInfo() {
    getInterval();
    if (trafficMode) {
        var laneName = this.id.replace("_", " ");
        var laneId = laneInfo[laneName];
        lastChecked[laneId] = this.checked;
    } else {
        var pollutantName = this.id;
        var pollutantId = pollutantInfo[pollutantName];
        lastCheckPollutants[pollutantId] = this.checked;
    }

    if (clickedSection) {
        plotHistoricalMeasures(SectionStr, clickedSectionID, false, false, false);
    } else {
        plotHistoricalMeasures(StationStr, clickedStationID, false, false, false);
    }
}

function adjustHours(date, n) {
    date.setHours(date.getHours() + n);
    return date;
}

function setDateTime(dateTime, date_id) {
    $('#' + date_id).data("DateTimePicker").date(dateTime);
}

function getDateTime(date_id) {
    var datetime = $('#' + date_id).data().date;
    return parseDateTime(datetime);
}

function dateInit() {
    // set time date
    var text = getOptionNameFromSelectId("realtime-vehclassscheme-selector");
    var curVehClassSchemeId = vehClassScheme[text];
    if (curVehClassSchemeId === "2"){
        $('#datetimepicker1').data("DateTimePicker").date("11/23/2014 12:00 AM");
        $('#datetimepicker2').data("DateTimePicker").date("11/28/2014 12:00 AM");
    }
    else{
        var yesDate = new Date().getDate();
        yesDate -= 7;
        var startDate = new Date();
        startDate.setDate(yesDate);
        startDate.setHours(0,0,0,0);
        $('#datetimepicker1').data("DateTimePicker").date(startDate);
        //more change needed!!!!!!!!!
        var endDate = new Date();
        endDate.setHours(0,0,0,0);
        $('#datetimepicker2').data("DateTimePicker").date(endDate);
    }
}

function parseDateTime(timeStr) {
    var dateTime = timeStr.split(" ");
    var date = dateTime[0], time = dateTime[1];
    var dateArray = date.split("/"), timeArray = time.split(":");

    var month = parseInt(dateArray[0]), day = parseInt(dateArray[1]),
        year = parseInt(dateArray[2]), hour = parseInt(timeArray[0]),
        minute = parseInt(timeArray[1]), am_pm = dateTime[2];

    var d = new Date();
    d.setFullYear(year, month - 1, day);
    if (am_pm === 'AM' && hour === 12) {
        hour = 0;
    } else if (am_pm === "PM") {
        hour += 12;
    }
    d.setHours(hour, minute, 0);
    return d;
}

function parseDate(timeStr) {
    var dateTime = timeStr.split(" ");
    var date = dateTime[0];
    var dateArray = date.split("-");
    var year = parseInt(dateArray[0]), month = parseInt(dateArray[1]),
        day = parseInt(dateArray[2]);
    if (interval === "1day"){
        var hour = 0, minute = 0, second = 0;
    }
    else{
        var time = dateTime[1];
        var timeArray = time.split(":");
        var hour = parseInt(timeArray[0]),
            minute = parseInt(timeArray[1]), second = parseInt(timeArray[2]);
    }
    var d = new Date();
    d.setFullYear(year, month - 1, day);
    d.setHours(hour, minute, second);
    return d;
}

function formatDate(timeNow) {
    var month = timeNow.getMonth() + 1;
    var hours = timeNow.getHours();
    var minutes = timeNow.getMinutes();
    var seconds = timeNow.getSeconds();
    hours = (hours < 10) ? "0" + hours.toString() : hours.toString();
    minutes = (minutes < 10) ? "0" + minutes.toString() : minutes.toString();
    seconds = (seconds < 10) ? "0" + seconds.toString() : seconds.toString();
    return timeNow.getFullYear().toString() +
        "-" + month.toString() + "-" + timeNow.getDate().toString() +
        " " + hours + ":" + minutes + ":" + seconds;
}


$("#download-button").click(function () {
    // get measure
    var measureOne = getOptionNameFromSelectId("historical-measure-select-one");
    var measureTwo = getOptionNameFromSelectId("historical-measure-select-two");

    if (measureTwo === NoneMeasureTwo) {
        measureTwo = measureOne;
        measureOne = "Time";
    } else {
        var temp = measureOne;
        measureOne = measureTwo;
        measureTwo = temp;
    }
    var csv = JSON2CSV(measureOneData, measureOne, measureTwo);
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
    var filename = "historical_data_" + appendTimeStr + ".csv";
    link.setAttribute("download", filename);
    document.body.appendChild(link); // Required for FF
    link.click();
});

