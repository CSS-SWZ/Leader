static char Command[32] = "beacon";

static int BeamSprite = -1;
static int HaloSprite = -1;

static float Delay = 1.0;
static int Color[4] = {128, 128, 128, 255};
static float StartRadius = 10.0;
static float EndRadius = 375.0;
static int Speed = 10;

static Handle BeaconTimer;

bool BeaconParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    BeaconToggle();
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

void BeaconToggle()
{
    if(IsBeaconActive())
    {
        BeaconOff();
    }
    else
    {
        BeaconOn();
    }
}

void BeaconOn()
{
    BeaconOff();

    BeaconTimer = CreateTimer(Delay, Timer_Beacon, CurrentLeader, TIMER_REPEAT);
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

void BeaconOff()
{
    delete BeaconTimer;
}


void BeaconPrecache()
{
    BeamSprite = PrecacheModel("sprites/laser.vmt");
    HaloSprite = PrecacheModel("sprites/halo01.vmt");
}