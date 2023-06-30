#if !defined MUTE
    #endinput
#endif

#include <basecomm>

static bool Mute;

static char Command[32] = "mute";

bool MuteParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
    
    if(!(GetUserFlagBits(CurrentLeader) & ADMFLAG_BAN))
        return true;

    MuteToggle();
    return true;
}

void MuteOnKeyValue(const char[] key, const char[] value)
{
    if(!strcmp(key, "command", false))
    {
        strcopy(Command, sizeof(Command), value);
    }
}

public void OnClientSpeaking(int client)
{
    if(!Mute)
        return;

    if(BaseComm_IsClientMuted(client))
        return;

    BaseComm_SetClientMute(client, true);
}

bool IsMuteActive()
{
    return Mute;
}

void MuteToggle()
{
    if(IsMuteActive())
    {
        MuteOff();
    }
    else
    {
        MuteOn();
    }
}

void MuteOn()
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if(CurrentLeader == i)
            continue;

        if(BaseComm_IsClientMuted(i))
            continue;

        BaseComm_SetClientMute(i, true);
    }
    Mute = true;
}

void MuteOff()
{
    if(!Mute)
        return;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if(CurrentLeader == i)
            continue;

        if(!BaseComm_IsClientMuted(i))
            continue;

        BaseComm_SetClientMute(i, false);
    }

    Mute = false;
}