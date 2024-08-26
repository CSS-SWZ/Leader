#if !defined MUTE
    #endinput
#endif

#define MUTE_NOTE_MESSAGE_RU "Вы можете использовать !leader @mute"
#define MUTE_NOTE_MESSAGE_EN "You can use !leader @mute"

#define MUTE_ON_FORMAT_RU "%s всех замутил"
#define MUTE_OFF_FORMAT_RU "%s всех размутил"

#define MUTE_ON_FORMAT_EN "%s muted everyone"
#define MUTE_OFF_FORMAT_EN "%s unmuted everyone"

#include <basecomm>

static bool Mute;

static char Command[32] = "mute";

static int NoteDelay[MAXPLAYERS + 1];
static int NoteCount[MAXPLAYERS + 1];

stock void MuteToggleMessage(bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), MUTE_ON_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), MUTE_ON_FORMAT_EN, name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), MUTE_OFF_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), MUTE_OFF_FORMAT_EN, name);
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

stock void MuteNote(bool from_menu = true)
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
        case true:  LeaderPrintToChat(leader, MUTE_NOTE_MESSAGE_RU);
        case false: LeaderPrintToChat(leader, MUTE_NOTE_MESSAGE_EN);
    }
}

stock void MuteOnClientDisconnect(int client)
{
    NoteDelay[client] = 0;
    NoteCount[client] = 0;
}

bool MuteParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;
    
    if(!(GetUserFlagBits(CurrentLeader) & ADMFLAG_BAN))
        return true;

    MuteToggle(false);
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

void MuteToggle(bool from_menu = true)
{
    MuteNote(from_menu);

    switch(IsMuteActive())
    {
        case true:  MuteOff(true);
        case false: MuteOn(true);
    }
}

void MuteOn(bool caused_by_client = false)
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

    if(caused_by_client)
        MuteToggleMessage(true);
}

void MuteOff(bool caused_by_client = false)
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

    if(caused_by_client)
        MuteToggleMessage(false);
}