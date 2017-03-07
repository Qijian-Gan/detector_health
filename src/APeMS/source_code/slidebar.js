
$('#station-section-tabs a[href="#section-table-tab"]').click(function (e) {
    //var formId = "map-metric-radios";
    //removeAllFromElementId(formId);
    //addRadioToFormId(formId, "map-metrics", "speed", "Speed", "map-speed-radios", true);
    updateCorridorMenu("-1", clickedCorridorName);
});

$('#station-section-tabs a[href="#station-table"]').click(function (e) {
    //var formId = "map-metric-radios";
    //removeAllFromElementId(formId);
    //addRadioToFormId(formId, "map-metrics", "speed", "Speed", "map-speed-radios", true);
    //addRadioToFormId(formId, "map-metrics", "volume", "Volume", "map-volume-radios", false);
    updateCorridorMenu("-1", clickedCorridorName);
});