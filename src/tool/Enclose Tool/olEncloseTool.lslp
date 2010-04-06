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
//    Authors: Falados Kapuskas, JoeTheCatboy Freelunch
	integer CHANNEL_MASK = 0xFFFFFF00;
integer DIALOG_CHANNEL;
integer SIZE_CHANNEL;
integer BROADCAST_CHANNEL=-1;
integer ENCLOSE_CHANNEL=-1;
integer ACCESS_LEVEL = 2;
integer ROWS;
integer gListenHandle_Enclose;
integer gListenHandle_Agent;
integer gScaleResponses;
integer gShifted = FALSE;
vector gMax;
vector gMin;
float MAX_RESPONSE_TIME = 15.0;
key gOperator;
integer gAutoEnclose;
integer gSculptType;
integer gWorking;
vector gScale;
vector gPos;
	list MAIN_DIALOG = [
	"[AUTO] Auto-encloses your sculpture.","AUTO",
	"[REZ] Rezes a sculpted prim in the same dimensions","REZ",
	"[SAVE] Save the enclosed sized and position","SAVE",
	"[DESTROY] Destroy the enclose tool","DESTROY"
];
	list SHIFT_OFF = [
	"[SHIFT] Shift the encloser 10m to the left.","SHIFT"
];
	list SHIFT_ON = [
	"[UNSHIFT] Shift back to original position","UNSHIFT"
];
	list SCULPT_DIALOG = [
	"[SPHERE] Converge top & bottom, stitch left side to right","SPHERE",
	"[TORUS] Stitch top to bottom, stitch left side to right","TORUS",
	"[PLANE] No stitching or converging","PLANE",
	"[CYLINDER] Stitch left side to right","CYLINDER"
];
	dialog(string message, list dialog, key id, integer channel)
{
	llListenRemove(gListenHandle_Agent);
	gListenHandle_Agent = llListen(channel,"",id,"");
	string m = message + llDumpList2String( llList2ListStrided(dialog,0,-1,2) , "\n");
	llDialog(id,m,llList2ListStrided( llDeleteSubList(dialog,0,0), 0,-1,2),channel);
}
rez(integer type)
{
	gSculptType = type;
	llRezObject("test-sculpt",llGetPos() + llRot2Fwd(llGetRot())*5,ZERO_VECTOR,ZERO_ROTATION,SIZE_CHANNEL);
}
modified()
{
	if(!gWorking)
	{
	llSetText("Modified (Not Saved)",<.5,0,1>,1.0);
	llSetColor(<.5,0,1>,ALL_SIDES);
	}
}
	save()
{
	gWorking = FALSE;
	gScale = llGetScale();
	gPos = llGetPos();
	llSetText("Ready",<1,1,1>,1.0);
	llSetColor(<1,1,1>,ALL_SIDES);
	llRegionSay(BROADCAST_CHANNEL,"#enc-size#" + llList2CSV([gPos,gScale]));
}
	autoenclose()
{
	gWorking = TRUE;
	llSetText("",<1,1,1>,1.0);
	ENCLOSE_CHANNEL = llFloor( llFrand( -1000000 ) - 1000000 );
	gScaleResponses = 0;
	llListenRemove(gListenHandle_Enclose);
	gListenHandle_Enclose = llListen(ENCLOSE_CHANNEL,"","","");
	gMin = <9999,9999,9999>;
	gMax = <-9999,-9999,-9999>;
	llShout(BROADCAST_CHANNEL,"#enclose#" + (string)ENCLOSE_CHANNEL);
	gAutoEnclose = TRUE;
	llResetTime();
}
	processRootCommands(string message)
{
	if( llSubStringIndex(message,"#setup#") == 0)
	{
	list l = llCSV2List(llGetSubString(message,7,-1));
	ACCESS_LEVEL = (integer)llList2String(l,1);  
	ROWS =  (integer)llList2String(l,2);
	}    
	if( message == "#die#" || message == "#enc-die#") { llDie(); }  
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
	minmax(vector vert) {
	//Min
	if( vert.x < gMin.x ) gMin.x = vert.x;
	if( vert.y < gMin.y ) gMin.y = vert.y;
	if( vert.z < gMin.z ) gMin.z = vert.z;
	//Max
	if( vert.x > gMax.x ) gMax.x = vert.x;
	if( vert.y > gMax.y ) gMax.y = vert.y;
	if( vert.z > gMax.z ) gMax.z = vert.z;
}
	default
{
	on_rez(integer i)
	{
	if(i == 0) return;
	gPos = llGetPos();
	gScale = llGetScale();
	DIALOG_CHANNEL = llFloor(llFrand(1000000) + 1000000);
	SIZE_CHANNEL = llFloor(llFrand(-1000000) - 1000000);
	BROADCAST_CHANNEL = (i & CHANNEL_MASK);
	llListen(BROADCAST_CHANNEL, "","","");
	llSetText("Ready",<1,1,1>,1.0);
	llSetTimerEvent(0.1);
	}
	listen(integer channel, string name, key id, string message)
	{    
	key k = llGetOwnerKey(id);
	if(!has_access(k)) return;        
	if(channel == BROADCAST_CHANNEL)
	{
		processRootCommands(message);
		return;
	}
	//Size Reponses
	if( channel == ENCLOSE_CHANNEL )
	{
		llResetTime();
		++gScaleResponses;
		integer break = llSubStringIndex(message,"|");
		if( break != -1 )
		{
		    minmax((vector)llGetSubString(message,0,break-1));
		    minmax((vector)llGetSubString(message,break+1,-1));
		} else {
		    minmax((vector)message);
		}
		float t = (float)gScaleResponses/ROWS;
		llSetText("Enclose Progress : " + (string)llCeil(t*100) + "%",<1,1,0>,1.0);
		llSetColor(<1,0,0>*(1-t) + <0,1,0>*(t),ALL_SIDES);
		if( gScaleResponses >= ROWS ) {
		      llSetColor(<1,1,1>,ALL_SIDES);
		    llSetText("",ZERO_VECTOR,0.0);
		
		    vector pos = (gMin + gMax)*0.5;
		    vector scale = <99,99,99>;
		    if( llFabs(gMax.x-pos.x) > llFabs(gMin.x-pos.x) ) scale.x = 2*llFabs(gMax.x-pos.x);
		    else scale.x = 2*llFabs(gMin.x-pos.x);
		    
		    if( llFabs(gMax.y-pos.y) > llFabs(gMin.y-pos.y) ) scale.y = 2*llFabs(gMax.y-pos.y);
		    else scale.y = 2*llFabs(gMin.y-pos.y);
		    
		    if( llFabs(gMax.z-pos.z) > llFabs(gMin.z-pos.z) ) scale.z = 2*llFabs(gMax.z-pos.z);
		    else scale.z = 2*llFabs(gMin.z-pos.z);
		    
		    if( llVecMag(scale) < 17.4 ) {
		        llSetScale(scale*1.01);
		        llSetPos(pos);
		        save();
		        llRegionSay(BROADCAST_CHANNEL,"#enc-size#" + llList2CSV([gPos,gScale]));
		    } else {
		        llInstantMessage(gOperator,"Enclose Failed - Size Too Big");
		    }
		    gWorking = FALSE;
		    gAutoEnclose = FALSE;
		    llListenRemove(gListenHandle_Enclose);
		}
	}
		if(channel == DIALOG_CHANNEL)
	{
		if(message == "AUTO")
		{
		    autoenclose();
		    return;
		}
		if(message == "SAVE")
		{
		    save();
		    llInstantMessage(id,"Saved Enclosure");
		}
		if( message == "DESTROY" )
		{
		    llInstantMessage(id,"Destroyed Enclosure, Not Saved.");
		    llDie();
		}
		
		if( message == "REZ" )
		{
		    dialog("Choose a Stiching Type:\n", SCULPT_DIALOG,id,DIALOG_CHANNEL);
		    return;
		}
		if( message == "SPHERE" ) 
		{
		    rez(PRIM_SCULPT_TYPE_SPHERE);
		    return;
		}
		if( message == "TORUS")
		{
		    rez(PRIM_SCULPT_TYPE_TORUS);
		    return;
		}
		if( message == "PLANE" ) 
		{
		    rez(PRIM_SCULPT_TYPE_PLANE);
		    return;
		}
		if(message == "CYLINDER")
		{
		    rez(PRIM_SCULPT_TYPE_CYLINDER);
		    return;
		}
		if( message == "SHIFT" )
		{
		    gShifted = TRUE;
		    llSetPos(gPos + llRot2Left(llGetRot())*10);
		}
		if( message == "UNSHIFT")
		{
		    gShifted = FALSE;
		    llSetPos(gPos);
		}
	}
	}
	touch_start(integer i)
	{
	key k = llDetectedKey(0);
	if(!has_access(k)) return;
	gOperator = k;
	list g = SHIFT_OFF;
	if(gShifted) g = SHIFT_ON;
	dialog("Choose an action:\n", MAIN_DIALOG + g, k,DIALOG_CHANNEL);
	}
	timer() {
	if(llGetPos() != gPos && !gShifted) modified();
	if(llGetScale() != gScale) modified();
	if(llGetRot() != ZERO_ROTATION) llSetRot(ZERO_ROTATION);
	if( gAutoEnclose && llGetTime() > MAX_RESPONSE_TIME)
	{
		gAutoEnclose = FALSE;
		llSetText("Ready",<1,1,1>,1.0);
		llSetColor(<1,1,1>,ALL_SIDES);
		llListenRemove(gListenHandle_Enclose);
		llInstantMessage(gOperator,"Enclose Failed - Not all nodes responded in time");
	}
	}
	object_rez(key id)
	{
	llSleep(0.25);
	llRegionSay(SIZE_CHANNEL,llList2CSV([gScale,gSculptType]));
	}
}