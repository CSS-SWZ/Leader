#include <sourcemod>
#include <sourcebanspp>
#include <sdktools>
#include <cstrike>

#define MARKERS
#define MUTE
#define NEON
#define TRAIL
#define COOLDOWN
//#define FLAGS

#define TAG "[Leader]"

#define MAX_PHRASES 10
#define MAX_LEADERS 100

#define ACTION_DEATH        0
#define ACTION_DISCONNECT   1
#define ACTION_ROUND_DRAW   2
#define ACTION_ROUND_WIN    3
#define ACTION_ROUND_LOSE   4
#define ACTION_LEADER_COME  5
#define ACTION_LEADER_LEAVE 6
#define ACTIONS_TOTAL       7

#define COLOR_TAG       0
#define COLOR_NAME      1
#define COLOR_DEFAULT   2
#define COLOR_RADIO     3
#define COLORS_TOTAL    4

#pragma newdecls required

int RussianLanguageId;

char Colors[COLORS_TOTAL][16];

int PhrasesCount[ACTIONS_TOTAL];
char Phrases[ACTIONS_TOTAL][MAX_PHRASES][64];

int CurrentLeader;

int LeadersCount;
int LeadersList[MAX_LEADERS];

enum struct Client
{
    bool Access;

    #if defined COOLDOWN
    int CooldownRoundsLeft;
    #endif
}

Client Clients[MAXPLAYERS + 1];

#include "Leader/flags.sp"
#include "Leader/markers.sp"
#include "Leader/config.sp"
#include "Leader/beacon.sp"
#include "Leader/trail.sp"
#include "Leader/neon.sp"
#include "Leader/radio.sp"
#include "Leader/mute.sp"
#include "Leader/menu.sp"
#include "Leader/cooldown.sp"

public Plugin myinfo =
{
    name = "Leader",
    author = "hEl",
    description = "Provides special features to the leader",
    version = "1.0",
    url = "https://github.com/CSS-SWZ/Leader"
};

public void OnPluginStart()
{
    if((RussianLanguageId = GetLanguageByCode("ru")) == -1)
    	SetFailState("Cant find russian language (see languages.cfg)");

    LoadTranslations("common.phrases");

    LoadLeaders();
    LoadConfig();

    RadioInit();
    LeaderMenuInit();

    #if defined FLAGS
    FlagsInit();
    #endif

    FindConVar("mp_restartgame").AddChangeHook(OnGameRestart);

    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_spawn", Event_Callback);
    HookEvent("player_death", Event_Callback);
    HookEvent("player_team", Event_Callback);
    HookEvent("round_end", Event_Callback);

    RegConsoleCmd("sm_leader", Command_Leader);
    RegConsoleCmd("sm_leaders", Command_Leaders);

    RegAdminCmd("sm_leaders_add", Command_LeadersAdd, ADMFLAG_RCON);
    RegAdminCmd("sm_leaders_reload", Command_LeadersReload, ADMFLAG_RCON);

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
            OnClientPutInServer(i);
    }
}

public void OnPluginEnd()
{
    FeaturesOff();
}

public void OnMapStart()
{
    #if defined TRAIL
    TrailPrecache();
    #endif
    
    #if defined MARKERS
    MarkersPrecache();
    #endif

    BeaconPrecache();
    LoadDownloadList();
}

public void OnGameRestart(ConVar cvar, const char[] oldValue, const char[] newValue)
{
    if(!CurrentLeader)
        return;

    if(StringToInt(oldValue) != StringToInt(newValue))
        HandleAction(ACTION_ROUND_DRAW);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    #if defined COOLDOWN
    CooldownOnRoundStart();
    #endif
    FeaturesOff();
    CurrentLeader = 0;
}

public void Event_Callback(Event event, const char[] name, bool dontBroadcast)
{
    if(!CurrentLeader)
        return;

    switch(name[0])
    {
        // round_end
        case 'r':
        {
            int winner = event.GetInt("winner");

            switch(winner)
            {
                case 2:  HandleAction(ACTION_ROUND_LOSE);
                case 3:  HandleAction(ACTION_ROUND_WIN);
                default: HandleAction(ACTION_ROUND_DRAW);
            }
        }
        // player_{death,team,spawn}
        case 'p':
        {
            int client = GetClientOfUserId(event.GetInt("userid"));

            if(CurrentLeader != client)
                return;

            switch(name[10])
            {
                case 't': HandleAction(ACTION_DEATH);
                case 'm': if(event.GetInt("team") == 2 && event.GetInt("oldteam") == 3) RequestFrame(OnLeaderTeam, client);
                case 'w': RequestFrame(OnLeaderSpawn, client);
            }
        }
    }
}

void OnLeaderTeam(int client)
{
    if(CurrentLeader != client)
        return;

    if(GetClientTeam(client) == 2)
        HandleAction(ACTION_DEATH);
}

void OnLeaderSpawn(int client)
{
    if(CurrentLeader != client)
        return;

    if(GetClientTeam(client) == 2)
        HandleAction(ACTION_DEATH);
}

public Action Command_Leader(int client, int args)
{
    if(CurrentLeader)
    {
        if(CurrentLeader == client)
        {
            if(args)
            {
                char buffer[32];
                GetCmdArg(1, buffer, sizeof(buffer));
                if(buffer[0] == '@')
                {
                    strcopy(buffer, sizeof(buffer), buffer[1]);

                    if(BeaconParseCommand(buffer))
                        return Plugin_Handled;

                    #if defined TRAIL
                    if(TrailParseCommand(buffer))
                        return Plugin_Handled;
                    #endif
                    
                    #if defined NEON
                    if(NeonParseCommand(buffer))
                        return Plugin_Handled;
                    #endif
                    
                    #if defined MARKERS
                    if(MarkerParseCommand(buffer))
                        return Plugin_Handled;
                    #endif

                    #if defined MUTE
                    if(MuteParseCommand(buffer))
                        return Plugin_Handled;
                    #endif
                }
            }
            LeaderMenuDisplay();
        }
        else
        {
            char name[64];
            GetClientName(CurrentLeader, name, sizeof(name));
            bool russian = (IsClientRussian(client));
            char message[256];

            FormatEx(message, sizeof(message), russian ? "Сейчас лидерствует %s":"Current leader is %s", name);
            PrintToChat(client, "\x01\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], message);
        }
        return Plugin_Handled;
    }

    if(GetUserFlagBits(client) & ADMFLAG_BAN)
    {
        int target = client;
        if(args)
        {
            char buffer[32];
            GetCmdArg(1, buffer, sizeof(buffer));
            target = FindTarget(client, buffer, true, false);

            if(target == -1)
                return Plugin_Handled;
        }
        if(CurrentLeader != target)
        {
            NewLeader(target);
        }
        else
        {
            HandleAction(ACTION_LEADER_LEAVE);
        }
        return Plugin_Handled;
    }
    if(Clients[client].Access)
    {
        if(args)
            return Plugin_Handled;

        #if defined COOLDOWN
        if(CheckClientCooldown(client))
            return Plugin_Handled;
        #endif

        NewLeader(client);
    }

    bool russian = (IsClientRussian(client));
    char message[256];
    strcopy(message, sizeof(message), russian ? "У вас нет доступа":"You have no access");
    PrintToChat(client, "\x01\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], message);
    return Plugin_Handled;
}

public Action Command_Leaders(int client, int args)
{
    bool russian = (IsClientRussian(client));
    char message[1024];
    FormatEx(message, sizeof(message), "\x01\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], russian ? "Потенциальные лидеры: ":"Potential leaders: ");
    int count;
    char name[64];
    for(int i = 1; i <= MaxClients; i++)
    {
        if(Clients[i].Access)
        {
            GetClientName(i, name, sizeof(name));
            StrCat(message, sizeof(message), name);
            StrCat(message, sizeof(message), ", ");
            count++;
        }
    }

    if(count)
        message[strlen(message) - 2] = 0;
    else
        StrCat(message, sizeof(message), russian ? "отсутствуют":"none");

    PrintToChat(client, message);
    return Plugin_Handled;
}

public Action Command_LeadersAdd(int client, int args)
{
    if(!args)
    {
        ReplyToCommand(client, "Usage: sm_leaders_add <account id> [comment]");
        return Plugin_Handled;
    }

    char buffer[40];
    GetCmdArg(1, buffer, sizeof(buffer));
    int account = StringToInt(buffer);

    if(!account)
    {
        ReplyToCommand(client, "Failure: invalid account id");
        return Plugin_Handled;
    }

    char path[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, path, sizeof(path), "configs/leaders.txt");

    File file = OpenFile(path, "a+");

    if(!file)
    {
        ReplyToCommand(client, "Can`t load file \"%s\"", path);
        return Plugin_Handled;
    }
    file.WriteLine("");
    if(args > 1)
    {
        GetCmdArg(2, buffer, sizeof(buffer));
        file.WriteLine("#%s", buffer);
    }
    file.WriteLine("%i", account);
    delete file;

    ReplyToCommand(client, "Account id \"%i\" was successfully inserted!", account);

    RequestFrame(ReloadLeaders);
    return Plugin_Handled;
}

public Action Command_LeadersReload(int client, int args)
{
    ReloadLeaders();
    ReplyToCommand(client, "[Leader] Leaderboard has been successfully reloaded. Total %i %s", LeadersCount, LeadersCount == 1 ? "leader":"leaders");

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
            OnClientPutInServer(i);
    }
    return Plugin_Handled;
}

void ReloadLeaders()
{
    LeadersCount = 0;
    LoadLeaders();

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientInGame(i))
            OnClientPutInServer(i);
    }
}

public void OnClientPutInServer(int client)
{
    if(!IsFakeClient(client))
    {
        int account = GetSteamAccountID(client);

        int index = FindAccountInLeaderList(account);

        if(index != -1)
            Clients[client].Access = true;

    }

    #if defined FLAGS
    FlagsOnLeaderLoaded(client);
    #endif
}

public void OnClientDisconnect(int client)
{
    if(CurrentLeader == client)
        HandleAction(ACTION_DISCONNECT);

    #if defined COOLDOWN
    CooldownOnClientDisconnect(client);
    #endif

    #if defined FLAGS
    FlagsOnClientDisconnect(client);
    #endif

    Clients[client].Access = false;
}

bool NewLeader(int client)
{
    int team = GetClientTeam(client);

    if(team == 2 || (team > 1 && !IsPlayerAlive(client)))
        return false;
    
    CurrentLeader = client;
    HandleAction(ACTION_LEADER_COME);
    LeaderMenuDisplay();

    return true;
}

void HandleAction(int action)
{
    FeaturesOff();

    #if defined COOLDOWN
    CooldownHandleAction(action);
    #endif

    char message_ru[256];
    char message_en[256];

    char name[MAX_NAME_LENGTH * 2];
    GetClientName(CurrentLeader, name, sizeof(name));
    Format(name, sizeof(name), "\x07%s%s", Colors[COLOR_NAME][1], name);

    int count = PhrasesCount[action];
    int index = GetRandomInt(0, count - 1);

    FormatEx(message_ru, sizeof(message_ru), "%s %s", name, Phrases[action][index]);
    
    switch(action)
    {
        case ACTION_DEATH:      FormatEx(message_en, sizeof(message_ru), "%s %s", name, "has died");
        case ACTION_DISCONNECT: FormatEx(message_en, sizeof(message_en), "%s %s", name, "disconnected");
    }

    PrintActionRusMessage(message_ru);
    PrintActionEngMessage(message_en);

    if(action != ACTION_LEADER_COME)
        CurrentLeader = 0;
}

void FeaturesOff()
{
    BeaconOff();

    #if defined MUTE
    MuteOff();
    #endif

    #if defined MARKERS
    MarkersOff();
    #endif

    #if defined TRAIL
    TrailOff();
    #endif

    #if defined NEON
    NeonOff();
    #endif
}

void PrintActionRusMessage(const char[] message)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || GetClientLanguage(i) != RussianLanguageId)
            continue;

        PrintToChat(i, "\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], message);
    }
}

void PrintActionEngMessage(const char[] message)
{
    if(!message[0])
        return;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(!IsClientInGame(i) || GetClientLanguage(i) == RussianLanguageId)
            continue;

        PrintToChat(i, "\x07%s%s \x07%s%s", Colors[COLOR_TAG][1], TAG, Colors[COLOR_DEFAULT][1], message);
    }
}

void LoadDownloadList()
{
    char path[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, path, sizeof(path), "configs/leader_downloadlist.txt");

    File file = OpenFile(path, "r");

    if(!file)
        return;

    char line[256];
    while(!file.EndOfFile() && file.ReadLine(line, sizeof(line)))
    {
        if(TrimString(line) <= 0 || line[0] == '#')
            continue;

        AddFileToDownloadsTable(line);
    }
    
    delete file;
}

void LoadLeaders()
{
    char path[PLATFORM_MAX_PATH];

    BuildPath(Path_SM, path, sizeof(path), "configs/leaders.txt");

    File file = OpenFile(path, "r");

    if(!file)
        return;

    int account;
    char line[40];
    while(!file.EndOfFile() && file.ReadLine(line, sizeof(line)) && LeadersCount < MAX_LEADERS)
    {
        if(TrimString(line) <= 0 || line[0] == '#')
            continue;

        account = StringToInt(line);

        if(!account)
            continue;

        LeadersList[LeadersCount] = account;
        ++LeadersCount;
    }
    
    delete file;
}

int FindAccountInLeaderList(int account)
{
    for(int i = 0; i < LeadersCount; i++)
    {
        if(LeadersList[i] == account)
            return i;
    }

    return -1;
}

stock bool IsClientRussian(int client)
{
    return (GetClientLanguage(client) == RussianLanguageId);
}

int GetPotintialLeadersCount()
{
    int count = 0;

    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientPotentialLeader(i))
            ++count;
    }

    return count;
}

bool IsClientPotentialLeader(int client)
{
    return Clients[client].Access;
}