
function getColor(value, metric) {
    var val = parseFloat(value);
    if (metric === "speed") {
        if (val >= 60.) {
            return ColorBar[1];
        } else if (val >= 50.0) {
            return ColorBar[2];
        } else if (val >= 40.0) {
            return ColorBar[3];
        } else {
            return ColorBar[4];
        }
    } else if (metric == 'volume') {
        if (val >= 2000.) {
            return ColorBar[4];
        } else if (val >= 1000.) {
            return ColorBar[3];
        } else if (val >= 500.0) {
            return ColorBar[2];
        } else {
            return ColorBar[1];
        }
    }
    return ColorBar[0];
}

function getRadius(value, metric) {
    var val = parseFloat(value);
    if (val >= 60.) {
        return RadiusBar[3];
    } else if (val >= 50.0) {
        return RadiusBar[2];
    } else if (val >= 40.0) {
        return RadiusBar[1];
    } else {
        return RadiusBar[0];
    }
}

function getPointOptions(values) {
    var metric = $('input[name="map-station-metrics"]:checked').val();
    if (!MetricInStation[metric]) {
        metric = "speed";
    }
    var options = {
        color: ColorBar[0],
        fillColor: ColorBar[0],
        opacity: 0.5,
        fillOpacity: 0.5,
        radius: 10
    };
    var value = values[metric];
    for (var key in value) {
        var val = value[key];
        if (val["lane_id"] === values.no_of_lanes && val["lane_type"] === "0") {
            var metricVal = val[metric];
            options["color"] = getColor(metricVal, metric);
            options["fillColor"] = options["color"];
            options['radius'] = getRadius(metricVal, metric);
            break;
        }
    }
    return options;
}

function specifyStationLayer(layer, values) {
    var options = getPointOptions(values);
    L.Util.setOptions(layer, options);
}

function getLineOptions(values) {
    var metric = $('input[name="map-section-metrics"]:checked').val();
    if (!MetricInSectionsFHWA[metric]) {
        metric = "speed";
    }
    var options = {
        color: ColorBar[0],
        weight: 6,
        opacity: 0.8,
        fillOpacity: 0.7
    };
    var value = values[metric];
    for (var key in value) {
        var val = value[key];
        if (val["lane_id"] === values.no_of_lanes && val["lane_type"] === "0") {
            var metricVal = val[metric];
            options["color"] = getColor(metricVal, metric);
            break;
        }
    }
    return options;
}

function specifySectionLayer(layer, values) {
    var options = getLineOptions(values);
    L.Util.setOptions(layer, options);
}

function hide_sb2(){
    var sb2 = document.getElementById("sidebar2");
    sb2.style.display = 'none';
}

function relocate(){
    var sb = document.getElementById("sidebar2");
    var mapCan = document.getElementById("map");
    sb.style.display = 'block';
    mapCan.style.width = '18%';
    mapCan.style.height = '35%';
    mapCan.style.top = '55px';
    mapCan.style.margin = '5px';
    mapCan.style.position = 'absolute';
    map.invalidateSize();
    var sb1 = document.getElementById("sidebar");
    sb1.style.top = '40%';
}
        
function relarge(){
    var sb = document.getElementById("sidebar2");
    var mapCan = document.getElementById("map");
    sb.style.display = 'none';
    mapCan.style.width = '82%';
    mapCan.style.height = '100%';
    mapCan.style.top = '0px';
    mapCan.style.margin = '0px';
    mapCan.style.position = 'relative';
    map.invalidateSize();
    var sb1 = document.getElementById("sidebar");
    sb1.style.top = '0';
}