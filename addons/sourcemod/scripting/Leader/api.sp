/**
 * Внешний API: нативы и форварды для других плагинов.
 * Публичный интерфейс описан в scripting/include/leader.inc.
 *
 * Причины снятия лидера намеренно отвязаны от внутренних ACTION_*: те содержат
 * ACTION_LEADER_COME, которого в "removed" быть не может, а их порядок — сугубо
 * внутреннее дело плагина.
 *
 * Модуль не гейтится: набор нативов не должен зависеть от того, с какими
 * #define собран плагин, иначе потребитель падает на несуществующем нативе.
 */

static GlobalForward FwdLeaderSet;
static GlobalForward FwdLeaderRemoved;

// Момент назначения действующего лидера (GetGameTime).
static float SetTime;

void APIInit()
{
    CreateNative("Leader_GetLeader", Native_GetLeader);
    CreateNative("Leader_GetLeaderTime", Native_GetLeaderTime);
    CreateNative("Leader_IsClientLeader", Native_IsClientLeader);
    CreateNative("Leader_SetLeader", Native_SetLeader);
    CreateNative("Leader_RemoveLeader", Native_RemoveLeader);
    CreateNative("Leader_IsClientPotentialLeader", Native_IsClientPotentialLeader);
    CreateNative("Leader_GetPotentialLeadersCount", Native_GetPotentialLeadersCount);

    RegPluginLibrary("leader");
}

void APIOnPluginStart()
{
    FwdLeaderSet = new GlobalForward("Leader_OnLeaderSet", ET_Ignore, Param_Cell);
    FwdLeaderRemoved = new GlobalForward("Leader_OnLeaderRemoved", ET_Ignore, Param_Cell, Param_Cell, Param_Float);
}

void APIOnLeaderSet(int client)
{
    SetTime = GetGameTime();

    Call_StartForward(FwdLeaderSet);
    Call_PushCell(client);
    Call_Finish();
}

void APIOnLeaderRemoved(int client, LeaderRemoveReason reason)
{
    Call_StartForward(FwdLeaderRemoved);
    Call_PushCell(client);
    Call_PushCell(reason);
    Call_PushFloat(GetGameTime() - SetTime);
    Call_Finish();

    SetTime = 0.0;
}

void APIOnHandleAction(int action)
{
    LeaderRemoveReason reason;

    switch(action)
    {
        case ACTION_DEATH:      reason = LeaderRemove_Death;
        case ACTION_DISCONNECT: reason = LeaderRemove_Disconnect;
        case ACTION_ROUND_DRAW: reason = LeaderRemove_RoundDraw;
        case ACTION_ROUND_WIN:  reason = LeaderRemove_RoundWin;
        case ACTION_ROUND_LOSE: reason = LeaderRemove_RoundLose;

        // Сюда попадает только ACTION_LEADER_LEAVE: ACTION_LEADER_COME лидера
        // не снимает и до этой функции не доходит.
        default:                reason = LeaderRemove_Left;
    }

    APIOnLeaderRemoved(CurrentLeader, reason);
}

public any Native_GetLeader(Handle plugin, int numParams)
{
    return CurrentLeader;
}

public any Native_GetLeaderTime(Handle plugin, int numParams)
{
    if(!CurrentLeader)
        return 0.0;

    return GetGameTime() - SetTime;
}

public any Native_IsClientLeader(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
        return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);

    return (CurrentLeader == client);
}

public any Native_SetLeader(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients || !IsClientInGame(client))
        return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);

    if(CurrentLeader == client)
        return false;

    return NewLeader(client);
}

public any Native_RemoveLeader(Handle plugin, int numParams)
{
    if(!CurrentLeader)
        return false;

    HandleAction(ACTION_LEADER_LEAVE);
    return true;
}

public any Native_IsClientPotentialLeader(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if(client < 1 || client > MaxClients)
        return ThrowNativeError(SP_ERROR_NATIVE, "Client index %i is invalid", client);

    return IsClientPotentialLeader(client);
}

public any Native_GetPotentialLeadersCount(Handle plugin, int numParams)
{
    return GetPotentialLeadersCount();
}
