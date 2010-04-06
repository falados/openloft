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
	integer MAX_FACTORIAL = 20;
integer FACTORIAL_N = 0;
integer LAST_N=-1;
	list control_keys;
list control_pos;
list control_scale;
list control_rot;
list anchors;
float t = 0.5;
	vector START_POS;
key ORIGIN = NULL_KEY;
integer CHANNEL_MASK = 0xFFFFFF00;
integer CONTROL_POINT_MASK = 0xFF;
integer BROADCAST_CHANNEL;
integer CONTROL_POINT_NUM;
integer MY_NUM;
integer MAX_CONTROL_POINTS;
integer MAX_INTER_POINTS;
integer ANCHOR_POINTS;
integer INTERP_ROT;
integer INTERP_SCALE;
integer gListenHandle;
	get_control_points()
{
	integer i;
	integer num;
	key k;
	list bbox;
	string name;
	ANCHOR_POINTS = 0;
	control_scale = [];
	control_pos = [];
	control_rot = [];
	anchors = [];
	for( i = 0; i < MAX_CONTROL_POINTS; ++i)
	{
	k = (key)llList2String(control_keys,i);
	list params = llGetObjectDetails(k,[OBJECT_NAME,OBJECT_POS,OBJECT_ROT]);
	if( params == [] )
	{
		jump continue;
	}
	name = llList2String(params,0);        
	control_pos = (control_pos = []) + control_pos + llList2List(params,1,1);
	bbox = llGetBoundingBox(k);
	control_scale = (control_scale = []) + control_scale + [llList2Vector(bbox,1)-llList2Vector(bbox,0)];
	control_rot = (control_rot = []) + control_rot + llList2List(params,2,2);
	if( name == "anchor")
	{
		anchors += [i];
		++ANCHOR_POINTS;
	}   
	@continue;    
	}
}
	setOriginPos()
{
	START_POS = llList2Vector(llGetObjectDetails(llList2Key(control_keys,0),[OBJECT_POS]),0);
}
	// Factorial (!) function : n(n-1)(n-2)...(1)
integer factorial(integer n)
{
	if( n == 0 || n == 1) return 1;
	if( n > MAX_FACTORIAL) 
	{
	llSay(DEBUG_CHANNEL,"Factorial size too big : " + (string)n + "\nLimited to " + (string)MAX_FACTORIAL);
	return 1/0; //Error Out with MATH ERROR
	}
	return n * factorial(n-1);
}
	// Mathematical nCr function = n! / (c! * (n-c)!)
integer nCr(integer n, integer c)
{
	if(LAST_N != n || FACTORIAL_N == 0)
	{
	LAST_N = n;
	FACTORIAL_N = factorial(n);
	}
	return FACTORIAL_N / ( factorial(c) * factorial(n-c) );
}
	rotation slerp( rotation a, rotation b, float f ) {
	float angleBetween = llAngleBetween(a, b);
	if ( angleBetween > PI )
	angleBetween = angleBetween - TWO_PI;
	return a*llAxisAngle2Rot(llRot2Axis(b/a)*a, angleBetween*f);
}
	bezier()
{
	if(control_keys == [] || MAX_CONTROL_POINTS <= 1) return;    
	get_control_points();
	setOriginPos();
	integer i;
	integer start=0;
	for(i = 0; i < ANCHOR_POINTS-1; ++i)
	{
	if( t >= llList2Float(anchors,i)/(MAX_CONTROL_POINTS-1) )
	{
		start = i;
	}
	}
	i = llList2Integer(anchors,start);
	integer j = llList2Integer(anchors,start+1);
	integer n = llRound(MAX_INTER_POINTS*((j-i)/(float)(MAX_CONTROL_POINTS-1)))-1;
	start = llRound(MAX_INTER_POINTS*(i/(float)(MAX_CONTROL_POINTS-1)));
	if(start != 0) 
	{
	--start;
	++n;
	}
	float tlocal; 
	if(n != 0) {
	tlocal = (MY_NUM - start) / (float)(n);
	if(tlocal>1) tlocal = 1;
	if(tlocal<0) tlocal = 0;
	} else {
	if(MY_NUM-start == 0) tlocal = 0;
	else tlocal = 1;
	}
	vector pos = ZERO_VECTOR;
	vector scale = ZERO_VECTOR;
	vector p;
	float b;
	n = j-i;
	start = i;
	for(i=0; i <= n; ++i)
	{       
	b = nCr(n,i) * llPow(tlocal,i) * llPow(1.0-tlocal,n-i);
	p = (llList2Vector(control_pos,start+i));
	pos += b * p;
	if(INTERP_SCALE) scale += b * (llList2Vector(control_scale,start+i));
	}
	if( llVecMag(pos-llGetPos()) > 20 )
	{
	llOwnerSay("Too Far!");
	return;
	}
	vector s = llGetScale();
	scale.z = s.z;
	list prim_params = [PRIM_POSITION,pos];
	if(INTERP_SCALE) prim_params += [PRIM_SIZE,scale];
	if(INTERP_ROT) prim_params += [PRIM_ROTATION,slerp(llList2Rot(control_rot,start),llList2Rot(control_rot,start+i-1),tlocal)];
	else prim_params += [PRIM_ROTATION,llList2Rot(control_rot,start+i-1)]; 
	llSetPrimitiveParams(prim_params);
}
	default {
	state_entry()
	{
	state enabled;
	}
}
	state enabled
{
	link_message(integer send_num, integer num, string str, key command)
	{
		if( command == "#bez_info#" )
	{
		FACTORIAL_N = 0;
		list parameters = llCSV2List(str);
		MAX_INTER_POINTS = llList2Integer(parameters,0);
		MY_NUM = llList2Integer(parameters,1);
		if(MAX_INTER_POINTS == 1) {
		    t = 1.0;
		} else {
		    t = (float)MY_NUM/(MAX_INTER_POINTS-1);
		}
		control_keys = [];
		llSetTimerEvent(0.0);
		return;
	} else
	if( command == "#bez_ctrl#")
	{
		control_keys = llCSV2List(str);
		MAX_CONTROL_POINTS = llGetListLength(control_keys);
		return;
	}
	if( command == "#bez_stop#")
	{
		state default;
	}
	if( command == "#bez_start#")
	{
		llSetTimerEvent((float)num/100);
	}
	if( command == "#bez_caps#")
	{
		list caps = llCSV2List(str);
		string KEY;
		string VAL;
		while( caps != [])
		{
		    KEY = llList2String(caps,0);
		    VAL = llList2String(caps,1);
		    if( KEY == "scale") INTERP_SCALE =  (integer)VAL;
		    if( KEY == "rot") INTERP_ROT = (integer)VAL;
		    caps = llDeleteSubList(caps,0,1);
		}
		return;
	}
	}
	timer()
	{
	bezier();
	}
	state_exit()
	{
	llSetScriptState(llGetScriptName(),FALSE);        
	}
}
