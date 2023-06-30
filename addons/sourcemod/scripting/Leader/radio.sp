#define RADIO_TOTAL 21
#define MAX_RADIO_PHRASES 10

static int RadioPhrasesCount[RADIO_TOTAL];
static char RadioPhrases[RADIO_TOTAL][MAX_RADIO_PHRASES][64];
static char RadioPhrasesColors[RADIO_TOTAL][16];

static const char RadioCommands[][] = 
{
    "coverme",
    "takepoint",
    "holdpos",
    "regroup",
    "followme",
    "takingfire",
    "go",
    "fallback",
    "sticktog",
    "getinpos",
    "stormfront",
    "report",
    "roger",
    "enemyspot",
    "needbackup",
    "sectorclear",
    "inposition",
    "reportingin",
    "getout",
    "negative",
    "enemydown"
}

static const char RadioPhrasesEng[][] = 
{
    "Cover Me!",
    "You take the point.",
    "Hold This Position.",
    "Regroup Team.",
    "Follow me.",
    "Taking fire... need assistance!",
    "Go go go!",
    "Team, fall back!",
	"Stick together, team.",
	"Report in, team.",
	"Roger that.",
	"Enemy spotted.",
	"Need backup.",
	"Sector clear.",
	"I'm in position.",
    "Get in position and wait for my go",
	"Storm the Front!",
	"Reporting In.",
	"Get out of there, it's gonna blow!.",
	"Negative.",
	"Enemy down."
}

void RadioOnKeyValue(const char[] key, const char[] value)
{
    int radio = GetRadioCommand(key);

    if(radio == -1)
        return;

    int count = RadioPhrasesCount[radio];

    if(count >= MAX_RADIO_PHRASES)
        return;

    strcopy(RadioPhrases[radio][count], sizeof(RadioPhrases[][]), value);
    ++RadioPhrasesCount[radio];
}

void RadioColorsOnKeyValue(const char[] key, const char[] value)
{
    int radio = GetRadioCommand(key);

    if(radio == -1)
        return;

    strcopy(RadioPhrasesColors[radio], sizeof(RadioPhrasesColors[]), value);
}

void RadioColorsOnEndSection()
{
    for(int i = 0; i < RADIO_TOTAL; i++)
    {
        if(!RadioPhrasesColors[i][0])
            strcopy(RadioPhrasesColors[i], sizeof(RadioPhrasesColors[]), Colors[COLOR_RADIO]);
    }
}

void RadioInit()
{
    for(int i = 0; i < sizeof(RadioCommands); i++)
        AddCommandListener(Command_Radio, RadioCommands[i]);
}

public Action Command_Radio(int client, const char[] command, int argc)
{
    if(!CurrentLeader || CurrentLeader != client)
        return Plugin_Continue;

    int radio = GetRadioCommand(command);
    PrintRadio(client, radio);
    return Plugin_Handled;
}

void PrintRadio(int client, int radio)
{
    char clantag[32];
    CS_GetClientClanTag(client, clantag, sizeof(clantag));
    
    char name[64];
    GetClientName(client, name, sizeof(name));
    char message_ru[256];
    char message_en[256];
    
    int count = RadioPhrasesCount[radio];
    int index = GetRandomInt(0, count - 1);
    FormatEx(message_ru, sizeof(message_en), "\x01\x07%s%s \x07%s%s %s (РАДИО): \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], clantag, name, RadioPhrasesColors[radio][1], RadioPhrases[radio][index]);
    FormatEx(message_en, sizeof(message_en), "\x01\x07%s%s \x07%s%s %s (RADIO): \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], clantag, name, RadioPhrasesColors[radio][1], RadioPhrasesEng[radio]);
    
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || IsFakeClient(i) || GetClientTeam(i) != 3)
            continue;
    
        if(GetClientLanguage(i) == RussianLanguageId)
        {
            PrintToChat(i, message_ru);
        }
        else
        {
            PrintToChat(i, message_en);
        }
    }
}

static int GetRadioCommand(const char[] command)
{
    for(int i = 0; i < sizeof(RadioCommands); i++)
    {
        if(!strcmp(RadioCommands[i], command, false))
            return i;
    }

    return -1;
}