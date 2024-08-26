static Menu LeaderMenu;

void LeaderMenuInit()
{
    LeaderMenu = new Menu(LeaderMenu_Handler, MenuAction_Select)
}

void LeaderMenuDisplay()
{
    bool russian = IsClientRussian(CurrentLeader);

    switch(russian)
    {
        case true:  LeaderMenu.SetTitle("Лидер меню");
        case false: LeaderMenu.SetTitle("Leader LeaderMenu");
    }
    LeaderMenu.RemoveAllItems();

    char buffer[256];
    FormatEx(buffer, sizeof(buffer), "%s: [%s]", russian ? "Маяк":"Beacon", IsBeaconActive() ? "+":"-");
    LeaderMenu.AddItem("Beacon", buffer);

    #if defined TRAIL
    FormatEx(buffer, sizeof(buffer), "%s: [%s]", russian ? "Трейл":"Trail", IsTrailActive() ? "+":"-");
    LeaderMenu.AddItem("Trail", buffer);
    #endif

    #if defined NEON
    FormatEx(buffer, sizeof(buffer), "%s: [%s]", russian ? "Неон":"Neon", IsNeonActive() ? "+":"-");
    LeaderMenu.AddItem("Neon", buffer);
    #endif

    #if defined MUTE
    if(GetUserFlagBits(CurrentLeader) & ADMFLAG_BAN)
    {
        FormatEx(buffer, sizeof(buffer), "%s: [%s]", russian ? "Мут всех":"Mute all", IsMuteActive() ? "+":"-");
        LeaderMenu.AddItem("Comms", buffer);
    }
    #endif

    #if defined MARKERS
    LeaderMenu.AddItem("Markers", russian ? "Маркеры":"Markers");
    #endif

    LeaderMenu.AddItem("Leave", russian ? "Покинуть":"Leave");
    LeaderMenu.Display(CurrentLeader, 0);
}

public int LeaderMenu_Handler(Menu menu, MenuAction action, int client, int item)
{
    if(!CurrentLeader || CurrentLeader != client)
        return 0;

    char info[16];
    menu.GetItem(item, info, sizeof(info));

    switch(info[0])
    {
        case 'B':
        {
            BeaconToggle();
            LeaderMenuDisplay();
        }

        #if defined TRAIL
        case 'T':
        {
            TrailToggle();
            LeaderMenuDisplay();
        }
        #endif

        #if defined NEON
        case 'N':
        {
            NeonToggle();
            LeaderMenuDisplay();
        }
        #endif

        #if defined MARKERS
        case 'M':
        {
            MarkersMenu(client);
        }
        #endif

        #if defined MUTE
        case 'C':
        {
            MuteToggle();
            LeaderMenuDisplay();
        }
        #endif

        case 'L':
        {
            HandleAction(ACTION_LEADER_LEAVE);
        }
    }
    return 0;
}
