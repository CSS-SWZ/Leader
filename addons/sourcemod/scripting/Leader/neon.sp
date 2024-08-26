#if !defined NEON
    #endinput
#endif

#define NEON_NOTE_MESSAGE_RU "Вы можете использовать !leader @neon"
#define NEON_NOTE_MESSAGE_EN "You can use !leader @neon"

#define NEON_ON_FORMAT_RU "%s включил неон"
#define NEON_OFF_FORMAT_RU "%s выключил неон"

#define NEON_ON_FORMAT_EN "%s turned on the neon"
#define NEON_OFF_FORMAT_EN "%s turned off the trail"

static char Command[32] = "neon";
static char Brightness[16] = "5";
static char Light[32] = "0 0 255 255";
static float SpotlightRadius = 50.0;
static char InnerCone[16] = "0";
static char Cone[16] = "0";
static char Angles[32] = "0 0 0";
static float Distance = 100.0;
static char Pitch[16] = "0";
static int Neon;

static int NoteDelay[MAXPLAYERS + 1];
static int NoteCount[MAXPLAYERS + 1];

stock void NeonToggleMessage(bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), NEON_ON_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), NEON_ON_FORMAT_EN, name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), NEON_OFF_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), NEON_OFF_FORMAT_EN, name);
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

stock void NeonNote(bool from_menu = true)
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
        case true:  LeaderPrintToChat(leader, NEON_NOTE_MESSAGE_RU);
        case false: LeaderPrintToChat(leader, NEON_NOTE_MESSAGE_EN);
    }
}

stock void NeonOnClientDisconnect(int client)
{
    NoteDelay[client] = 0;
    NoteCount[client] = 0;
}

bool NeonParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    NeonToggle(false);
    return true;
}

void NeonOnKeyValue(const char[] key, const char[] value)
{
    if(!strcmp(key, "command", false))
    {
        strcopy(Command, sizeof(Command), value);
    }
    else if(!strcmp(key, "brightness", false))
    {
        strcopy(Brightness, sizeof(Brightness), value);
    }
    else if(!strcmp(key, "light", false))
    {
        strcopy(Light, sizeof(Light), value);
    }
    else if(!strcmp(key, "spotlightradius", false))
    {
        SpotlightRadius = StringToFloat(value);
    }
    else if(!strcmp(key, "inner_cone", false))
    {
        strcopy(InnerCone, sizeof(InnerCone), value);
    }
    else if(!strcmp(key, "cone", false))
    {
        strcopy(Cone, sizeof(Cone), value);
    }
    else if(!strcmp(key, "angles", false))
    {
        strcopy(Angles, sizeof(Angles), value);
    }
    else if(!strcmp(key, "distance", false))
    {
        Distance = StringToFloat(value);
    }
    else if(!strcmp(key, "pitch", false))
    {
        strcopy(Pitch, sizeof(Pitch), value);
    }
}

bool IsNeonActive()
{
    return (Neon && EntRefToEntIndex(Neon) != INVALID_ENT_REFERENCE);
}

void NeonToggle(bool from_menu = true)
{
    NeonNote(from_menu);

    switch(IsNeonActive())
    {
        case true:  NeonOff(true);
        case false: NeonOn(true);
    }
}

void NeonOn(bool caused_by_client = false)
{
    NeonOff();

    int entity = CreateEntityByName("light_dynamic");

    if(entity == INVALID_ENT_REFERENCE)
        return;

    DispatchKeyValue(entity, "brightness", Brightness);
    DispatchKeyValue(entity, "_light", Light);
    DispatchKeyValueFloat(entity, "spotlight_radius", SpotlightRadius);
    DispatchKeyValue(entity, "_inner_cone", InnerCone);
    DispatchKeyValue(entity, "_cone", Cone);
    DispatchKeyValue(entity, "angles", Angles);
    DispatchKeyValueFloat(entity, "distance", Distance);
    DispatchKeyValue(entity, "pitch", Pitch);
    DispatchKeyValue(entity, "style", "0");
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", CurrentLeader);

    if(!DispatchSpawn(entity))
        return;


    AcceptEntityInput(entity, "TurnOn");

    float origin[3];
    GetClientAbsOrigin(CurrentLeader, origin);
    TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);

    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", CurrentLeader, entity, 0);

    Neon = EntIndexToEntRef(entity);

    if(caused_by_client)
        NeonToggleMessage(true);
}

void NeonOff(bool caused_by_client = false)
{
    if(Neon)
    {
        int entity = EntRefToEntIndex(Neon);

        if(entity != INVALID_ENT_REFERENCE)
            RemoveEntity(Neon);

        Neon = 0;

        if(caused_by_client)
            NeonToggleMessage(false);
    }
}