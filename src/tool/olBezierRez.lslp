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
	integer BROADCAST_CHANNEL;
integer CHANNEL_MASK = 0xFFFFFF00;
integer DIALOG_CHANNEL;
integer gListenHandle_Dialog;
integer gListenHandle_Rezer;
list gControlPoints;
list gAnchorPoints;
list gTorusControlPos;
list gTorusControlRot;
list gTorusControlAnchor;
list gControlPos;
list gControlRot;
list gControlAnchor;
rotation gRezRotation;
vector gRezOffset;
float gRezScale = 1.0;
integer gRezType;
integer gRezState;
	integer gRezNumber;
default
{
	state_entry()
	{
	float magic = 0.551784;
	DIALOG_CHANNEL = llFloor(llFrand(1000000) + 1000000);
	gTorusControlPos = [
		<0,0,0>,
		<0,0.5*magic,0>,
		<0,0.5,0.5*(1-magic)>,
		<0,0.5,0.5>,
		<0,0.5,0.5*(1+magic)>,
		<0,0.5*magic,1>,
		<0,0,1>,
		<0,-0.5*magic,1>,
		<0,-0.5,0.5*(1+magic)>,
		<0,-0.5,0.5>,
		<0,-0.5,0.5*(1-magic)>,
		<0,-0.5*magic,0>,
		<0,0,0>                    
	];
	gTorusControlRot = [
		llEuler2Rot(<-PI_BY_TWO,0,0>),
		llEuler2Rot(<-PI_BY_TWO,0,0>),
		llEuler2Rot(<0,0,0>),
		llEuler2Rot(<0,0,0>),
		llEuler2Rot(<0,0,0>),
		llEuler2Rot(<PI_BY_TWO,0,0>),
		llEuler2Rot(<PI_BY_TWO,0,0>),
		llEuler2Rot(<PI_BY_TWO,0,0>),
		llEuler2Rot(<PI,0,0>),
		llEuler2Rot(<PI,0,0>),
		llEuler2Rot(<PI,0,0>),
		llEuler2Rot(<-PI_BY_TWO,0,0>),
		llEuler2Rot(<-PI_BY_TWO,0,0>)
	];
	gTorusControlAnchor = [
		1,
		0,
		0,
		1,
		0,
		0,
		1,
		0,
		0,
		1,
		0,
		0,
		1
	];
	}
	listen(integer channel, string name, key id, string message)
	{
	if(channel == DIALOG_CHANNEL)
	{
		gRezState = 0;
		if( message == "COLUMN" )
		{
		    gRezOffset = ZERO_VECTOR;
		    gRezRotation = ZERO_ROTATION;
		    gRezScale =  1.0;
		    gRezType = 0;
		    gControlPos = [<0,0,1>,<0,0,5>];
		    gControlRot = [ZERO_ROTATION,ZERO_ROTATION];
		    gControlAnchor = [1,1];
		}
		if( message == "TORUS" )
		{
		    gRezOffset = ZERO_VECTOR;
		    gRezRotation = ZERO_ROTATION;
		    gRezScale = 5.0;
		    gRezType = 1;
		    gControlPos = gTorusControlPos;
		    gControlRot = gTorusControlRot;
		    gControlAnchor = gTorusControlAnchor;
		}
		llRezObject("Cut Rezer",llGetPos(),ZERO_VECTOR,ZERO_ROTATION,BROADCAST_CHANNEL);
	}
	if( channel == BROADCAST_CHANNEL )
	{
		if( llSubStringIndex(message,"#rezed#") == 0 )
		{
		    if( gRezState == 1)
		    {
		        gControlPoints += [(key)llGetSubString(message,7,-1)];
		        if(llList2Integer(gControlAnchor,0)) gAnchorPoints += [(key)llGetSubString(message,7,-1)];
		        gControlPos = llDeleteSubList(gControlPos,0,0);
		        gControlRot = llDeleteSubList(gControlRot,0,0);
		        gControlAnchor = llDeleteSubList(gControlAnchor,0,0);
		        if(gControlPos != [])
		        {
		            list params = [++gRezNumber,gRezOffset + (llList2Vector(gControlPos,0)*gRezRotation)*gRezScale,llList2Rot(gControlRot,0)*gRezRotation];
		            llRegionSay(BROADCAST_CHANNEL,"#rez-ctrl#" + llList2CSV(params));    
		        } else {
		            gRezState = 2;
		        }
		    }
		    if( gRezState == 2)
		    {
		        gRezState = 3;
		        llRegionSay(BROADCAST_CHANNEL,"#rez_cuts#" + llList2CSV([<0,0,1>,<0,0,5>]));
		    }
		}
		if( message == "#cuts-rezed#")
		{
		    gRezState = 0;
		    llRegionSay(BROADCAST_CHANNEL,"#bez-ctrl#" + llList2CSV(gControlPoints));
		    llSleep(0.2);
		    llRegionSay(BROADCAST_CHANNEL,"#bez-anchors#" + llList2CSV(gAnchorPoints));
		    llRegionSay(BROADCAST_CHANNEL,"#rezer-die#");
		    llMessageLinked(LINK_THIS,0,"","#rez_fin#");
		}
	}
	}
	link_message(integer sn, integer i, string str, key id)
	{
	if(id == "#rez#") 
	{
		gRezState=0;
		BROADCAST_CHANNEL = i;
		llListenRemove(gListenHandle_Dialog);
		gListenHandle_Dialog = llListen(DIALOG_CHANNEL,"",(key)str,"");
		llDialog((key)str,"Pick a sculpt to rez:\n",["COLUMN","TORUS"],DIALOG_CHANNEL);
	}
	}
	object_rez(key k)
	{
	if( gRezState == 0)
	{
		gControlPoints = [];
		gAnchorPoints = [];
		gRezState = 1;
		llSleep(0.2);
		llListenRemove(gListenHandle_Rezer);
		gListenHandle_Rezer = llListen(BROADCAST_CHANNEL,"",k,"");
		gRezNumber = 0;
		list params = [gRezNumber,llList2Vector(gControlPos,0),llList2Rot(gControlRot,0)];
		llRegionSay(BROADCAST_CHANNEL,"#rez-ctrl#" + llList2CSV(params));
	}
	}
}
	