var netRaw;
var speedRaw;

//for the network data
var linkList;
var cellList=[];
var totalLink;

//for speed data
var speedMap=[];
var VMTMap=[];
var VHTMap=[];
var totalFrame;


//colors
//var colors=["#420000","#FF0000","#FF6500","#FFAE00","#FFFF00","#9CD700","#00FF00","#008000"];
var colors=["#420000","#CC0000","#FF3300","#FFCC00","#FFFF00","#CCFF00","#99FF00","#00FF00"];

	
var tmpCurFrame=[];
var tmpPolyLine=[];
var tmpPolyLine1=[];
var type;
var preType;

function parseDisplay() {
	var speedLayer = map.getLayersByName("Speed Map")[0];
	parseNet();
	parseSpeed();
	alert("Parsing Finished");
	iniCell();
	speedLayer.addFeatures(cellList);
	updateState(0);
	document.getElementById("rangeControl").innerHTML=
		"Current Frame: <b id='crFrame'>1</b><br>1<input id='range' type='range' value='1' min='1' max='"+totalFrame+"'>"+totalFrame;
	speedLayer.redraw();
	document.getElementById('rangeControl').addEventListener('change',onFrameChange,false);
	//document.getElementById('timeMinus').addEventListener('click',timeM,false);
	//document.getElementById('timePlus').addEventListener('click',timeP,false);
}

//function timeM(){
//	document.getElementById('range').value=document.getElementById('range').value-1;
//}

//function timeP(){
//	document.getElementById('range').value=document.getElementById('range').value+1;
//}




function onFrameChange(){
	var speedLayer = map.getLayersByName("Speed Map")[0];
	var crFrame = document.getElementById('range').value;
	updateState(crFrame-1);
	speedLayer.redraw();
	document.getElementById("crFrame").innerHTML = crFrame;
}


function iniCell(){
	for (var i=0;i<totalLink;i++){
		var shp = linkList[i].shp;
		for (var j=0;j<shp.length-1;j++){
			var start = shp[j];
			var end = shp[j+1];
			var cellGeo = new OpenLayers.Geometry.LineString(
					[new OpenLayers.Geometry.Point(start.lon, start.lat).transform(new OpenLayers.Projection("EPSG:4326"),new OpenLayers.Projection("EPSG:900913")),
					 new OpenLayers.Geometry.Point(end.lon, end.lat).transform(new OpenLayers.Projection("EPSG:4326"), new OpenLayers.Projection("EPSG:900913"))]);
			var cellFeature = new OpenLayers.Feature.Vector(cellGeo);
			cellList.push(cellFeature);
		}
	}
}

function updateState(frame){
	var speedLayer = map.getLayersByName("Speed Map")[0];
	for (var i=0;i<speedLayer.features.length;i++){
		speedLayer.features[i].attributes={
				VHT:VHTMap[frame][i],
				VMT:VMTMap[frame][i],
				Speed:speedMap[frame][i],
				Color:speed2color(speedMap[frame][i])};
	}
}

function speed2color(speed){
	var color = colors[0];
	switch (true){
	case (speed<5):
		color = colors[0];
	break;
	case (speed<15):
		color = colors[1];
	break;
	case (speed<25):
		color = colors[2];
	break;
	case (speed<35):
		color = colors[3];
	break;
	case (speed<45):
		color = colors[4];
	break;
	case (speed<55):
		color = colors[5];
	break;
	case (speed<65):
		color = colors[6];
	break;
	case (speed>=65):
		color = colors[7];
	break;
	default:
		color = colors[0];
	};
	return color;
}

function readNet(evt) {
    //Retrieve the first (and only!) File from the FileList object
    f = evt.target.files[0];
    loadFile(f,"net");
}

function readSpeed(evt) {
    //Retrieve the first (and only!) File from the FileList object
    var f = evt.target.files[0];
    loadFile(f,"speed");
    
}

function link(id,numLane,type,len,numShp,shp){//constructor function for link class
	this.id=id;
	this.numLane=numLane;
	this.type=type;
	this.len=len;
	this.numShp=numShp;
	this.shp=shp;
}

function cell(x,y,speedTable){
	this.x=x;
	this.y=y;
	this.speedTable=speedTable;
}



function parseNet(){
    var myLine=netRaw.split("\n");//get all rows
    myLine.pop();//delete the last row
    totalLink=myLine.length;//get the total number of links
    linkList= new Array(totalLink);//redefine linkList size
    for (var i=0;i<myLine.length;i++)//!loop for all link, consider to use map
    {
        var singleRt=myLine[i].split(",");//get the elements inside
        var id=parseInt(singleRt[0]);//get the link ID
        var numLane=parseInt(singleRt[1]);//get the number of lanes
        var type=parseInt(singleRt[2]);
        var len=parseFloat(singleRt[3]);//link length
        var numShp=parseInt(singleRt[4]);//get the total number of shape points in each link (=num_cell +1 )          
        var shp=new Array(numShp);//initiate shape point file
        for(var j=0;j<numShp;j++)//generate link file
        {
        	shp[j]=new OpenLayers.LonLat(parseFloat(singleRt[6+j*2])-118,parseFloat(singleRt[5+j*2])+33);
        }      
        
        linkList[i]=new link(id,numLane,type,len,numShp,shp);
       }
}


function parseSpeed()//speed lookup table organized by time, link, cell
{
    var tmpLine=speedRaw.split("\n");//get all rows
    //alert(tmpLine[1]);
    tmpLine.pop();//remove the last column
    //alert(tmpLine[1]);
    totalFrame=tmpLine.length/totalLink;//get the number of frames
    //alert(totalFrame);
    //the data should be organized by their Frame ID
    speedMap = Create2DArray(totalFrame);   
    VHTMap = Create2DArray(totalFrame);   
    VMTMap = Create2DArray(totalFrame); 
            
    for (var i=0;i<tmpLine.length;i++)//process each row, consider to use map
    {
        var singleRt=tmpLine[i].split(",");//get the elements inside
        //alert(singleRt);
        var linkInd = i%totalLink;
        var frameInd = Math.floor(i/totalLink);
        //tmpTimes[i]=singleRt[1]+" "+singleRt[2];//get the time
        
        //alert(myTimes[i]);
        //tmpTimes[i]=tmpTimes[i].replace(/\-/g,'/');//replace all dashes with slashes
        //tmpCurFrame[i]=parseInt(singleRt[3]);
        var numCell = linkList[linkInd].numShp-1; //number of cell's for link i
               
    //    speedMap[frameInd][linkInd] = new Array(numCell);
    //    VHTMap[frameInd][linkInd] = new Array(numCell);
    //    VMTMap[frameInd][linkInd] = new Array(numCell);
        
        for (var j=0;j<numCell;j++)
        {
        	VMTMap[frameInd].push(parseFloat(singleRt[4+2*j]));
        	VHTMap[frameInd].push(parseFloat(singleRt[5+2*j]));
        	speedMap[frameInd].push(parseFloat(singleRt[4+2*j])/parseFloat(singleRt[5+2*j]));//
        }
    }
}


function loadFile(f,type){
	var r=new FileReader();
	if (f) {
        r.onload = function (e) { //e is the onload event
            switch (type)
            {
            case "net":
            	netRaw=e.target.result;
            	break;
            case "speed":
            	speedRaw=e.target.result;
            	break;
            default:
            	alert("Wrong input");
            break;
            }
        };
        r.readAsText(f);
    } else {
        alert("Failed to load file");
    }
}


function Create2DArray(rows) {
	  var arr = [];

	  for (var i=0;i<rows;i++) {
	     arr[i] = [];
	  }

	  return arr;
	}