//    This file is part of OpenLoft.
//
//    OpenLoft is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    OpenLoft is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with OpenLoft.  If not, see <http://www.gnu.org/licenses/>.
//
//    Author: Falados Kapuskas
	//-- CONSTANTS --//
list HTTP_PARAMS = [
	HTTP_METHOD, "POST",
	HTTP_MIMETYPE,"application/x-www-form-urlencoded"
];
	list BASE_DIALOG = [
	"[REZ] Rez the Disks","REZ",
	"[TOOLS] Tools Menu","TOOLS",
	"[OPTIONS] Options Menu","OPTIONS",
	"[SELECTION] Transforms for Selection","SELECTION",
	"[SAVE] Save Sculpt","SAVE",
	"[KILL CUTS] Kill all cuts","KILL CUTS",
	"[CLEANUP] Clean up all tools and cuts","CLEANUP"
];
	list OPTIONS_MENU = [
	"[PART SIZE] Change Particle Size","PART SIZE",
	"[PART TYPE] Change Particle Line Style","PART TYPE",
	"[PART COLOR] Change Particle Color","PART COLOR",
	"[ACCESS] Access Levels","ACCESS",
	"[RESOLUTION] Change Resolution","RESOLUTION",
	"[CUT THICK] Change Cut Thickness","CUT THICK",
	"[BASE TEX] Change Base Texture","BASE TEX"
];
	list SELECTION_MENU = [
	"[POS] Distribute position evenly","POS",
	"[ROT] Distribute rotation evenly","ROT",
	"[SHAPE] interpolate vertex data","SHAPE",
	"[SPLINE] Activate Spline","SPLINE",
	"[LOAD] Load a sculpt","LOAD",
	"[PASTE CUT] Paste cut on selection","PASTE CUT",
	"[DESELECT] Deselect the seleciton","DESELECT"
];
	list TOOL_MENU = [
	"[CUT MIRROR] Mirror tool for cuts","CUT MIRROR",
	"[L PUSHER] Cut Pusher (Linear)","L PUSHER",
	"[R PUSHER] Cut Pusher (Radial)","R PUSHER"
];
	list RENDER_DIALOG = 
[
	"[ENCLOSER] Rez an encloser.","ENCLOSER",
	"[RENDER] Render the sculpt under the encloser.","RENDER",
	"[SMOOTH] Change the smoothing parameter","SMOOTH"
];
	list ACCESS_DIALOG =
[
	"[EVERYONE] Everyone can use this","EVERYONE",
	"[GROUP] Group-members can you this","GROUP",
	"[OWNER] Only Owner can use this","OWNER"
];
	list SPLINE_DIALOG =
[
	"[BEZ STOP] Stops slices from following the spline","BEZ STOP",
	"[BEZ START] Lets slices follow the bezier curve","BEZ START",
	"[ADD CTRL] Adds a control point","ADD CTRL",
	"[DEL CTRL] Deletes the last control point","DEL CTRL",
	"[BEZ SCALE] Scale slices along the bezier","BEZ SCALE",
	"[BEZ ROT] Rotate slices along the bezier","BEZ ROT",
	"[STOP SCALE] Stop scaling slices","STOP SCALE",
	"[STOP ROT] Stop rotating slices","STOP ROT"
];
	list SMOOTH_DIALOG =
[
	"[NONE] No smoothing, use raw vertex data","NONE",
	"[LINEAR] Blurs the image slightly to smooth out bumps","LINEAR",
	"[GAUSSIAN] Blurs the image, but preserves some finer details","GAUSSIAN"
];
	list RESOLUTIONS =
[
	"32x32",<32,32,0>,
	"16x16",<16,16,0>,
	"8x8",<8,8,0>,
	"64x16",<64,16,0>,
	"128x8",<128,8,0>,
	"256x4",<256,4,0>,
	"16x64",<16,64,0>,
	"8x128",<8,128,0>,
	"4x256",<4,256,0>
];
	list ACCESS_LEVELS = [
	"OWNER",2,
	"GROUP",1,
	"EVERYONE",0
];
	//CONSTANTS (sorta)
	//CUT object (the crossection of the sculpt with verticies)
string  NODE_NAME = "cut";
	//Control Point
string  CONTROL_NAME = "control";
	//MASK for accep
integer CHANNEL_MASK         = 0xFFFFFF00;
integer CONTROL_POINT_MASK     = 0xFF;
integer COMMON_CHANNEL         = -2101; //War was begining
integer BROADCAST_CHANNEL;    //Set later on
integer DIALOG_CHANNEL;        //Set later on
integer ENCLOSE_CHANNEL;    //Set later on 
integer RESOLUTION_CHANNEL;    //Set later on;
integer TOTAL_CUTS               = 32;
integer VERTS_PER_CUT        = 32;
integer ENCLOSED            = FALSE;
string  URL;                //Set Via Notecard
integer ACCESS_LEVEL        = 2;    //Defaults to Owner Onl
key BASE_TEXTURE             = "3341baad-162b-02b5-4080-7ed96b67cf23";
	//-- Globals --//
key gOperatorKey;                    //Current dialog operator
key gDataserverRequest;                //Dataserver Request Key
key gHTTPRequest;                    //HTTP Request key
string gBlurType = "none";            //Blur function to use on the sculpt image
integer gHasRezedCuts;                //Cuts have been rezed
integer gRenderOnDataserver;        //Render when the dataserver event is triggered
vector gEncloseScale = ZERO_VECTOR;    //Position of the encloser tool
vector gEnclosePos = ZERO_VECTOR;    //Scale of the encloser tool
integer gListenHandle_Broadcast;    //Listen on Broadcast Channel
integer gListenHandle_Common;        //Listen on Common Channel
integer gListenHandle_Dialog;        //Listen on Dialog Channel
integer gListenHandle_Errors;        //Render Errors
integer gListenHandle_Success;        //Render Success
integer gCutUploadResponses;        //Successful responses received so far from cuts
integer gAnnounceParams;            //Announce setup params on object rez
	//Selection
integer gSelectionStart;
integer gSelectionEnd;
integer gSelectionValid=FALSE;
	//Particle Parameters: type    size      color
list gParticleParams = [1.0,<0.2,0.2,0>,<1,1,1>];
	//-- FUNCTIONS --//
	announceSetupParams()
{
	llRegionSay(BROADCAST_CHANNEL,"#setup#" + llList2CSV([VERTS_PER_CUT,ACCESS_LEVEL,TOTAL_CUTS]));
}
	//Starts the Rendering Process by announcing and waiting
//for replies.  Once all replies are in, a final request
//is sent that informs the server to compile the image.
render()
{
	gCutUploadResponses = 0;
	llListenRemove(gListenHandle_Errors);
	llListenRemove(gListenHandle_Success);
	gListenHandle_Errors     = llListen(-2002,"","","");
	gListenHandle_Success     = llListen(-2001,"","","");
	llRegionSay(BROADCAST_CHANNEL,"#render#"+URL);
}
	retextureBase()
{
	llSetPrimitiveParams([
	PRIM_TEXTURE,-1, TEXTURE_BLANK, <1,1,0>, ZERO_VECTOR,0.0,
	PRIM_TEXTURE,0, BASE_TEXTURE, <1,1,0>, ZERO_VECTOR,0.0,
	PRIM_TEXTURE,5, BASE_TEXTURE, <1,1,0>, ZERO_VECTOR,PI
	]);
}
	dialog(string message, list dialog, key id)
{
	gOperatorKey = id;
	gListenHandle_Dialog = llListen(DIALOG_CHANNEL,"",id,"");
	string m = message + llDumpList2String( llList2ListStrided(dialog,0,-1,2) , "\n");
	llDialog(id,m,llList2ListStrided( llDeleteSubList(dialog,0,0), 0,-1,2),DIALOG_CHANNEL);
}
	//Get Access Allowed/Denited
integer has_access(key agent)
{
	//Everyone has access
	if(ACCESS_LEVEL == 0) return TRUE;
	else
	//Owner has access
	if(ACCESS_LEVEL == 2)
	{
	return agent == llGetOwner();
	}
	else
	//Group has access
	if(ACCESS_LEVEL == 1)
	{
	return llSameGroup(agent);
	}
	//Failed
	return FALSE;
}
	processDialog(integer channel,string name, key id, string button)
{
	if(channel != DIALOG_CHANNEL) return;
	gOperatorKey = id;
	llListenRemove(gListenHandle_Dialog);
	/// --- BASE DIALOG --- ///
	// - REZ BUTTON - //
	//TODO: Implement the REZ button
	if ( button == "REZ" )
	{
	gAnnounceParams = TRUE;
	llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,(string)gOperatorKey,"#rez#");
	return;
	}
	if( button == "TOOLS" )
	{
	dialog("Choose a tool to rez:\n",TOOL_MENU,id);
	return;
	}
	if( button == "OPTIONS" )
	{
	dialog("Choose an option to change\n",OPTIONS_MENU,id);
	return;
	}
	if( button == "SELECTION" )
	{
	dialog("Choose an action to apply on the selection\n",SELECTION_MENU,id);
	return;
	}
	if( button == "SAVE" )
	{
	//TODO: Add Save Function
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "KILL CUTS" )
	{
	//TODO: Add Kill Cuts function
	llOwnerSay(button + " button not implemented");
	return;
	}
	if ( button =="CLEANUP")
	{
	list d = [
		"[DELETE] Yes, Delete everything","DELETE",
		"[CANCEL] No way! Get me the hell out of here!","CANCEL"
	];
	dialog("Are you sure you want to clean up? This will delete everything!\n",d,id);
	return;
	}
	if (  button == "DELETE" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#die#");
	gHasRezedCuts = FALSE;
	return;
	}
	/// --- OPTIONS MENU --- ///
	if( button == "ACCESS" )
	{
	dialog("Choose an access level:\n",ACCESS_DIALOG,id);
	return;
	}
	integer access = llListFindList(ACCESS_LEVELS,[button]);
	if (access != -1 ) {
	ACCESS_LEVEL = llList2Integer(ACCESS_LEVELS,access+1);
	announceSetupParams();
	return;
	}
	if ( button == "RESOLUTION") 
	{
	gListenHandle_Dialog = llListen(RESOLUTION_CHANNEL,"",id,"");
	llDialog(id,"Pick a resolution",llList2ListStrided(RESOLUTIONS,0,-1,2),RESOLUTION_CHANNEL);
	return;
	}
	if ( button == "BASE TEX" )
	{
	//TODO: Implement Base Texture Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if ( button == "PART SIZE" )
	{
	//TODO: Implement Part Size Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if ( button == "PART TYPE" )
	{
	//TODO: Implement Part type Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if ( button == "PART COLOR" )
	{
	//TODO: Implement Part color Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "CUT THICK")
	{
	//TODO: Implement Cut Thickness Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	/// --- SELECTION MENU --- ///
	if( button == "POS" )
	{
	//TODO: Implement Position Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "ROT" )
	{
	//TODO: Implement Rotation Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "SHAPE" )
	{
	//TODO: Implement Rotation Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "SPLINE" )
	{
	//TODO: Implement Rotation Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "LOAD" )
	{
	//TODO: Implement Rotation Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "PASTE CUT" )
	{
	//TODO: Implement Rotation Button
	llOwnerSay(button + " button not implemented");
	return;
	}
	if( button == "DESELECT" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#deselect#");
	return;
	}
	if ( button =="RENDERING") 
	{
	dialog("Choose an action:\n",RENDER_DIALOG,id);
	return;
	}
	if ( button =="SMOOTH")
	{
	dialog("Pick a smoothing option\n",SMOOTH_DIALOG,id);
	return;
	}
	if ( button =="SPLINE")
	{
	dialog("Pick a SPLINE action:\n",SPLINE_DIALOG,id);  
	return;
	}
	// - RENDER MENU - //
	if ( button =="ENCLOSER"){
	list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
	vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
	llRegionSay(BROADCAST_CHANNEL,"#enc-die#");
	gAnnounceParams = TRUE;
	llRezObject("Enclose Tool",llGetPos(),ZERO_VECTOR,ZERO_ROTATION,BROADCAST_CHANNEL);
	}
	if ( button =="RENDER"){
	if(gEncloseScale != ZERO_VECTOR) {
		gOperatorKey=id;
		gRenderOnDataserver = TRUE;
		gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
	} else {
		llOwnerSay("You must first ENCLOSE the sculpt before you can render it");
	}
	}            
	// - TOOLS MENU - //   
	if(  button =="SHOW" ||  button =="HIDE") {
	llRegionSay(BROADCAST_CHANNEL,"#" +llToLower(button)+"#");
	return;
	}         
	if ( button =="MIRROR") {
	list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
	vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
	gAnnounceParams = TRUE;
	llRezObject("Mirror Tool",pos,ZERO_VECTOR,ZERO_ROTATION,BROADCAST_CHANNEL);
	}
	if ( button =="COPY") {
	list d = llGetObjectDetails(id,[OBJECT_POS,OBJECT_ROT]);
	vector pos = llList2Vector(d,0) + llRot2Fwd(llList2Rot(d,1))*2;
	gAnnounceParams = TRUE;
	llRezObject("Node Tool",pos,ZERO_VECTOR,llEuler2Rot(<-PI_BY_TWO,0,0>),BROADCAST_CHANNEL);
	}            
	// - SMOOTH MENU - //
	if ( button =="LINEAR" || button == "GAUSSIAN" || button == "NONE"){
	gBlurType = llToLower(button);
	return;
	}
	// - SPLINE MENU -- //
	if(  button =="ADD CTRL")
	{
	llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,"","#add_control#");
	return;
	}
	if(  button =="DEL CTRL")
	{
	llMessageLinked(LINK_THIS,BROADCAST_CHANNEL,"","#remove_control#");
	return;
	}
	if(  button =="BEZ STOP")
	{
	llRegionSay(BROADCAST_CHANNEL,"#bezier-stop#");                
	return;
	}
	if(  button =="BEZ START")
	{
	llRegionSay(BROADCAST_CHANNEL,"#bezier-start#");    
	return;
	}
	if(  button =="BEZ SCALE" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["scale",1]));
	return;
	}
	if(  button =="STOP SCALE" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["scale",0]));
	return;
	}
	if(  button =="BEZ ROT" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["rot",1]));
	return;
	}
	if(  button =="STOP ROT" )
	{
	llRegionSay(BROADCAST_CHANNEL,"#bez-caps#" + llList2CSV(["rot",0]));
	return;
	}
	}
	//-- STATES --//
	default
{
	state_entry()
	{
	//Random (negative) channel
	BROADCAST_CHANNEL= llFloor(llFrand(-1000000) - 1000000) & CHANNEL_MASK;
	DIALOG_CHANNEL = llFloor(llFrand(1000000) + 1000000);
	ENCLOSE_CHANNEL = llFloor(llFrand(-1000000) - 1000000);
	RESOLUTION_CHANNEL = llFloor(llFrand(-1000000) - 1000000);
	llListen(BROADCAST_CHANNEL,"","","");
	llListen(COMMON_CHANNEL,"","","");
	}
	//Reset on rez to get a new broadcast channel
	on_rez(integer p){
	llResetScript();
	}
	listen(integer c, string st, key id, string m)
	{
	if(!has_access(llGetOwnerKey(id))) return;
	processDialog(c,st,id,m);
	if( c == BROADCAST_CHANNEL)
	{
		if(llSubStringIndex(m,"#enc-size#") == 0)
		{
		    list enc = llCSV2List(llGetSubString(m,10,-1));
		    gEnclosePos = (vector)llList2String(enc,0);
		    gEncloseScale = (vector)llList2String(enc,1);
		    return;
		}
		if(llSubStringIndex(m,"#sel-start#") == 0)
		{
		    gSelectionStart = (integer)llGetSubString(m,11,-1);
		    return;
		}
		if(llSubStringIndex(m,"#sel-end#") == 0)
		{
		    gSelectionEnd = (integer)llGetSubString(m,9,-1);
		    if(gSelectionStart != -1) 
		    {
		        llRegionSay(BROADCAST_CHANNEL,"#selection#" + llList2CSV([gSelectionStart,gSelectionEnd]) );
		        gSelectionValid = TRUE;
		    }
		    return;
		}
	}
	if( c == RESOLUTION_CHANNEL)
	{
		llListenRemove(gListenHandle_Dialog);
		integer i = llListFindList(RESOLUTIONS,[m]);
		if(i != -1)
		{
		    vector v = llList2Vector(RESOLUTIONS,i+1);
		    TOTAL_CUTS = (integer)v.x;
		    VERTS_PER_CUT = (integer)v.y;
		}
	}
	//Successful Upload Responses
	if( c == -2001 ) {
		++gCutUploadResponses;
		float t = (float)gCutUploadResponses/TOTAL_CUTS;
		llSetText("Render Progress : " + (string)llCeil(t*100) + "%",<1,1,0>,1.0);
		llSetColor(<1,0,0>*(1-t) + <0,1,0>*(t),ALL_SIDES);
		if( gCutUploadResponses == TOTAL_CUTS ) {
		    if(URL != "" && URL != "none") {
		        gHTTPRequest = llHTTPRequest(URL + "action=render",HTTP_PARAMS,
		            "scale=" + llEscapeURL((string)gEncloseScale) +
		            "&org=" + llEscapeURL((string)gEnclosePos) +
		            "&smooth=" + gBlurType +
		            "&w=" + (string)VERTS_PER_CUT +
		            "&h=" + (string)TOTAL_CUTS
		        );
		    }
		    llSetColor(<1,1,1>,ALL_SIDES);
		    llSetText("",ZERO_VECTOR,0.0);
		}
	}
	//Errored Responses
	if( c == -2002 ) {
		llOwnerSay("Error on row " + m);
	}
	if( c == COMMON_CHANNEL)
	{
		if(m == "#send-bcast#")
		{
		    llRegionSay(COMMON_CHANNEL,"#bcast#" + (string)BROADCAST_CHANNEL);
		}
	}
	}
	link_message(integer sn, integer n, string s, key id)
	{
	//Done Rezing
	if( id == "#rez_fin#" )
	{
		llRegionSay(BROADCAST_CHANNEL,"#bez-start#"+ llList2CSV([0,TOTAL_CUTS-1]));
		gHasRezedCuts = TRUE;
		gDataserverRequest = llGetNotecardLine("OpenLoft URL",0);
	}
	}
	touch_start(integer total_number)
	{
	if(!has_access(llDetectedKey(0))) return;
	dialog("Choose an action:\n",BASE_DIALOG,llDetectedKey(0));
	}
	dataserver( key request_id, string data)
	{
	if( gDataserverRequest == request_id) {
		URL = data;
		if( URL != "URL HERE") {
		    if(llSubStringIndex(URL,"?") == -1) URL = URL + "?";
		} else {
		    llOwnerSay("You must replace the url in the 'OpenLoft URL' notecard");
		    URL = "none";
		}
		if(gRenderOnDataserver) 
		{
		    gRenderOnDataserver = FALSE;
		    render();
		}
		announceSetupParams();
	}
	}
	object_rez(key id)
	{
	llSleep(0.2);
	if(gAnnounceParams)
	{
		announceSetupParams();
	}
	}
	//This is here simply to echo the links that the server replies with
	http_response( key request_id, integer status, list meta, string data)
	{
	if(gHTTPRequest != request_id) return;
	if( status == 200 ) { //OK
		if( llStringTrim(data,STRING_TRIM) != "" )
		    llInstantMessage(gOperatorKey,data);
	} else {
		    llInstantMessage(gOperatorKey,"Server Error: " + (string)status + "\n" + llList2CSV(meta) + "\n" + data);
	}
	}
}
	