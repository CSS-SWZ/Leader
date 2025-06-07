#if !defined TRAIL
    #endinput
#endif

#define TRAIL_NOTE_MESSAGE_RU "Вы можете использовать !leader @trail"
#define TRAIL_NOTE_MESSAGE_EN "You can use !leader @trail"

#define TRAIL_ON_FORMAT_RU "%s включил трейл"
#define TRAIL_OFF_FORMAT_RU "%s выключил трейл"

#define TRAIL_ON_FORMAT_EN "%s turned on the trail"
#define TRAIL_OFF_FORMAT_EN "%s turned off the trail"

static char Command[32] = "trail";
static float LifeTime = 2.0;
static float StartWidth = 15.0;
static float EndWidth = 20.0;
static char SpriteName[256] = "materials/nide/leader/trail.vmt";
static char Shift[16] = "0 10.0 10.0";

static int Trail;

static int NoteDelay[MAXPLAYERS + 1];
static int NoteCount[MAXPLAYERS + 1];

bool Precached;

stock void TrailToggleMessage(bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), TRAIL_ON_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), TRAIL_ON_FORMAT_EN, name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), TRAIL_OFF_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), TRAIL_OFF_FORMAT_EN, name);
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

stock void TrailNote(bool from_menu = true)
{
    if(!from_menu)
        return;

    int time = GetTime();
    int leader = CurrentLeader;

    if(NoteDelay[leader] > time)
        return;

    if(NoteCount[leader] >= NOTE_COUNT_MAX)
        return;

    ++NoteCount[leader];
    NoteDelay[leader] = time + NOTE_DELAY;

    switch(IsClientRussian(leader))
    {
        case true:  LeaderPrintToChat(leader, TRAIL_NOTE_MESSAGE_RU);
        case false: LeaderPrintToChat(leader, TRAIL_NOTE_MESSAGE_EN);
    }
}

stock void TrailOnClientDisconnect(int client)
{
    NoteDelay[client] = 0;
    NoteCount[client] = 0;
}

bool TrailParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    TrailToggle(false);
    return true;
}

void TrailOnKeyValue(const char[] key, const char[] value)
{
    if(!strcmp(key, "command", false))
    {
        strcopy(Command, sizeof(Command), value);
    }
    else if(!strcmp(key, "lifetime", false))
    {
        LifeTime = StringToFloat(value);
    }
    else if(!strcmp(key, "startwidth", false))
    {
        StartWidth = StringToFloat(value);
    }
    else if(!strcmp(key, "endwidth", false))
    {
        EndWidth = StringToFloat(value);
    }
    else if(!strncmp(key, "sprite", 6, false))
    {
        strcopy(SpriteName, sizeof(SpriteName), value);
    }
    else if(!strcmp(key, "shift", false))
    {
        strcopy(Shift, sizeof(Shift), value);
    }

}

bool IsTrailActive()
{
    return (Trail && EntRefToEntIndex(Trail) != INVALID_ENT_REFERENCE);
}

void TrailToggle(bool from_menu = true)
{
    TrailNote(from_menu);

    switch(IsTrailActive())
    {
        case true:  TrailOff(true);
        case false: TrailOn(true);
    }
}

void TrailOn(bool caused_by_client = false)
{
    TrailOff();

    if(!Precached)
        return;

    int entity = CreateEntityByName("env_spritetrail");

    if(entity == INVALID_ENT_REFERENCE)
        return;

    //float dest_vector[3];
    float origin[3];
        
    DispatchKeyValueFloat(entity, "lifetime", LifeTime);
        

    DispatchKeyValueFloat(entity, "startwidth", StartWidth);
    DispatchKeyValueFloat(entity, "endwidth", EndWidth);
        
    DispatchKeyValue(entity, "spritename", SpriteName);
    DispatchKeyValue(entity, "renderamt", "255");
    DispatchKeyValue(entity, "rendercolor", "255 255 255");
    
    DispatchKeyValue(entity, "rendermode", "1");
    DispatchKeyValue(entity, "disablereceiveshadows", "1");

    // We give the name for our entities here
    DispatchKeyValue(entity, "targetname", "trail");
        
    DispatchSpawn(entity);

    char angle[3][8];
    float angles[3]; 

    ExplodeString(Shift, " ", angle, sizeof(angle), sizeof(angle[]), false);
    angles[0] = StringToFloat(angle[0]);
    angles[1] = StringToFloat(angle[1]);
    angles[2] = StringToFloat(angle[2]);

    GetClientAbsOrigin(CurrentLeader, origin);
    origin[0] += angles[0];
    origin[1] += angles[1];
    origin[2] += angles[2];
        
    TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
        
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", CurrentLeader); 
    SetEntPropFloat(entity, Prop_Send, "m_flTextureRes", 0.05);
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", CurrentLeader);

    Trail = EntIndexToEntRef(entity);

    if(caused_by_client)
        TrailToggleMessage(true);
}

void TrailOff(bool caused_by_client = false)
{
    if(Trail)
    {
        int entity = EntRefToEntIndex(Trail);

        if(entity != INVALID_ENT_REFERENCE)
            RemoveEntity(Trail);

        Trail = 0;

        if(caused_by_client)
            TrailToggleMessage(false);
    }
}

void TrailPrecache()
{
    char vtf[256];
    char vmt[256];
    strcopy(vmt, sizeof(vmt), SpriteName);
    strcopy(vtf, sizeof(vtf), SpriteName);
    ReplaceString(vtf, sizeof(vtf), ".vmt", ".vtf", false);

    switch(Late)
    {
        case true:
        {
            Precached = (!is_map_not_ze && IsGenericPrecached(vmt) && IsGenericPrecached(vtf));
        }
        case false:
        {
            Precached = (!is_map_not_ze && PrecacheGeneric(vmt, true) && PrecacheGeneric(vtf, true));
        }
    }
}