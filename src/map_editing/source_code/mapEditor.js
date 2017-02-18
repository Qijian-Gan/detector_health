var map;

var selected_features,link,node, drawControls;
function init(){
	//register event listeners	
	document.getElementById('netInput').addEventListener('change', readNet, false);
	document.getElementById('speedInput').addEventListener('change', readSpeed, false);
	document.getElementById('parse').addEventListener('click',parseDisplay,false);
	
	map = new OpenLayers.Map('map');
	var apiKey="As0LJW7Xkr5JYjWbUtYF0OzEVIvspfrEAQeU9f8u6x9ep3YBfg74dHjBuPdvBAYj";
	osm = new OpenLayers.Layer.OSM();
	//style
	var style_Freeway = new OpenLayers.Style({'strokeWidth': 6,	'strokeColor': "#FE383D"});
	var style_HOV = new OpenLayers.Style({strokeWidth: 3,	strokeColor: "#FE383D"});
	var style_FF = new OpenLayers.Style({strokeWidth: 6,	strokeColor: "#FE383D"});
	var style_Ramp = new OpenLayers.Style({strokeWidth: 3,	strokeColor: "#FE383D"});
	var style_Arterial = new OpenLayers.Style({strokeWidth: 4.5,	strokeColor: "#D79509"});
	var style_Street = new OpenLayers.Style({strokeWidth: 4.5,	strokeColor: "#F8C250 "});
	var style_node = new OpenLayers.Style({fillColor: "#FF5500", fillOpacity: 0.5, pointRadius:6 ,strokeColor: "#00FF00", label : "Node: ${id}" });
	var style_speed = new OpenLayers.Style({strokeWidth: 3, strokeWidth:5,	strokeColor: "${Color}"});
	
	link1 = new OpenLayers.Layer.Vector('Freeway Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_Freeway
		})
	});
	link2 = new OpenLayers.Layer.Vector('HOV Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_HOV
		})
	});
	link3 = new OpenLayers.Layer.Vector('FF connector Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_FF
		})
	});
	link4 = new OpenLayers.Layer.Vector('On/Off ramp Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_Ramp
		})
	});
	link5 = new OpenLayers.Layer.Vector('Local arterial Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_Arterial
		})
	});
	link6 = new OpenLayers.Layer.Vector('Local street Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_Street
		})
	});
	link_array = [link1, link2, link3, link4, link5, link6];
	
	
	node = new OpenLayers.Layer.Vector('Node Layer',{
		styleMap: new OpenLayers.StyleMap({'default':style_node
		})
	});
	
	speed = new OpenLayers.Layer.Vector('Speed Map',{
		styleMap: new OpenLayers.StyleMap({'default':style_speed
		})
	});
	
	
	
	
	// Direction layers
	OpenLayers.Renderer.symbol.arrow = [0,2, 1,0, 2,2, 1,0, 0,2];
	var styleMap = new OpenLayers.StyleMap(OpenLayers.Util.applyDefaults(
			{graphicName:"arrow",rotation : "${angle}"},
			OpenLayers.Feature.Vector.style["default"]));
	var dirLayer = new OpenLayers.Layer.Vector("direction", {styleMap: styleMap});
	
	
    for(var key in link_array){
    	link_array[key].events.on({
    		'featureselected':onFeatureSelected, //can only select features on the same layer
    		'featureunselected':onFeatureSelected, 
    		'featureadded':onFeatureAdded,
    		'featuresremoved':onFeaturesRemoved
    	})   	    	
    }
//	link_array[0].events.on({
//		'featureselected':onFeatureSelected, //can only select features on the same layer
//		'featureunselected':onFeatureSelected, 
//		'featureadded':onFeatureAdded,
//		'featuresremoved':onFeaturesRemoved
//       }
//    )
	

    
    
    //define controls
    snap = new OpenLayers.Control.Snapping({//snap to all link layers
                layer: link1,
                targets:link_array,
                greedy: false
            });
            snap.activate();
            var target=snap.targets[0];
    target["node"]=true;
    target["vertex"]=false;
    target["edge"]=false;
    
    drawControls = {//only on current layer
            line: new OpenLayers.Control.DrawFeature(// draw only on current layer
            		link1, OpenLayers.Handler.Path
            ),
            select: new OpenLayers.Control.SelectFeature(//select only on current layer
            		link1,
                {
                    clickout: true, toggle: false,
                    multiple: false, hover: false,
                    toggleKey: "ctrlKey", // ctrl key removes from selection
                    multipleKey: "shiftKey", // shift key adds to selection
                    box: true
                }
            )
    };
    
    //add controls    
    map.addControl(new OpenLayers.Control.LayerSwitcher());
    for(var key in drawControls) {
    	map.addControl(drawControls[key]);
    }
    
    //projections
    var fromProjection = new OpenLayers.Projection("EPSG:4326");   // Transform from EPSG:4326 (Lat/Lon)
    var toProjection   = new OpenLayers.Projection("EPSG:900913"); // to EPSG:900913 (used by google and OpenStreetMap)
    var position       = new OpenLayers.LonLat(-117.943983,33.699208).transform( fromProjection, toProjection);
    var zoom           = 15; 
    
    //add layers
    map.addLayers([osm,dirLayer,link1,link2,link3,link4,link5,link6,speed,node]);
    map.setCenter(position, zoom);
    
    //define lines
    
    
    //adlines
    
    }
    
    //additional functions
    function toggleControl(element) {
    	for(key in drawControls) {
    		var control = drawControls[key];
    		if(element.value == key && element.checked) {
    			control.activate();
    			} else {
    				control.deactivate();
    				}
    		}
    	}

   function updateDirection() {
	    var dirLayer = map.getLayersByName("direction")[0];
		dirLayer.removeAllFeatures();
		var points=[];
		var features=[];
		for (var key in link_array){
			features=features.concat(link_array[key].features)
		}
		//var features = map.layers[1].features;
		for (var i=0;i<features.length ;i++ )	{
			var linePoints = createDirection(features[i].geometry,"middle",true) ;
			for (var j=0;j<linePoints.length ;j++ ) {
				linePoints[j].attributes.lineFid = features[i].fid;
			}
			points =points.concat(linePoints);
		}
		map.layers[1].addFeatures(points);
	}
   
   function onFeatureSelected(evt){
	   selected_features=this.selectedFeatures;
	   //update information in textarea
	   document.getElementById('output').value= update_text_area(selected_features);
	   //count the number of elements selected	   
	   document.getElementById('counter').innerHTML = selected_features.length;
	   //update selected features
   }
   
   
   function onFeaturesRemoved(evt){//for each deleted feature, update its start node and end node information
	   var nodeList=[];//nodes involved
	   var nodeLayer = map.getLayersByName("Node Layer")[0];
	   var removedLinks=evt.features;
	   for (key in removedLinks){//loop through all removed links
		   var removedLink=removedLinks[key];
		   var linkID=removedLink.id;
		   var startNode=nodeLayer.getFeatureById(removedLink.attributes.origin);
		   var endNode=nodeLayer.getFeatureById(removedLink.attributes.destination);
		   var index1=startNode.attributes.downstream.indexOf(linkID);
		   startNode.attributes.downstream.splice(index1,1);// update downstream field
		   var index2=endNode.attributes.upstream.indexOf(linkID);
		   endNode.attributes.upstream.splice(index2,1);// update upstream field
		   if (nodeList.indexOf(startNode)==-1)  nodeList.push(startNode);
		   if (nodeList.indexOf(endNode)==-1)   nodeList.push(endNode);
	   }
	   var removeList=[];
	   for (key in nodeList){//loop through all involved nodes
		   var node=nodeList[key];
		   if ((node.attributes.downstream.length==0) && (node.attributes.upstream.length==0)){
			   removeList.push(node);
		   }
	   }
	   nodeLayer.removeFeatures(removeList);
   }
   
   
//   function onFeatureRemoved(evt){
//	 //count the number of elements selected	   
//	 document.getElementById('counter').innerHTML = 0;
//	 //update information in textarea
//	 document.getElementById('output').value= '';
//	 //clear selected_features
//   selected_features=[];
//   }
   
   function onFeatureAdded(evt){
	   var link=evt.feature;
	   var crLayer=evt.feature.layer;
	   var linkid=link.id;
	   var startFlag=true;
	   var endFlag=true;
	   var startNode;
	   var endNode;
	   var arrPoints = link.geometry.getVertices(true);	 
	   var proj_3857 = new OpenLayers.Projection('EPSG:900913');
	   var start=arrPoints[0].clone();	   //start node geometry
	   var end=arrPoints[arrPoints.length-1].clone();//end node geometry
	   //link information
	   var length=link.geometry.getGeodesicLength(proj_3857);
	   var linkType=document.getElementById("link_type").value; 
	   var max_speed=document.getElementById("max_sd").value;
	   var cap=document.getElementById("cap").value;
	   var jd=document.getElementById("jd").value;
	   var lane=document.getElementById("lane").value;
	   //alert(linkType+","+max_speed+","+capacity+","+jammedDensity)
	   var nodeLayer = map.getLayersByName("Node Layer")[0];
	   
	   
	   var nodes = nodeLayer.features;//get all nodes
	   for (var i=0;i<nodes.length;i++ ){//loop through all nodes
		   if (start.equals(nodes[i].geometry)){//start node already exists
			   startNode=nodes[i];//use existed one
			  // alert("start point equals:"+startNode.id);
			   startNode.attributes.downstream.push(linkid);//update node.downstream
			   startFlag=false;
		   }
		   if (end.equals(nodes[i].geometry)){//end node already exists
			   endNode=nodes[i];//use existed one
			 //  alert("end point equals:"+endNode.id);
			   endNode.attributes.upstream.push(linkid);//update node.upstream
			   endFlag=false;
		   }
	   }
	   
	   if (startFlag){//node doesn't exist, define new node
		   startNode = new OpenLayers.Feature.Vector(start,{id:start.id.split("_").pop(),upstream:[],downstream:[linkid]});
		   startNode.attributes.id= startNode.id.split("_").pop();
		   node.addFeatures([startNode]);
	   }
	   if (endFlag){//node doesn't exist, define new node
		   endNode= new OpenLayers.Feature.Vector(end,{id:end.id.split("_").pop(),upstream:[linkid],downstream:[]});
		   endNode.attributes.id= endNode.id.split("_").pop();
		   node.addFeatures([endNode]);
	   }
	   //update attributes for the link
	   link.attributes={id:linkid.split("_").pop(),origin:startNode.id, destination:endNode.id, link_type:linkType, FF:max_speed, Qc:cap, kj:jd, noOfLanes:lane, length: length};
	   crLayer.redraw();
   }
   
   function removeFeature(){//remove features on current layer
	   if (selected_features.length!=0){
		   map.layers[document.getElementById("link_type").value].removeFeatures(selected_features);  
	   }
		 //count the number of elements selected	   
		 document.getElementById('counter').innerHTML = 0;
		 //update information in text area
		 document.getElementById('output').value= '';
		 //clear selected_features
	     selected_features=[];
	     updateDirection();
   }
   
   
   function snapping_check(){
	   var check=document.getElementById('snapping');
	   if(check.checked) {
		   snap.activate();
		   }
	   else {
		   snap.deactivate();
		   }
	   }
   //translate type Id to required type
   function show_link_type(typeId){
	   switch (typeId){
	   case "2":
		   return "Freeway";
		   break;
	   case "3":
		   return "HOV/HOT";
		   break;
	   case "4":
		   return "FF connector";
		   break;
	   case "5":
		   return "On/Off ramp";
		   break;
	   case "6":
		   return "Local arterial";
		   break;
	   case "7":
		   return "Local street";
	   default:
		   return "N/A";
		   break;
		   }
   }
   
   function update_text_area(feature){
	   var result='';
	   if (feature.length!=0){
		   for (var i=0; i<feature.length;i++){
			   result +='Link_'+feature[i].id.split("_").pop()//link ID
			   +':node_'+feature[i].attributes.origin.split("_").pop()//upstream node
			   +'->node_'+feature[i].attributes.destination.split("_").pop()//downstream node
			   +"|"+show_link_type(feature[i].attributes.link_type)
			   +"|FF:"+feature[i].attributes.FF
			   +"|Qc:"+feature[i].attributes.Qc
			   +"|kj:"+feature[i].attributes.kj
			   +"|Lane:"+feature[i].attributes.noOfLanes
			   +"|Length:"+feature[i].attributes.length
			   +'\r\n';
		   }
	   }
	   return result;
   }
   
   function onChange(){	   
	   var cr_layer=map.layers[document.getElementById("link_type").value];
	   snap.setLayer(cr_layer);
	   
	   //update editable layer for draw control
	   var drawActive = drawControls.line.active;	   
	   if (drawActive){
		   drawControls.line.deactivate();
	   }
	   drawControls.line.layer = cr_layer
	   if(drawActive) {
		   drawControls.line.activate();
       }
	   //update editable layer for select control
	   drawControls.select.unselectAll();
	   var selectActive = drawControls.select.active;
	   if (selectActive){
		   drawControls.select.deactivate();
	   }
	   drawControls.select.layer = cr_layer;
	   if(selectActive) {
		   drawControls.select.activate();
       }
   }
      function getLinkFile(){
	   var result='';
	   for (var i=2;i<=7;i++){ 
		   var feature=map.layers[i].features;
		   if (feature.length!=0){
			   for (var j=0; j<feature.length;j++){
				   result +=feature[j].id.split("_").pop()//link ID
		   		   +','+feature[j].attributes.origin.split("_").pop()//upstream node
		   		   +','+feature[j].attributes.destination.split("_").pop()//downstream node
		   		   +","+feature[j].attributes.link_type
		   		   +","+feature[j].attributes.FF
		   		   +","+feature[j].attributes.Qc
		   		   +","+feature[j].attributes.kj
		   		   +","+feature[j].attributes.noOfLanes
		   		   +","+(feature[j].attributes.length/1609.34).toFixed(4)//convert to miles, two decimals
		   		   +'\r\n';
				   }
			   }
		   }
	   document.getElementById('output').value= result;
	   }
   
   function getDemand(){
	   var nodeLayer = map.getLayersByName("Node Layer")[0];
	   var result = ""; //output results
	   var nodes = nodeLayer.features;//get all nodes
	   for (var i=0;i<nodes.length;i++ ){//loop through all nodes
		   if (nodes[i].attributes.upstream.length==0){//demand nodes
			   result +=nodes[i].id.split("_").pop()+',*'+'\r\n';//use * as place holder
		   }
	   }
	   document.getElementById('output').value= result;   
   }
   
   function getTP(){//note: add dummy links to origin nodes
	   var nodeLayer = map.getLayersByName("Node Layer")[0];
	   var result = ""; //output results
	   var up = 1;//no of upstream links
	   var down = 1;//no of downstream links
	   var nodes = nodeLayer.features;//get all nodes
	   for (var i=0;i<nodes.length;i++ ){//loop through all nodes
		   up = nodes[i].attributes.upstream.length;
		   down = nodes[i].attributes.downstream.length;
		   if (down>1){
			   result+=nodes[i].id.split("_").pop()+','
			   +up+','+nodes[i].attributes.upstream.map(simplify).toString()+','
			   +down + ','+nodes[i].attributes.downstream.map(simplify).toString()
			   +Array(up*down+1).join(',*')+'\r\n';	   		   		   
		   }
		   
	   }
	   document.getElementById('output').value= result;  
   }
   
   function getLatLong(){
	   var result='';
	   for (var i=2;i<=7;i++){//loop all link layers
		   var feature=map.layers[i].features;
		   if (feature.length!=0){
			   for (var j=0; j<feature.length;j++){//for all links in the current layer			
				   result+=simplify(feature[j].id)+",";
				   result+=feature[j].clone().geometry.getVertices().map(pointLatLon).toString()+"\r\n";
				   }
			   }
		   }
	   document.getElementById('output').value= result;
   }
   
   
   
   
   function simplify(str){
	   return str.split("_").pop();
   }
   
   function pointLatLon(point){
	   var fromProjection = new OpenLayers.Projection("EPSG:900913");   // Transform from (used by google and OpenStreetMap)
	   var toProjection   = new OpenLayers.Projection("EPSG:4326"); // to EPSG:4326 
	   return point.transform(fromProjection,toProjection).toShortString();
   }

   
 