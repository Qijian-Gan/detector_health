
var dryRunMode = false;
var trafficMode = true;

var NoneMeasureTwo = "None";
var NoDataFoundStr = "No Data Found";
var AggregatedStr = "Aggregated";
var AggStr = "Total";
var AggregatedVal = "14"; //use 14 for veh_class:total, 0 for lane:total
var AllVal = "All";
var SectionStr = 'section';
var StationStr = 'station';

var ColorLevel = [0.7, 0.9];

// var ColorBar = ['#E9E5DC', '#00B22D', '#FF9E00', '#FF0000', '#BE0000'];
var ColorBar = ['#787D7B', '#00B22D', '#FF9E00', '#FF0000', '#BE0000'];
var RadiusBar = [25, 20, 15, 10];

// if in this list, then the bigger the worse
var ReverseLimits = {"speed": true};

var Limits = {
    "vht": 1200.0,
    "vmt": 80000.0,
    "speed": 90.0,
    "matching_rate": 100.0,
    "travel_time_index": 4.0,
    "emission_rate": {},  // assigned when retrieve the pollutant IDs
    "emission": {},
    "volume": 100000.0,
    "occupancy": 100.0,
    "travel_time": {}
};

var Full2Abbr = {
    "None": NoDataFoundStr,
    "Vehicle Hours Traveled": "vht",
    "Vehicle Miles Traveled": "vmt",
    "Speed": "speed",
    "Matching Rate": "matching_rate",
    "Travel Time Index": "travel_time_index",
    "Emission Rate": "emission_rate",
    "Emission": "emission",
    "Volume": "volume",
    "Occupancy": "occupancy",
    "Lane Change Intensity Matrix":"lcim",
    "Travel Time":"travel_time"
};

var MetricUnits = {
    "None": "",
    "Vehicle Hours Traveled": "Vehicle Hours Traveled (Veh-Hours)",
    "Vehicle Miles Traveled": "Vehicle Miles Traveled (Veh-Miles)",
    "Speed": "Speed (mph)",
    "Matching Rate": "Matching Rate (%)",
    "Travel Time Index": "Travel Time Index",
    "Emission Rate": "Emission Rate (%)",
    "Emission": "Emission",
    "Volume": "Volume (Veh/Interval)",
    "Occupancy": "Occupancy (%)",
    "Travel Time":"Travel Time (sec)"
};

var Abbr2Full = {
    "None": NoDataFoundStr,
    "vht": "Vehicle Hours Traveled",
    "vmt": "Vehicle Miles Traveled",
    "speed": "Speed",
    "matching_rate": "Matching Rate",
    "travel_time_index": "Travel Time Index",
    "emission_rate": "Emission Rate",
    "emission": "Emission",
    "volume": "Volume",
    "occupancy": "Occupancy",
    "travel_time":"Travel Time"
};

var FHWA_ID = '1';
var EMFAC2007 = '2';
var HPMS_ID = '3';

// For historical
var VehClass_HPMS2FHWA = {
    0: ['0'],
    1: ['1'],
    2: ['2'],
    3: ['3'],
    4: ['4', '5', '6'],
    5: ['7', '8', '9', '10', '11', '12'],
    6: ['13'],
    7: ['14']
};

// For realtime
var VehClass_FHWA2HPMS = {
    0: '0',//class 1 mc
    1: '1',//class 2 pc
    2: '2',//class 3 LT
    3: '3',//class 4 bs
    4: '4',//class 5-7
    5: '4',//class 5-7
    6: '4',//class 5-7
    7: '5',//class 8-13
    8: '5',//class 8-13
    9: '5',//class 8-13
    10: '5',//class 8-13
    11: '5',//class 8-13
    12: '5',//class 8-13
    13: '6',//class 14:others
    14: '7'//total
};

var MetricInSectionsFHWA = {
    "travel_time_index": true,
    "travel_time":true,
    "vht": true,
    "vmt": true,
    "speed": true,
    "matching_rate": true
};

var AggLaneOnlyMetric = {
    "vht": true,
    "vmt": true,
    "speed": true,
    //"occupancy": true,
    "matching_rate": true
    //"travel_time_index": true
}

var MetricInSectionEMFAC = {
    "emission_rate": true,
    "emission": true,
    "speed": true
};

var vehSchemeClassInTrafficMode = {
    "FHWA": true,
    "HPMS": true
};
var vehSchemeClassInEmissionMode = {
    "EMFAC2007": true
};

var metricInTrafficMode = {
    "Travel Time Index": true,
    "Travel Time":true,
    "Speed": true,
    "Vehicle Miles Traveled": true,
    "Vehicle Hours Traveled": true,
    "Matching Rate": true,
    "Lane Change Intensity Matrix": true
};

var metricInEmissionMode = {
    "Emission": true,
    "Emission Rate": true,
    "Speed": true
};

var MetricInStation = {
    "speed": true,
    "volume": true,
    "occupancy": true
};

var Interval2NoSpace = {
    '30 secs': '30sec',
    '5 mins': '5min',
    '15 mins': '15min',
    '1 hour': '1hour',
    '1 day': '1day'
};

var Interval2Space = {
    '30sec': '30 secs',
    '5min': '5 mins',
    '15min': '15 mins',
    '1hour': '1 hour',
    '1day': '1 day'
};

var laneName2CommoNname = {
    "Mainline": "Lane",
    "HOT": "HOT",
    "HOV": "HOV",
    "Total": "All",
    "Through": "Through",
    "Right": "Right Turn",
    "Left": "Left Turn",
    "Through-DnStream": "Intersection DnStream Through",
    "OffRamp": "Off-Ramp",
    "OnRamp":"On-Ramp",
    "FF to EB":"FF-to-EB",
    "FF to WB":"FF-to-WB",
    "FF to NB":"FF-to-NB",
    "FF to SB":"FF-to-SB",
    "FF from EB":"FF-from-EB",
    "FF from WB":"FF-from-WB",
    "FF from NB":"FF-from-NB",
    "FF from SB":"FF-from-SB"
};

var timeSegId2Name = {
    "24": "All",
    "0": "00:00",
    "1": "01:00",
    "2": "02:00",
    "3": "03:00",
    "4": "04:00",
    "5": "05:00",
    "6": "06:00",
    "7": "07:00",
    "8": "08:00",
    "9": "09:00",
    "10": "10:00",
    "11": "11:00",
    "12": "12:00",
    "13": "13:00",
    "14": "14:00",
    "15": "15:00",
    "16": "16:00",
    "17": "17:00",
    "18": "18:00",
    "19": "19:00",
    "20": "20:00",
    "21": "21:00",
    "22": "22:00",
    "23": "23:00"
    
};

var timeSegId2NameAbbr = {
    "24": "All",
    "0": "0",
    "1": "1",
    "2": "2",
    "3": "3",
    "4": "4",
    "5": "5",
    "6": "6",
    "7": "7",
    "8": "8",
    "9": "9",
    "10": "10",
    "11": "11",
    "12": "12",
    "13": "13",
    "14": "14",
    "15": "15",
    "16": "16",
    "17": "17",
    "18": "18",
    "19": "19",
    "20": "20",
    "21": "21",
    "22": "22",
    "23": "23"
};

var pollutantId2Name = {
    "0":"HC",
    "1":"CO",
    "2":"NOx",
    "3":"SOx",
    "4":"PM",
    "5":"TOG",
    "6":"ROG",
    "7":"CO2",
    "8":"CH4",
    "9":"PM10",
    "10":"PM2.5",
    "11":"All"
};

var FHWA_to_EMFAC = {
    "0":"10",
    "1":"0",
    "2":"1",
    "3":"9",
    "4":"2",
    "5":"11",
    "6":"3",
    "7":"4",
    "8":"5",
    "9":"12",
    "10":"6",
    "11":"8",
    "12":"7"
};

var SpeedBin = {
    "0":"0-10mph",
    "1":"10mph-20mph",
    "2":"20mph-30mph",
    "3":"30mph-40mph",
    "4":"40mph-50mph",
    "5":"50mph-60mph",
    "6":"60mph-70mph",
    "7":"70mph-80mph",
    "8":"80mph+"
};

function convertFull2Abbr(full) {
    return Full2Abbr[full];
}

function convertAbbr2Full(abbr) {
    return Abbr2Full[abbr];
}

var IntervalTimeSpan = {
    "30sec": 3600 * 24 * 1000,
    "5min": 3600 * 24 * 1000 * 7,
    "15min": 3600 * 24 * 1000 * 7,
    "1hour": 3600 * 24 * 1000 * 7 * 4,
    "1day": 3600 * 24 * 1000 * 365
};

var IntervalTimeSpanStr = {
    "30sec": "One Day",
    "5min": "One Week",
    "15min": "One Week",
    "1hour": "Four Weeks",
    "1day": "One Year"
};

var weekdays = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

var stationMapping = {
    "1":"0",
    "2":"1",
    "3":"2",
    "5":"3",
    "6":"3",
    "7":"4",
    "8":"1",
    "9":"2",
    "10":"0",
    "11":"1",
    "12":"2",
    "13":"3",
    "14":"4",
    "15":"0",
    "16":"0",
    "17":"1",
    "18":"2"    
};

var sectionMapping = {
    "1":"0",
    "2":"1",
    "3":"2",
    "4":"0",
    "5":"1",
    "6":"2"
}

ADP_Station_List = {
    "1: I-405 NB: Laguna Canyon":"1",
    "2: I-405 NB: Sand Canyon":"2",
    "3: I-405 NB: N. Sand Canyon":"3",
    "5: I-405 NB: Yale":"5",
    "6: I-10 WB & San Antonio":"6",
    "7: I-10 EB & San Antonio":"7",
    "8: SR-60 WB & Benson":"8",
    "9: SR-60 EB & Benson":"9",
    "10: TH-55 WB & MN-100":"10",
    "11: TH-55 WB: Douglas":"11",
    "12: TH-55 WB: Glenwood":"12",
    "13: TH-55 WB: Rhode Island":"13",
    "14: I-405 SB: Yale":"14",
    "15: SR-57 NB: Lambert":"15",
    "16: I-70 EB: W SH-36":"16",
    "17: I-70 WB: W SH-36":"17",
    "18: I-70 WB: Holly St":"18"
}