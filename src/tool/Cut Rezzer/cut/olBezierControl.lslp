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
//    Authors: Falados Kapuskas
	//-- CONSTANTS --//
integer BROADCAST_CHANNEL;
integer CHANNEL_MASK = 0xFFFFFF00;
integer CONTROL_POINT_MASK = 0xFF;
integer ACCESS_LEVEL        = 2;    //2 = OWNER, 1 = GROUP, 0 = ALL
integer MY_ROW;            //Set on_rez
integer IS_ACTIVE = FALSE;
	//LinkCommands
integer COMMAND_CTYPE       = -1;
integer COMMAND_RESET       = -2;
integer COMMAND_SCALE       = -3;
integer COMMAND_VISIBLE     = -4;
integer COMMAND_RENDER      = -5;
integer COMMAND_CSECT       = -6;
integer COMMAND_INTERP      = -7;
integer COMMAND_SIZE        = -8;
integer COMMAND_COPY        = -9;
integer COMMAND_SENDNODES   = -10;
integer COMMAND_SPAWNSHAPE  = -11;
integer COMMAND_SETUP_PARAMS= -12;
	string control_points;
	//Globals
integer gListenHandle;
list gBezierCapabilities;
string gBezierControls;
//-- FUNCTIONS --//
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
	handleRootCommand(string message) 
{
	if(llSubStringIndex(message,"#bez-ctrl#")==0)
	{
	gBezierControls = llGetSubString(message,10,-1);
	llMessageLinked(LINK_THIS,0,gBezierControls,"#bez_ctrl#");
	}
	if(llSubStringIndex(message,"#bez-caps#")==0)
	{
	list bc = llCSV2List(llGetSubString(message,10,-1));
	while(bc != [])
	{
		integer i = llListFindList(gBezierCapabilities,llList2List(bc,0,0));
		if( i == -1)
		{
		    gBezierCapabilities += llList2List(bc,0,1);
		} else {
		    gBezierCapabilities = llListReplaceList(gBezierCapabilities,llList2List(bc,0,1),i,i+1);
		}
		bc = llDeleteSubList(bc,0,1);
	}
	llMessageLinked(LINK_THIS,0,llList2CSV(gBezierCapabilities),"#bez_caps#");
	}
	if(llSubStringIndex(message,"#bez-start#")==0)
	{
	list range = llCSV2List(llGetSubString(message,11,-1));
	integer start = llList2Integer(range,0);
	integer end = llList2Integer(range,1);
	if( MY_ROW >= start && MY_ROW <= end)
	{
		integer length = end-start;
		start = MY_ROW - start;
		llSetScriptState("bezier",TRUE);
		llMessageLinked(LINK_THIS,0,llList2CSV(gBezierCapabilities),"#bez_caps#");
		llMessageLinked(LINK_THIS,0,llList2CSV([length+2,start]),"#bez_info#");
		llMessageLinked(LINK_THIS,0,gBezierControls,"#bez_ctrl#");
		llMessageLinked(LINK_THIS,50,"","#bez_start#");
	} else {
		llMessageLinked(LINK_THIS,0,"","#bez_stop#");
	}
	}
	if(message == "#bez-stop#")
	{
	llMessageLinked(LINK_THIS,0,"","#bez_stop#");
	}    
}
	//-- STATES --//
	default
{
	on_rez(integer i)
	{
	BROADCAST_CHANNEL = (i & CHANNEL_MASK);
	gListenHandle = llListen(BROADCAST_CHANNEL, "","","");
	MY_ROW = i & CONTROL_POINT_MASK;
	}
	listen( integer channel, string name, key id, string message )
	{
	if( !has_access(llGetOwnerKey(id)) ) return;
	handleRootCommand(message);
	}
}