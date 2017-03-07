var map, featureList,
    clickedCorridorName, clickedCorridorID,
    clickedStationName, clickedStationID,
    clickedSectionName, clickedSectionID,
    changeSectionStation = false,
    citySearch = [], sectionSearch = [], stationSearch = [],
    corridorNameToId = {}, corridorIdToName = {};
var citiesBH, sectionsBH, stationsBH, geonamesBH;

//var target = document.getElementById('spin-loading');
//var spinner = new Spinner().spin(target);

$(document).on("click", ".feature-row", function(e) {
  sidebarClick(parseInt($(this).attr("id"), 10));
});

$("#dry-run-btn").click(function () {
  dryRunMode = !dryRunMode;
  if (!dryRunMode) {
    this.innerHTML = '<i class="fa fa-database"></i>&nbsp;&nbsp;Dry Run Mode';
  } else {
    this.innerHTML = '<i class="glyphicon glyphicon-ok"></i>&nbsp;&nbsp;<i class="fa fa-database"></i>&nbsp;&nbsp;Dry Run Mode';
  }
});

$("#list-btn").click(function() {
  $('#sidebar').toggle();
  map.invalidateSize();
  return false;
});

$("#nav-btn").click(function() {
  $(".navbar-collapse").collapse("toggle");
  return false;
});

$("#sidebar-toggle-btn").click(function() {
  $("#sidebar").toggle();
  map.invalidateSize();
  return false;
});

$("#sidebar-hide-btn").click(function() {
  $('#sidebar').hide();
  map.invalidateSize();
});

function sidebarClick(id) {
  //map.addLayer(stations);
  //map.addLayer(sections);
  var layer = markerClusters.getLayer(id);
  if (typeof(layer.getLatLng) === typeof(Function)) {
    //markerClusters.zoomToShowLayer(layer, function () {
    //map.setView([layer.getLatLng().lat, layer.getLatLng().lng], 4);
    //});
    var bounds = L.latLngBounds([layer.getLatLng()]);
      bounds._northEast.lat += 0.01;
      bounds._northEast.lng += 0.01;
      bounds._southWest.lat -= 0.01;
      bounds._southWest.lng -= 0.01;
    map.fitBounds(bounds);
  } else if (typeof(layer.getLatLngs) === typeof(Function)) {
    var bounds = L.latLngBounds(layer.getLatLngs());
      bounds._northEast.lat += 0.01;
      bounds._northEast.lng += 0.01;
      bounds._southWest.lat -= 0.01;
      bounds._southWest.lng -= 0.01;
    map.fitBounds(bounds);
  }

  layer.fire("click");
  /* Hide sidebar and go to the map on small screens */
  if (document.body.clientWidth <= 767) {
    $("#sidebar").hide();
    map.invalidateSize();
  }
}

/* Basemap Layers */
var mapquestOSM = L.tileLayer("http://{s}.mqcdn.com/tiles/1.0.0/osm/{z}/{x}/{y}.png", {
  maxZoom: 14,
  subdomains: ["otile1", "otile2", "otile3", "otile4"],
  attribution: 'Tiles courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">. Map data (c) <a href="http://www.openstreetmap.org/" target="_blank">OpenStreetMap</a> contributors, CC-BY-SA.'
});
var mapquestOAM = L.tileLayer("http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg", {
  maxZoom: 14,
  subdomains: ["oatile1", "oatile2", "oatile3", "oatile4"],
  attribution: 'Tiles courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a>. Portions Courtesy NASA/JPL-Caltech and U.S. Depart. of Agriculture, Farm Service Agency'
});
var mapquestHYB = L.layerGroup([L.tileLayer("http://{s}.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg", {
  maxZoom: 14,
  subdomains: ["oatile1", "oatile2", "oatile3", "oatile4"]
}), L.tileLayer("http://{s}.mqcdn.com/tiles/1.0.0/hyb/{z}/{x}/{y}.png", {
  maxZoom: 14,
  subdomains: ["oatile1", "oatile2", "oatile3", "oatile4"],
  attribution: 'Labels courtesy of <a href="http://www.mapquest.com/" target="_blank">MapQuest</a> <img src="http://developer.mapquest.com/content/osm/mq_logo.png">. Map data (c) <a href="http://www.openstreetmap.org/" target="_blank">OpenStreetMap</a> contributors, CC-BY-SA. Portions Courtesy NASA/JPL-Caltech and U.S. Depart. of Agriculture, Farm Service Agency'
})]);

/* Overlay Layers */
var highlight = L.geoJson(null);
/* Single marker cluster layer to hold all clusters */
var markerClusters = new L.MarkerClusterGroup({
  spiderfyOnMaxZoom: true,
  showCoverageOnHover: false,
  zoomToBoundsOnClick: true,
  disableClusteringAtZoom: 4
});
var cities = L.geoJson(null, {
  style: function (feature) {
    return {
      color: "black",
      fill: false,
      opacity: 1,
      clickable: false
    };
  },
  onEachFeature: function (feature, layer) {
    citySearch.push({
      name: layer.feature.properties.BoroName,
      source: "cities",
      id: L.stamp(layer),
      bounds: layer.getBounds()
    });
  }
});
$.getJSON("data/cities.geojson", function (data) {
  cities.addData(data);
})

function newSections() {
  return L.geoJson(null, {
    onEachFeature: function (feature, layer) {
      if (feature.properties) {
        //var content = "<table class='table table-striped table-bordered table-condensed'>" + "<tr><th>Name</th><td>" + feature.properties.name + "</td></tr>" + "<table>";
        specifySectionLayer(layer, feature.properties);
        layer.on({
          click: function (e) {
            $("#feature-title").html(feature.properties.name);
            var title = "Speed of the " + feature.properties.name;
            clickedSectionID = feature.id;
            clickedSectionName = feature.properties.name;
            if (clickedSection === false) {
              changeSectionStation = true;
            } else {
              changeSectionStation = false;
            }
            clickedSection = true;
            $('#station-section-tabs a[href="#section-table-tab"]').tab('show');
            specifySectionLayer(layer, feature.properties);
            makeSelect("section");
            makeMetricSelector(SectionStr);
            renderRealtimeData(true);
            //plotHistoricalMeasures(SectionStr, clickedSectionID, true, true, true);
            $("#featureModal").modal("show");
          }
        });
        $("#sections-list tbody").append('<tr class="feature-row" id="' + L.stamp(layer) + '">' +
        '<td style="vertical-align: middle;"><img width="18" height="14" src="assets/img/section.png"></td>' +
        '<td class="feature-name">' + layer.feature.properties.name + '</td>' +
        '<td style="vertical-align: middle;"><i class="fa fa-chevron-right pull-right"></i></td></tr>');
        sectionSearch.push({
          name: layer.feature.properties.name,
          source: "Sections",
          id: L.stamp(layer),
          lat: layer.feature.geometry.coordinates[1],
          lng: layer.feature.geometry.coordinates[0]
        });
      }
    }
  });
}

var sections = null;

function newStations() {
  return L.geoJson(null, {
    pointToLayer: function (feature, latlng) {
      return L.circleMarker(latlng);
    },
    onEachFeature: function (feature, layer) {
      if (feature.properties) {
        //var content = "<table class='table table-striped table-bordered table-condensed'>" + "<tr><th>Name</th><td>" + feature.properties.name + "</td></tr>" + "<table>";
        specifyStationLayer(layer, feature.properties);
        layer.on({
          click: function (e) {
            $("#feature-title").html(feature.properties.name);
            var plot_id = "#station-plot";
            var plot_title_id = "#station-plot-title";
            var title = "Speed of the " + feature.properties.name;
            clickedStationID = feature.id;
            clickedStationName = feature.properties.name;
            var startTime, endTime, interval = 1, measure = "Speed";
            //plotSpeed(plot_id, plot_title_id, title, clickedCorridorID, clickedStationID,
            //    startTime, endTime, interval, measure);
            if (clickedSection === true) {
              changeSectionStation = true;
            } else {
              changeSectionStation = false;
            }
            clickedSection = false;
            $('#station-section-tabs a[href="#station-table"]').tab('show');
            specifyStationLayer(layer, feature.properties);
            makeSelect("station");
            makeMetricSelector(StationStr);
            relocate();
            map.fitBounds(stations.getBounds());
            renderRealtimeData(true);
            //plotHistoricalMeasures(StationStr, clickedStationID, true, true, true);
            $("#featureModal").modal("show");
          }
        });
        $("#feature-list tbody").append('<tr class="feature-row" id="'+L.stamp(layer)+'">' +
        '<td style="vertical-align: middle;"><img width="18" height="18" src="assets/img/exit.png"></td>' +
        '<td class="feature-name">'+layer.feature.properties.name+'</td>' +
        '<td style="vertical-align: middle;"><i class="fa fa-chevron-right pull-right"></i></td></tr>');
        stationSearch.push({
          name: layer.feature.properties.name,
          source: "Stations",
          id: L.stamp(layer),
          lat: layer.feature.geometry.coordinates[1],
          lng: layer.feature.geometry.coordinates[0]
        });
      }
    }
  });
}

map = L.map("map", {
  zoom: 2,
  //center: [33.651123, -117.775267],
    center: [33.474202, -117.709139],
  //layers: [mapquestOSM, markerClusters, highlight],
    layers: MQ.mapLayer(),
  zoomControl: true,
  attributionControl: false
});

var stations = null;

/* corridor list */
function loadCorridorList() {
  $.ajaxSettings.async = false;
  $.getJSON(generateJsonPath("getCorridorList"), function (data) {
    $.each(data.result, function (key, val) {
      corridorNameToId[val.name] = val.id;
      corridorIdToName[val.id] = val.name;
    });
  });
  $.ajaxSettings.async = true;
}

function updateCorridorMenu(targetIndex, corridorName) {
  //spinner.spin();
  $("#loading").show();
  loadCorridorList();
  if (corridorName === "") {
    // by default, we load the first corridor
    loadRealtimeData("1");
  } else {
    loadRealtimeData(corridorNameToId[corridorName]);
  }

  // remove the list of the corridor
  $("#corridor-list").empty();

  var clickedCorridor = "<li><a href='#'  data-toggle='collapse' data-target='.navbar-collapse.in'>" +
      "<i class='glyphicon glyphicon-ok'></i>&nbsp;&nbsp;&nbsp;<i class='glyphicon glyphicon-map-marker'></i>";
  var nonClickedCorridor = "<li><a href='#'  data-toggle='collapse' data-target='.navbar-collapse.in'>" +
      "&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<i class='glyphicon glyphicon-map-marker'></i>";
  var ending = "</a></li>";

  var i = 1;
  var newCorridorNameToId = {}, newCorridorIdToName = {};
  $.each(corridorNameToId, function (name, id) {
    if (name === corridorName || i.toString() === targetIndex) {
      $("#corridor-list").append(clickedCorridor + name + ending);
      clickedCorridorName = name;
      clickedCorridorID = id;
      // set the corridor name of the panel
      $("#panel-corridor-name")[0].innerHTML = "<h5><b>" + clickedCorridorName;
      $("#corridor-list-href").text('Region: ' + name);
    } else {
      $("#corridor-list").append(nonClickedCorridor + name + ending);
    }
    newCorridorNameToId[name] = id;
    newCorridorIdToName[id] = name;
    ++i;
  });
  corridorNameToId = newCorridorNameToId;
  corridorIdToName = newCorridorIdToName;

  /* Load station data */
  if (stations) {
    markerClusters.removeLayer(stations);
    layerControl.removeLayer(stations);
  }
  if (sections) {
    markerClusters.removeLayer(sections);
    layerControl.removeLayer(sections);
  }

  // clear search box
  stationSearch = [];
  sectionSearch = [];

  // remove previous children
  $("#feature-list tbody").empty();
  $("#sections-list tbody").empty();

  delete stations;
  delete sections;

  stations = newStations();
  sections = newSections();

  //spinner.stop();
  $("#loading").hide();

  // data loading error
  if (realtime_data === undefined) {
    var noDataIcon = L.divIcon({iconSize: 500, html:'<h2>Data temporariliy unavailable</h2>', className: 'NoDataIcon'});
    L.marker([33.6766399299826, -117.86922454833984], {icon: noDataIcon}).addTo(map);
    return;
  }

  var realtimeSectionData = realtime_data.result.sections;
  var realtimeStationData = realtime_data.result.stations;
  // add layer to the updated stations
  stations.addData(realtimeStationData);
  map.addLayer(stations);
  markerClusters.addLayer(stations);

  sections.addData(realtimeSectionData);
  map.addLayer(sections);
  markerClusters.addLayer(sections);
  /*if (corridorId === 2){
    map.fitBounds(stations.getBounds());
  }else{
      map.fitBounds(sections.getBounds());
  }*/
    map.fitBounds(stations.getBounds());

  // change LayerControl
  if (layerControl) {
    layerControl.addOverlay(stations, "<img src='assets/img/exit.png' width='28' height='28'>&nbsp;Station", "Show on Map:");
    layerControl.addOverlay(sections, "<img src='assets/img/section.png' width='28' height='22'>&nbsp;Section", "Show on Map:");
  }
}
// Initially, set the first corridor as the clicked corridor
clickedCorridorID = "1";
updateCorridorMenu("1", "");

/* click the select corridor menu */
// IE does not know about the target attribute. It looks for srcElement
// This function will get the event target in a browser-compatible way
function getEventTarget(e) {
  e = e || window.event;
  return e.target || e.srcElement;
}
$("#corridor-list").click(function (e) {
  var target = getEventTarget(e);
  var corridorName = target.text.trim();

  // update the corridor menu
  updateCorridorMenu("-1", corridorName);
    if (corridorName == "Denver, CO"){
         $("#section-tab-select").hide();
    }
    else{
         $("#section-tab-select").show();
    }
  setupTypeahead();
});

/* Layer control listeners that allow for a single markerClusters layer */
map.on("overlayadd", function(e) {
  if (e.layer === stations) {
    markerClusters.addLayer(stations);
  }
  if (e.layer === sections) {
    markerClusters.addLayer(sections);
  }
});

map.on("overlayremove", function(e) {
  if (e.layer === stations) {
    markerClusters.removeLayer(stations);
  }
  if (e.layer === sections) {
    markerClusters.removeLayer(sections);
  }
});

/* Clear feature highlight when map is clicked */
map.on("click", function(e) {
  highlight.clearLayers();
});

/* Attribution control */
function updateAttribution(e) {
  $.each(map._layers, function(index, layer) {
    if (layer.getAttribution) {
      $("#attribution").html((layer.getAttribution()));
    }
  });
}
map.on("layeradd", updateAttribution);
map.on("layerremove", updateAttribution);

var attributionControl = L.control({
  position: "bottomright"
});
attributionControl.onAdd = function (map) {
  var div = L.DomUtil.create("div", "leaflet-control-attribution");
  div.innerHTML = "<span class='hidden-xs'>Developed by <a href='http://bryanmcbride.com'>bryanmcbride.com</a> | </span><a href='#' onclick='$(\"#attributionModal\").modal(\"show\"); return false;'>Attribution</a>";
  return div;
};
//map.addControl(attributionControl);

var zoomControl = L.control.zoom({
  position: "bottomright"
}).addTo(map);

/* GPS enabled geolocation control set to follow the user's location */
var locateControl = L.control.locate({
  position: "bottomright",
  drawCircle: true,
  follow: true,
  setView: true,
  keepCurrentZoomLevel: true,
  markerStyle: {
    weight: 1,
    opacity: 0.8,
    fillOpacity: 0.8
  },
  circleStyle: {
    weight: 1,
    clickable: false
  },
  icon: "icon-direction",
  metric: false,
  strings: {
    title: "My location",
    popup: "You are within {distance} {unit} from this point",
    outsideMapBoundsMsg: "You seem located outside the boundaries of the map"
  },
  locateOptions: {
    maxZoom: 4,
    watch: true,
    enableHighAccuracy: true,
    maximumAge: 10000,
    timeout: 10000
  }
}).addTo(map);

/* Larger screens get expanded layer control and visible sidebar */
if (document.body.clientWidth <= 767) {
  var isCollapsed = true;
} else {
  var isCollapsed = false;
}

var baseLayers = {
  "Street Map": mapquestOSM,
  "Aerial Imagery": mapquestOAM,
  "Imagery with Streets": mapquestHYB
};

var refresh_on = true;
var groupedOverlays = {
  "Show on Map:": {
    //"Cities": cities,
    "<img src='assets/img/exit.png' width='28' height='28'>&nbsp;Station": stations,
    "<img src='assets/img/section.png' width='28' height='22'>&nbsp;Section": sections
  },
  "Auto-Refresh:": {
	"On": refresh_on
  }
};

var layerControl = L.control.groupedLayers(baseLayers, groupedOverlays, {
  collapsed: isCollapsed
});
//layerControl.addTo(map);

/* Highlight search box text on click */
$("#searchbox").click(function () {
  $(this).select();
});


$("#application-list").click(function (e) {
  var target = getEventTarget(e);
  var mode = target.text.trim();
  $("#application-list").empty();

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
  makeVehClassSchemeSelector("historical-vehscheme-select", "historical-vehclass-select");
});

/* Typeahead search functionality */
function setupTypeahead() {
  $("#loading").hide();
  $("#loading-modal").hide();
  //spinner.stop();
  /* Fit map to city bounds */
  //map.fitBounds(cities.getBounds());
  featureList = new List("features", {valueNames: ["feature-name"]});
  //featureList.sort("feature-name", {order:"asc"});

  citiesBH = new Bloodhound({
    name: "Cities",
    datumTokenizer: function (d) {
      return Bloodhound.tokenizers.whitespace(d.name);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    local: citySearch,
    limit: 10
  });

  stationsBH = new Bloodhound({
    name: "Stations",
    datumTokenizer: function (d) {
      return Bloodhound.tokenizers.whitespace(d.name);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    local: stationSearch,
    limit: 10
  });

  sectionsBH = new Bloodhound({
    name: "Sections",
    datumTokenizer: function (d) {
      return Bloodhound.tokenizers.whitespace(d.name);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    local: sectionSearch,
    limit: 10
  });

  geonamesBH = new Bloodhound({
    name: "GeoNames",
    datumTokenizer: function (d) {
      return Bloodhound.tokenizers.whitespace(d.name);
    },
    queryTokenizer: Bloodhound.tokenizers.whitespace,
    remote: {
      url: "http://api.geonames.org/searchJSON?username=bootleaf&featureClass=P&maxRows=5&countryCode=US&name_startsWith=%QUERY",
      filter: function (data) {
        return $.map(data.geonames, function (result) {
          return {
            name: result.name + ", " + result.adminCode1,
            lat: result.lat,
            lng: result.lng,
            source: "GeoNames"
          };
        });
      },
      ajax: {
        beforeSend: function (jqXhr, settings) {
          settings.url += "&east=" + map.getBounds().getEast() + "&west=" + map.getBounds().getWest() + "&north=" + map.getBounds().getNorth() + "&south=" + map.getBounds().getSouth();
          $("#searchicon").removeClass("fa-search").addClass("fa-refresh fa-spin");
        },
        complete: function (jqXHR, status) {
          $('#searchicon').removeClass("fa-refresh fa-spin").addClass("fa-search");
        }
      }
    },
    limit: 10
  });
  citiesBH.initialize();
  stationsBH.initialize();
  sectionsBH.initialize();
  geonamesBH.initialize();

  /* instantiate the typeahead UI */
  $("#searchbox").typeahead({
    minLength: 3,
    highlight: true,
    hint: false
  }, {
    name: "Cities",
    displayKey: "name",
    source: citiesBH.ttAdapter(),
    templates: {
      header: "<h4 class='typeahead-header'>Cities</h4>"
    }
  }, {
    name: "Stations",
    displayKey: "name",
    source: stationsBH.ttAdapter(),
    templates: {
      header: "<h4 class='typeahead-header'><img src='assets/img/exit.png' width='28' height='28'>&nbsp;Stations</h4>",
      suggestion: Handlebars.compile(["{{name}}<br>&nbsp;<small>{{address}}</small>"].join(""))
    }
  }, {
    name: "Sections",
    displayKey: "name",
    source: sectionsBH.ttAdapter(),
    templates: {
      header: "<h4 class='typeahead-header'><img src='assets/img/section.png' width='28' height='28'>&nbsp;Sections</h4>",
      suggestion: Handlebars.compile(["{{name}}<br>&nbsp;<small>{{address}}</small>"].join(""))
    }
  }, {
    name: "GeoNames",
    displayKey: "name",
    source: geonamesBH.ttAdapter(),
    templates: {
      header: "<h4 class='typeahead-header'><img src='assets/img/globe.png' width='25' height='25'>&nbsp;GeoNames</h4>"
    }
  }).on("typeahead:selected", function (obj, datum) {
    if (datum.source === "Boroughs") {
      map.fitBounds(datum.bounds);
    }

    if (datum.source === "Stations") {
      if (!map.hasLayer(stations)) {
        map.addLayer(stations);
      }
      map.setView([datum.lat, datum.lng], 4);
      if (map._layers[datum.id]) {
        map._layers[datum.id].fire("click");
      }
    }
    if (datum.source === "Sections") {
      if (!map.hasLayer(sections)) {
        map.addLayer(sections);
      }
      map.setView([datum.lat, datum.lng],4);
      if (map._layers[datum.id]) {
        map._layers[datum.id].fire("click");
      }
    }

    if (datum.source === "GeoNames") {
      map.setView([datum.lat, datum.lng], 4);
    }
    if ($(".navbar-collapse").height() > 50) {
      $(".navbar-collapse").collapse("hide");
    }
  }).on("typeahead:opened", function () {
    $(".navbar-collapse.in").css("max-height", $(document).height() - $(".navbar-header").height());
    $(".navbar-collapse.in").css("height", $(document).height() - $(".navbar-header").height());
  }).on("typeahead:closed", function () {
    $(".navbar-collapse.in").css("max-height", "");
    $(".navbar-collapse.in").css("height", "");
  });
  $(".twitter-typeahead").css("position", "static");
  $(".twitter-typeahead").css("display", "block");
}
$(document).one("ajaxStop", setupTypeahead);