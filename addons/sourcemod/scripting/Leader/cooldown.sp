#if !defined COOLDOWN
    #endinput
#endif

static int RoundTime;

bool CheckClientCooldown(int client)
{
    if(Clients[client].CooldownRoundsLeft <= 0)
        return false;

    if(GetTime() - RoundTime < 7)
    {
        switch(IsClientRussian(client))
        {
            case true:  LeaderPrintToChat(client, "Подождите немного!");
            case false: LeaderPrintToChat(client, "Wait a bit!");
        }
        
        return true;
    }

    return false;
}

void CooldownHandleAction(int action)
{
    if(!IsClientPotentialLeader(CurrentLeader))
        return;

    int count = GetPotintialLeadersCount();

    if(count <= 1)
        return;

    switch(action)
    {
        case ACTION_DEATH, ACTION_ROUND_LOSE:
        {
            Clients[CurrentLeader].CooldownRoundsLeft = count;
        }
    }
}

void CooldownOnRoundStart()
{
    RoundTime = GetTime();

    for(int i = 1; i <= MaxClients; i++)
    {
        if(Clients[i].CooldownRoundsLeft > 0)
            --Clients[i].CooldownRoundsLeft;
    }
}

void CooldownOnClientDisconnect(int client)
{
    Clients[client].CooldownRoundsLeft = 0;
}