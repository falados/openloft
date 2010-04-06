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
	integer CHANNEL_MASK = 0xFFFFFF00;
integer CONTROL_POINT_MASK = 0xFF;
integer BROADCAST_CHANNEL;
integer CONTROL_POINT_NUM;
integer ACCESS_LEVEL;
	integer MAX_CONTROL_POINTS;
integer MAX_INTER_POINTS;
	integer gListenHandle;
integer gPointType;
	integer processRootCommands(string message)
{
	if( llSubStringIndex(message,"#bez-ctrl#") == 0 )
	{
	list parameters = llCSV2List( llGetSubString(message,10,-1));
	MAX_CONTROL_POINTS = llGetListLength(parameters);
	CONTROL_POINT_NUM = llListFindList(parameters,[(string)llGetKey()]);
	if( CONTROL_POINT_NUM == -1) llDie();
	if(CONTROL_POINT_NUM == 0 || CONTROL_POINT_NUM == MAX_CONTROL_POINTS-1 || gPointType == 1)
	{
		return 1;
	} else {
		return 0;
	}        
	}
	if( llSubStringIndex(message,"#setup#") == 0)
	{
	list l = llCSV2List(llGetSubString(message,7,-1));
	ACCESS_LEVEL = (integer)llList2String(l,1);
	}
	if( llSubStringIndex(message,"#bez-anchors#") == 0)
	{
	list parameters = llCSV2List( llGetSubString(message,13,-1));
	integer anchor = llListFindList(parameters,[(string)llGetKey()]);
	if(CONTROL_POINT_NUM == 0 || CONTROL_POINT_NUM == MAX_CONTROL_POINTS-1 || anchor != -1)
	{
		return 1;
	} else {
		return 0;
	}
	}
	if( message == "#die#") { llDie(); }
	return -1;
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
	default
{
	on_rez(integer i)
	{
	BROADCAST_CHANNEL = (i & CHANNEL_MASK);
	gListenHandle = llListen(BROADCAST_CHANNEL, "","","");
	CONTROL_POINT_NUM = i & CONTROL_POINT_MASK;
	llSetObjectDesc((string)CONTROL_POINT_NUM);
	llSetText(llGetObjectDesc(),<1,1,1>,1.0);
	}
	listen(integer channel, string name, key id, string message)
	{
	integer i = processRootCommands(message);
	if( i == 0 ) state control_point_loop;
	if( i == 1 ) state anchor_point_loop;
	}
}
	state control_point_loop {
	state_entry() { state control_point;}
}
state control_point
{
	state_entry()
	{
	gPointType=0;        
	llSetColor(<1,0,0>,-1);        
	gListenHandle = llListen(BROADCAST_CHANNEL, "","","");
	llSetObjectName("control");     
	}
	listen(integer channel, string name, key id, string message)
	{
	integer i = processRootCommands(message);
	if( i == 0 ) state control_point_loop;
	if( i == 1 ) state anchor_point_loop;
	}
	touch_end(integer i)
	{
	if(!has_access(llDetectedKey(0))) return;
	state anchor_point;
	}
}
state anchor_point_loop {
	state_entry() { state anchor_point;}
}
state anchor_point
{
	state_entry()
	{
	gPointType=1;
	llSetColor(<0,0,1>,-1);
	gListenHandle = llListen(BROADCAST_CHANNEL, "","","");
	llSetObjectName("anchor");     
	}
	listen(integer channel, string name, key id, string message)
	{
	integer i = processRootCommands(message);
	if( i == 0 ) state control_point_loop;
	if( i == 1 ) state anchor_point_loop;
	}
	touch_end(integer i)
	{
	if(!has_access(llDetectedKey(0))) return;
	if(CONTROL_POINT_NUM == 0 || CONTROL_POINT_NUM == MAX_CONTROL_POINTS-1)
	{
		return;
	}
	state control_point;
		}
}
	