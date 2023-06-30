#if !defined MARKERS
    #endinput
#endif

#define MAX_MARKERS 10

enum struct Marker
{
    char Command[32];

    char Skin[16];
    char Name[64];
    char Model[256];
    char Sequence[32];
    float Playbackrate;
    float LifeTime;
    float ModelScale;

    void Init()
    {
        this.Playbackrate = 1.0;
        this.ModelScale = 1.0;
        this.LifeTime = 30.0;
    }
}

static Marker Markers[MAX_MARKERS];

static int MarkersCount;
static int MarkersEnts[MAX_MARKERS];

static Handle MarkersTimers[MAX_MARKERS];


bool MarkerParseCommand(const char[] command)
{
    for(int i = 0; i < MarkersCount; i++)
    {
        if(!strcmp(Markers[i].Command, command, false))
        {
            MarkerToggle(i);
            return true;
        }
    }
    
    return false;
}

void MarkersOnNewSection(const char[] name)
{
    if(MarkersCount >= MAX_MARKERS)
        return;

    int marker = MarkersCount;
    Markers[marker].Init();
    strcopy(Markers[marker].Name, sizeof(Markers[].Name), name);
    ++MarkersCount;
}

void MarkersOnKeyValue(const char[] key, const char[] value)
{
    int marker = MarkersCount - 1;

    if(!strcmp(key, "command", false))
    {
        strcopy(Markers[marker].Command, sizeof(Markers[].Command), value);
    }
    else if(!strcmp(key, "skin", false))
    {
        strcopy(Markers[marker].Skin, sizeof(Markers[].Skin), value);
    }
    else if(!strcmp(key, "model", false))
    {
        strcopy(Markers[marker].Model, sizeof(Markers[].Model), value);
    }
    else if(!strcmp(key, "sequence", false))
    {
        strcopy(Markers[marker].Sequence, sizeof(Markers[].Sequence), value);
    }
    else if(!strcmp(key, "playbackrate", false))
    {
        Markers[marker].Playbackrate = StringToFloat(value);
    }
    else if(!strcmp(key, "lifetime", false))
    {
        Markers[marker].LifeTime = StringToFloat(value);
    }
    else if(!strcmp(key, "modelscale", false))
    {
        Markers[marker].ModelScale = StringToFloat(value);
    }
}

void MarkersMenu(int client)
{
    if(!MarkersCount)
    {
        LeaderMenuDisplay();
        return;
    }
    bool russian = (IsClientRussian(client));

    Menu menu = new Menu(MarkersMenu_Handler, MenuAction_Cancel | MenuAction_End | MenuAction_Select);

    menu.SetTitle(russian ? "Маркеры":"Markers");

    char buffer[256];
    for(int i = 0; i < MarkersCount; i++)
    {
        FormatEx(buffer, sizeof(buffer), "%s: [%s]", Markers[i].Name, IsMarkerActive(i) ? "+":"-");
        menu.AddItem(Markers[i].Name, buffer);
    }

    menu.ExitBackButton = true;
    menu.Display(client, 0);
}

public int MarkersMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
        case MenuAction_End: delete menu;

        case MenuAction_Cancel:
        {
            if(!CurrentLeader || CurrentLeader != client)
                return 0;

            if(item == MenuCancel_ExitBack)
                LeaderMenuDisplay();
        }
        case MenuAction_Select:
        {
            if(!CurrentLeader || CurrentLeader != client)
                return 0;

            MarkerToggle(item);
            MarkersMenu(client);
        }
    }

    return 0;
}

bool IsMarkerActive(int marker)
{
    return (MarkersEnts[marker] && EntRefToEntIndex(MarkersEnts[marker]) != INVALID_ENT_REFERENCE);
}

void MarkerToggle(int marker)
{
    if(IsMarkerActive(marker))
    {
        MarkerOff(marker);
    }
    else
    {
        MarkerOn(marker);
    }
}

void MarkerOn(int marker)
{
    MarkerOff(marker);  

    float ang[3];
    float pos[3];
    float vec[3];
    float start[3]; 
    GetClientEyePosition(CurrentLeader, pos);
    GetClientEyeAngles(CurrentLeader, ang); 
    TR_TraceRayFilter(pos, ang, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer);    

    if(!TR_DidHit(null))
        return; 

    TR_GetEndPosition(start, null); 
    TR_GetPlaneNormal(null, vec); 
    GetVectorAngles(vec, vec); 
    vec[0] += 90.0;

    int entity = CreateEntityByName("prop_dynamic_override");    

    if (entity == INVALID_ENT_REFERENCE)
    	return;

    DispatchKeyValue(entity, "spawnflags", "0");
    DispatchKeyValue(entity, "PerformanceMode", "1");
    DispatchKeyValue(entity, "solid", "0");
    DispatchKeyValue(entity, "fademindist", "2048");
    DispatchKeyValue(entity, "fademaxdist", "2048");
    DispatchKeyValue(entity, "disableshadows", "1");
    DispatchKeyValue(entity, "disablereceiveshadows", "1");
    DispatchKeyValue(entity, "disablebonefollowers", "1");
    DispatchKeyValue(entity, "rendermode", "0");
    DispatchKeyValue(entity, "renderfx", "0");
    DispatchKeyValue(entity, "rendercolor", "255 255 255");
    DispatchKeyValue(entity, "renderamt", "255");
    DispatchKeyValue(entity, "health", "0");
    DispatchKeyValue(entity, "ExplodeRadius", "0");
    DispatchKeyValue(entity, "ExplodeDamage", "0");
    DispatchKeyValue(entity, "skin", Markers[marker].Skin);
    DispatchKeyValue(entity, "model", Markers[marker].Model);

    if(!DispatchSpawn(entity))
        return;

    if(Markers[marker].ModelScale != 1.0 && Markers[marker].ModelScale > 0.0)
        SetEntPropFloat(entity, Prop_Send, "m_flModelScale", 2.5);

    TeleportEntity(entity, start, vec, NULL_VECTOR);

    if(Markers[marker].Sequence[0])
    {
        SetVariantString(Markers[marker].Sequence);
        AcceptEntityInput(entity, "SetAnimation", -1, -1, 0);
        SetEntPropFloat(entity, Prop_Send, "m_flPlaybackRate", Markers[marker].Playbackrate);
    }

    MarkersEnts[marker] = EntIndexToEntRef(entity);
    if(Markers[marker].LifeTime > 0.0)
        MarkersTimers[marker] = CreateTimer(Markers[marker].LifeTime, Timer_MarkerOff, marker);
}

public Action Timer_MarkerOff(Handle timer, int marker)
{
    MarkersTimers[marker] = null;

    MarkerOff(marker);

    return Plugin_Continue;
}

void MarkersOff()
{
    for(int i = 0; i < MarkersCount; i++)
        MarkerOff(i);
}

void MarkerOff(int marker)
{
    delete MarkersTimers[marker];

    if(MarkersEnts[marker])
    {
        MarkersEnts[marker] = EntRefToEntIndex(MarkersEnts[marker]);

        if(MarkersEnts[marker] != INVALID_ENT_REFERENCE)
            RemoveEntity(MarkersEnts[marker]);

        MarkersEnts[marker] = 0;
    }
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void MarkersPrecache()
{
    for(int i = 0; i < MarkersCount; i++)
        PrecacheModel(Markers[i].Model, true);
}