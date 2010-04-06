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
integer BROADCAST_CHANNEL;
integer ACCESS_LEVEL;
integer TOTAL_CUTS;
integer VERTS_PER_CUT;
integer gRezAllDisks;
integer gRezInProgress;
integer gCutNumber;
vector gStartPosition;
vector gEndPosition;
rotation gRotation = ZERO_ROTATION;
	key gBaseKey;
	list warp_pos( vector from, vector to )
{
	list l = [];
	vector p = from;
	while( p != to ) {
	if( llVecMag( to - p ) > 10 ) {
		p += llVecNorm(to - p)*10.0;
	} else {
		p = to;
	}
	l += [PRIM_POSITION,p];
	}
	return l;
}
	integer rez_cut(integer i)
{
	if(TOTAL_CUTS == 0) return FALSE;
	if(i >= TOTAL_CUTS) return FALSE;
	vector pos = llList2Vector(llGetObjectDetails(gBaseKey,[OBJECT_POS]),0);
	float t = i/(float)(TOTAL_CUTS);
	pos += (1.0-t)*gStartPosition + t*gEndPosition;
	//Go
	llSetPrimitiveParams(warp_pos(llGetPos(),pos));
	//Rez
	llRezObject("cut",pos,ZERO_VECTOR,gRotation,BROADCAST_CHANNEL | (i & 0xFF) );
	llSetText("Rezing Cuts : " + (string)(i+1) + " of " + (string)TOTAL_CUTS,<0,1,0>,1.0);
	llSleep(0.2);
	return TRUE;
}
	processRootCommands(string message, key id)
{
	if( llSubStringIndex(message,"#setup#") == 0)
	{
	list l = llCSV2List(llGetSubString(message,7,-1));
	gBaseKey = id;
	VERTS_PER_CUT = llList2Integer(l,0);
	ACCESS_LEVEL = llList2Integer(l,1);
	TOTAL_CUTS =  llList2Integer(l,2);
	}    
	if( message == "#rezer-die#") { llDie(); }
	if(llSubStringIndex(message,"#rez_cuts#") == 0) 
	{
	gBaseKey = id;        
	list l = llCSV2List(llGetSubString(message,10,-1));
	gRotation = ZERO_ROTATION;
	gStartPosition = (vector)llList2String(l,0);
	gEndPosition = (vector)llList2String(l,1);
	gRezAllDisks = TRUE;
	gCutNumber = 0;
	rez_cut(gCutNumber);
	return;
	}
	if( llSubStringIndex(message,"#rez-cut#") == 0) 
	{
	gBaseKey = id;
	gRezAllDisks = FALSE;
	list l = llCSV2List(llGetSubString(message,9,-1));
	integer row = llList2Integer(l,0);
	gEndPosition = gStartPosition = (vector)llList2String(l,1);
	gRotation = (rotation)llList2String(l,2);
	rez_cut(row);
	return;
	}
	if(  llSubStringIndex(message,"#rez-ctrl#") == 0) 
	{
	gRezInProgress = TRUE;
	gRezAllDisks = FALSE;
	gBaseKey = id;        
	list l = llCSV2List(llGetSubString(message,10,-1));
	integer ctrl = llList2Integer(l,0);
	vector pos = llList2Vector(llGetObjectDetails(gBaseKey,[OBJECT_POS]),0) + (vector)llList2String(l,1);
	rotation rot = (rotation)llList2String(l,2);
	llSetPrimitiveParams(warp_pos(llGetPos(),pos));
	llRezObject("control",pos,ZERO_VECTOR,rot,BROADCAST_CHANNEL | (ctrl & 0xFF) );
	return;
	}
}
	default
{
	on_rez(integer i)
	{
	if(i == 0) return;
	BROADCAST_CHANNEL = (i & CHANNEL_MASK);
	llListen(BROADCAST_CHANNEL, "","","");
	}
	listen(integer channel, string name, key id, string message)
	{
	if( llGetOwnerKey(id) != llGetOwner()) return;
	processRootCommands(message,id);
	}
	object_rez(key id)
	{
	if(gRezAllDisks && !gRezInProgress) 
	{
		if(!rez_cut(++gCutNumber))
		{
		    gRezAllDisks = FALSE;
		    llSetText("",ZERO_VECTOR,0.0);
		    llRegionSay(BROADCAST_CHANNEL,"#cuts-rezed#");
		}
	}
	gRezInProgress=FALSE;
	llRegionSay(BROADCAST_CHANNEL,"#rezed#" + (string)id);
	}
}
