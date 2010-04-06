$import src.Common.lslm ();
$import fksllib.modules.page_dialog.lslm ();
$import fksllib.modules.warp_pos.lslm (list_max=WARP_LIST_MAX);
$import fksllib.modules.largecom.lslm (CHANNEL=BROADCAST_CHANNEL);
$import fksllib.modules.bezier.lslm(MAX_N=MAX_CONTROL_POINTS);
$import fksllib.modules.slerp.lslm();
integer WARP_LIST_MAX=50;
float BEZIER_UPDATE_TIME = 0.1;
string CONTROL_OBJECT = "control";
integer MAX_CONTROL_POINTS = 20;
integer BEZ_ENABLED = FALSE;
integer BEZ_POSITION = TRUE;
integer BEZ_ROTATION = TRUE;
integer BEZ_SCALE = FALSE;
integer CONTROL_CHANNEL;
integer gListenHandle_Controls;
integer DIALOG_NUM;
	list CONTROL_POINTS;
list ANCHOR_POINTS;
	integer SelectionMade()
{
	return !(CUT_START == -1 || CUT_END == -1);
}
	ShowMainMenu(key agent)
{
	list MAIN_MENU;
	if( SelectionMade() ) MAIN_MENU += ["[SELECT] Select Cuts for Bezier Operation","SELECT"];
	else  MAIN_MENU += ["[DESELECT] Deselect Cuts","DESELECT"];
	if( BEZ_ENABLED ) MAIN_MENU += ["[DISABLE] Disables Interpolation","DISABLE"];
	else MAIN_MENU += ["[ENABLE] Enables Interpolation","ENABLE"];
	if( BEZ_POSITION ) MAIN_MENU += ["[POS] Toggle Bezier Position","[X] POS"];
	else MAIN_MENU += ["[POS] Toggle Bezier Position","[ ] POS"];
	if( BEZ_ROTATION ) MAIN_MENU += ["[ROT] Toggle Bezier Rotation","[X] ROT"];
	else MAIN_MENU += ["[ROT] Toggle Bezier Rotation","[ ] ROT"];
	if( BEZ_SCALE ) MAIN_MENU += ["[SCALE] Toggle Bezier Scale","[X] SCALE"];
	else MAIN_MENU += ["[SCALE] Toggle Bezier Scale","[ ] SCALE"];
	integer cp = llGetListLength(CONTROL_POINTS);
	if( cp > 2 ) MAIN_MENU += ["[-CONTROL] Remove a control point","-CONTROL"];
	if( cp < MAX_CONTROL_POINTS ) MAIN_MENU += ["[+CONTROL] Add a control point","+CONTROL"];
	DIALOG_NUM = SendDialogAnnotated(agent,"Select an Option",MAIN_MENU);
	}
	HandleCommand(string command)
{
	if( command == "SELECT" )
	{
	StartSelectionMode();
	return;
	}
	if( command == "DESELECT" )
	{
	CUT_START = -1;
	CUT_END = -1;
	return;
	}
	if( command == "DISABLE" )
	{
	BEZ_ENABLED = FALSE;
	llSetTimerEvent(0);
	}
	if( command == "ENABLE" )
	{
	BEZ_ENABLED = TRUE;
	llSetTimerEvent(BEZIER_UPDATE_TIME);
	UpdateBezier();
	}
	if( command == "[X] POS" || command == "[ ] POS" )
	{
	BEZ_POSITION = !BEZ_POSITION;
	return;
	}
	if( command == "[X] ROT" || command == "[ ] ROT" )
	{
	BEZ_ROTATION = !BEZ_ROTATION;
	return;
	}
	if( command == "[X] SCALE" || command == "[ ] SCALE" )
	{
	BEZ_SCALE = !BEZ_SCALE;
	return;
	}
	if( command == "+CONTROL" )
	{
	AddControl();
	}
	if( command == "-CONTROL" )
	{
	RemoveControl(llList2Key(CONTROL_POINTS,-1));
	}
}
	AddControl()
{
	list d;
	if( (string)CONTROL_POINTS == "" )
	{ 
	d  = llGetObjectDetails( llList2Key(CONTROL_POINTS,-1) , [OBJECT_POS,OBJECT_ROT] );
	} else {
	d = llGetObjectDetails( llGetKey(), [OBJECT_POS,OBJECT_ROT] );
	}
	vector pos = llGetPos();
	vector topos = llList2Vector(d,0) + llRot2Up(llList2Rot(d,1)); 
	WarpPos( topos );
	llRezObject(CONTROL_OBJECT, topos , ZERO_VECTOR , llList2Rot(d,1), CONTROL_CHANNEL | MY_ID );
	WarpPos( pos );
	UpdateBezier();
}
	RemoveControl(key id)
{
	integer num = llListFindList(CONTROL_POINTS,[id]) + 1;
	if( num > 0 )
	{
	llRegionSay(BROADCAST_CHANNEL,"#die#" + (string)id);
	CONTROL_POINTS = llDeleteSubList(CONTROL_POINTS,num-1,num-1);
	llRegionSay(CONTROL_CHANNEL,"#control-del#" + llList2CSV([num,llGetListLength(CONTROL_POINTS),id]));
	UpdateBezier();
	}
}
	UpdateBezier()
{
	list pos;
	list scale;
	list rot;
	integer num;
	integer anchors = (integer)llListStatistics( LIST_STAT_SUM , ANCHOR_POINTS );
	if( anchors < 2 ) return;
	integer c;
	integer control_start;
	integer control_end;
	list bbox;
	list scales;
	list positions;
	rotation rot_start;
	rotation rot_end;
	float t;
	vector p;
	string FULL_MESSAGE = "#cut-params#";
	for( num = CUT_START; num <= CUT_END; ++num)
	{
	FULL_MESSAGE += "#" + (string)num + "#";
	if( c == num/anchors ) jump skip_pop;
	c = num/anchors;
	scales = [];
	positions = [];
	control_start = llListFindList(llList2List(ANCHOR_POINTS,c,-1),[1]) + c;
	control_end = llListFindList(llList2List(ANCHOR_POINTS,c+1,-1),[1]) + c+1;
	rot_start = llList2Rot( llGetObjectDetails( llList2Key(CONTROL_POINTS,control_start) , [OBJECT_ROT] ), 0);
	rot_end = llList2Rot( llGetObjectDetails( llList2Key(CONTROL_POINTS,control_end) , [OBJECT_ROT] ), 0);
	// Bezier Quantities
	for( c = control_start; c <= control_end; ++c)
	{			
	positions += llList2Vector( llGetObjectDetails( llList2Key(CONTROL_POINTS,c), [OBJECT_POS] ) , 0);
	bbox = llGetBoundingBox( llList2Key(CONTROL_POINTS,c) );
	scales += llList2Vector(bbox,1)-llList2Vector(bbox,0);					
	}
	t = ((float)(num-control_start) / (control_end-control_start+1));
	@skip_pop;
	if(BEZ_POSITION) FULL_MESSAGE += "p/" + (string)bezier(positions,t) + "/";
	if(BEZ_SCALE) FULL_MESSAGE += "s/" + (string)bezier(scales,t) + "/";
	if(BEZ_ROTATION) {
	FULL_MESSAGE += "r/" + (string)slerp(rot_start,rot_end,t);
	}
	}
	llOwnerSay(FULL_MESSAGE);
}
	DisplaySelection()
{
	if(SelectionMade())
	{
	llSetText("Cuts Selected\n" + (string)CUT_START + " to " + (string)CUT_END,<1,1,1>,1.0);
	} else {
	llSetText("",<1,1,1>,1.0);
	}
}
	default {
	on_rez(integer param)
	{
	HandleRez(param);
	CONTROL_CHANNEL = llFloor(llFrand(-1000000)-1000000) & 0xFFFFFF00;
	llListenRemove(gListenHandle_Controls);
	gListenHandle_Controls = llListen(CONTROL_CHANNEL,"","","");
	AddControl();
	}
	listen( integer channel, string name, key id, string message)
	{
	if( channel == BROADCAST_CHANNEL )
	{
	if( HandleRootCommands(name,id) ) return;
	}
	if(! CanAccess( llGetOwnerKey(id) ) ) return;
	if( channel == SELECTION_CHANNEL )
	{
	if( HandleSelection( message ) )
	{
	DisplaySelection();
	}
	}
	if( channel == CONTROL_CHANNEL )
	{
	if( message == "#register#" )
	{
	if( llListFindList(CONTROL_POINTS,[id]) == -1)
	{
	CONTROL_POINTS += [id];
	ANCHOR_POINTS += [TRUE];
	integer num = llGetListLength(CONTROL_POINTS);
	llRegionSay(CONTROL_CHANNEL,"#control-add#" + llList2CSV([num,num,id]));
	if( num < 2 ) AddControl();
	}
	return;
	}
	if( message == "#control-destroy#" )
	{
	RemoveControl(id);
	return;
	}
	if( message == "#a#" || message == "#cp#" )
	{
	integer i = llListFindList(CONTROL_POINTS,[id]);
	if( i != -1 )
	{
	if( i > 0 && i < llGetListLength(CONTROL_POINTS)-1 )
	{
	ANCHOR_POINTS = llListReplaceList(ANCHOR_POINTS,[(message=="#a#")],i,i);
	}
	}
	}	
	}
	}
	touch_start(integer num_detected)
	{
	if(! CanAccess( llDetectedKey(0) ) ) return;
	ShowMainMenu( llDetectedKey(0) );
	}
	link_message( integer send_num, integer num, string str, key id)
	{
	if( id == "#dialog-response#" && num == DIALOG_NUM ) HandleCommand(str);
	}
}
