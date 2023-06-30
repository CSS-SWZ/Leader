#if !defined NEON
    #endinput
#endif

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

bool NeonParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    NeonToggle();
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

void NeonToggle()
{
    if(IsNeonActive())
    {
        NeonOff();
    }
    else
    {
        NeonOn();
    }
}

void NeonOn()
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
}

void NeonOff()
{
    if(Neon)
    {
        int entity = EntRefToEntIndex(Neon);

        if(entity != INVALID_ENT_REFERENCE)
            RemoveEntity(Neon);

        Neon = 0;
    }
}