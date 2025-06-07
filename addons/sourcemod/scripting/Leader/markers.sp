#if !defined MARKERS
    #endinput
#endif

#define MAX_MARKERS 10

#define MARKERS_NOTE_FORMAT_RU "Вы можете использовать !leader @%s"
#define MARKERS_NOTE_FORMAT_EN "You can use !leader @%s"

#define MARKERS_ON_FORMAT_RU "%s установил маркер %s"
#define MARKERS_OFF_FORMAT_RU "%s удалил маркер %s"

#define MARKERS_ON_FORMAT_EN "%s has set a %s marker"
#define MARKERS_OFF_FORMAT_EN "%s removed the %s marker"

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
    bool Precached;

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

static int NoteDelay[MAXPLAYERS + 1][MAX_MARKERS];
static int NoteCount[MAXPLAYERS + 1][MAX_MARKERS];

stock void MarkersToggleMessage(int marker, bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), MARKERS_ON_FORMAT_RU, name, Markers[marker].Name);
            FormatEx(message_en, sizeof(message_en), MARKERS_ON_FORMAT_EN, name, Markers[marker].Name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), MARKERS_OFF_FORMAT_RU, name, Markers[marker].Name);
            FormatEx(message_en, sizeof(message_en), MARKERS_OFF_FORMAT_EN, name, Markers[marker].Name);
        }
    }
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i) || i == CurrentLeader || GetClientTeam(i) != 3)
            continue;
    
        if(GetClientLanguage(i) == RussianLanguageId)
        {
            LeaderPrintToChat(i, message_ru);
        }
        else
        {
            LeaderPrintToChat(i, message_en);
        }
    }
}

stock void MarkersNote(int marker, bool from_menu)
{
    if(!from_menu)
        return;

    int time = GetTime();
    int leader = CurrentLeader;

    if(NoteDelay[leader][marker] > time)
        return;

    if(NoteCount[leader][marker] >= NOTE_COUNT_MAX)
        return;

    ++NoteCount[leader][marker];
    NoteDelay[leader][marker] = time + NOTE_DELAY;

    switch(IsClientRussian(leader))
    {
        case true:  LeaderPrintToChat(leader, MARKERS_NOTE_FORMAT_RU, Markers[marker].Command);
        case false: LeaderPrintToChat(leader, MARKERS_NOTE_FORMAT_EN, Markers[marker].Command);
    }
}

stock void MarkersOnClientDisconnect(int client)
{
    for(int i = 0; i < MarkersCount; ++i)
    {
        NoteDelay[client][i] = 0;
        NoteCount[client][i] = 0;
    }
}

bool MarkerParseCommand(const char[] command)
{
    for(int i = 0; i < MarkersCount; i++)
    {
        if(!strcmp(Markers[i].Command, command, false))
        {
            MarkerToggle(i, false);
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

    Menu menu = new Menu(MarkersMenu_Handler, MenuAction_Cancel | MenuAction_End | MenuAction_Select);

    switch(IsClientRussian(client))
    {
        case true:  menu.SetTitle("Маркеры");
        case false: menu.SetTitle("Markers");
    }

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

void MarkerToggle(int marker, bool from_menu = true)
{
    MarkersNote(marker, from_menu);

    switch(IsMarkerActive(marker))
    {
        case true:  MarkerOff(marker, true);
        case false: MarkerOn(marker, true);
    }
}

void MarkerOn(int marker, bool caused_by_client = false)
{
    MarkerOff(marker);

    if(!Markers[marker].Precached)
        return;

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

    if(caused_by_client)
        MarkersToggleMessage(marker, true);
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

void MarkerOff(int marker, bool caused_by_client = false)
{
    delete MarkersTimers[marker];

    if(MarkersEnts[marker])
    {
        MarkersEnts[marker] = EntRefToEntIndex(MarkersEnts[marker]);

        if(MarkersEnts[marker] != INVALID_ENT_REFERENCE)
            RemoveEntity(MarkersEnts[marker]);

        MarkersEnts[marker] = 0;

        if(caused_by_client)
            MarkersToggleMessage(marker, false);
    }
}

public bool TraceEntityFilterPlayer(int entity, int contentsMask)
{
	return entity > MaxClients || !entity;
}

void MarkersPrecache()
{
    switch(Late)
    {
        case true:
        {
            for(int i = 0; i < MarkersCount; i++)
                Markers[i].Precached = (!is_map_not_ze && IsModelPrecached(Markers[i].Model));

        }
        case false:
        {
            for(int i = 0; i < MarkersCount; i++)
                Markers[i].Precached = (!is_map_not_ze && PrecacheModel(Markers[i].Model, true) != 0);
        }
    }
}