stock int GetClientByAccount(int account)
{
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(IsClientInGame(i) && GetSteamAccountID(i) == account)
            return i;
    }

    return 0;
}