#if !defined FLAGS
	#endinput
#endif

#if !defined _sourcebanspp_included
	#undef FLAGS
	#endinput
#endif

static ConVar FlagsCvar;
static ConVar GroupCvar;

static bool Enable;
static char Group[32];
static int Flags;

static bool leader_loaded[MAXPLAYERS + 1];

void FlagsInit()
{
	FlagsCvar = CreateConVar("sm_leader_flags", "t", "", 0, false, 0.0, false, 0.0);
	GroupCvar = CreateConVar("sm_leader_group", "", "", 0, false, 0.0, false, 0.0);
	ReadFlags();
	GroupCvar.GetString(Group, sizeof(Group));

	FlagsCvar.AddChangeHook(OnConVarFlagsChanged);
	GroupCvar.AddChangeHook(OnConVarFlagsChanged);

	Enable = (Flags || Group[0]);
}

void ReadFlags()
{
	char flags[64];
	FlagsCvar.GetString(flags, sizeof(flags));
	Flags = ReadFlagString(flags);
}

public void OnConVarFlagsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if (convar == FlagsCvar)
	{
		ReadFlags();
	}
	else if(convar == GroupCvar)
	{
		convar.GetString(Group, sizeof(Group));
	}

	Enable = (Flags || Group[0]);
}

void FlagsOnLeaderLoaded(int client)
{
	leader_loaded[client] = true;

	if(sourcebanspp)
		SBPP_CheckLoadAdmin(client);
}

public Action SBPP_OnCheckLoadAdmin(int client)
{
	if (!Enable)
		return Plugin_Continue;

	return leader_loaded[client] ? Plugin_Continue:Plugin_Handled;
}

public void OnClientPostAdminFilter(int client)
{
	GiveClientPerks(client);
}

stock void GiveClientPerks(int client)
{
	if(!Enable)
		return;

	if(!leader_loaded[client])
		return;

	bool leader = Clients[client].Access;

	if(!leader)
		return;

	GroupId group;
	if (Group[0] && (group = FindAdmGroup(Group)) != INVALID_GROUP_ID)
	{
		AdminId admin = GetUserAdmin(client);
		if (admin == INVALID_ADMIN_ID)
		{
			admin = CreateAdmin("");
			SetUserAdmin(client, admin, true);
			admin.InheritGroup(group);
		}
		else
		{
			SetUserFlagBits(client, group.GetFlags() | GetUserFlagBits(client));
		}
	}
	else
	{
		SetUserFlagBits(client, Flags | GetUserFlagBits(client));
	}
}

public void FlagsOnClientDisconnect(int client)
{
	leader_loaded[client] = false;
}