static bool Late;

void LateOnAskPluginLoad2(bool late)
{
    Late = late;
}

// If plugin was loaded late but no real clients are connected yet,
// treat it as safe for precache/downloads on this map.
void LateInit()
{
    if(!Late)
        return;

    for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientConnected(i))
            continue;

        if(IsFakeClient(i))
            continue;

        return;
    }
    Late = false;
}

void LateOnMapEnd()
{
    Late = false;
}

bool LateIsPluginLoadedLate()
{
    return Late;
}