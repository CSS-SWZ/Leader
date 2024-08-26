#define BEAM "sprites/laser.vmt"
#define HALO "sprites/halo01.vmt"

#define BEACON_NOTE_MESSAGE_RU "Вы можете использовать !leader @beacon"
#define BEACON_NOTE_MESSAGE_EN "You can use !leader @beacon"

#define BEACON_ON_FORMAT_RU "%s включил маяк"
#define BEACON_OFF_FORMAT_RU "%s отключил маяк"

#define BEACON_ON_FORMAT_EN "%s turned on the beacon"
#define BEACON_OFF_FORMAT_EN "%s turned off the beacon"

static char Command[32] = "beacon";

static int BeamSprite = -1;
static int HaloSprite = -1;

static float Delay = 1.0;
static int Color[4] = {128, 128, 128, 255};
static float StartRadius = 10.0;
static float EndRadius = 375.0;
static int Speed = 10;

static Handle BeaconTimer;

static int NoteDelay[MAXPLAYERS + 1];
static int NoteCount[MAXPLAYERS + 1];

static bool Precached;

stock void BeaconToggleMessage(bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), BEACON_ON_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), BEACON_ON_FORMAT_EN, name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), BEACON_OFF_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), BEACON_OFF_FORMAT_EN, name);
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

stock void BeaconNote(bool from_menu = true)
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
        case true:  LeaderPrintToChat(leader, BEACON_NOTE_MESSAGE_RU);
        case false: LeaderPrintToChat(leader, BEACON_NOTE_MESSAGE_EN);
    }
}

stock void BeaconOnClientDisconnect(int client)
{
    NoteDelay[client] = 0;
    NoteCount[client] = 0;
}

bool BeaconParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    BeaconToggle(false);
    return true;
}

void BeaconOnKeyValue(const char[] key, const char[] value)
{
    if(!strcmp(key, "command", false))
    {
        strcopy(Command, sizeof(Command), value);
    }
    else if(!strcmp(key, "delay", false))
    {
        Delay = StringToFloat(value);
    }
    else if(!strcmp(key, "Color", false))
    {
        char buffers[4][16];

        int count = ExplodeString(value, " ", buffers, sizeof(buffers), sizeof(buffers[]));

        for(int i = 0; i < count; i++)
            Color[i] = StringToInt(buffers[i]);
    }
    else if(!strcmp(key, "startradius", false))
    {
        StartRadius = StringToFloat(value);
    }
    else if(!strcmp(key, "endradius", false))
    {
        EndRadius = StringToFloat(value);
    }
    else if(!strcmp(key, "endradius", false))
    {
        EndRadius = StringToFloat(value);
    }
    else if(!strcmp(key, "speed", false))
    {
        Speed = StringToInt(value);
    }
}

bool IsBeaconActive()
{
    return !!BeaconTimer;
}

void BeaconToggle(bool from_menu = true)
{
    BeaconNote(from_menu);

    switch(IsBeaconActive())
    {
        case true:  BeaconOff(true);
        case false: BeaconOn(true);
    }
}

void BeaconOn(bool caused_by_client = false)
{
    BeaconOff();

    if(!Precached)
        return;

    BeaconTimer = CreateTimer(Delay, Timer_Beacon, CurrentLeader, TIMER_REPEAT);

    if(caused_by_client)
        BeaconToggleMessage(true);
}

public Action Timer_Beacon(Handle timer, int client)
{
    float vec[3];
    GetClientAbsOrigin(client, vec);
    vec[2] += 10;

    TE_SetupBeamRingPoint(vec, StartRadius, EndRadius, BeamSprite, HaloSprite, 0, 15, 0.5, 5.0, 0.0, Color, Speed, 0);
    TE_SendToAll();

    int rainbowColor[4];
    float i = GetGameTime();
    float Frequency = 2.5;
    rainbowColor[0] = RoundFloat(Sine(Frequency * i + 0.0) * 127.0 + 128.0);
    rainbowColor[1] = RoundFloat(Sine(Frequency * i + 2.0943951) * 127.0 + 128.0);
    rainbowColor[2] = RoundFloat(Sine(Frequency * i + 4.1887902) * 127.0 + 128.0);
    rainbowColor[3] = 255;

    TE_SetupBeamRingPoint(vec, StartRadius, EndRadius, BeamSprite, HaloSprite, 0, 10, 0.6, 10.0, 0.5, rainbowColor, Speed, 0);
    TE_SendToAll();

    return Plugin_Continue;
}

void BeaconOff(bool caused_by_client = false)
{
    delete BeaconTimer;

    if(caused_by_client)
        BeaconToggleMessage(false);
}


void BeaconPrecache()
{
    switch(Late)
    {
        case true:
        {
            Precached = (IsModelPrecached(BEAM) && IsModelPrecached(HALO));

            if(Precached)
            {
                BeamSprite = PrecacheModel(BEAM);
                HaloSprite = PrecacheModel(HALO);
            }
        }
        case false:
        {
            BeamSprite = PrecacheModel(BEAM);
            HaloSprite = PrecacheModel(HALO);
            Precached = (BeamSprite && HaloSprite);
        }
    }
}