#if !defined TRAIL
    #endinput
#endif

static char Command[32] = "trail";
static float LifeTime = 2.0;
static float StartWidth = 15.0;
static float EndWidth = 20.0;
static char SpriteName[256] = "materials/nide/leader/trail.vmt";
static char Shift[16] = "0 10.0 10.0";

static int Trail;

bool TrailParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
        
    TrailToggle();
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

void TrailToggle()
{
    if(IsTrailActive())
    {
        TrailOff();
    }
    else
    {
        TrailOn();
    }
}

void TrailOn()
{
    TrailOff();

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
}

void TrailOff()
{
    if(Trail)
    {
        int entity = EntRefToEntIndex(Trail);

        if(entity != INVALID_ENT_REFERENCE)
            RemoveEntity(Trail);

        Trail = 0;
    }
}

void TrailPrecache()
{
    char buffer[256];
    strcopy(buffer, sizeof(buffer), SpriteName);
    PrecacheGeneric(buffer, true);
    ReplaceString(buffer, sizeof(buffer), ".vmt", ".vtf", false);
    PrecacheGeneric(buffer, true);
}