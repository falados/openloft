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
	key DEFAULT_SCULPT = "39d23b96-719c-b893-d3c8-30b9074cd2f8";
	default
{
	on_rez(integer param)
	{
	if(param != 0)
	{
		llListen(param,"","","");
		llSetTimerEvent(30.0);
	}
	}
	listen(integer channel, string name, key id, string message)
	{
	list params = llCSV2List(message);
	vector scale = (vector)llList2String(params,0);
	integer shape = llList2Integer(params,1);
		llSetPrimitiveParams([PRIM_SIZE,scale,PRIM_TYPE,PRIM_TYPE_SCULPT,DEFAULT_SCULPT,shape]);
	llRemoveInventory(llGetScriptName());
	}
	timer()
	{
	llWhisper(0,"No setup parameters received");
	llDie();
	}
}