
function isDryRun() {
    var ip = location.host;
    return ip.indexOf("localhost") > -1 || dryRunMode;
}

function generateJsonPath(filename) {
    if (isDryRun()) {
        return "data/" + filename;
    } else {
        return "api/" + filename;
    }
}

function generateRealtimeJsonPath(corridorId, interval) {
    if (isDryRun()) {
        //need change here!!!!!!!!!!
        return "data/realtime_data" + corridorId;
    } else {
        return "api/getMeasuresRT?corridor_id=" + corridorId + "&aggint=" + interval;
    }
}

function generateHistoricalJsonPath(section_or_station,
                                    id,
                                    measure,
                                    interval,
                                    startTimeStr,
                                    endTimeStr,
                                    vehSchemeClass,
                                    vehClass) {
    if (isDryRun()) {
        return "data/getMeasureHT" + section_or_station +
            id.toString() + measure + interval;
    } else {
        return "api/getMeasuresHT?type=" + section_or_station +
            "&id=" + id +
            "&measure=" + measure +
            "&aggint=" + interval +
            "&start_time=" + startTimeStr +
            "&end_time=" + endTimeStr +
            "&vehschemeclass=" + vehSchemeClass +
            "&vehclass=" + vehClass;
    }
}

function generateADPJsonPath(start_time, end_time, interval, station_id){
    return "api/ADP?start_time=" + start_time +
            "&end_time=" + end_time +
            "&interval=" + interval +
            "&station_id=" + station_id;
}

function removeAllFromElement(element) {
    while (element.firstChild) {
        element.removeChild(element.firstChild);
    }
    return element;
}

function removeAllFromElementId(elementId) {
    var element = document.getElementById(elementId);
    return removeAllFromElement(element);
}

function addLabel(element, text, className) {
    var labelHtml = '<label>' + text + '</label>';
    var div = document.createElement('div');
    div.classList.add(className);
    div.innerHTML = labelHtml;
    element.appendChild(div);
}

function addCheckBox(element, id, text, checkboxClassName, styleClassName, checked) {
    var checkBoxHtml = '<input type="checkbox" id="' + id;
    if (checked) {
        checkBoxHtml += '" checked>' + text;
    } else {
        checkBoxHtml += '">' + text;
    }
    var div = document.createElement('div');
    div.classList.add(styleClassName);
    var divInner = document.createElement('div');
    divInner.classList.add("input-group");
    divInner.innerHTML = checkBoxHtml;
    divInner.firstChild.addEventListener("change", rePlotWithoutChangeLaneInfo);
    div.appendChild(divInner);
    element.appendChild(div);
}

function addRadioToForm(form, name, radioValue, radioText, radioId, checked) {
    var radioHtml = '<input type="radio" name="' + name +
        '" value="' + radioValue +
        '" id="' + radioId + '"';
    if (checked) {
        radioHtml += ' checked="checked"';
    }
    radioHtml += '>' + '<label for="' + radioValue + '">' + radioText + '</label>';

    var radioFragment = document.createElement('div');
    radioFragment.innerHTML = radioHtml;

    form.appendChild(radioFragment.firstChild);
    form.appendChild(radioFragment.lastChild);
}

function addRadioToFormId(formId, name, radioValue, radioText, radioId, checked) {
    var form = document.getElementById(formId);
    addRadioToForm(form, name, radioValue, radioText, radioId, checked);
}

function removeAllFromSelect(select) {
    var num = select.length;
    while (num > 0) {
        --num;
        select.remove(0);
    }
}

function removeAllFromSelectId(selectId) {
    var select = document.getElementById(selectId);
    removeAllFromSelect(select);
}

function addOptionToSelect(select, optionText) {
    var option = document.createElement("option");
    option.text = optionText;
    select.add(option);
}

function addOptionToSelectId(selectId, optionText) {
    var select = document.getElementById(selectId);
    addOptionToSelect(select, optionText);
}

function getOptionNameFromSelect(select) {
    return select.options[select.selectedIndex].text;
}

function getOptionNameFromSelectId(selectId) {
    var select = document.getElementById(selectId);
    return getOptionNameFromSelect(select);
}

function clearTable(table) {
    var tableRowsNum = table.rows.length;
    for (var i = 0; i < tableRowsNum; ++i) {
        table.deleteRow(-1);
    }
    table.deleteTHead();
}

function createTableHeader(table, headerStrs) {
    var header = table.createTHead();
    var row = header.insertRow(0);
    var cell = row.insertCell(-1);
    cell.style.padding = '0';
    if (headerStrs[NoDataFoundStr] === undefined) {
        cell.innerHTML = "<strong>" + "&nbsp" + "</strong>";
        cell.classList.add("text-center");
    } else {
        cell.innerHTML = "<strong>" + NoDataFoundStr + "</strong>";
        cell.classList.add("text-center");
        return;
    }
    for (var col in headerStrs) {
        var cell = row.insertCell(-1);
        cell.innerHTML = "<strong>" + col + "</strong>";
        cell.classList.add("text-center");
    }
}

function createTableRows(table, tableData) {
    var cells = [];
    var ColsCnt = Object.keys(tableData.colNames).length;

    var rowNames = [];
    if (tableData.metric === 'travel_time_index') {
        rowNames = {15: "Travel Time Index"};
    }
    else if (tableData.metric === 'lcim'){
        for (var i=0; i<(tableData.data.length/ColsCnt); i++){
            var lcim_lane = "US Lane" + (i+1).toString();
            rowNames.push(lcim_lane);
        }
    }
    else {
        rowNames = VehClassId2Name;
    }
    for (var i in rowNames) {
        var row = table.insertRow(-1);
        var cell = row.insertCell(-1);
        if (tableData.metric === 'travel_time_index'){
            cell.innerHTML = "Travel Time Index";
        }
        else if (tableData.metric === 'lcim'){
            cell.innerHTML = rowNames[i];
        }
        else{
            cell.innerHTML = VehClassId2Name[i];
        }
        cell.classList.add("text-center");
        cell.style.width = '108px';
        cell.style.padding = '0';
        cell.style.height = '20px';
        for (var j in tableData.colNames) {
            var cell = row.insertCell(-1);
            cell.style.height = '20px';
            cell.style.padding = '0';
            cell.style.width = '48px';   
            cells.push(cell);
        }
    }

    var data = tableData.data;
    var metric = tableData.metric;
    if (metric == "vmt" || metric == "vht" || metric == "matching_rate"){
        for (var index in data) {
            var rowNum = parseInt(data[index].vehclass_id);
            var colNum = 0;
            var cell = cells[rowNum * ColsCnt + colNum];
            var value = data[index]['volume'];
            //console.log("rowNum: " + rowNum.toString() + " colNum: " + colNum);
            cell.innerHTML = getHtmlTextFromNullable(value);
            cell.classList.add(getColorCode(value, metric, data[index]["pollutant_id"]));
            cell.classList.add("text-center");
        }
        for (var index in data) {
            var rowNum = parseInt(data[index].vehclass_id);
            var colNum = 1;
            var cell = cells[rowNum * ColsCnt + colNum];
            var value = data[index][metric];
            //console.log("rowNum: " + rowNum.toString() + " colNum: " + colNum);
            cell.innerHTML = getHtmlTextFromNullable(value);
            cell.classList.add(getColorCode(value, metric, data[index]["pollutant_id"]));
            cell.classList.add("text-center");
        }
    }
    else if (metric == "lcim"){
        for (var index in data) {
            var rowNum = parseInt(data[index].usLane);
            var colNum = parseInt(data[index].dsLane);
            var cell = cells[rowNum * ColsCnt + colNum];
            var value = data[index][metric];
            //console.log("rowNum: " + rowNum.toString() + " colNum: " + colNum);
            cell.innerHTML = getHtmlTextFromNullable(value);
            cell.classList.add(getColorCode(value, metric, data[index]["pollutant_id"]));
            cell.classList.add("text-center");
        }
    }
    else{
        for (var index in data) {
            var rowNum = parseInt(data[index].vehclass_id);
            var colNum = parseInt(data[index].lane_id);
            var cell = cells[rowNum * ColsCnt + colNum];
            var value = data[index][metric];
            //console.log("rowNum: " + rowNum.toString() + " colNum: " + colNum);
            cell.innerHTML = getHtmlTextFromNullable(value);
            cell.classList.add(getColorCode(value, metric, data[index]["pollutant_id"]));
            cell.classList.add("text-center");
        }
    }
}

function getColorCode(value, metric, pollutantId) {
    if (value === undefined || value === null) {
        return "active";
    }
    value = parseFloat(value);

    var maxValue;
    if (metric !== "emission_rate" && metric !== "emission") {
        maxValue = Limits[metric];
    } else {
        maxValue = Limits[metric][pollutantId];
    }
    maxValue = parseFloat(maxValue);

    if (ReverseLimits[metric]) {
        maxValue = -maxValue;
        value = -value;
    }

    if (value > maxValue * ColorLevel[1]) {
        return "danger";
    } else if (value > maxValue * ColorLevel[0]) {
        return "warning";
    } else {
        return "success";
    }
}

function getHtmlTextFromNullable(value) {
    return (value === undefined || value === null) ? "&nbsp" : value;
}

var hasOwnProperty = Object.prototype.hasOwnProperty;

function isEmpty(obj) {
    // null and undefined are "empty"
    if (obj == null) return true;

    // Assume if it has a length property with a non-zero value
    // that that property is correct.
    if (obj.length > 0)    return false;
    if (obj.length === 0)  return true;

    // Otherwise, does it have any properties of its own?
    // Note that this doesn't handle
    // toString and valueOf enumeration bugs in IE < 9
    for (var key in obj) {
        if (hasOwnProperty.call(obj, key)) return false;
    }

    return true;
}

function getSpacingPieChart(numCharts, idxChart){
    var spacingStr ;
    if (idxChart == numCharts-1){
        spacingStr = ['10%', '50%'];
    }
    else{
        if(numCharts <= 5){
            var spacing = 100/(numCharts);
            var temp = 33 + spacing*idxChart;
            spacingStr = [temp.toString() + '%', '50%'];
        }
        else{
            var spacing = 20;
            if (idxChart<4){
                var temp = spacing*idxChart + 33;
                spacingStr = [temp.toString() + '%', '18%'];
            }
            else{
                var temp = spacing*(idxChart%4) + 33;
                spacingStr = [temp.toString() + '%', '82%'];
            }
        }
    }
    return spacingStr;
}

function getPieSize(numCharts, idxChart){
    var sizeStr;
    if (idxChart == numCharts-1){
        sizeStr = '70%';
    }
    else{
        sizeStr = '50%';
    }
    return sizeStr;
}
//sub-routine to get current time interval selected
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

function getUnits(metric, interval) {
    if (metric !== 'Volume') {
        return MetricUnits[metric];
    } else {
        var pos = /[A-z]+/.exec(interval).index;

        // capitalize the first letter and
        // add hyphen between number and letter
        interval = [
            interval.slice(0, pos), '-',
            interval.charAt(pos).toUpperCase(),
            interval.slice(pos + 1)
        ].join('');

        // remove last s
        if (interval.slice(-1) === 's') {
            interval = interval.slice(0, -1);
        }

        var unit = MetricUnits[metric].replace(/Interval/, interval);
        return unit;
    }
}

function getDownloadStr(savedData, secstnID, realtime_data){
	var scheme = savedData.data[0].vehclass_scheme;
	if (scheme == FHWA_ID) scheme = "FHWA";
	else if (scheme == HPMS_ID) scheme = "HPMS";
	else scheme = "EMFAC2007";
	
	var secstnStr;
	var secstn = savedData.type;
	secstn = secstn.toString()+"s";
	if (savedData.type == "station") secstnStr = "Station: ";
	else secstnStr = "Section: ";
	secstnStr = secstnStr + realtime_data.result[secstn]["features"][secstnID].properties.name;
	secstnStr = secstnStr + "\r\nTime: " + realtime_data.result.time;
	var str = secstnStr + "\r\nVehicle Class Scheme: "+ scheme + "\r\nClass 14 is the aggregation of all other classes." + "\r\n\r\nlane\t|\tclass\t|\t" + savedData.metric + "\r\n";
	for (var id in savedData.data){
		var datum = savedData.data[id];
		var laneStr = savedData.laneInfo[parseInt(datum.lane_id)];
		var classStr = datum.vehclass_id;
		var metricStr = datum[savedData.metric];
		if (laneStr == "All"){
			str = str + laneStr + "\t\t|\t\t" + classStr + "\t|\t" + metricStr + "\r\n";
		}
		else{
			str = str + laneStr + "\t|\t\t" + classStr + "\t|\t" + metricStr + "\r\n";
		}
	}
	return str;
}

function getDownloadData(savedData,secstnID,realtime_data,interval){
	//vehicle class scheme name
	var scheme = savedData.data[0].vehclass_scheme;
	if (scheme == FHWA_ID) var schemeStr = "Vehicle Class Scheme: FHWA";
	else if (scheme == HPMS_ID) var schemeStr = "Vehicle Class Scheme: HPMS";
	else var schemeStr = "Vehicle Class Scheme: EMFAC2007";
	
	//section or station name
	var secstn = savedData.type;
	secstn = secstn.toString()+"s";
    var secstnStr;
	if (savedData.type == "station"){
        secstnStr = "Station: " + realtime_data.result[secstn]["features"][stationMapping[secstnID]].properties.name;
    }
	else{
        secstnStr = "Section: " + realtime_data.result[secstn]["features"][sectionMapping[secstnID]].properties.name;
    }

	//time string
	var timeStr = realtime_data.result.time;
	var dateTime = timeStr.split(" ");
	var date = dateTime[0], time = dateTime[1];
	var dateArray = date.split("-"),timeArray = time.split(":");
    var month = parseInt(dateArray[1]), day = parseInt(dateArray[2]),
        year = parseInt(dateArray[0]), hour = parseInt(timeArray[0]),
        minute = parseInt(timeArray[1]);
	var d = new Date();
    d.setFullYear(year, month - 1, day);
	d.setHours(hour, minute, 0);
	if (interval == "5min"){ d.setMinutes(minute-5);}
	else if (interval == "15min") { d.setMinutes(minute-15);}
	else if (interval == "1hour") { d.setHours(hour-1);}
	else { d.setDate(d.getDate()-1);}
	timeStr = "Time Period: " + formatDate(d) + " -- " + timeStr;
    var metricStr = "Measurement: " + savedData.metric;
    if (savedData.metric == "speed") metricStr += " (MPH)";
    else if (savedData.metric == "occupancy") metricStr += " (%)";
    else if (savedData.metric == "volume"){
        if (interval != "1day") metricStr += " (veh/" + interval + ")";
        else metricStr += " (veh/hr)";
    }
	//header
	/*var csvData = [["class 0-12 is FHWA class 1-13"],
					["class 13 is unrecognized and class 14 is the aggregation of all the classes"],
					[schemeStr],
					[secstnStr],
					[timeStr],
					["lane","class",savedData.metric]];
                    */
    var csvData = [[schemeStr],
					[secstnStr],
					[timeStr],
                   [metricStr]];
    if (scheme == FHWA_ID){
        if (interval == "1day") csvData.push(["Hour|Class","1","2","3","4","5","6","7","8","9","10","11","12","13","Unrecognized","Total"]);
        else csvData.push(["Lane|Class","1","2","3","4","5","6","7","8","9","10","11","12","13","Unrecognized","Total"]);
        for (var id = 0; id < savedData.data.length; id=id+15){
            var laneStr = savedData.laneInfo[parseInt(savedData.data[id].lane_id)];
            csvData.push([laneStr,savedData.data[id][savedData.metric],savedData.data[id+1][savedData.metric],savedData.data[id+2][savedData.metric],savedData.data[id+3][savedData.metric],savedData.data[id+4][savedData.metric],
                             savedData.data[id+5][savedData.metric],savedData.data[id+6][savedData.metric],savedData.data[id+7][savedData.metric],savedData.data[id+8][savedData.metric],savedData.data[id+9][savedData.metric],
                             savedData.data[id+10][savedData.metric],savedData.data[id+11][savedData.metric],savedData.data[id+12][savedData.metric],savedData.data[id+13][savedData.metric],savedData.data[id+14][savedData.metric]]);
        }
    }
    else if (scheme == HPMS_ID){
        if (interval == "1day") csvData.push(["Hour|Class","1","2","3","4","5","6","Unrecognized","Total"]);
        else csvData.push(["Lane|Class","1","2","3","4","5","6","Unrecognized","Total"]);
        for (var id = 0; id < savedData.data.length; id=id+8)
        {
            var laneStr = savedData.laneInfo[parseInt(savedData.data[id].lane_id)];
            csvData.push([laneStr,savedData.data[id][savedData.metric],savedData.data[id+1][savedData.metric],savedData.data[id+2][savedData.metric],savedData.data[id+3][savedData.metric],savedData.data[id+4][savedData.metric],savedData.data[id+5][savedData.metric],savedData.data[id+6][savedData.metric],savedData.data[id+7][savedData.metric]]);
        }
    }
	return csvData;
}

function JSON2CSV(objArray, measureOne, measureTwo) {
    var array = typeof objArray != 'object' ? JSON.parse(objArray) : objArray;

    var csvData = [['Lane',measureOne,measureTwo]];
    for (var id in array) {
        var laneData = array[id]["data"];
        var laneName = array[id]["name"];
        for (var index in laneData) {
			if (measureOne === "Time"){
				var d = new Date(laneData[index][0]);
                var offset = 8;
                if (d.dst()) offset = 7;
				d.setHours(d.getHours() + offset);
				var xaxisData = formatDate(d);
			}
			else{ var xaxisData = laneData[index][0];}
            var yaxisData = laneData[index][1];
            csvData.push([laneName,xaxisData.toString(),yaxisData.toString()]);
        }
    }
    return csvData;
    /*var str = '';
    var line = '';

    var head = array[0];
    for (var index in array[0]) {
        var value = index + "";
        line += '"' + value.replace(/"/g, '""') + '",';
    }
    line = line.replace("label", "Lanes");
    line = line.replace("lines", "Measures");
    line = line.slice(0, -1);
    str += line + '\r\n';

    for (var i = 0; i < array.length; i++) {
        var line = '';

        for (var index in array[i]) {
            var value = array[i][index] + "";
            line += '"' + value.replace(/"/g, '""') + '",';
        }
        line = line.replace("[object", measureOne + ",");
        line = line.replace("Object]", measureTwo);
        line = line.slice(0, -1);
        str += line + '\r\n';
    }
    return str;*/

}


Date.prototype.stdTimezoneOffset = function() {
    var jan = new Date(this.getFullYear(), 0, 1);
    var jul = new Date(this.getFullYear(), 6, 1);
    return Math.max(jan.getTimezoneOffset(), jul.getTimezoneOffset());
}

Date.prototype.dst = function() {
    return this.getTimezoneOffset() < this.stdTimezoneOffset();
}


function loadHPMSDataLine(data) {
    reloadVehClassList(HPMS_ID);
    // get load veh class ids
    var text = getOptionNameFromSelectId("class-selector");
    var curVehClassId = VehClassName2Id[text];
    var loadVehClassIds = VehClass_HPMS2FHWA[curVehClassId];

    var DataLoaded = [];
    for (var vehClassId in loadVehClassIds) {
        var temp = loadLineData(data, loadVehClassIds[vehClassId]);
            appendArray(DataLoaded, temp);
        }
    measureData = [];
    appendArray(measureData, DataLoaded);
    
    // get measure
    var measure = getOptionNameFromSelectId("metrics-selector");
    var measureAbbr = Full2Abbr[measure];

    var allData = {data: measureData, metric: measureAbbr};

    /*function loadVolumeData() {
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
    loadVolumeData(allDataOne, allDataTwo);*/

    // aggregate data
    measureData = HPMS_HistoricalAggregater(allData);
    
    return measureData;
}


function loadLineData(data, classId) {
    var geoObjId = clickedSection ? clickedSectionID : clickedStationID;
    var text = "FHWA";
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
        startTimeStr = formatDate(startTime);
    }
    var endTime = new Date();
    var endTimeStr = formatDate(endTime);
    
    var lineData = null;
    var curVehClass = classId;
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
    return lineData;
}



