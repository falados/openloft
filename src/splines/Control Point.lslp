integer CONTROL_CHANNEL;
integer BEZ_ID;
integer gListenHandle;
	default {
	on_rez(integer param)
	{
	CONTROL_CHANNEL = param & 0xFFFFFF00;
	BEZ_ID = param & 0xFF;
	llRegionSay(CONTROL_CHANNEL,"#register#");
	llListenRemove(gListenHandle);
	gListenHandle = llListen(CONTROL_CHANNEL,"","","");
	}
}
