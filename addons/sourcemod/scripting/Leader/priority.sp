#if !defined PRIORITY
    #endinput
#endif

#define PRIORITY_NOTE_MESSAGE_RU "Вы можете использовать !leader @priority"
#define PRIORITY_NOTE_MESSAGE_EN "You can use !leader @priority"

#define PRIORITY_ON_FORMAT_RU "%s включил приоритет голоса"
#define PRIORITY_OFF_FORMAT_RU "%s выключил приоритет голоса"

#define PRIORITY_ON_FORMAT_EN "%s turned on voice priority"
#define PRIORITY_OFF_FORMAT_EN "%s turned off voice priority"

// Кого глушить, пока лидер говорит. Битовое поле, ключ "targets".
#define TARGET_CT       (1 << 0)
#define TARGET_T        (1 << 1)
#define TARGET_SPEC     (1 << 2)
#define TARGET_ADMINS   (1 << 3)

static char Command[32] = "priority";
static int Targets = TARGET_CT|TARGET_T|TARGET_SPEC;

static bool Active;     // фича включена лидером
static bool Ducking;    // лидер говорит прямо сейчас

static int NoteDelay[MAXPLAYERS + 1];
static int NoteCount[MAXPLAYERS + 1];

stock void PriorityToggleMessage(bool toggle)
{
    char name[64];
    GetClientName(CurrentLeader, name, sizeof(name));

    char message_ru[256];
    char message_en[256];

    switch(toggle)
    {
        case true:
        {
            FormatEx(message_ru, sizeof(message_ru), PRIORITY_ON_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), PRIORITY_ON_FORMAT_EN, name);

        }
        case false:
        {
            FormatEx(message_ru, sizeof(message_ru), PRIORITY_OFF_FORMAT_RU, name);
            FormatEx(message_en, sizeof(message_en), PRIORITY_OFF_FORMAT_EN, name);
        }
    }

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i) || !IsPlayerAlive(i) || i == CurrentLeader || GetClientTeam(i) != 3)
            continue;

        if(GetClientLanguage(i) == RussianLanguageId)
        {
            LeaderPrintToChat(i, "%s", message_ru);
        }
        else
        {
            LeaderPrintToChat(i, "%s", message_en);
        }
    }
}

stock void PriorityNote(bool from_menu = true)
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
        case true:  LeaderPrintToChat(leader, PRIORITY_NOTE_MESSAGE_RU);
        case false: LeaderPrintToChat(leader, PRIORITY_NOTE_MESSAGE_EN);
    }
}

stock void PriorityOnClientDisconnect(int client)
{
    NoteDelay[client] = 0;
    NoteCount[client] = 0;
}

bool PriorityParseCommand(const char[] command)
{
    if(strcmp(Command, command, false))
        return false;

    PriorityToggle(false);
    return true;
}

void PriorityOnKeyValue(const char[] key, const char[] value)
{
    if(!strcmp(key, "command", false))
    {
        strcopy(Command, sizeof(Command), value);
    }
    else if(!strcmp(key, "targets", false))
    {
        Targets = StringToInt(value);
    }
}

void PriorityOnConfigsExecuted()
{
    // Ненулевой sm_deadtalk заставляет basecomm вешать хуки на player_spawn и
    // player_death (basecomm.sp:131-144) и переписывать там голосовые флаги.
    // Это снимет наше глушение с любого, кто умер во время речи лидера.
    ConVar deadtalk = FindConVar("sm_deadtalk");

    if(deadtalk && deadtalk.IntValue)
        LogError("sm_deadtalk is %i: basecomm rewrites voice flags on spawn/death and will cancel voice priority", deadtalk.IntValue);
}

bool IsPriorityActive()
{
    return Active;
}

void PriorityToggle(bool from_menu = true)
{
    PriorityNote(from_menu);

    switch(IsPriorityActive())
    {
        case true:  PriorityOff(true);
        case false: PriorityOn(true);
    }
}

void PriorityOn(bool caused_by_client = false)
{
    Active = true;

    if(caused_by_client)
        PriorityToggleMessage(true);
}

void PriorityOff(bool caused_by_client = false)
{
    PriorityDuckOff();

    if(caused_by_client && Active)
        PriorityToggleMessage(false);

    Active = false;
}

// OnClientSpeaking приходит на каждом голосовом пакете (hooks.cpp:598-606),
// поэтому фронт речи ловим сами — по флагу Ducking.
void PriorityOnClientSpeaking(int client)
{
    if(!Active || client != CurrentLeader)
        return;

    PriorityDuckOn();
}

void PriorityOnClientSpeakingEnd(int client)
{
    if(client != CurrentLeader)
        return;

    PriorityDuckOff();
}

static void PriorityDuckOn()
{
    if(Ducking)
        return;

    Ducking = true;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsPriorityTarget(i))
            VoiceMute(i, REASON_PRIORITY);
    }
}

static void PriorityDuckOff()
{
    if(!Ducking)
        return;

    Ducking = false;

    // Снимаем со всех, а не только с тех, кого глушили: игрок мог сменить
    // команду посреди речи. VoiceUnmute без нашей причины ничего не делает.
    for(int i = 1; i <= MaxClients; i++)
        VoiceUnmute(i, REASON_PRIORITY);
}

static bool IsPriorityTarget(int client)
{
    if(client == CurrentLeader)
        return false;

    if(!IsClientInGame(client) || IsFakeClient(client))
        return false;

    if(!(Targets & TARGET_ADMINS) && (GetUserFlagBits(client) & (ADMFLAG_GENERIC|ADMFLAG_ROOT)))
        return false;

    switch(GetClientTeam(client))
    {
        case 3:  return !!(Targets & TARGET_CT);
        case 2:  return !!(Targets & TARGET_T);
        default: return !!(Targets & TARGET_SPEC);
    }
}
